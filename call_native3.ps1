$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Native {
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr LoadLibraryA(string name);
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr GetProcAddress(IntPtr h, string name);
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate IntPtr CharPtrFn();
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate IntPtr CharPtrFn2(IntPtr arg);
}
"@

$h = [Native]::LoadLibraryA("C:\Program Files (x86)\Javelin3\DrumlinRast.dll")
Write-Output ("handle: " + $h)
$modLo = 0x10000000
$modHi = 0x12000000

function DumpBytes($label, $addr, $len) {
    $v = $addr.ToInt64()
    if ($v -lt $modLo -or $v -gt $modHi) { Write-Output "$label : [outside module] 0x$($v.ToString('X'))"; return }
    $sb = New-Object System.Text.StringBuilder
    $ascii = ""
    for ($i = 0; $i -lt $len; $i++) {
        $b = [System.Runtime.InteropServices.Marshal]::ReadByte($addr, $i)
        [void]$sb.Append($b.ToString("X2"))
        if ($b -ge 32 -and $b -lt 127) { $ascii += [char]$b } else { $ascii += "." }
    }
    Write-Output ("$label : " + $sb.ToString())
    Write-Output ("$label : |" + $ascii)
}

Write-Output "===== CALL FUNCTIONS FIRST ====="
foreach ($fn in @("?Key@CPublisher@@SAPADXZ","?Iv@CPublisher@@SAPADXZ","?IvUSK@CPublisher@@SAPADXZ")) {
    $addr = [Native]::GetProcAddress($h, $fn)
    if ($addr -eq [IntPtr]::Zero) { Write-Output "$fn NOT FOUND"; continue }
    try {
        $d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($addr, [type][Native+CharPtrFn])
        $r = $d.Invoke()
        Write-Output "CALL $fn -> 0x$($r.ToString('X8'))"
        if ($r -ne [IntPtr]::Zero) { DumpBytes "  result" $r 64 }
    } catch {
        Write-Output "CALL $fn FAILED: $($_.Exception.Message)"
    }
}

$addr = [Native]::GetProcAddress($h, "?KeyUSK@CPublisher@@SAPADPAD@Z")
if ($addr -ne [IntPtr]::Zero) {
    try {
        $kb = [System.Text.Encoding]::ASCII.GetBytes("u~*e|wt{,")
        $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($kb.Length + 1)
        [System.Runtime.InteropServices.Marshal]::Copy($kb, 0, $buf, $kb.Length)
        [System.Runtime.InteropServices.Marshal]::WriteByte($buf, $kb.Length, 0)
        $d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($addr, [type][Native+CharPtrFn2])
        $r = $d.Invoke($buf)
        Write-Output "CALL KeyUSK(keycode) -> 0x$($r.ToString('X8'))"
        if ($r -ne [IntPtr]::Zero) { DumpBytes "  result" $r 64 }
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf)
    } catch {
        Write-Output "CALL KeyUSK FAILED: $($_.Exception.Message)"
    }
}

Write-Output "===== DATA EXPORTS AFTER CALLS ====="
foreach ($n in @("?iv0@CPublisher@@0PADA","?iv1@CPublisher@@0PADA","?iv2@CPublisher@@0PADA","?ivRes@CPublisher@@0PADA","?ivUSK@CPublisher@@0PADA","?key0@CPublisher@@0PADA","?key1@CPublisher@@0PADA","?key2@CPublisher@@0PADA","?keyRes@CPublisher@@0PADA","?keyUSK@CPublisher@@0PADA","?key1@CFiler@@0PADA","?key2@CFiler@@0PADA")) {
    $a = [Native]::GetProcAddress($h, $n)
    if ($a -eq [IntPtr]::Zero) { Write-Output "$n NOT FOUND"; continue }
    try {
        $p = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($a)
        Write-Output "$n -> 0x$($p.ToString('X8'))"
        if ($p -ne [IntPtr]::Zero) { DumpBytes "  " $p 64 }
    } catch {
        Write-Output "$n : read failed"
    }
}

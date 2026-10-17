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

function DumpPtr($label, $addr) {
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt 64; $i++) {
        $b = [System.Runtime.InteropServices.Marshal]::ReadByte($addr, $i)
        [void]$sb.Append($b.ToString("X2"))
    }
    $ascii = ""
    for ($i = 0; $i -lt 64; $i++) {
        $b = [System.Runtime.InteropServices.Marshal]::ReadByte($addr, $i)
        if ($b -ge 32 -and $b -lt 127) { $ascii += [char]$b } else { $ascii += "." }
    }
    Write-Output ("$label -> " + $sb.ToString() + "  |" + $ascii)
}

$names = @(
 "?Iv@CPublisher@@SAPADXZ",
 "?IvUSK@CPublisher@@SAPADXZ",
 "?Key@CPublisher@@SAPADXZ",
 "?KeyUSK@CPublisher@@SAPADPAD@Z",
 "?iv0@CPublisher@@0PADA","?iv1@CPublisher@@0PADA","?iv2@CPublisher@@0PADA","?ivRes@CPublisher@@0PADA","?ivUSK@CPublisher@@0PADA",
 "?key0@CPublisher@@0PADA","?key1@CPublisher@@0PADA","?key2@CPublisher@@0PADA","?keyRes@CPublisher@@0PADA","?keyUSK@CPublisher@@0PADA",
 "?key1@CFiler@@0PADA","?key2@CFiler@@0PADA",
 "?m_bPreparedIV@CPublisher@@0_NA","?m_bPreparedKey@CPublisher@@0_NA"
)
foreach ($n in $names) {
    $addr = [Native]::GetProcAddress($h, $n)
    if ($addr -eq [IntPtr]::Zero) { Write-Output "$n : NOT FOUND"; continue }
    Write-Output "--- $n @ 0x$($addr.ToString('X8'))"
    DumpPtr "  raw bytes" $addr
    # if it's a data pointer export, deref and dump the string it points to
    try {
        $p = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($addr)
        if ($p -ne [IntPtr]::Zero) { DumpPtr "  deref" $p }
    } catch {}
}

# call Key(), Iv(), IvUSK()
foreach ($fn in @("?Key@CPublisher@@SAPADXZ","?Iv@CPublisher@@SAPADXZ","?IvUSK@CPublisher@@SAPADXZ")) {
    $addr = [Native]::GetProcAddress($h, $fn)
    if ($addr -eq [IntPtr]::Zero) { continue }
    $d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($addr, [type][Native+CharPtrFn])
    $r = $d.Invoke()
    Write-Output "CALL $fn -> 0x$($r.ToString('X8'))"
    DumpPtr "  result" $r
}

# call KeyUSK(keycode)
$addr = [Native]::GetProcAddress($h, "?KeyUSK@CPublisher@@SAPADPAD@Z")
if ($addr -ne [IntPtr]::Zero) {
    $kb = [System.Text.Encoding]::ASCII.GetBytes("u~*e|wt{,")
    $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($kb.Length + 1)
    [System.Runtime.InteropServices.Marshal]::Copy($kb, 0, $buf, $kb.Length)
    [System.Runtime.InteropServices.Marshal]::WriteByte($buf, $kb.Length, 0)
    $d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($addr, [type][Native+CharPtrFn2])
    $r = $d.Invoke($buf)
    Write-Output "CALL KeyUSK(keycode) -> 0x$($r.ToString('X8'))"
    DumpPtr "  result" $r
    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf)
}

# after calls, re-dump statics
Write-Output "===== statics after calls ====="
foreach ($n in @("?iv0@CPublisher@@0PADA","?iv1@CPublisher@@0PADA","?iv2@CPublisher@@0PADA","?ivRes@CPublisher@@0PADA","?ivUSK@CPublisher@@0PADA","?key0@CPublisher@@0PADA","?key1@CPublisher@@0PADA","?key2@CPublisher@@0PADA","?keyRes@CPublisher@@0PADA","?keyUSK@CPublisher@@0PADA","?key1@CFiler@@0PADA","?key2@CFiler@@0PADA")) {
    $a = [Native]::GetProcAddress($h, $n)
    if ($a -ne [IntPtr]::Zero) {
        $p = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($a)
        Write-Output "$n -> 0x$($p.ToString('X8'))"
        if ($p -ne [IntPtr]::Zero) { DumpPtr "  " $p }
    }
}

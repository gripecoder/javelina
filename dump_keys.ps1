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

function DumpNul($label, $addr, $len) {
    $bytes = New-Object System.Collections.Generic.List[byte]
    for ($i = 0; $i -lt $len; $i++) {
        $b = [System.Runtime.InteropServices.Marshal]::ReadByte($addr, $i)
        $bytes.Add($b)
    }
    $hex = ($bytes | ForEach-Object { $_.ToString("X2") }) -join ""
    Write-Output "$label (len=$($bytes.Count)): $hex"
}

# call and dump 128 bytes
foreach ($fn in @("?Key@CPublisher@@SAPADXZ","?Iv@CPublisher@@SAPADXZ","?IvUSK@CPublisher@@SAPADXZ")) {
    $a = [Native]::GetProcAddress($h, $fn)
    $d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+CharPtrFn])
    $r = $d.Invoke()
    DumpNul $fn $r 128
}
# KeyUSK
$a = [Native]::GetProcAddress($h, "?KeyUSK@CPublisher@@SAPADPAD@Z")
$kb = [System.Text.Encoding]::ASCII.GetBytes("u~*e|wt{,")
$buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($kb.Length + 1)
[System.Runtime.InteropServices.Marshal]::Copy($kb, 0, $buf, $kb.Length)
$d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+CharPtrFn2])
$r = $d.Invoke($buf)
DumpNul "KeyUSK" $r 128
# raw statics at data export addresses (16 bytes each)
foreach ($n in @("?iv0@CPublisher@@0PADA","?iv1@CPublisher@@0PADA","?iv2@CPublisher@@0PADA","?ivRes@CPublisher@@0PADA","?ivUSK@CPublisher@@0PADA","?key0@CPublisher@@0PADA","?key1@CPublisher@@0PADA","?key2@CPublisher@@0PADA","?keyRes@CPublisher@@0PADA","?keyUSK@CPublisher@@0PADA","?key1@CFiler@@0PADA","?key2@CFiler@@0PADA")) {
    $a = [Native]::GetProcAddress($h, $n)
    DumpNul "static $n" $a 16
}

$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Native {
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr LoadLibraryA(string name);
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr GetProcAddress(IntPtr h, string name);
    [UnmanagedFunctionPointer(CallingConvention.ThisCall)]
    public delegate void ScrambleFn(IntPtr thisPtr, IntPtr buf, int len, IntPtr key, int keylen);
}
"@
$h = [Native]::LoadLibraryA("%USERPROFILE%\Documents\github\rea\mountainmaps\j3patched\DrumlinRast.dll")
$a = [Native]::GetProcAddress($h, "?ScrambleBuffer@CFiler@@ABEXPAEHPADH@Z")
Write-Output ("ScrambleBuffer addr: 0x" + $a.ToString("X8"))
$buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x100)
for ($i = 0; $i -lt 0x100; $i++) { [System.Runtime.InteropServices.Marshal]::WriteByte($buf, $i, $i) }
$key = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x20)
$keyA = [byte[]](0xBA,0xBA,0x18,0x11,0xAD,0xEA,0xB4,0x4C,0x08,0x04,0xC0,0x0E,0x50,0x37,0x24,0x49,0x44,0xCC,0xAA,0x0A,0x0D,0x00,0x05,0x9C,0x99,0x99,0xC9,0x9E,0x29,0x93,0x29,0x99)
[System.Runtime.InteropServices.Marshal]::Copy($keyA, 0, $key, 0x20)
$d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+ScrambleFn])
$d.Invoke([IntPtr]::Zero, $buf, 0x100, $key, 0x20)
$ok = $true
for ($i = 0; $i -lt 0x100; $i++) {
    $b = [System.Runtime.InteropServices.Marshal]::ReadByte($buf, $i)
    $exp = $i -bxor $keyA[$i % 32]
    if ($b -ne $exp) { $ok = $false; Write-Output "MISMATCH at $i : got $($b.ToString('X2')) want $($exp.ToString('X2'))"; break }
}
if ($ok) { Write-Output "SCRAMBLE CORRECT" }

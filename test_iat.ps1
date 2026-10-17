$ErrorActionPreference = "Stop"
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Native {
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr LoadLibraryA(string name);
    [DllImport("kernel32", CharSet=CharSet.Ansi, SetLastError=true)]
    public static extern IntPtr GetProcAddress(IntPtr h, string name);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate bool WriteFileFn(IntPtr hFile, IntPtr buf, uint len, IntPtr written, IntPtr overlapped);
    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate IntPtr CreateFileWFn(string path, uint access, uint share, IntPtr sec, uint create, uint flags, IntPtr templ);
}
"@
$h = [Native]::LoadLibraryA("%USERPROFILE%\Documents\github\rea\mountainmaps\j3patched\DrumlinRast.dll")
$slot = [IntPtr]0x100EC050
$wfaddr = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($slot)
Write-Output ("IAT[0x100EC050] = 0x" + $wfaddr.ToString("X8"))
$slot2 = [IntPtr]0x100EC074
$cfw = [System.Runtime.InteropServices.Marshal]::ReadIntPtr($slot2)
Write-Output ("IAT[0x100EC074] = 0x" + $cfw.ToString("X8"))
$wfd = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($wfaddr, [type][Native+WriteFileFn])
$cfwd = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($cfw, [type][Native+CreateFileWFn])
$hFile = $cfwd.Invoke("%USERPROFILE%\Documents\github\rea\mountainmaps\iat_test.bin", 0x40000000, 1, [IntPtr]::Zero, 2, 0x80, [IntPtr]::Zero)
Write-Output ("hFile: 0x" + $hFile.ToString("X8"))
$buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x100)
for ($i = 0; $i -lt 0x100; $i++) { [System.Runtime.InteropServices.Marshal]::WriteByte($buf, $i, 0xAB) }
$w = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
$ok = $wfd.Invoke($hFile, $buf, 0x100, $w, [IntPtr]::Zero)
$n = [System.Runtime.InteropServices.Marshal]::ReadInt32($w)
Write-Output "WriteFile ok=$ok written=$n"
Get-Item "%USERPROFILE%\Documents\github\rea\mountainmaps\iat_test.bin" | Select-Object Length

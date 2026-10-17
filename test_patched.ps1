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
    [UnmanagedFunctionPointer(CallingConvention.ThisCall)]
    public delegate void ScrambleFn(IntPtr thisPtr, IntPtr buf, int len, IntPtr key, int keylen);
}
"@
$h = [Native]::LoadLibraryA("%USERPROFILE%\Documents\github\rea\mountainmaps\j3patched\DrumlinRast.dll")
Write-Output "handle: $($h.ToString('X'))"
# sanity: call Key()
$a = [Native]::GetProcAddress($h, "?Key@CPublisher@@SAPADXZ")
$d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+CharPtrFn])
$r = $d.Invoke()
Write-Output "Key() -> 0x$($r.ToString('X8'))"
$b = [System.Runtime.InteropServices.Marshal]::ReadByte($r)
Write-Output "first key byte: $($b.ToString('X2'))"
# test ScrambleBuffer entry (patched) with a 2MB buffer
$a = [Native]::GetProcAddress($h, "?ScrambleBuffer@CFiler@@ABEXPAEHPADH@Z")
if ($a -eq [IntPtr]::Zero) { Write-Output "ScrambleBuffer export not found (expected)"; exit }
$big = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x200000)
for ($i = 0; $i -lt 0x100; $i++) { [System.Runtime.InteropServices.Marshal]::WriteByte($big, $i, $i) }
$key = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x20)
$d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+ScrambleFn])
$d.Invoke([IntPtr]::Zero, $big, 0x200000, $key, 0x20)
Write-Output "ScrambleBuffer returned OK"
Start-Sleep -Milliseconds 500
if (Test-Path "%USERPROFILE%\Documents\github\rea\mountainmaps\dump.bin") {
    $f = Get-Item "%USERPROFILE%\Documents\github\rea\mountainmaps\dump.bin"
    Write-Output "dump.bin size: $($f.Length)"
    $hdr = [System.IO.File]::ReadAllBytes($f.FullName)[0..15]
    Write-Output ("dump head: " + (($hdr | ForEach-Object { $_.ToString('X2') }) -join ""))
} else {
    Write-Output "no dump file"
}

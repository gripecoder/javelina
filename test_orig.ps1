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
$h = [Native]::LoadLibraryA("C:\Program Files (x86)\Javelin3\DrumlinRast.dll")
$a = [Native]::GetProcAddress($h, "?ScrambleBuffer@CFiler@@ABEXPAEHPADH@Z")
Write-Output ("ScrambleBuffer addr: 0x" + $a.ToString("X8"))
$buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x40)
for ($i = 0; $i -lt 0x40; $i++) { [System.Runtime.InteropServices.Marshal]::WriteByte($buf, $i, $i) }
$key = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(0x20)
for ($i = 0; $i -lt 0x20; $i++) { [System.Runtime.InteropServices.Marshal]::WriteByte($key, $i, 0x41) }
$d = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer($a, [type][Native+ScrambleFn])
$d.Invoke([IntPtr]::Zero, $buf, 0x40, $key, 0x20)
Write-Output "returned. buffer[0..7]:"
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt 8; $i++) { [void]$sb.Append(([System.Runtime.InteropServices.Marshal]::ReadByte($buf, $i)).ToString("X2")) }
Write-Output $sb.ToString()
Write-Output ("expected 41424344... if XOR 0x41 ran over 0,1,2,3...")

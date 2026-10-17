$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem3 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "NO APP"; exit 1 }
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
$BASE = [int64]$mod.BaseAddress
$h = [Mem3]::OpenProcess(0x1F0FFF, $false, $p.Id)
$b = New-Object byte[] 40
$n = 0
[void][Mem3]::ReadProcessMemory($h, [IntPtr]($BASE + 0x137000), $b, 40, [ref]$n)
Write-Output ("stub bytes: " + (($b[0..31] | ForEach-Object { $_.ToString('X2') }) -join " "))
$e = New-Object byte[] 8
[void][Mem3]::ReadProcessMemory($h, [IntPtr]($BASE + 0x8D00), $e, 8, [ref]$n)
Write-Output ("entry bytes: " + (($e | ForEach-Object { $_.ToString('X2') }) -join " "))
$s = New-Object byte[] 8
[void][Mem3]::ReadProcessMemory($h, [IntPtr]($BASE + 0x133F80), $s, 8, [ref]$n)
$ptr = [BitConverter]::ToUInt32($s, 0)
$len = [BitConverter]::ToUInt32($s, 4)
Write-Output ("slot: ptr=0x" + $ptr.ToString('X8') + " len=" + $len)
[void][Mem3]::CloseHandle($h)

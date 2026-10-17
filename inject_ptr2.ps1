$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem4 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr addr, int size, uint protect, out uint old);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int written);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "NO APP"; exit 1 }
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
if (-not $mod) { "DLL NOT LOADED"; exit 1 }
$BASE = [int64]$mod.BaseAddress
Write-Output ("pid=" + $p.Id + " base=0x" + $BASE.ToString('X8'))

$h = [Mem4]::OpenProcess(0x1F0FFF, $false, $p.Id)
$ENTRYVA = $BASE + 0x8D00
$STUBVA  = $BASE + 0xEBC60
$SLOTVA  = $BASE + 0xEBCE0
$LOOPVA  = $BASE + 0x8D0A

function D32([long]$v) { [BitConverter]::GetBytes([int]$v) }
function REL([long]$field, [long]$dst) { [BitConverter]::GetBytes([int]($dst - ($field + 4))) }

$s = New-Object System.Collections.Generic.List[byte]
$s.AddRange([byte[]](0x8B,0x44,0x24,0x04))
$s.AddRange([byte[]](0xA3)); $s.AddRange([byte[]](D32 $SLOTVA))
$s.AddRange([byte[]](0x8B,0x44,0x24,0x08))
$s.AddRange([byte[]](0xA3)); $s.AddRange([byte[]](D32 ($SLOTVA+4)))
$s.AddRange([byte[]](0x31,0xC0))
$s.AddRange([byte[]](0x8B,0x54,0x24,0x08))
$e9 = $STUBVA + $s.Count + 1
$s.AddRange([byte[]](0xE9)); $s.AddRange([byte[]](REL $e9 $LOOPVA))
$stubBytes = $s.ToArray()
Write-Output ("stub=" + $stubBytes.Length)

$old = 0
$vp = [Mem4]::VirtualProtectEx($h, [IntPtr]$STUBVA, 0x1000, 0x40, [ref]$old)
Write-Output ("cave protect=" + $vp + " old=0x" + $old.ToString('X'))
$wr = 0
$ok = [Mem4]::WriteProcessMemory($h, [IntPtr]$STUBVA, $stubBytes, $stubBytes.Length, [ref]$wr)
Write-Output ("stubwrite=" + $ok + " n=" + $wr)
$zero = New-Object byte[] 8
$ok = [Mem4]::WriteProcessMemory($h, [IntPtr]$SLOTVA, $zero, 8, [ref]$wr)
Write-Output ("slot zero=" + $ok)

$vp = [Mem4]::VirtualProtectEx($h, [IntPtr]$ENTRYVA, 0x10, 0x40, [ref]$old)
$entry = [byte[]](0xE9) + [byte[]](REL ($ENTRYVA + 1) $STUBVA)
$ok = [Mem4]::WriteProcessMemory($h, [IntPtr]$ENTRYVA, $entry, 5, [ref]$wr)
Write-Output ("entrywrite=" + $ok)

$b = New-Object byte[] 32
$n = 0
[void][Mem4]::ReadProcessMemory($h, [IntPtr]$STUBVA, $b, 29, [ref]$n)
Write-Output ("verify stub: " + (($b[0..28] | ForEach-Object { $_.ToString('X2') }) -join " "))
$e = New-Object byte[] 5
[void][Mem4]::ReadProcessMemory($h, [IntPtr]$ENTRYVA, $e, 5, [ref]$n)
Write-Output ("verify entry: " + (($e | ForEach-Object { $_.ToString('X2') }) -join " "))
[void][Mem4]::CloseHandle($h)
Write-Output "READY"

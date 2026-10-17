$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem2 {
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

$h = [Mem2]::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { "OpenProcess FAILED"; exit 1 }

$ENTRYVA = $BASE + 0x8D00
$STUBVA  = $BASE + 0x137000
$SLOTVA  = $BASE + 0x133F80
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
[void][Mem2]::VirtualProtectEx($h, [IntPtr]$STUBVA, 0x1000, 0x40, [ref]$old)
$wr = 0
$ok = [Mem2]::WriteProcessMemory($h, [IntPtr]$STUBVA, $stubBytes, $stubBytes.Length, [ref]$wr)
Write-Output ("stubwrite=" + $ok + " n=" + $wr)
[void][Mem2]::VirtualProtectEx($h, [IntPtr]$ENTRYVA, 0x10, 0x40, [ref]$old)
$entry = [byte[]](0xE9) + [byte[]](REL ($ENTRYVA + 1) $STUBVA)
$ok = [Mem2]::WriteProcessMemory($h, [IntPtr]$ENTRYVA, $entry, 5, [ref]$wr)
Write-Output ("entrywrite=" + $ok)
[void][Mem2]::CloseHandle($h)

$BASE.ToString('X8') | Set-Content "%USERPROFILE%\Documents\github\rea\mountainmaps\base.txt"
Write-Output "READY"

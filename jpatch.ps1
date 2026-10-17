param([string]$Mode = "status")
$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem5 {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr addr, int size, uint protect, out uint old);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int written);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
function D32([long]$v) { [BitConverter]::GetBytes([int]$v) }
function REL([long]$field, [long]$dst) { [BitConverter]::GetBytes([int]($dst - ($field + 4))) }

$procs = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue
if (-not $procs) { "NO PROCESSES"; exit 1 }
foreach ($p in $procs) {
    $mod = $null
    try { $mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1 } catch {}
    if (-not $mod) { Write-Output ("pid=" + $p.Id + " rast=NOTLOADED"); continue }
    $BASE = [int64]$mod.BaseAddress
    Write-Output ("pid=" + $p.Id + " rast=0x" + $BASE.ToString('X8'))
    $h = [Mem5]::OpenProcess(0x1F0FFF, $false, $p.Id)
    if ($h -eq [IntPtr]::Zero) { Write-Output "  openfail"; continue }
    $ENTRYVA = $BASE + 0x8D00
    $STUBVA  = $BASE + 0xEBC60
    $SLOTVA  = $BASE + 0xEBCE0
    $LOOPVA  = $BASE + 0x8D0A
    if ($Mode -eq "inject") {
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
        $old = 0
        [void][Mem5]::VirtualProtectEx($h, [IntPtr]$STUBVA, 0x1000, 0x40, [ref]$old)
        $wr = 0
        $ok = [Mem5]::WriteProcessMemory($h, [IntPtr]$STUBVA, $stubBytes, $stubBytes.Length, [ref]$wr)
        $zero = New-Object byte[] 8
        [void][Mem5]::WriteProcessMemory($h, [IntPtr]$SLOTVA, $zero, 8, [ref]$wr)
        [void][Mem5]::VirtualProtectEx($h, [IntPtr]$ENTRYVA, 0x10, 0x40, [ref]$old)
        $entry = [byte[]](0xE9) + [byte[]](REL ($ENTRYVA + 1) $STUBVA)
        $ok2 = [Mem5]::WriteProcessMemory($h, [IntPtr]$ENTRYVA, $entry, 5, [ref]$wr)
        Write-Output ("  inject stub=" + $ok + " entry=" + $ok2)
        $BASE.ToString('X8') | Set-Content "%USERPROFILE%\Documents\github\rea\mountainmaps\base.txt"
    }
    $e = New-Object byte[] 5
    $n = 0
    [void][Mem5]::ReadProcessMemory($h, [IntPtr]$ENTRYVA, $e, 5, [ref]$n)
    Write-Output ("  entry: " + (($e | ForEach-Object { $_.ToString('X2') }) -join " "))
    $sl = New-Object byte[] 8
    [void][Mem5]::ReadProcessMemory($h, [IntPtr]$SLOTVA, $sl, 8, [ref]$n)
    $ptr = [BitConverter]::ToUInt32($sl, 0)
    $len = [BitConverter]::ToUInt32($sl, 4)
    Write-Output ("  slot: ptr=0x" + $ptr.ToString('X8') + " len=" + $len)
    [void][Mem5]::CloseHandle($h)
}

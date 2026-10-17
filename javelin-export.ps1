param(
    [ValidateSet("inject","dump","status")]
    [string]$Mode = "status",
    [string]$OutFile = "%USERPROFILE%\Documents\github\rea\mountainmaps\exported.pdf"
)
$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class JX {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint a, bool i, int p);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr a, int s, uint p, out uint o);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr a, byte[] b, int l, out int w);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr a, byte[] b, int l, out int r);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
function D32([long]$v) { [BitConverter]::GetBytes([int]$v) }
function REL([long]$f, [long]$d) { [BitConverter]::GetBytes([int]($d - ($f + 4))) }

# ---- version-pinned offsets for Javelin3 3.1.0.44 / DrumlinRast.dll (ts 0x5d72395f) ----
$RVA_SCRAMBLE = 0x8D00   # CFiler::ScrambleBuffer entry
$RVA_LOOP     = 0x8D0A   # its XOR loop
$RVA_CAVE     = 0xEBC60  # zero-filled code cave inside .text
$RVA_SLOT     = 0xEBCE0  # (ptr,len) store, 8 bytes

$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { Write-Output "NO Javelin3 PROCESS"; exit 1 }
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
if (-not $mod) { Write-Output "DrumlinRast.dll NOT LOADED - open the document first"; exit 1 }
$BASE = [int64]$mod.BaseAddress
$ENTRYVA = $BASE + $RVA_SCRAMBLE
$STUBVA  = $BASE + $RVA_CAVE
$SLOTVA  = $BASE + $RVA_SLOT
$LOOPVA  = $BASE + $RVA_LOOP
Write-Output ("pid=" + $p.Id + " base=0x" + $BASE.ToString('X8'))

$h = [JX]::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { Write-Output "OpenProcess FAILED"; exit 1 }

if ($Mode -eq "inject") {
    $s = New-Object System.Collections.Generic.List[byte]
    $s.AddRange([byte[]](0x8B,0x44,0x24,0x04))              # mov eax,[esp+4]  buf
    $s.AddRange([byte[]](0xA3)); $s.AddRange([byte[]](D32 $SLOTVA))
    $s.AddRange([byte[]](0x8B,0x44,0x24,0x08))              # mov eax,[esp+8]  len
    $s.AddRange([byte[]](0xA3)); $s.AddRange([byte[]](D32 ($SLOTVA+4)))
    $s.AddRange([byte[]](0x31,0xC0))                        # xor eax,eax
    $s.AddRange([byte[]](0x8B,0x54,0x24,0x08))              # mov edx,[esp+8]
    $e9 = $STUBVA + $s.Count + 1
    $s.AddRange([byte[]](0xE9)); $s.AddRange([byte[]](REL $e9 $LOOPVA))
    $stub = $s.ToArray()
    $old = 0; $wr = 0
    [void][JX]::VirtualProtectEx($h, [IntPtr]$STUBVA, 0x1000, 0x40, [ref]$old)
    $ok1 = [JX]::WriteProcessMemory($h, [IntPtr]$STUBVA, $stub, $stub.Length, [ref]$wr)
    $z = New-Object byte[] 8
    [void][JX]::WriteProcessMemory($h, [IntPtr]$SLOTVA, $z, 8, [ref]$wr)
    [void][JX]::VirtualProtectEx($h, [IntPtr]$ENTRYVA, 0x10, 0x40, [ref]$old)
    $entry = [byte[]](0xE9) + [byte[]](REL ($ENTRYVA + 1) $STUBVA)
    $ok2 = [JX]::WriteProcessMemory($h, [IntPtr]$ENTRYVA, $entry, 5, [ref]$wr)
    Write-Output ("injected stub=" + $ok1 + " entry=" + $ok2)
    Write-Output "NOW: close the document (Ctrl+W) and reopen it, then run: -Mode dump"
}

if ($Mode -eq "status" -or $Mode -eq "dump") {
    $e = New-Object byte[] 5
    $n = 0
    [void][JX]::ReadProcessMemory($h, [IntPtr]$ENTRYVA, $e, 5, [ref]$n)
    $sl = New-Object byte[] 8
    [void][JX]::ReadProcessMemory($h, [IntPtr]$SLOTVA, $sl, 8, [ref]$n)
    $ptr = [BitConverter]::ToUInt32($sl, 0)
    $len = [BitConverter]::ToUInt32($sl, 4)
    Write-Output ("entry=" + (($e | ForEach-Object { $_.ToString('X2') }) -join " "))
    Write-Output ("slot ptr=0x" + $ptr.ToString('X8') + " len=" + $len)
    if ($Mode -eq "dump") {
        if ($ptr -eq 0 -or $len -lt 1000 -or $len -gt 0x10000000) {
            Write-Output "no valid captured buffer - reopen the document first"
            exit 1
        }
        $fs = [System.IO.File]::Create($OutFile)
        $bw = New-Object System.IO.BinaryWriter($fs)
        $chunk = 0x100000
        $buf = New-Object byte[] $chunk
        $off = 0
        while ($off -lt $len) {
            $cur = [Math]::Min($chunk, $len - $off)
            $got = 0
            if (-not [JX]::ReadProcessMemory($h, [IntPtr]($ptr + $off), $buf, $cur, [ref]$got)) { break }
            if ($got -le 0) { break }
            $bw.Write($buf, 0, $got)
            $off += $got
        }
        $bw.Flush(); $bw.Close()
        Write-Output ("wrote " + (Get-Item $OutFile).Length + " bytes -> " + $OutFile)
        $hdr = [System.IO.File]::ReadAllBytes($OutFile)[0..7]
        Write-Output ("head: " + [System.Text.Encoding]::ASCII.GetString($hdr))
    }
}
[void][JX]::CloseHandle($h)

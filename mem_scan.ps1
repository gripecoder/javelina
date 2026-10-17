$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] public static extern int VirtualQueryEx(IntPtr hProc, IntPtr addr, out MEMORY_BASIC_INFORMATION mbi, int len);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr hProc, IntPtr addr, byte[] buf, int len, out int read);
    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORY_BASIC_INFORMATION {
        public IntPtr BaseAddress;
        public IntPtr AllocationBase;
        public uint AllocationProtect;
        public IntPtr RegionSize;
        public uint State;
        public uint Protect;
        public uint Type;
    }
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no process"; exit 1 }
"pid: $($p.Id) title: '$($p.MainWindowTitle)'"
$h = [Mem]::OpenProcess(0x0410, $false, $p.Id)  # QUERY_INFORMATION | VM_READ
if ($h -eq [IntPtr]::Zero) { "OpenProcess failed"; exit 1 }
"handle: $h"

$mbi = New-Object Mem+MEMORY_BASIC_INFORMATION
$addr = [IntPtr]0x10000
$pat = [byte[]](0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E)  # %PDF-1.
$found = @()
$scanned = 0
$max = [IntPtr]0x80000000  # 2GB
while ($addr.ToInt64() -lt $max.ToInt64()) {
    $r = [Mem]::VirtualQueryEx($h, $addr, [ref]$mbi, [System.Runtime.InteropServices.Marshal]::SizeOf($mbi))
    if ($r -eq 0) {
        $addr = [IntPtr]($addr.ToInt64() + 0x10000)
        continue
    }
    $size = $mbi.RegionSize.ToInt64()
    if ($mbi.State -eq 0x1000 -and $size -gt 0) {  # MEM_COMMIT
        $size = [Math]::Min($size, 0x8000000)
        $chunk = 0x100000
        $off = 0
        while ($off -lt $size) {
            $len = [Math]::Min($chunk, $size - $off)
            $buf = New-Object byte[] $len
            $read = 0
            if ([Mem]::ReadProcessMemory($h, [IntPtr]($addr.ToInt64() + $off), $buf, $len, [ref]$read)) {
                for ($i = 0; $i -le $read - 7; $i++) {
                    $match = $true
                    for ($j = 0; $j -lt 7; $j++) { if ($buf[$i+$j] -ne $pat[$j]) { $match = $false; break } }
                    if ($match) {
                        $loc = [IntPtr]($addr.ToInt64() + $off + $i)
                        $found += $loc
                        "FOUND %PDF at 0x$($loc.ToString('X8'))"
                    }
                }
            }
            $off += $len
        }
    }
    $addr = [IntPtr]($addr.ToInt64() + $size)
    $scanned++
    if ($scanned % 300 -eq 0) { "scanned $scanned regions, addr 0x$($addr.ToString('X8')), hits so far: $($found.Count)" }
}
"total found: $($found.Count)"
$found | ForEach-Object { "0x$($_.ToString('X8'))" }

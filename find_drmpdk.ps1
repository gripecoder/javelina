Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern int VirtualQueryEx(IntPtr h, IntPtr addr, out MEMORY_BASIC_INFORMATION mbi, int len);
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
$p = Get-Process -Name Javelin3 | Select-Object -First 1
$h = [Mem]::OpenProcess(0x1F0FFF, $false, $p.Id)
$pat = [byte[]](0x7B,0x44,0x52,0x4D,0x50,0x44,0x4B,0x7D)
$addr = [IntPtr]0x10000
$max = [IntPtr]0x7FF00000
while ($addr.ToInt64() -lt $max.ToInt64()) {
    $mbi = New-Object Mem+MEMORY_BASIC_INFORMATION
    $r = [Mem]::VirtualQueryEx($h, $addr, [ref]$mbi, 28)
    if ($r -eq 0) { $addr = [IntPtr]($addr.ToInt64() + 0x10000); continue }
    $size = $mbi.RegionSize.ToInt64()
    if ($mbi.State -eq 0x1000 -and $size -gt 0 -and $size -lt 0x4000000) {
        $chunk = 0x40000
        $off = 0
        while ($off -lt $size) {
            $len = [Math]::Min($chunk, $size - $off)
            $buf = New-Object byte[] $len
            $read = 0
            if ([Mem]::ReadProcessMemory($h, [IntPtr]($addr.ToInt64()+$off), $buf, $len, [ref]$read)) {
                for ($i = 0; $i -le $read - 8; $i++) {
                    $m = $true
                    for ($j = 0; $j -lt 8; $j++) { if ($buf[$i+$j] -ne $pat[$j]) { $m = $false; break } }
                    if ($m) { "FOUND {DRMPDK} at 0x$(($addr.ToInt64()+$off+$i).ToString('X8'))" }
                }
            }
            $off += $len
        }
    }
    $addr = [IntPtr]($addr.ToInt64() + $size)
}
"scan done"

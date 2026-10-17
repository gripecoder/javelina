$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
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
$p = Get-Process -Name Javelin3 | Select-Object -First 1
$h = [Mem]::OpenProcess(0x0410, $false, $p.Id)
"h: $h"
foreach ($a in @(0x10000, 0x400000, 0x10000000, 0x20000000, 0x70000000)) {
    $mbi = New-Object Mem+MEMORY_BASIC_INFORMATION
    $r = [Mem]::VirtualQueryEx($h, [IntPtr]$a, [ref]$mbi, 28)
    if ($r -gt 0) {
        "addr 0x$($a.ToString('X8')): r=$r base=0x$($mbi.BaseAddress.ToString('X8')) size=0x$($mbi.RegionSize.ToString('X8')) state=$($mbi.State.ToString('X8')) protect=$($mbi.Protect.ToString('X8')) type=$($mbi.Type.ToString('X8'))"
    } else {
        "addr 0x$($a.ToString('X8')): FAILED r=$r"
    }
}

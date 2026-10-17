$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MemQ {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern int VirtualQueryEx(IntPtr h, IntPtr addr, out MEMORY_BASIC_INFORMATION mbi, int len);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
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
if (-not $p) { "NO APP"; exit 1 }
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
$BASE = [int64]$mod.BaseAddress
$h = [MemQ]::OpenProcess(0x1F0FFF, $false, $p.Id)
foreach ($off in 0x8D00, 0x133F80, 0x137000, 0x13701E) {
    $mbi = New-Object MemQ+MEMORY_BASIC_INFORMATION
    $r = [MemQ]::VirtualQueryEx($h, [IntPtr]($BASE + $off), [ref]$mbi, 28)
    Write-Output ("off=0x" + $off.ToString('X6') + " r=" + $r + " state=" + $mbi.State.ToString('X8') + " protect=" + $mbi.Protect.ToString('X8') + " size=" + $mbi.RegionSize.ToString('X8'))
}
[void][MemQ]::CloseHandle($h)

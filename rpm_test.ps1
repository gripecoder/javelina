Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll", SetLastError=true)] public static extern uint GetLastError();
}
"@
$p = Get-Process -Name Javelin3 | Select-Object -First 1
"pid $($p.Id) elevated? " + (($p.SessionId -ge 0))
$h = [Mem]::OpenProcess(0x1F0FFF, $false, $p.Id)
"h: $h err: $([Mem]::GetLastError())"
foreach ($a in @(0x400000, 0x10000000, 0x10008D00, 0x20000000)) {
    $buf = New-Object byte[] 16
    $read = 0
    $ok = [Mem]::ReadProcessMemory($h, [IntPtr]$a, $buf, 16, [ref]$read)
    "0x$($a.ToString('X8')): ok=$ok read=$read err=$([Mem]::GetLastError()) bytes=" + (($buf | ForEach-Object { $_.ToString('X2') }) -join " ")
}

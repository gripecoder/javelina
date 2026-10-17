$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Inj {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr addr, int size, uint allocType, uint protect);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int written);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr sa, int stack, IntPtr start, IntPtr param, int flags, out int tid);
    [DllImport("kernel32.dll")] public static extern uint WaitForSingleObject(IntPtr h, uint ms);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr addr, int size, uint protect, out uint old);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr h, string name);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string name);
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "NO APP"; exit 1 }
Write-Output ("pid=" + $p.Id)
$h = [Inj]::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { "OpenProcess FAILED"; exit 1 }

$k32 = [Inj]::GetModuleHandle("kernel32.dll")
$ll = [Inj]::GetProcAddress($k32, "LoadLibraryA")
Write-Output ("LoadLibraryA=0x" + ([int64]$ll).ToString('X8'))

$path = "C:\Program Files (x86)\Javelin3\DrumlinRast.dll"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($path) + [byte[]](0)
$mem = [Inj]::VirtualAllocEx($h, [IntPtr]::Zero, $bytes.Length + 16, 0x3000, 0x04)
Write-Output ("remote mem=0x" + ([int64]$mem).ToString('X8'))
$wr = 0
[void][Inj]::WriteProcessMemory($h, $mem, $bytes, $bytes.Length, [ref]$wr)
$tid = 0
$th = [Inj]::CreateRemoteThread($h, [IntPtr]::Zero, 0, $ll, $mem, 0, [ref]$tid)
Write-Output ("thread=" + $th + " tid=" + $tid)
if ($th -ne [IntPtr]::Zero) { [void][Inj]::WaitForSingleObject($th, 5000) }
[void][Inj]::CloseHandle($h)
Start-Sleep -Seconds 2
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
if ($mod) { Write-Output ("DLL base=0x" + ([int64]$mod.BaseAddress).ToString('X8')) } else { Write-Output "DLL NOT PRESENT" }

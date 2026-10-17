$ErrorActionPreference = "Stop"
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mem {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr h, IntPtr addr, int size, uint protect, out uint old);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int written);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, int len, out int read);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no Javelin3 process"; exit 1 }
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
if (-not $mod) { "DrumlinRast not loaded"; exit 1 }
$BASE = [int64]$mod.BaseAddress
"pid: $($p.Id)  DrumlinRast base: 0x$($BASE.ToString('X8'))"

$h = [Mem]::OpenProcess(0x1F0FFF, $false, $p.Id)
if ($h -eq [IntPtr]::Zero) { "OpenProcess failed"; exit 1 }

$SCRAMBLE_VA = $BASE + 0x8D00
$STUB_VA = $BASE + 0x137000
$WRITTEN_VA = $BASE + 0x1373FC
$PATH_VA = $BASE + 0x137400
$ORIG_LOOP = $BASE + 0x8D0A
$IAT_CREATEFILEW = $BASE + 0xEC074
$IAT_WRITEFILE = $BASE + 0xEC050
$IAT_CLOSEHANDLE = $BASE + 0xEC0BC

function i32([long]$v) { [BitConverter]::GetBytes([int]$v) }
function rel([long]$field, [long]$dst) { [BitConverter]::GetBytes([int]($dst - ($field + 4))) }

$stub = New-Object System.Collections.Generic.List[byte]
$stub.AddRange([byte[]](0x55,0x56,0x57,0x53))
$stub.AddRange([byte[]](0x8B,0x74,0x24,0x14))
$stub.AddRange([byte[]](0x8B,0x7C,0x24,0x18))
$stub.AddRange([byte[]](0x6A,0x00))
$stub.AddRange([byte[]](0x68,0x80,0x00,0x00,0x00))
$stub.AddRange([byte[]](0x6A,0x02))
$stub.AddRange([byte[]](0x6A,0x00))
$stub.AddRange([byte[]](0x6A,0x01))
$stub.AddRange([byte[]](0x68,0x00,0x00,0x00,0x40))
$stub.AddRange([byte[]](i32 $PATH_VA))
$stub.AddRange([byte[]](0xFF,0x15)); $stub.AddRange([byte[]](i32 $IAT_CREATEFILEW))
$stub.AddRange([byte[]](0x8B,0xD8))
$stub.AddRange([byte[]](0x6A,0x00))
$stub.AddRange([byte[]](i32 $WRITTEN_VA))
$stub.AddRange([byte[]](0x6A,0x04))
$stub.AddRange([byte[]](0x8D,0x44,0x24,0x24))
$stub.AddRange([byte[]](0x50))
$stub.AddRange([byte[]](0x53))
$stub.AddRange([byte[]](0xFF,0x15)); $stub.AddRange([byte[]](i32 $IAT_WRITEFILE))
$stub.AddRange([byte[]](0x6A,0x00))
$stub.AddRange([byte[]](i32 $WRITTEN_VA))
$stub.AddRange([byte[]](0x57))
$stub.AddRange([byte[]](0x56))
$stub.AddRange([byte[]](0x53))
$stub.AddRange([byte[]](0xFF,0x15)); $stub.AddRange([byte[]](i32 $IAT_WRITEFILE))
$stub.AddRange([byte[]](0x53))
$stub.AddRange([byte[]](0xFF,0x15)); $stub.AddRange([byte[]](i32 $IAT_CLOSEHANDLE))
$stub.AddRange([byte[]](0x5B,0x5F,0x5E,0x5D))
$stub.AddRange([byte[]](0x31,0xC0))
$stub.AddRange([byte[]](0x8B,0x54,0x24,0x08))
$e9at = $STUB_VA + $stub.Count + 1
$stub.AddRange([byte[]](0xE9))
$stub.AddRange([byte[]](rel $e9at $ORIG_LOOP))
$stubBytes = $stub.ToArray()
"stub: $($stubBytes.Length) bytes"

$old = 0
$vp = [Mem]::VirtualProtectEx($h, [IntPtr]$STUB_VA, 0x1000, 0x40, [ref]$old)
"reloc RWX: $vp (old=$old)"
$wr = 0
$ok = [Mem]::WriteProcessMemory($h, [IntPtr]$STUB_VA, $stubBytes, $stubBytes.Length, [ref]$wr)
"stub written: $ok ($wr)"
$path = [System.Text.Encoding]::Unicode.GetBytes("%USERPROFILE%\Documents\github\rea\mountainmaps\dump.bin") + [byte[]](0,0)
$ok = [Mem]::WriteProcessMemory($h, [IntPtr]$PATH_VA, $path, $path.Length, [ref]$wr)
"path written: $ok ($wr)"
$vp = [Mem]::VirtualProtectEx($h, [IntPtr]$SCRAMBLE_VA, 0x10, 0x40, [ref]$old)
"entry RWX: $vp"
$entry = [byte[]](0xE9) + (rel ($SCRAMBLE_VA + 1) $STUB_VA)
$ok = [Mem]::WriteProcessMemory($h, [IntPtr]$SCRAMBLE_VA, $entry, 5, [ref]$wr)
"entry patched: $ok ($wr)"
[Mem]::CloseHandle($h) | Out-Null
"LIVE PATCH INJECTED - close and reopen the document in Javelin3"


$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class FG2 {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
}
"@
$doc = "%USERPROFILE%\Documents\maps\MountainDirectory\MountainDirectoryCombined.drmz"
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "NO APP"; exit 1 }
$p.Refresh()
[FG2]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[FG2]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 800
$p.Refresh()
"before: '$($p.MainWindowTitle)'"
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Seconds 4
$dlg = Get-Process -Name Javelin3 | Select-Object -First 1
"after ^o title: '$($dlg.MainWindowTitle)'"
[System.Windows.Forms.SendKeys]::SendWait($doc)
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 30
$p.Refresh()
"final: '$($p.MainWindowTitle)'"

$ErrorActionPreference = "Stop"
Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
$doc = "%USERPROFILE%\Documents\maps\MountainDirectory\MountainDirectoryCombined.drmz"
Start-Process -FilePath "C:\Program Files (x86)\Javelin3\Javelin3.exe" -ArgumentList ('"' + $doc + '"')
Start-Sleep -Seconds 18
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "APP DID NOT START"; exit 1 }
"pid=$($p.Id) title='$($p.MainWindowTitle)'"
$mod = $p.Modules | Where-Object { $_.ModuleName -eq "DrumlinRast.dll" } | Select-Object -First 1
"rast loaded: $([bool]$mod)"

# inject
& "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\github\rea\mountainmaps\javelin-export.ps1" -Mode inject 2>&1

# close doc + reopen via keyboard
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class FG {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
}
"@
$p.Refresh()
[FG]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[FG]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 700
"closing doc"
[System.Windows.Forms.SendKeys]::SendWait("^w")
Start-Sleep -Seconds 3
"opening doc"
[System.Windows.Forms.SendKeys]::SendWait("^o")
Start-Sleep -Seconds 3
[System.Windows.Forms.SendKeys]::SendWait($doc)
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 25
"state: title='$($p.MainWindowTitle)'"
& "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\github\rea\mountainmaps\javelin-export.ps1" -Mode dump -OutFile "%USERPROFILE%\Documents\github\rea\mountainmaps\exported.pdf" 2>&1

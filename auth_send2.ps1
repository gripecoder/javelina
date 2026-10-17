param([string]$Code = "ajz5hcdk3")
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mouse {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
"@
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no app"; exit 1 }
[Mouse]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$p.Id)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
function Find-All($parent) {
    $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
}
function Click-Name($win, $name) {
    foreach ($c in (Find-All $win)) {
        if ($c.Current.Name -eq $name) {
            $r = $c.Current.BoundingRectangle
            [Mouse]::SetCursorPos([int]($r.X + $r.Width/2), [int]($r.Y + $r.Height/2)) | Out-Null
            [Mouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero); [Mouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
            "clicked '$name'"
            return $true
        }
    }
    "not found: $name"
    return $false
}
# close update dialog first
Click-Name $win "No" | Out-Null
Start-Sleep -Milliseconds 800
# now authorize
[System.Windows.Forms.Clipboard]::SetText($Code)
Click-Name $win "Paste" | Out-Null
Start-Sleep -Milliseconds 800
Click-Name $win "OK" | Out-Null
"done"

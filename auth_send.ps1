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
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
[System.Windows.Forms.Clipboard]::SetText($Code)
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no app"; exit 1 }
$hwnd = $p.MainWindowHandle
[Mouse]::ShowWindow($hwnd, 9) | Out-Null
[Mouse]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 600
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$p.Id)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
function Find-Aid($parent, $aid) {
    foreach ($c in $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        if ($c.Current.AutomationId -eq $aid) { return $c }
    }
    return $null
}
function Click($el) {
    $r = $el.Current.BoundingRectangle
    [Mouse]::SetCursorPos([int]($r.X + $r.Width/2), [int]($r.Y + $r.Height/2)) | Out-Null
    [Mouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    [Mouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
$box = Find-Aid $win "1055370"
if ($box) { Click $box; Start-Sleep -Milliseconds 400 }
$paste = Find-Aid $win "531850"
if ($paste) { Click $paste; Start-Sleep -Milliseconds 800 }
$ok = Find-Aid $win "531292"
if ($ok) { Click $ok }
"sent code $Code"

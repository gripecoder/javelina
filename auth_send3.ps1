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
if (-not $p) { "NO APP"; exit 1 }
[Mouse]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 500
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$p.Id)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if (-not $win) { "NO WINDOW"; exit 1 }

# dump all named controls with rects
foreach ($c in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
    $n = $c.Current.Name
    if ($n -in @("No","Yes","OK","Cancel","Paste","Do not ask me again")) {
        $r = $c.Current.BoundingRectangle
        Write-Output ("CTRL '$n' at $([int]$r.X),$([int]$r.Y) size $([int]$r.Width)x$([int]$r.Height)")
    }
}
function Click($el) {
    $r = $el.Current.BoundingRectangle
    $x = [int]($r.X + $r.Width / 2); $y = [int]($r.Y + $r.Height / 2)
    Write-Output "CLICK ($x,$y)"
    [Mouse]::SetCursorPos($x, $y) | Out-Null
    [Mouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero)
    [Mouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
$no = $null
foreach ($c in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
    if ($c.Current.Name -eq "No") { $no = $c }
}
if ($no) { Click $no; Start-Sleep -Milliseconds 1000 } else { "NO 'No' BUTTON" }
[System.Windows.Forms.Clipboard]::SetText($Code)
foreach ($c in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
    if ($c.Current.Name -eq "Paste") { Click $c; Start-Sleep -Milliseconds 800 }
}
foreach ($c in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
    if ($c.Current.Name -eq "OK") { Click $c }
}
"DONE"

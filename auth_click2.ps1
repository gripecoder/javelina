Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mouse {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
}
"@
[System.Windows.Forms.Clipboard]::SetText("u~*e|wt{,")
$procId = (Get-Process -Name Javelin3 | Select-Object -First 1).Id
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$procId)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
function Find-Aid($parent, $aid) {
    foreach ($c in $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        if ($c.Current.AutomationId -eq $aid) { return $c }
    }
    return $null
}
function Click($el) {
    $r = $el.Current.BoundingRectangle
    $x = [int]($r.X + $r.Width / 2); $y = [int]($r.Y + $r.Height / 2)
    "click ($x,$y) '$($el.Current.Name)'"
    [Mouse]::SetCursorPos($x, $y)
    [Mouse]::mouse_event(2,0,0,0,[UIntPtr]::Zero); [Mouse]::mouse_event(4,0,0,0,[UIntPtr]::Zero)
}
# print rects first
foreach ($aid in "1055370","531850","531292","1710476") {
    $el = Find-Aid $win $aid
    if ($el) { $r = $el.Current.BoundingRectangle; "$aid '$($el.Current.Name)' rect: $([int]$r.X),$([int]$r.Y),$([int]$r.Width),$([int]$r.Height)" }
}
$paste = Find-Aid $win "531850"
if ($paste) { Click $paste; Start-Sleep -Milliseconds 800 }
$ok = Find-Aid $win "531292"
if ($ok) { Click $ok; Start-Sleep -Milliseconds 500 }
"done"

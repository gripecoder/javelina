Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

function Find-El($parent, $name, $type) {
    foreach ($c in $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        if ($c.Current.Name -eq $name -and $c.Current.ControlType -eq $type) { return $c }
    }
    return $null
}
function Find-Type($parent, $type) {
    $out = @()
    foreach ($c in $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        if ($c.Current.ControlType -eq $type) { $out += $c }
    }
    return $out
}

$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$args[0])
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if (-not $win) { "no window for pid $($args[0])"; exit }

# find the Authorize dialog inside
$dlg = Find-El $win "Authorize Document" ([System.Windows.Automation.ControlType]::Window)
if (-not $dlg) { $dlg = Find-El $win "" ([System.Windows.Automation.ControlType]::Window) }
"dialog found: '$($dlg.Current.Name)'"

$edits = Find-Type $dlg ([System.Windows.Automation.ControlType]::Edit)
"edits: $($edits.Count)"
$i = 0
foreach ($e in $edits) {
    $i++
    "edit $i : '$($e.Current.Name)'"
    $vp = $e.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    $vp.SetValue("u~*e|wt{,")
}
$btns = Find-Type $dlg ([System.Windows.Automation.ControlType]::Button)
"buttons: $($btns.Count)"
foreach ($b in $btns) { "button: '$($b.Current.Name)'" }
$ok = Find-El $dlg "OK" ([System.Windows.Automation.ControlType]::Button)
if ($ok) {
    $ip = $ok.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $ip.Invoke()
    "OK clicked"
} else { "no OK button" }

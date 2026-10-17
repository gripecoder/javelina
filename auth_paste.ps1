Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Windows.Forms

[System.Windows.Forms.Clipboard]::SetText("u~*e|wt{,")
"clipboard set"

$procId = (Get-Process -Name Javelin3 | Select-Object -First 1).Id
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$procId)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)

function Find-ByName($parent, $name) {
    foreach ($c in $parent.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
        if ($c.Current.Name -eq $name) { return $c }
    }
    return $null
}

$paste = Find-ByName $win "Paste"
if ($paste) {
    $ip = $paste.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $ip.Invoke()
    "paste clicked"
} else { "no paste button" }
Start-Sleep -Seconds 2
$ok = Find-ByName $win "OK"
if ($ok) {
    $ip = $ok.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $ip.Invoke()
    "ok clicked"
} else { "no OK button" }

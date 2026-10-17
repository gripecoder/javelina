Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$procId = (Get-Process -Name Javelin3 | Select-Object -First 1).Id
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$procId)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
function Walk($el, $depth) {
    if ($depth -gt 8) { return }
    $n = $el.Current.Name
    $t = $el.Current.ControlType.ProgrammaticName -replace "ControlType\.", ""
    $auto = $el.Current.AutomationId
    Write-Output ("  " * $depth + "$t name='$n' aid='$auto'")
    foreach ($c in $el.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)) {
        Walk $c ($depth + 1)
    }
}
Walk $win 0

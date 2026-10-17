Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no app"; exit }
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, [int]$p.Id)
$win = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $cond)
if (-not $win) { "no window"; exit }
foreach ($c in $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
    $n = $c.Current.Name
    $t = $c.Current.ControlType.ProgrammaticName -replace "ControlType\.", ""
    $aid = $c.Current.AutomationId
    if ($t -in @("MenuItem","ToolBar","Button","MenuBar")) {
        Write-Output ("$t name='$n' aid='$aid'")
    }
}

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process -Name Javelin3 -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "no process"; exit }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
function Walk($el, $depth) {
    if ($depth -gt 6) { return }
    $name = $el.Current.Name
    $type = $el.Current.ControlType.ProgrammaticName -replace "ControlType\.", ""
    if ($name -or $type -ne "Pane") {
        Write-Output ("  " * $depth + "$type '$name'")
    }
    foreach ($c in $el.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)) {
        Walk $c ($depth + 1)
    }
}
Write-Output ("window: " + $root.Current.Name)
Walk $root 0

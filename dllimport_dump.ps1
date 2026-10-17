$ErrorActionPreference = "Stop"
$asm = [System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\Javelin3\DCL.dll")
foreach ($t in $asm.GetTypes()) {
  foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]"Public,NonPublic,Static,Instance,DeclaredOnly")) {
    $attrs = $m.GetCustomAttributes($false)
    foreach ($at in $attrs) {
      if ($at -is [System.Runtime.InteropServices.DllImportAttribute]) {
        $ep = $at.EntryPoint
        $mod = $at.Value
        if ($ep -match "CEX|OpenDoc|SaveDoc|Key|Iv|ReadHeader|LoadDocument|Encryp|Recode|GetDocData|Counters|Scramble") {
          Write-Output "$mod :: $ep"
          Write-Output "   -> $($m.ToString())"
        }
      }
    }
  }
}

$ErrorActionPreference = "Stop"
foreach ($f in @("C:\Program Files (x86)\Javelin3\DCL.dll", "C:\Program Files (x86)\Javelin3\Javelin3.exe")) {
  Write-Output "===== $f ====="
  $asm = [System.Reflection.Assembly]::LoadFrom($f)
  $seen = @{}
  foreach ($t in $asm.GetTypes()) {
    foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]"Public,NonPublic,Static,Instance,DeclaredOnly")) {
      try {
        $attrs = $m.GetCustomAttributes($false)
      } catch {
        continue
      }
      foreach ($at in $attrs) {
        if ($at -is [System.Runtime.InteropServices.DllImportAttribute]) {
          $key = "$($at.Value) :: $($at.EntryPoint)"
          if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $m.ToString()
          }
        }
      }
    }
  }
  foreach ($k in ($seen.Keys | Sort-Object)) {
    Write-Output "$k   <-   $($seen[$k])"
  }
}

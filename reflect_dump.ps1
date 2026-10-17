$ErrorActionPreference = "Stop"
$files = @("C:\Program Files (x86)\Javelin3\Javelin3.exe",
           "C:\Program Files (x86)\Javelin3\DCL.dll",
           "C:\Program Files (x86)\Javelin3\DrumlinRast.dll",
           "C:\Program Files (x86)\Javelin3\Brandll.dll")
$pat = "crypt|decrypt|encrypt|rijndael|aes|keycode|authoriz|licence|license|drmz|drmx|unlock|password|register"
foreach ($f in $files) {
  Write-Output "=== $f ==="
  try {
    $asm = [System.Reflection.Assembly]::LoadFrom($f)
    foreach ($t in $asm.GetTypes()) {
      $hit = $false
      if ($t.Name -match $pat) { $hit = $true; Write-Output "TYPE: $($t.FullName)" }
      foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]"Public,NonPublic,Static,Instance,DeclaredOnly")) {
        if ($m.Name -match $pat) {
          Write-Output ("  METHOD: {0}.{1}{2}" -f $t.FullName, $m.Name, ($m.ToString().Substring($m.Name.Length)))
        }
      }
    }
  } catch {
    Write-Output "LOAD ERROR: $($_.Exception.Message)"
  }
}

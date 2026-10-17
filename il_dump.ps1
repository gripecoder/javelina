$ErrorActionPreference = "Stop"
$asm = [System.Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\Javelin3\DCL.dll")
$targets = @("Encryption.MyEncryption","Encryption.DocEncryption","Encryption.PDKEncryption","Encryption.NewEncryption")
foreach ($tn in $targets) {
  $t = $asm.GetType($tn)
  if (-not $t) { Write-Output "MISSING TYPE $tn"; continue }
  Write-Output "===== TYPE $tn ====="
  foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]"Public,NonPublic,Static,Instance,DeclaredOnly")) {
    $b = $m.GetMethodBody()
    if ($null -eq $b) { Write-Output "  $($m.Name): no body"; continue }
    $il = $b.GetILAsByteArray()
    $hex = ($il | ForEach-Object { $_.ToString("X2") }) -join ""
    Write-Output "  METHOD $($m.Name)  maxstack=$($b.MaxStackSize) locals=$($b.LocalVariables.Count)"
    for ($i = 0; $i -lt $hex.Length; $i += 64) {
      Write-Output ("    " + $hex.Substring($i, [Math]::Min(64, $hex.Length - $i)))
    }
  }
  # also fields
  foreach ($f in $t.GetFields([System.Reflection.BindingFlags]"Public,NonPublic,Static,Instance")) {
    Write-Output "  FIELD $($f.Name) : $($f.FieldType) (static=$($f.IsStatic))"
  }
}

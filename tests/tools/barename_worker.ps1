# barename_worker.ps1 -- compile a per-module probe and harvest catalog-body warnings.
param([int]$WorkerId, [string]$ListFile, [string]$OutFile, [string]$WorkDir)
$exe = "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\target_r40\debug\xiom.exe"
$dir = Join-Path $WorkDir ("w" + $WorkerId)
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$mods = Get-Content $ListFile
foreach ($mod in $mods) {
  $safe = $mod -replace '\.', '_'
  $src = Join-Path $dir ($safe + '.xi')
  $bin = Join-Path $dir ($safe + '.exe')
  Set-Content -Path $src -Value ("module p_probe_$safe`nuse $mod;`nfn main() -> Int { return 0; }`n") -Encoding ASCII
  $out = & $exe --force -o $bin $src 2>&1 | Out-String
  $hits = $out -split "`n" | Where-Object { $_ -match 'catalog body' }
  foreach ($h in $hits) { Add-Content -Path $OutFile -Value ("{0}`t{1}" -f $mod, $h.Trim()) }
  Remove-Item $bin -ErrorAction SilentlyContinue
}
Write-Output ("worker $WorkerId done: " + $mods.Count + " modules")

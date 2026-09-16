# triage_sweep47.ps1 -- consolidate round-32 worker CSVs, classify results.
$work = "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\sweep47"
$all = @()
Get-ChildItem "$work\results*.csv" | ForEach-Object { $all += Get-Content $_.FullName }
$rows = $all | ForEach-Object { $p = $_ -split ","; [pscustomobject]@{ Name = $p[0]; CompileOk = [int]$p[1]; RunExit = [int]$p[2]; Secs = [double]$p[3] } }
$pass = $rows | Where-Object { $_.CompileOk -eq 1 -and $_.RunExit -eq 0 }
$runfail = $rows | Where-Object { $_.CompileOk -eq 1 -and $_.RunExit -ne 0 }
$cfail = $rows | Where-Object { $_.CompileOk -eq 0 }
Write-Output ("TOTAL: " + $rows.Count + "  PASS: " + $pass.Count + "  RUNFAIL: " + $runfail.Count + "  COMPILEFAIL: " + $cfail.Count)
Write-Output "`n=== RUNFAIL list ==="
$runfail | Sort-Object Name | ForEach-Object { Write-Output ("{0}  exit={1}" -f $_.Name, $_.RunExit) }
Write-Output "`n=== COMPILEFAIL list ==="
$cfail | Sort-Object Name | ForEach-Object { Write-Output $_.Name }

# Gate #7: contract-coverage ratchet (fails the sweep gate on regression).
$floors = "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\coverage_floors43.json"
if (Test-Path $floors) {
  Write-Output "`n=== COVERAGE RATCHET ==="
  & powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\coverage_scan.ps1" -RatchetFile $floors | Select-Object -Last 2
  if ($LASTEXITCODE -ne 0) { Write-Output "SWEEP GATE: FAILED (coverage ratchet)"; exit 1 }
} else {
  Write-Output "`n(coverage ratchet skipped: $floors not found)"
}






















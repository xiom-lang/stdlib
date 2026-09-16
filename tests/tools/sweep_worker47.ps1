# sweep_worker32.ps1 -- round-32 worker: compile+run a slice of the smoke corpus.
# Stdin of every child is redirected from NUL (a stdin-reading smoke must not hang a worker).
param([int]$WorkerId, [string]$FileList, [string]$ResultsCsv, [string]$ErrLog)
$exe = "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\target_r47\debug\xiom.exe"
$outDir = Join-Path (Split-Path $ResultsCsv) ("out" + $WorkerId)
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$nulFile = Join-Path (Split-Path $ResultsCsv) "nul.stdin"
if (-not (Test-Path $nulFile)) { New-Item -ItemType File -Path $nulFile -Force | Out-Null }
$files = Get-Content $FileList
foreach ($f in $files) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($f)
  $bin = Join-Path $outDir ($name + ".exe")
  $start = Get-Date
  $p = Start-Process -FilePath $exe -ArgumentList @("--run", "--force", "-o", $bin, $f) -NoNewWindow -Wait -PassThru -RedirectStandardInput $nulFile -RedirectStandardOutput "$bin.stdout" -RedirectStandardError "$bin.stderr"
  $compileOk = if (Test-Path $bin) { 1 } else { 0 }
  $runExit = -999
  if ($compileOk -eq 1) {
    $r = Start-Process -FilePath $bin -NoNewWindow -Wait -PassThru -RedirectStandardInput $nulFile -RedirectStandardOutput "$bin.runout" -RedirectStandardError "$bin.runerr"
    $runExit = $r.ExitCode
  }
  $dur = ((Get-Date) - $start).TotalSeconds
  Add-Content -Path $ResultsCsv -Value "$name,$compileOk,$runExit,$([math]::Round($dur,1))"
  if ($compileOk -eq 0) {
    $errs = Get-Content "$bin.stderr" -ErrorAction SilentlyContinue | Where-Object { $_ -match "error|failed|panic" } | Select-Object -First 3
    Add-Content -Path $ErrLog -Value ("### " + $name + " COMPILE-FAIL")
    $errs | ForEach-Object { Add-Content -Path $ErrLog -Value $_ }
  }
}
Write-Output ("worker $WorkerId done: " + $files.Count + " files")














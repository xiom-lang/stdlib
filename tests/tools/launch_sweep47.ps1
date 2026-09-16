# launch_sweep47.ps1 -- fan out the full smoke corpus over 8 workers (round-32 binary).
# Run with CWD = E:\Projects\AXIOM so both stdlib resolution roots point at one tree.
$root = "E:\Projects\AXIOM\examples\stdlib_smoke"
$work = "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\sweep47"
New-Item -ItemType Directory -Path $work -Force | Out-Null
$files = Get-ChildItem -Path $root -Filter *.xi | Sort-Object Name
$n = $files.Count
$workers = 8
$chunk = [math]::Ceiling($n / $workers)
Write-Output ("corpus: $n files, $workers workers, chunk $chunk")
$procs = @()
for ($w = 0; $w -lt $workers; $w++) {
  $slice = $work + ("\slice{0}.txt" -f $w)
  $csv = $work + ("\results{0}.csv" -f $w)
  $err = $work + ("\errors{0}.log" -f $w)
  $sel = $files | Select-Object -Skip ($w * $chunk) -First $chunk
  if (-not $sel) { continue }
  $sel.FullName | Set-Content $slice
  $p = Start-Process powershell -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\sweep_worker47.ps1", "-WorkerId", "$w", "-FileList", $slice, "-ResultsCsv", $csv, "-ErrLog", $err) -WindowStyle Hidden -PassThru
  $procs += $p
}
Write-Output ("launched " + $procs.Count + " workers")
$procs | ForEach-Object { $_.WaitForExit() }
Write-Output "ALL WORKERS DONE"
Get-Content ($work + "\results*.csv") | Measure-Object -Line | ForEach-Object { Write-Output ("result lines: " + $_.Lines) }
















# gen_call_probes.ps1 -- generated call probes for never-referenced pub fns.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# The zero-arg tranche is locked by tools/probes/p_never_called_zeroarg.xi and
# the scalar single-param tranche by tools/probes/p_sweep_single_param.xi.
# This generator scans xiom/ for pub fns with MinParams..MaxParams params,
# keeps the ones never referenced in tests/ or xiom/ outside their
# declaration, emits ONE probe per declaring module (so failures localize by
# module group), type-checks it, then compiles it (no run: generated
# arguments may violate active contracts).
#
# Parameter classes: by-value scalars by default; -IncludeRefs adds
# `&T`/`&mut T` (scalar T) and `Vec[E]` by value/reference; -IncludeStructs
# adds struct-typed params when the declaring module has a public constructor
# (exact return type, non-struct params) -- the probe emits
# `var s = module.ctor(...)` and passes it by value/reference; -IncludeFns
# adds `fn(...)` params with scalar-or-empty inner params and a scalar or
# Unit return -- the probe emits a matching local helper function and passes
# its name; `-IncludeWrappedCtors` extends the struct class with
# Result[T, ...]/Option[T] constructors, binding the call and emitting the
# target call inside the success arm (at most one wrapped param per call).
# Parameter lists are split on top-level commas and scanned with
# balanced parens, so `fn(Int) -> Bool` and bracketed commas parse whole.
#
# Output: probes + a report under -OutDir (default: system temp). Nothing is
# written inside the repo unless -OutDir points there.
param(
  [string]$Compiler = "",
  [string]$Root = "",
  [int]$MinParams = 2,
  [int]$MaxParams = 4,
  [string]$OutDir = "",
  [switch]$KeepPassing,
  [switch]$EmitOnly,
  [switch]$IncludeRefs,
  [switch]$IncludeStructs,
  [switch]$IncludeFns,
  [switch]$IncludeWrappedCtors,
  [int]$OnlyCalls = 0,
  [int]$Limit = 0,
  [int]$Timeout = 300
)
# NOTE: do NOT set $ErrorActionPreference = "Stop" here: PowerShell 5.1 turns
# a native compiler's stderr lines into ErrorRecords, which Stop would treat
# as terminating. Exit codes are checked explicitly instead.
$ErrorActionPreference = "Continue"
$repoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (Resolve-Path (Join-Path (Split-Path -Parent $PSScriptRoot) ".")).Path }
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "xiom"))) { Write-Output "ERROR: xiom/ not found under $repoRoot"; exit 2 }
if ($env:XIOM_COMPILER -and (Test-Path -LiteralPath $env:XIOM_COMPILER)) { $Compiler = $env:XIOM_COMPILER }
if (-not $Compiler) {
  $cmd = Get-Command xiom -ErrorAction SilentlyContinue
  if ($cmd) { $Compiler = $cmd.Source } else { Write-Output "ERROR: no compiler (pass -Compiler or set XIOM_COMPILER)"; exit 2 }
}
if (-not $OutDir) { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("xiom-genprobes-" + (Get-Date -Format "yyyyMMdd-HHmmss")) }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$env:XIOM_STDLIB = $repoRoot

$scalar = @{
  "Int" = "0"; "Int8" = "0 as Int8"; "Int16" = "0 as Int16"; "Int32" = "0 as Int32"; "Int64" = "0 as Int64";
  "UInt" = "0 as UInt"; "UInt8" = "0 as UInt8"; "UInt16" = "0 as UInt16"; "UInt32" = "0 as UInt32"; "UInt64" = "0 as UInt64";
  "Bool" = "false"; "Char" = "65 as Char"; "Float32" = "0.0 as Float32"; "Float64" = "0.0"; "Str" = '""'
}

# Param-spec classifier. Without -IncludeRefs only by-value scalars pass (the
# historical tranche definition). With -IncludeRefs the generator additionally
# accepts `&T` / `&mut T` where T is a scalar, and `Vec[E]` / `&Vec[E]` /
# `&mut Vec[E]` where E is an identifier: locals are emitted and passed by
# reference, and by-value vectors are constructed with `Vec[E].new()`.
# Anything else (structs, Option/Result/Map/Set, fn types, arrays, self,
# explicit type args) still skips the function.
# Splits a parameter list on top-level commas only (brackets/parens/quotes
# aware at one level of nesting), so `Map[Str, Int]` and `fn(Int) -> Bool`
# stay single params.
function Split-TopLevel([string]$text) {
  $parts = @(); $depth = 0
  $cur = New-Object System.Text.StringBuilder
  foreach ($ch in $text.ToCharArray()) {
    if ($ch -eq '(' -or $ch -eq '[' -or $ch -eq '{') { $depth++ }
    elseif ($ch -eq ')' -or $ch -eq ']' -or $ch -eq '}') { $depth-- }
    if ($ch -eq ',' -and $depth -eq 0) { $parts += $cur.ToString().Trim(); [void]$cur.Clear(); continue }
    [void]$cur.Append($ch)
  }
  if ($cur.Length -gt 0) { $parts += $cur.ToString().Trim() }
  return $parts
}

function Get-ParamSpec([string]$text, [bool]$allowRefs, [bool]$allowStructs, [bool]$allowFns) {
  $t = $text.Trim()
  if ($t -match '^self\b') { return $null }
  $m = [regex]::Match($t, '^[A-Za-z_][A-Za-z0-9_]*\s*:\s*(?:(&)\s*(mut\s+)?)?(.+)$')
  if (-not $m.Success) { return $null }
  $isRef = $m.Groups[1].Success
  $isMut = $m.Groups[2].Success
  $base = $m.Groups[3].Value.Trim()
  if ($isRef -and -not $allowRefs) { return $null }
  $prefix = if ($isMut) { 'refmut' } else { 'ref' }
  # fn-typed params: fn() / fn(T1, T2, ..) [-> R] with scalar-or-empty inner
  # params and a scalar-or-Unit return. The probe emits a matching local
  # helper function and passes its name.
  if ($allowFns -and $base -match '^fn\(([^)]*)\)\s*(?:->\s*(.+))?$') {
    $inner = $Matches[1].Trim(); $fret = ''
    if ($Matches[2]) { $fret = $Matches[2].Trim() }
    $innerOk = $true
    if ($inner -ne '') {
      foreach ($ip in @(Split-TopLevel $inner)) {
        if ($ip -notmatch '^[A-Za-z_][A-Za-z0-9_]*\s*:\s*(.+)$') { $innerOk = $false; break }
        if (-not $scalar.ContainsKey($Matches[1].Trim())) { $innerOk = $false; break }
      }
    }
    if ($innerOk -and ($fret -eq '' -or $scalar.ContainsKey($fret))) {
      return @{ Kind = ($prefix + '_fn'); Base = $base; FnInner = $inner; FnRet = $fret }
    }
    return $null
  }
  if (-not $isRef) {
    if ($scalar.ContainsKey($base)) { return @{ Kind = 'scalar'; Base = $base } }
    if ($allowRefs -and $base -match '^Vec\[([A-Za-z_][A-Za-z0-9_]*)\]$') { return @{ Kind = 'vec'; Base = $Matches[1] } }
    if ($allowStructs -and $base -match '^[A-Za-z_][A-Za-z0-9_]*$') { return @{ Kind = 'struct'; Base = $base } }
    return $null
  }
  if ($scalar.ContainsKey($base)) { return @{ Kind = ($prefix + '_scalar'); Base = $base } }
  if ($allowRefs -and $base -match '^Vec\[([A-Za-z_][A-Za-z0-9_]*)\]$') { return @{ Kind = ($prefix + '_vec'); Base = $Matches[1] } }
  if ($allowStructs -and $base -match '^[A-Za-z_][A-Za-z0-9_]*$') { return @{ Kind = ($prefix + '_struct'); Base = $base } }
  return $null
}

$files = Get-ChildItem -LiteralPath (Join-Path $repoRoot "xiom") -Filter *.xi -Recurse | Sort-Object FullName
$corpus = New-Object System.Text.StringBuilder
foreach ($f in $files) { [void]$corpus.AppendLine([System.IO.File]::ReadAllText($f.FullName)) }
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "tests") -Filter *.xi -Recurse | Sort-Object FullName)) { [void]$corpus.AppendLine([System.IO.File]::ReadAllText($f.FullName)) }
$corpusText = $corpus.ToString()

$allPub = @()
foreach ($f in $files) {
  $src = [System.IO.File]::ReadAllText($f.FullName)
  $mod = "?"
  if ($src -match '(?m)^\s*module\s+([A-Za-z_][\w.]*)') { $mod = $Matches[1] }
  foreach ($m in [regex]::Matches($src, '(?m)^\s*pub\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)(\s*\[[^\]]*\])?\s*\(')) {
    $name = $m.Groups[1].Value
    if ($m.Groups[2].Value -ne "") { continue }  # generic fns need explicit type args
    # Balanced-paren scan for the parameter list: types like fn(Int) -> Bool
    # contain a ')' that a flat [^)]* capture would truncate.
    $open = $m.Index + $m.Length - 1
    $depth = 0; $close = -1
    for ($ci = $open; $ci -lt $src.Length; $ci++) {
      $c = $src[$ci]
      if ($c -eq '(') { $depth++ }
      elseif ($c -eq ')') { $depth--; if ($depth -eq 0) { $close = $ci; break } }
    }
    if ($close -lt 0) { continue }
    $rawParams = $src.Substring($open + 1, $close - $open - 1).Trim()
    if ($rawParams -eq "") { continue }
    $ret = ""
    $rest = $src.Substring($close + 1)
    if ($rest -match '^\s*->\s*([^\r\n{]+)') { $ret = $Matches[1].Trim() }
    $parts = @(Split-TopLevel $rawParams)
    $specs = @(); $ok = $true
    foreach ($p in $parts) {
      $s = Get-ParamSpec $p ([bool]$IncludeRefs) ([bool]$IncludeStructs) ([bool]$IncludeFns)
      if ($null -eq $s) { $ok = $false; break }
      $specs += $s
    }
    if (-not $ok) { continue }
    $allPub += [pscustomobject]@{ Module = $mod; Name = $name; Specs = $specs; Ret = $ret; File = $f.FullName }
  }
}

# Constructor index (used by -IncludeStructs): same-module pub fns whose
# return type is exactly a struct identifier and whose params are all
# non-struct specs. These can be called to produce arguments for struct
# params without naming the type (locals use inference).
$ctorsByModule = @{}
foreach ($d in $allPub) {
  if (-not $d.Ret -or $d.Ret -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') { continue }
  if (($d.Specs | Where-Object { $_.Kind -like '*struct' -or $_.Kind -like '*_fn' }).Count -gt 0) { continue }
  if (-not $ctorsByModule.ContainsKey($d.Module)) { $ctorsByModule[$d.Module] = @{} }
  $perMod = $ctorsByModule[$d.Module]
  if (-not $perMod.ContainsKey($d.Ret)) { $perMod[$d.Ret] = @() }
  $perMod[$d.Ret] += $d
}

# Wrapped-constructor index (used by -IncludeWrappedCtors): same-module pub
# fns returning Result[T, ...] / Option[T] with T an identifier and all
# non-struct/non-fn params. The probe binds the call and uses the payload
# bound in the success arm (at most one wrapped param per generated call).
$wrappedCtorsByModule = @{}
foreach ($d in $allPub) {
  if (-not $d.Ret) { continue }
  $wm = [regex]::Match($d.Ret, '^(Result|Option)\[([A-Za-z_][A-Za-z0-9_]*)[,\]]')
  if (-not $wm.Success) { continue }
  if (($d.Specs | Where-Object { $_.Kind -like '*struct' -or $_.Kind -like '*_fn' }).Count -gt 0) { continue }
  $t = $wm.Groups[2].Value
  $wrap = $wm.Groups[1].Value
  if (-not $wrappedCtorsByModule.ContainsKey($d.Module)) { $wrappedCtorsByModule[$d.Module] = @{} }
  $perModW = $wrappedCtorsByModule[$d.Module]
  if (-not $perModW.ContainsKey($t)) { $perModW[$t] = @() }
  $perModW[$t] += [pscustomobject]@{ Decl = $d; Wrap = $wrap }
}

# never-referenced filter + constructibility check for struct params.
$decls = @()
foreach ($d in $allPub) {
  # Never-referenced: the name must not appear anywhere else (declarations
  # themselves count once per declaration; require exactly one decl hit).
  $hits = [regex]::Matches($corpusText, "\b" + [regex]::Escape($d.Name) + "\b").Count
  if ($hits -gt 1) { continue }
  if ($d.Specs.Count -lt $MinParams -or $d.Specs.Count -gt $MaxParams) { continue }
  $wrappedNeeded = 0
  $constructible = $true
  foreach ($s in $d.Specs) {
    if ($s.Kind -notlike '*struct') { continue }
    $plain = $false
    if ($ctorsByModule.ContainsKey($d.Module)) {
      $perMod = $ctorsByModule[$d.Module]
      if ($perMod.ContainsKey($s.Base) -and $perMod[$s.Base].Count -gt 0) { $plain = $true }
    }
    if ($plain) { continue }
    $hasWrapped = $false
    if ($IncludeWrappedCtors -and $wrappedCtorsByModule.ContainsKey($d.Module)) {
      $perModW = $wrappedCtorsByModule[$d.Module]
      if ($perModW.ContainsKey($s.Base) -and $perModW[$s.Base].Count -gt 0) { $hasWrapped = $true }
    }
    if ($hasWrapped) { $wrappedNeeded++ } else { $constructible = $false; break }
  }
  if (-not $constructible) { continue }
  if ($wrappedNeeded -gt 1) { continue }
  $decls += $d
}

$byModule = $decls | Group-Object Module | Sort-Object Name
if ($OnlyCalls -gt 0) { $byModule = $byModule | Where-Object { $_.Count -eq $OnlyCalls } }
if ($Limit -gt 0) { $byModule = $byModule | Select-Object -First $Limit }
$report = @(); $fail = @(); $total = 0
foreach ($g in $byModule) {
  $safe = ($g.Name -replace '[^A-Za-z0-9_]', '_')
  $probe = Join-Path $OutDir ("gcp_" + $safe + ".xi")
  $lines = @("module gcp_$safe", "use $($g.Name);", "", "fn main() -> Int {")
  $helperLines = @()
  $callIdx = 0
  foreach ($d in $g.Group) {
    $args = @(); $k = 0; $callPrefix = ''; $callSuffix = @()
    foreach ($s in $d.Specs) {
      $ln = "a" + $callIdx + "_" + $k
      if ($s.Kind -eq 'scalar') { $args += $scalar[$s.Base] }
      elseif ($s.Kind -eq 'vec') { $args += ("Vec[" + $s.Base + "].new()") }
      elseif ($s.Kind -eq 'ref_scalar' -or $s.Kind -eq 'refmut_scalar') {
        $lines += ("  var " + $ln + ": " + $s.Base + " = " + $scalar[$s.Base] + ";")
        if ($s.Kind -eq 'refmut_scalar') { $args += ("&mut " + $ln) } else { $args += ("&" + $ln) }
      }
      elseif ($s.Kind -eq 'ref_vec' -or $s.Kind -eq 'refmut_vec') {
        $lines += ("  var " + $ln + ": Vec[" + $s.Base + "] = Vec[" + $s.Base + "].new();")
        if ($s.Kind -eq 'refmut_vec') { $args += ("&mut " + $ln) } else { $args += ("&" + $ln) }
      }
      elseif ($s.Kind -like '*_fn') {
        $hname = "gp_cb" + $callIdx + "_" + $k
        $hp = @()
        if ($s.FnInner -ne '') {
          $pi = 0
          foreach ($ip in @(Split-TopLevel $s.FnInner)) {
            if ($ip -match '^[A-Za-z_][A-Za-z0-9_]*\s*:\s*(.+)$') {
              $hp += ("p" + $pi + ": " + $Matches[1].Trim())
            }
            $pi++
          }
        }
        $sig = "fn " + $hname + "(" + ($hp -join ", ") + ")"
        if ($s.FnRet -ne '') {
          $helperLines += ($sig + " -> " + $s.FnRet + " { return " + $scalar[$s.FnRet] + "; }")
        } else {
          $helperLines += ($sig + " { }")
        }
        $args += $hname
      }
      elseif ($s.Kind -like '*struct') {
        $plainCtors = $null
        if ($ctorsByModule.ContainsKey($d.Module)) {
          $perMod = $ctorsByModule[$d.Module]
          if ($perMod.ContainsKey($s.Base) -and $perMod[$s.Base].Count -gt 0) { $plainCtors = $perMod[$s.Base] }
        }
        $ctor = $null; $wrapped = $null
        if ($plainCtors) { $ctor = $plainCtors[0] }
        else {
          $wrapped = $wrappedCtorsByModule[$d.Module][$s.Base][0]
          $ctor = $wrapped.Decl
        }
        $cargs = @(); $j = 0
        foreach ($cs in $ctor.Specs) {
          $cln = "c" + $callIdx + "_" + $k + "_" + $j
          if ($cs.Kind -eq 'scalar') { $cargs += $scalar[$cs.Base] }
          elseif ($cs.Kind -eq 'vec') { $cargs += ("Vec[" + $cs.Base + "].new()") }
          elseif ($cs.Kind -eq 'ref_scalar' -or $cs.Kind -eq 'refmut_scalar') {
            $lines += ("  var " + $cln + ": " + $cs.Base + " = " + $scalar[$cs.Base] + ";")
            if ($cs.Kind -eq 'refmut_scalar') { $cargs += ("&mut " + $cln) } else { $cargs += ("&" + $cln) }
          }
          elseif ($cs.Kind -eq 'ref_vec' -or $cs.Kind -eq 'refmut_vec') {
            $lines += ("  var " + $cln + ": Vec[" + $cs.Base + "] = Vec[" + $cs.Base + "].new();")
            if ($cs.Kind -eq 'refmut_vec') { $cargs += ("&mut " + $cln) } else { $cargs += ("&" + $cln) }
          }
          $j++
        }
        if ($plainCtors) {
          $lines += ("  var " + $ln + " = " + $d.Module + "." + $ctor.Name + "(" + ($cargs -join ", ") + ");")
          if ($s.Kind -eq 'refmut_struct') { $args += ("&mut " + $ln) }
          elseif ($s.Kind -eq 'ref_struct') { $args += ("&" + $ln) }
          else { $args += $ln }
        } else {
          # Wrapped constructor: bind the call, use the payload from the
          # success arm; the target call is emitted inside that arm.
          $wname = "w" + $callIdx + "_" + $k
          $vname = "v" + $callIdx + "_" + $k
          $lines += ("  var " + $wname + " = " + $d.Module + "." + $ctor.Name + "(" + ($cargs -join ", ") + ");")
          $lines += ("  match " + $wname + " {")
          if ($wrapped.Wrap -eq 'Result') {
            $lines += ("    Ok(" + $vname + ") => {")
            $callSuffix = @("    }", "    Err(e) => { return 97; }", "  }")
          } else {
            $lines += ("    Some(" + $vname + ") => {")
            $callSuffix = @("    }", "    None => { return 97; }", "  }")
          }
          $callPrefix = "  "
          if ($s.Kind -eq 'refmut_struct') { $args += ("&mut " + $vname) }
          elseif ($s.Kind -eq 'ref_struct') { $args += ("&" + $vname) }
          else { $args += $vname }
        }
      }
      $k++
    }
    $indent = if ($callPrefix -ne '') { "  " + $callPrefix } else { "  " }
    $lines += ($indent + $g.Name + "." + $d.Name + "(" + ($args -join ", ") + ");")
    if ($callSuffix.Count -gt 0) { $lines += $callSuffix }
    $callIdx++
    $total++
  }
  $lines += "  return 0;"; $lines += "}"
  if ($helperLines.Count -gt 0) { $lines += ""; $lines += $helperLines }
  Set-Content -LiteralPath $probe -Value ($lines -join "`n") -Encoding ASCII
  if ($EmitOnly) { $report += "EMITTED $($g.Name) calls=$($g.Group.Count)"; continue }
  $checkOut = & $Compiler --check $probe 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { $report += "CHECKFAIL $($g.Name) calls=$($g.Group.Count)"; $fail += "$safe.check"; continue }
  $bin = Join-Path $OutDir ("gcp_" + $safe + ".exe")
  # -Timeout passes through to the compiler's own compile watchdog (default
  # 300s). Heavy import sets (xiom.net, xiom.num) legitimately exceed it in a
  # debug build; pass -Timeout 0 to disable the watchdog for those tranches.
  $compOut = & $Compiler --force --timeout $Timeout -o $bin $probe 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    $report += "COMPILEFAIL $($g.Name) calls=$($g.Group.Count)"
    Set-Content -LiteralPath (Join-Path $OutDir ("gcp_" + $safe + ".err.txt")) -Value $compOut -Encoding ASCII
    $fail += "$safe.compile"
  } else {
    $report += "OK $($g.Name) calls=$($g.Group.Count)"
    if (-not $KeepPassing) { Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue }
  }
}
Write-Output ("GENPROBES: modules=$($byModule.Count) calls=$total failed=$($fail.Count) outdir=$OutDir")
$report | ForEach-Object { Write-Output $_ }
if ($fail.Count -gt 0) { Write-Output ("FAILED: " + ($fail -join " ")); exit 1 }
exit 0

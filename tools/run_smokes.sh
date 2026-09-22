#!/usr/bin/env bash
# run_smokes.sh -- XIOM stdlib smoke-corpus runner (Linux / macOS).
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Contract (docs/REPO_MIGRATION_RUNBOOK.md section 6.1):
#   --compiler <path>   compiler binary (default: $XIOM_COMPILER, then `xiom` on PATH)
#   --filter <text>     run only files whose name contains <text>
#   --workers <n>       parallel workers (default 8)
#   --json <path>       write a machine-readable result summary
# The child compiler always runs with XIOM_STDLIB=<repo root> so the corpus
# tests THIS checkout, never an installed copy. Exit code is nonzero when any
# file fails to compile or exits nonzero; every file's codes are printed.
#
# Extra (local triage): --corpus <dir> (default tests/smoke), --workdir <dir>,
# --retry-failed (solo re-run of failures before reporting), --quiet.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

COMPILER="${XIOM_COMPILER:-}"
FILTER=""
WORKERS=8
JSON=""
CORPUS="$REPO_ROOT/tests/smoke"
WORKDIR=""
RETRY_FAILED=0
QUIET=0

usage() {
  echo "usage: run_smokes.sh [--compiler <path>] [--filter <text>] [--workers <n>]"
  echo "                     [--json <path>] [--corpus <dir>] [--workdir <dir>]"
  echo "                     [--retry-failed] [--quiet]"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --compiler) COMPILER="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --workers) WORKERS="$2"; shift 2 ;;
    --json) JSON="$2"; shift 2 ;;
    --corpus) CORPUS="$2"; shift 2 ;;
    --workdir) WORKDIR="$2"; shift 2 ;;
    --retry-failed) RETRY_FAILED=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$COMPILER" ]; then
  if command -v xiom >/dev/null 2>&1; then
    COMPILER="$(command -v xiom)"
  else
    echo "ERROR: no compiler given: pass --compiler, set XIOM_COMPILER, or put xiom on PATH" >&2
    exit 2
  fi
fi
if command -v "$COMPILER" >/dev/null 2>&1; then COMPILER="$(command -v "$COMPILER")"; fi
if [ ! -x "$COMPILER" ]; then
  echo "ERROR: compiler not executable: $COMPILER" >&2
  exit 2
fi
export XIOM_STDLIB="$REPO_ROOT"

if [ ! -d "$CORPUS" ]; then echo "ERROR: corpus not found: $CORPUS" >&2; exit 2; fi
if [ -z "$WORKDIR" ]; then
  WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/xiom-smokes-XXXXXXXX")"
fi
mkdir -p "$WORKDIR/bin" "$WORKDIR/logs"
rm -f "$WORKDIR"/results.w*.csv "$WORKDIR"/errors.w*.log

# Build the work list (sorted, filter applied).
LIST="$WORKDIR/files.txt"
: > "$LIST"
for f in "$CORPUS"/*.xi; do
  [ -e "$f" ] || continue
  base="$(basename "$f")"
  case "$base" in
    *"$FILTER"*) printf '%s\n' "$f" >> "$LIST" ;;
  esac
done
TOTAL_FILES="$(wc -l < "$LIST" | tr -d ' ')"
if [ "$TOTAL_FILES" -eq 0 ]; then echo "ERROR: no corpus files matched" >&2; exit 2; fi

# Round-robin the files into per-worker slices.
for i in $(seq 0 $((WORKERS - 1))); do : > "$WORKDIR/slice.w$i.txt"; done
awk -v n="$WORKERS" -v wdir="$WORKDIR" '{ print > (wdir "/slice.w" ((NR - 1) % n) ".txt") }' "$LIST"

run_slice() {
  local slice="$1" tag="$2"
  local results="$WORKDIR/results.w$tag.csv"
  local errors="$WORKDIR/errors.w$tag.log"
  : > "$results"
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    local name
    name="$(basename "$file" .xi)"
    local bin="$WORKDIR/bin/$name"
    local start end crc cok rrc
    start="$(date +%s)"
    "$COMPILER" --force -o "$bin" "$file" >"$WORKDIR/logs/$name.compile.log" 2>&1
    crc=$?
    cok=0
    if [ "$crc" -eq 0 ] && [ -f "$bin" ]; then cok=1; fi
    if [ "$cok" -eq 0 ]; then
      {
        echo "### $name COMPILE-FAIL rc=$crc"
        grep -E "error|failed|panic" "$WORKDIR/logs/$name.compile.log" | head -n 3
      } >> "$errors" 2>/dev/null || true
    fi
    rrc=-999
    if [ "$cok" -eq 1 ]; then
      "$bin" < /dev/null >"$WORKDIR/logs/$name.run.out" 2>"$WORKDIR/logs/$name.run.err"
      rrc=$?
    fi
    end="$(date +%s)"
    printf '%s,%s,%s,%s,%s\n' "$name" "$crc" "$cok" "$rrc" "$((end - start))" >> "$results"
    if [ "$QUIET" -eq 0 ] || [ "$cok" -eq 0 ] || [ "$rrc" -ne 0 ]; then
      printf '[w%s] %s compile=%s run=%s\n' "$tag" "$name" "$crc" "$rrc"
    fi
    rm -f "$bin"
  done < "$slice"
}

START_TS="$(date +%s)"
echo "run_smokes: repo=$REPO_ROOT"
echo "run_smokes: compiler=$COMPILER"
echo "run_smokes: corpus=$CORPUS  files=$TOTAL_FILES  workers=$WORKERS"
echo "run_smokes: workdir=$WORKDIR"

pids=""
for i in $(seq 0 $((WORKERS - 1))); do
  [ -s "$WORKDIR/slice.w$i.txt" ] || continue
  run_slice "$WORKDIR/slice.w$i.txt" "$i" >"$WORKDIR/worker$i.out.log" 2>"$WORKDIR/worker$i.err.log" &
  pids="$pids $!"
done
for p in $pids; do wait "$p"; done

if [ "$RETRY_FAILED" -eq 1 ]; then
  : > "$WORKDIR/retry.txt"
  awk -F, '$3 == 0 || $4 != 0 { print $1 }' "$WORKDIR"/results.w*.csv | while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf '%s\n' "$CORPUS/$name.xi"
  done > "$WORKDIR/retry.txt"
  RETRY_COUNT="$(wc -l < "$WORKDIR/retry.txt" | tr -d ' ')"
  if [ "$RETRY_COUNT" -gt 0 ]; then
    echo "run_smokes: retrying $RETRY_COUNT failed file(s) solo"
    run_slice "$WORKDIR/retry.txt" 99
  fi
fi

# Merge (retry w99 overrides earlier rows by name), sorted for stable output.
RESULTS_ALL="$WORKDIR/results.all.csv"
awk -F, '{ m[$1] = $0 } END { for (k in m) print m[k] }' "$WORKDIR"/results.w*.csv | sort -t, -k1,1 > "$RESULTS_ALL"

echo ""
echo "PER-FILE RESULTS:"
awk -F, -v quiet="$QUIET" '{
  status = "PASS"; if ($3 == 0 || $4 != 0) status = "FAIL";
  if (quiet == 0 || status == "FAIL") printf "  %s %s compile=%s run=%s\n", status, $1, $2, $4;
}' "$RESULTS_ALL"

TOTAL="$(wc -l < "$RESULTS_ALL" | tr -d ' ')"
# Fail closed: every corpus file must produce one result row (a worker
# failure used to look like a clean 0/0 run).
if [ "$TOTAL" -ne "$TOTAL_FILES" ]; then
  echo "ERROR: expected $TOTAL_FILES result rows, got $TOTAL (workers failed?)" >&2
  exit 2
fi
PASS="$(awk -F, '$3 == 1 && $4 == 0' "$RESULTS_ALL" | wc -l | tr -d ' ')"
CFAIL="$(awk -F, '$3 == 0' "$RESULTS_ALL" | wc -l | tr -d ' ')"
RFAIL="$(awk -F, '$3 == 1 && $4 != 0' "$RESULTS_ALL" | wc -l | tr -d ' ')"
END_TS="$(date +%s)"
SECS=$((END_TS - START_TS))
echo ""
echo "SUMMARY: total=$TOTAL pass=$PASS compilefail=$CFAIL runfail=$RFAIL seconds=$SECS"
echo "WORKDIR: $WORKDIR"

if [ -n "$JSON" ]; then
  {
    printf '{\n'
    printf '  "generated": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  "compiler": "%s",\n' "$COMPILER"
    printf '  "corpus": "%s",\n' "$CORPUS"
    printf '  "workers": %s,\n' "$WORKERS"
    printf '  "total": %s,\n' "$TOTAL"
    printf '  "pass": %s,\n' "$PASS"
    printf '  "compilefail": %s,\n' "$CFAIL"
    printf '  "runfail": %s,\n' "$RFAIL"
    printf '  "seconds": %s,\n' "$SECS"
    printf '  "failures": ['
    first=1
    awk -F, '$3 == 0 || $4 != 0 { print $1 "," $2 "," $4 }' "$RESULTS_ALL" | while IFS=, read -r name crc rrc; do
      if [ "$first" -eq 0 ]; then printf ', '; fi
      first=0
      printf '{"name": "%s", "compile_rc": %s, "run_exit": %s}' "$name" "$crc" "$rrc"
    done
    printf ']\n}\n'
  } > "$JSON"
  echo "JSON: $JSON"
fi

[ "$PASS" -eq "$TOTAL" ]

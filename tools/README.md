# XIOM stdlib tooling

Verification tooling for the stdlib repo. Contract: `docs/REPO_MIGRATION_RUNBOOK.md`
section 6.1 (stdlib repo test ownership) in the `xiom-lang/.github` repo.
All scripts are repo-relative: they work from any CWD and from CI checkouts.

## Gates

| Gate | Tool | What it proves |
|---|---|---|
| Corpus | `run_smokes.ps1` / `run_smokes.sh` | compile + run every `tests/smoke/*.xi`; nonzero exit on any failure |
| Coverage ratchet | `coverage_scan.ps1` | contract-clause coverage never falls below the recorded floors |
| Bare-name scan | `barename_scan.ps1` | strict catalog-body findings across all manifest modules (0 expected) |
| Module check | `check_modules.ps1` | `xiom --check` type-checks every manifest module |
| Probes | `run_smokes.ps1 -Corpus tools/probes` | re-run the per-lock probes after a compiler bump |

## Compiler selection

Every tool resolves the compiler in this order:

1. `-Compiler <path>` / `--compiler <path>`
2. `$XIOM_COMPILER` / `$env:XIOM_COMPILER`
3. `xiom` on `PATH`

All tools export `XIOM_STDLIB=<repo root>` for the child compiler, so a run
always tests THIS checkout, never an installed copy. The CI pin lives in
`COMPILER_VERSION` at the repo root (mirror of the compiler repo's
`STDLIB_VERSION`).

## Usage

### Windows / PowerShell (5.1 and pwsh 7+)

```powershell
# full corpus, 8 workers
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe

# one family, solo-rerun failures before reporting
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe -Filter smoke_string -RetryFailed

# machine-readable summary
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe -Json out/smokes.json

# coverage ratchet (floors live in tools/coverage_floors*.json)
pwsh tools/coverage_scan.ps1 -RatchetFile tools/coverage_floors50.json

# dump new floors after a contract wave or a new module
pwsh tools/coverage_scan.ps1 -DumpFloors tools/coverage_floors51.json

# strict bare-name gate over all 509 manifest modules
pwsh tools/barename_scan.ps1 -Compiler C:\path\to\xiom.exe

# check-only type-check of every manifest module
pwsh tools/check_modules.ps1 -Compiler C:\path\to\xiom.exe
```

### Linux / macOS

```bash
./tools/run_smokes.sh --compiler /path/to/xiom --workers 8
./tools/run_smokes.sh --compiler /path/to/xiom --filter kat_ --json out/kats.json
```

`run_smokes.sh` mirrors the PowerShell runner (same flags, same CSV/JSON
shape); the coverage and module scans use the `.ps1` scripts through `pwsh`,
which is preinstalled on GitHub-hosted runners.

## Exit codes

- `0` all green
- `1` gate failure (failed file, ratchet regression, finding)
- `2` setup error (missing compiler/corpus/modules file)

## Output

Working directories default to the system temp directory
(`xiom-smokes-*`, `xiom-barescan-*`, `xiom-checkmods-*`) and contain per-file
compile/run logs plus a CSV per worker; override with `-WorkDir`/`--workdir`
and `-OutDir`. Nothing is written inside the repo.

## Probes

`tools/probes/` holds the versioned probe corpus (only `.xi` files are
tracked; run captures are ignored). Each probe locks a specific compiler or
contract behavior from the session handoff probe index; re-run them after
every compiler bump. `tools/modlist_all.txt` is the manifest module list used
by the bare-name and check-module scans.

## Generated call probes (untested-surface sweep)

`tools/gen_call_probes.ps1` covers the multi-parameter tranche of the
never-referenced public surface: it scans `xiom/` for `pub fn` declarations
whose parameters are all scalar (`Int*`/`UInt*`/`Bool`/`Char`/`Float*`/`Str`),
keeps the ones never referenced in `tests/` or `xiom/`, and emits ONE probe
per declaring module (calls are module-qualified). Each probe is
`--check`ed, then fully compiled (not run: generated arguments may violate
active contracts). Failures are localized by module group and the stderr is
saved next to the probe.

```powershell
pwsh tools/gen_call_probes.ps1 -Compiler C:\path\to\xiom.exe -MinParams 2 -MaxParams 4
```

The zero-arg tranche is locked by `tools/probes/p_never_called_zeroarg.xi`;
the single-param tranche is currently a known compiler failure
(`tools/known_failures/p_sweep_single_param.xi`).

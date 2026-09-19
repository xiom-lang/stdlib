# Verification Baseline -- compiler v0.60.0 freeze

**Date:** 2026-09-17
**Compiler:** `xiom-lang/xiom` tag `v0.60.0`, built debug
(`target/debug/xiom.exe`), strict catalog findings (the flip is ON).
**Repo state:** stdlib `main` at the commit that adds this file.

## CORRECTION 2026-09-19 -- runtime detection was not working

`tools/run_smokes.ps1` passed `-RedirectStandardInput 'NUL'` to
`Start-Process`. Windows PowerShell 5.1 resolves `NUL` against the CWD and
rejects the call, so the process never started, `$p.ExitCode` was `$null`,
and `[int]$null` recorded `run=0` for every file: **the corpus was runtime
blind** (compilefail detection worked; runtime aborts did not). Any
`runfail=0` claim made before 2026-09-19 -- including the v0.60.0 freeze
table below -- is therefore not evidence of runtime correctness. The harness
is fixed (empty-file stdin; a process that fails to start records
`run=-997`), commit `68e8324`.

With the fixed harness, the true state on compiler main R46b (`504fcc1e`)
and stdlib main was **938/949 with 11 runtime aborts**. All 11 were contract
clauses evaluated at runtime:

- call-expression `@pre` clauses reading post-state (the compiler bug
  reproduced as `tools/known_failures/p_pre_call_capture.xi`):
  kdtree/rbtree/tree/list/intmap/hash/lfu/btree smokes;
- four remove-clauses written with the wrong implication
  (`result == false => contains(...)`, should be `== false`) in
  `btree`/`btreeplus`/`cuckoo`/`lfu`.

Remediation (stdlib-side): every dangerous call-`@pre` clause was replaced
with an `@pre`-free equivalent, and the inverted clauses were fixed.

**Corrected runtime baseline (2026-09-19): 949/949 PASS, 0 compilefail,
0 runfail (2435.3s, 8 workers, `-RetryFailed`), compiler main R46b; module
check 509/509.** Stronger size-relation clauses can be restored once the
compiler's `@pre` call capture is fixed.

## Provenance note

Tag `v0.60.0` predates the resource-asset fix (`e3714884`, 2026-09-17
00:38): `crates/xiom/build.rs` needs `resource/img/xiom-icon.ico` for the
Windows build, and that file is not in the tagged tree. The freeze build
therefore copied `resource/` from `main` into the tag export; compiler
logic is exactly the tag. The stdlib CI action carries the same documented
workaround. **Compiler-lane follow-up:** a buildable tag (or a release
artifact built from a fixed commit) is needed before the public beta.

## Results

| Gate | Result | Tool |
|---|---|---|
| Full strict smoke corpus | **947/947 PASS**, 0 compilefail, 0 runfail (1260.7s, 8 workers, no retry needed) | `tools/run_smokes.ps1 -RetryFailed` |
| Module type-check | **509/509 clean** (213s, 8 workers) | `tools/check_modules.ps1` |
| Strict bare-name scan | **0 hits in 509 modules** (512s, 8 workers) | `tools/barename_scan.ps1` |
| Contract-coverage ratchet | **OK** (floors43; global 15.3% clauses / 14.6% pub-with-clause) | `tools/coverage_scan.ps1` |

Raw per-file JSON (normalized: local paths replaced): 
`docs/baselines/freeze-compiler-v0.60.0-smokes.json`.

This supersedes the r47 baseline recorded in `docs/stdlib_session.md`
(the r47 binary was built mid-flight; this run is from the frozen tag) and
closes post-split order item 2.

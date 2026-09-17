# Verification Baseline -- compiler v0.60.0 freeze

**Date:** 2026-09-17
**Compiler:** `xiom-lang/xiom` tag `v0.60.0`, built debug
(`target/debug/xiom.exe`), strict catalog findings (the flip is ON).
**Repo state:** stdlib `main` at the commit that adds this file.

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

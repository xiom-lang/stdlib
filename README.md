# XIOM Standard Library

The standard library for the [XIOM programming language](https://github.com/xiom-lang/xiom):
containers, strings/unicode, encoding, networking, crypto, compression,
serialization, time, IO/OS, math, async and more, plus the C/asm runtime the
compiler's codegen targets.

## Layout

| Path | Contents |
|---|---|
| `xiom/` | module tree; `use xiom.foo` resolves to `xiom/foo.xi` |
| `runtime/` | C/asm runtime (cross-repo API: compiler codegen references it) |
| `tests/smoke/` | executable corpus (`smoke_*.xi`, `kat_*.xi`, `smoke_prop_*.xi`, `smoke_stress_*.xi`) |
| `tools/` | verification tooling + versioned probes (see `tools/README.md`) |
| `docs/` | design, readiness, dedup, limitations, session handoffs |
| `package.xi` | package identity + compiler compatibility range |

## Requirements

- XIOM compiler `>=0.60.0 <1.0.0` (declared in `package.xi`).
- The repo pins the compiler it is verified against in `COMPILER_VERSION`.
- The compiler resolves this checkout through `XIOM_STDLIB=<repo root>`, an
  exe-relative `lib/`/`stdlib/` install, or a CWD-relative `stdlib/`.

## Verification

`tools/README.md` documents every gate. The short version:

```powershell
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe   # full smoke corpus
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe -Corpus tools/probes
./tools/coverage_scan.ps1 -RatchetFile ./tools/coverage_floors192.json
./tools/barename_scan.ps1 -Compiler C:\path\to\xiom.exe
./tools/check_modules.ps1 -Compiler C:\path\to\xiom.exe
```

CI lives in `.github/workflows/` (PR gates, weekly heavy suites, release).

## Status (last verified)

- 2026-10-20, compiler **`v0.64.8`** (official release archive; Windows
  x64 zip sha256 `c31d9c46...`, Linux x64 tar.gz sha256 `a8c003c0...`):
  module check **533/533 clean**, smoke corpus **963/963 PASS**
  (0 compilefail / 0 runfail), probe corpus **383/383**, strict bare-name
  scan **0/533**, coverage ratchet OK (`floors192`).
- Contract coverage: **90.0%** of public functions carry at least one
  clause (6200/6890); clauses/functions **92.1%** (8574). Readiness meter:
  **89.0%**; gate 8 is 90.0% and gate 9 is the remaining open gate. Full
  record: `docs/PRODUCTION_READINESS_QUEUE.md` and
  `docs/stdlib_session.md` (snapshot 74).
- Release: **`stdlib-v0.64.8` published** (tag object `0bf5b75` ->
  `112c5b6`; release run 39289746856); registry `xiom-std 0.64.8` is live
  (sha256 `c4ab5c61...`). Compiler pin is `COMPILER_VERSION=v0.64.8`.
- 15 KAT files (RFC 4648/4231/5869/8439/1952, NIST SHS, JSONTestSuite
  subset, Kuhn UTF-8), collection property smokes, async stress +
  cancellation smokes all green.

## Known limitations

See `docs/STDLIB_BETA_LIMITATIONS.md` (TLS, full tzdata, parser fuzzing)
and `docs/STDLIB_READINESS_PLAN.md` for the production gate status.

## License

Dual-licensed under MIT OR Apache-2.0. See `LICENSE-MIT`, `LICENSE-APACHE`
and `NOTICE`.

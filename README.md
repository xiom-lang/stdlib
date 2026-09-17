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
./tools/run_smokes.ps1 -Compiler C:\path\to\xiom.exe   # full corpus
./tools/coverage_scan.ps1 -RatchetFile ./tools/coverage_floors47.json
./tools/barename_scan.ps1 -Compiler C:\path\to\xiom.exe
./tools/check_modules.ps1 -Compiler C:\path\to\xiom.exe
```

CI lives in `.github/workflows/` (PR gates, weekly heavy suites, release).

## Baseline (last verified)

- 2026-09-17, compiler tag `v0.60.0` (strict catalog findings ON), clean
  freeze build: full strict sweep **947/947 PASS**, module check
  **509/509 clean**, bare-name scan **0 hits**, coverage ratchet OK
  (floors43). Full record: `docs/VERIFICATION_BASELINE.md`.
- 15 KAT files (RFC 4648/4231/5869/8439/1952, NIST SHS, JSONTestSuite
  subset, Kuhn UTF-8), collection property smokes, async stress +
  cancellation smokes all green.

## Known limitations

See `docs/STDLIB_BETA_LIMITATIONS.md` (TLS, full tzdata, parser fuzzing)
and `docs/STDLIB_READINESS_PLAN.md` for the production gate status.

## License

Dual-licensed under MIT OR Apache-2.0. See `LICENSE-MIT`, `LICENSE-APACHE`
and `NOTICE`.

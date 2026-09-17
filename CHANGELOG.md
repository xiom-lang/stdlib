# Changelog

All notable changes to the XIOM standard library are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- CI: PR gates, weekly heavy suites, release pipeline, reusable compiler
  build action; `COMPILER_VERSION` compiler pin.
- Registry publish workflow (dispatch-only until staging is verified) and
  `docs/CI.md` credentials policy; releases ship SHA256SUMS plus a
  build-provenance attestation (minisign deferred).
- Repo-relative verification tooling in `tools/` (runner, coverage ratchet,
  bare-name scan, module check, probes) and `p_wave7_shapes.xi`.

### Changed

- Contract waves 7-8: wave 7 (25 collect clauses: constructors,
  Option/query relations, post-remove absence, order/iter lengths) and
  wave 8 (26 clauses: unicode width/code-length/value bounds; collect
  pop/remove `@pre` size relations). collect 23.6% -> 30.8%, string
  40.5% -> 44.6%, global pub-with-clause 14.6% -> 15.4% (floors45).
- Runtime: removed 9 definition-only symbols; annotated the hot-reload ABI
  family as intentionally exported.
- `package.xi`: identity `xiom-std` + compiler range `>=0.60.0 <1.0.0`.
- `tools/probes/` versions only `.xi` locks (713 run captures removed).

### Fixed

- Verification tooling no longer depends on pre-split temp paths; the
  runner always tests `XIOM_STDLIB=<repo root>`.

## [0.60.0] - 2026-09-16

### Added

- Standalone repository split from the xiom monorepo: module tree at the
  repo root, `runtime/` (C/asm), `tests/smoke/` corpus (947 files),
  `tools/` verification tooling and versioned probes, `docs/` handoffs.
- `package.xi` identity (`xiom-std`) with the compiler compatibility range
  `>=0.60.0 <1.0.0`; `COMPILER_VERSION` pins the verified compiler.
- Verification tooling: `run_smokes.ps1` / `run_smokes.sh` (contract
  runner), `coverage_scan.ps1` (ratchet, gate 7), `barename_scan.ps1`
  (strict detector), `check_modules.ps1` (check-only all modules).
- CI: PR gates (`.github/workflows/ci.yml`), weekly heavy suites
  (`heavy.yml`), release pipeline (`release.yml`).

### Verified

- Freeze sweep 2026-09-17 on a clean compiler tag `v0.60.0` build:
  947/947 strict PASS, 509/509 module check clean, 0 bare-name hits,
  coverage ratchet OK (floors43, global 15.3% clauses / 14.6%
  pub-with-clause). Full record: `docs/VERIFICATION_BASELINE.md`.
- 15 KAT files, collection property smokes (avl/heap/lhmap/bloom/
  persistent/rbtree/hashchurn), async stress + cancellation smokes.

### Security

- CSPRNG on OS entropy (`xiom_os_entropy`: ProcessPrng/RtlGenRandom and
  /dev/urandom); legacy ciphers quarantined under `crypto/legacy/`.

### Known limitations

- No TLS (schannel binding pending), host-only timezone data (phase 1),
  TOML reader only, stdlib parser fuzzing pending. See
  `docs/STDLIB_BETA_LIMITATIONS.md`.

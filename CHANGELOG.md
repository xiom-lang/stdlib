# Changelog

All notable changes to the XIOM standard library are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

- Full strict sweep 947/947 with compiler r47 (R28/R29 fixes, strict
  catalog findings ON); coverage ratchet OK (floors43, global 15.3%
  clauses / 14.6% pub-with-clause); bare-name scan 0 hits across 509
  modules; canonical corpus gate clean.
- 15 KAT files, collection property smokes (avl/heap/lhmap/bloom/
  persistent/rbtree/hashchurn), async stress + cancellation smokes.

### Security

- CSPRNG on OS entropy (`xiom_os_entropy`: ProcessPrng/RtlGenRandom and
  /dev/urandom); legacy ciphers quarantined under `crypto/legacy/`.

### Known limitations

- No TLS (schannel binding pending), host-only timezone data (phase 1),
  TOML reader only, stdlib parser fuzzing pending. See
  `docs/STDLIB_BETA_LIMITATIONS.md`.

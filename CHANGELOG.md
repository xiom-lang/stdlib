# Changelog

All notable changes to the XIOM standard library are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Notes

- `stdlib-v0.61.1` is a **dead tag**: cut on 2026-09-22 but never published
  (its release gates failed because three smokes hardcoded a local temp
  path). The `stdlib-v*` release-tags ruleset blocks moving or deleting
  tags, so it stays in place; `0.61.2` is the shipping release at the same
  compiler pin (`v0.61.1`).

## [0.61.2] - 2026-09-22

Pinned to compiler `v0.61.1`. All compiler findings tracked by this repo are
resolved or ruled; the probe corpus and the generated untested-surface
tranches are fully green.

### Added

- CI: PR gates, weekly heavy suites, release pipeline, reusable compiler
  build action; `COMPILER_VERSION` compiler pin.
- Contract waves 7-21 and their shape probes: collect constructors/pop
  relations, unicode bounds, combinatorics specs, rbtree/cache surfaces,
  cache membership, string builder/align/wrap, collect size relations
  restored after R52, io payload-reading Result clauses, sort/search
  bounds + sortedness, bits width/count identities, geom component mirrors,
  error chain/backtrace relations; floors45-58 wired into every workflow.
  Global pub-with-clause 14.6% -> 21.2%; io 78.7%, search 62.2%, string
  60.0%, collect 60.7%, error 37.5%, bits 36.6%, sort 31.9%, geom 10.6%.
- `tools/gen_call_probes.ps1` untested-surface generator: scalar
  multi-param, `-IncludeRefs` (`&T`/`&mut T`, `Vec[E]`), `-IncludeStructs`,
  `-IncludeFns`, `-IncludeWrappedCtors` (Result/Option constructors), and
  `-Timeout` pass-through. Full scan: 126 modules / 751 calls, compile-only
  126/126 on R61.
- Same-leaf type audit: `tools/same_leaf_audit.ps1` + generated conflict
  worklist (`docs/SAME_LEAF_TYPE_CONFLICTS.md`) for the compiler R44
  qualification slice: 16 genuinely conflicting leaves, 24 benign.
- Parser fuzz harness: deterministic mutation stress smoke over
  json/toml/csv/url parsing (+ writer round-trip stability) and http
  header totalness, seeded for reproducibility.
- TOML writer: `toml_write` emits the v1 subset (root keys first,
  `[section]` blocks in first-appearance order, the five common escapes,
  float markers for round-tripping) with a full round-trip smoke.
- Registry publish workflow (dispatch-only until staging is verified) and
  `docs/CI.md` credentials policy; releases ship SHA256SUMS plus a
  build-provenance attestation (minisign deferred). Publishing now uses
  GitHub OIDC trusted publishing with a per-run ephemeral ed25519 key and
  a release-asset wait step.
- Repo-relative verification tooling in `tools/` (runner, coverage ratchet,
  bare-name scan, module check, probes) and versioned shape probes.

### Changed

- Probe corpus curated: the 18 historical red files split into
  `tools/probes/evidence/` (understood failures) and `tools/known_failures/`
  (open findings), then emptied as R59-R61 resolved or ruled them; six
  probes promoted back to the running corpus (170/170 on R61).
- `xiom.async.io` reads and writes descriptors through the runtime
  `xiom_read`/`xiom_write` helpers; the fd-as-`FILE*` casts are gone.
- `runtime/xiom_runtime.c`: the `XIOM_NO_ASM` fallback stubs carry external
  linkage, so no-NASM compiler builds link the stdlib externs; both build
  configurations verified.
- Copyright attribution normalized to "Eleftherios Notas and The XIOM
  Authors" across 1,689 files; `package.xi` metadata uses the collective
  name.
- CI: DCO sign-off check added; OIDC trusted publishing for registry
  publishes (no long-lived token).
- `package.xi`: identity `xiom-std` + compiler range `>=0.60.0 <1.0.0`
  (release 0.61.2 pins `COMPILER_VERSION` at `v0.61.1`).
- `tools/probes/` versions only `.xi` locks (run captures removed).

### Fixed

- Release/CI gates: `tools/run_smokes.ps1` now launches workers
  cross-platform (the launcher passed Windows-only `-ExecutionPolicy` /
  `-WindowStyle` flags, so `pwsh` workers exited immediately on Linux) and
  both runners fail closed when the result rows do not match the corpus
  count. A silently no-op 0/0 run can no longer report success (observed on
  the ubuntu `stdlib-v0.61.1` release gates).
- Release pipeline: `release.yml` dispatches the staging registry canary
  itself once the package job has uploaded `xiom-std-<ver>.tar.gz`, so the
  publish workflow no longer races the upload; the manual asset wait was
  extended from 15 to 90 minutes for belt-and-braces re-runs.
- Runner-hostile smoke paths: `smoke_async`, `smoke_async_stress` and
  `smoke_io2` hardcoded `C:\\Users\\lefte\\...` temp paths (25 sites),
  so their fs writes failed on CI runners and the Windows release gate went
  red; they now build paths from `fs.fs_temp_dir()`.
- Same-leaf `HttpResponse` collision (compiler R44): `net.net`'s legacy
  2-field type renamed to `NetHttpResponse`, unblocking
  `net.http.http_parse_response` (probe + fuzz harness green).
- Verification tooling no longer depends on pre-split temp paths; the
  runner always tests `XIOM_STDLIB=<repo root>`.
- Windows environment shims: `xiom_env_set`/`xiom_env_unset` exported by the
  runtime; `xiom.os`/`xiom.env` use them (no more `undefined symbol: setenv`).
- `collect/*` strong `@pre` size relations restored after R52 fixed the
  callee-mutation snapshot residual; `p_wave8_shapes` is a live lock.
- Generated-call link gap: no-NASM fallbacks (above) fixed the `xiom.ffi.c`
  group; `xiom.net` group compiles with `-Timeout 0`.

### Verified

- Compiler main R61 (`ff293f8e`, with R59/R60 `2aad5ecd`): check_modules
  509/509; full corpus 949/949 with 0 compilefail / 0 runfail; probe corpus
  170/170; strict bare-name scan 0 hits / 509 modules; coverage ratchet
  floors58 OK; doc ratchet 100% (6,984/6,984). Untested-surface tranches
  126/126. Full record: `docs/VERIFICATION_BASELINE.md` R61 section.

### Known limitations

- No TLS (schannel binding pending compiler FFI hardening), timezone data
  phase 1 only, untested generic/struct-constructor tail, the same-leaf
  collision qualification slice, and 20 definition-only runtime delete
  candidates awaiting compiler-lane confirmation. See
  `docs/STDLIB_BETA_LIMITATIONS.md`.

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

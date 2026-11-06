# Stdlib roadmap after readiness 10/10

Status: **active**. Created 2026-11-03 after the gate-9 fix verification
(blocks 329/330). Owner: stdlib lane.

The table in section 2 is the checklist: every initiative has an ID, horizon,
status, exit criterion and evidence link. Update it in the same commit as the
evidence; do not delete rows (mark `done` or `cancelled` with a reason).

## 0. Starting position (2026-11-03)

- Readiness is **9/10** formally. Gate 9's technical blocker is fixed and
  verified on the compiler fix (`REL-20261103-1626`): the gate probe is flat,
  5.6 / 5.6 / 6.4 / 9.2 / 14.0 MB at 10k / 20k / 40k / 100k / 200k, and the
  stdlib ownership contracts are committed (`9de28f1`).
- Remaining for 10/10: compiler commits the fix and cuts **v0.65.6**; bump
  `COMPILER_VERSION`; re-run the gate on the archive; mark
  `REL-20261020-1704-pulse` fixed; PULSE confirms
  (`REL-20261103-1807-stdlib`).
- Baseline to preserve: modules 543/543, smokes 964/964, function references
  3541/6664 (53.1%), gate-8 no-clause tail 285 functions.

This roadmap starts when RF-0 lands. It is about keeping the floor rising, not
about closing a checklist.

## 1. Principles

1. **Adversarial verification beats presence.** Sanitizers, fuzzing, fault and
   OOM injection decide quality, not gate counts.
2. **Contracts are the API specification.** Every public function has
   `requires`/`ensures` or a documented "total/no contract needed" exemption.
3. **Performance and memory are SLOs.** Budgets on pinned hardware; a
   regression is a defect.
4. **Lean core, registry for optional domains.** Pick the boundary explicitly.
5. **Platform and ABI parity is a gate**, not an afterthought.
6. **1.0 means compatibility guarantees**: surface freeze, deprecation windows,
   LTS.
7. **Dogfood.** The stdlib must build with the self-hosted compiler and be used
   by the tooling.
8. **Every defect gets a minimal repro**, and once fixed, a permanent probe.

## 2. Initiatives

Status values: `planned` / `in_progress` / `blocked` / `done` / `cancelled`.
Horizons: H1 = 0-30 days, H2 = 30-90, H3 = 90-180, H4 = 6-12 months.

### RF-0 -- pre-roadmap carry-over

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| RF-0 | Flip gate 9: v0.65.6 release, archive re-run, mark 1704 fixed, PULSE confirmation, readiness 10/10 | H1 | done | Green release dry-run + flat archive run + PULSE verified + queue at 10/10 | DONE 2026-11-04: stdlib 0.65.6 tag `6fdde4e`; release 41873341844; registry 41873341859 (xiom-std 0.65.6, compiler v0.65.6, sha `7f6475d4`, 17:54:33Z); PULSE verified/closed 1704 (build+stringify 14.4 B/iter, parse 15.1 B/iter, bttger 5k clean); readiness 10/10 |

### Pillar A -- Adversarial correctness

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| A1 | ASan + UBSan + LSan on the full corpus (Windows + Linux); no suppressions without an item | H1 | in_progress | Full corpus green under sanitizers on both platforms | 2026-11-06: nightly `sanitizers.yml` runs a memory-error lane (ASan/UBSan, leaks off) and a leak-audit lane (LSan vs `tools/sanitizer_leak_baseline.json`; growth fails). Block 338: `run_sanitizers.ps1` gained `-MemoryFiles`/`-LeakFiles`; memory lane broadened from 12 to 15 files by adding `smoke_fuzz_bignum`/`smoke_fuzz_ffi`/`smoke_fuzz_encodings`; leak lane stays on the 12 baselined files until a nightly run records the fuzz leak budget (no silent 0-byte budget). Local v0.65.6 compile-only: memory 15/15, leak 12/12. Remaining: first nightly run with the broadened lane, record + add the fuzz leak budgets, Windows ASan, shrink the compiler drop residual, full-corpus sanitizers |
| A2 | TSan lane for async, pool, channel, thread; documented data-race policy | H2 | planned | TSan corpus green; races triaged | |
| A3 | Fuzz targets: `json_parse` (depth/unicode), lexer/parser, bigint/bigfloat parse+format, encodings, FFI boundaries | H1 | in_progress | Corpora running continuously; crashes triaged within 48 h | 2026-11-06: json depth/unicode + surrogate reject fixed; parser fuzz 600/600 in CI. Block 337: `smoke_fuzz_bignum` (bigint str/hex/base36 + bigfloat sci round-trip, arithmetic invariants), `smoke_fuzz_ffi` (SafePtr/FFIBuffer bounds + ffi_check), `smoke_fuzz_encodings` (hex/base64/base32/percent round-trips) added; `XIOM_FUZZ_SEED`/`XIOM_FUZZ_ITERS` (3 seeds); nightly `fuzz.yml` at 3x2000. Local 3x1000 per target green. Fuzz caught `bigint_div_mod(-16,97)` = +16; fixed in `xiom/num/bigint.xi` + `smoke_bigint` case 22. Remaining: first nightly run + 48 h triage |
| A4 | Fault/OOM injection: allocator failure points, trampoline repeat-fault, partial IO | H2 | planned | Suite green; failure paths covered | |
| A5 | Per-subsystem memory gates + in-process allocator stats; flat-peak criteria; 1M-iteration soak | H1 | planned | Collections/string/io/async/serialize all flat under soak | |
| A6 | Defect-to-probe policy: every fixed bug gets a `known_failures` repro, then a permanent probe | H2 | planned | Policy in README; reviews enforce it | |

### Pillar B -- Contracts as the API spec

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| B1 | Contract policy: public function => contracts or documented exemption; per-module sign-off | H2 | done | Policy doc merged; ownership map agrees | 2026-11-06: `docs/CONTRACT_POLICY.md` + `docs/MODULE_OWNERSHIP.md` (44 modules, 6,992 pub fns, 6,707 covered, 285 EX-0 tail); `tools/contract_exemptions.json`; `tools/check_contract_policy.ps1` wired into the CI static job and green on `main` |
| B2 | Ratchet public-API contract coverage from 95.9% global (100% non-tail) to 100% of public functions (exemptions counted) | H2-H3 | in_progress | Floors at 100% public coverage; gate 8 tracks it | 2026-11-06 baseline corrected: 53.1% was module-smoke function refs, not contract coverage; gate-8 contract baseline is 6,707/6,992 (95.9%) with the 285-function EX-0 tail. Block 341: `tools/contract_tail_inventory.ps1` + `docs/CONTRACT_TAIL.md` list every EX-0 function by module/file/line (ffi 4, format 11, iter 54, math 94, os 111, serialize 6, thread 5), cross-checked against `coverage_scan.ps1`. Block 342: ffi reclassified to per-function exemptions (`dl_open_global`/`dl_sym_address` EX-2; `errno_perror`/`safe_ptr_free` EX-1), validated against source. Block 343: thread 5 reclassified (`scope` EX-2; `sleep_ms`/`is_main_thread`/`thread_yield`/`thread_parallel_for` EX-1); Block 345: serialize 6 + format 2 moved to per-function (EX-3/EX-1), and the nine format ANSI helpers got constant clauses; coverage is now 6,716/6,992 (96.1%) with 276 uncovered (259 EX-0 + 17 per-function). Next: reclassify the remaining 259 EX-0 (iter/os/math) |
| B3 | Generate reference docs from contracts; run doc examples as tests | H3 | planned | Docs generated in CI; examples green | |
| B4 | Decide contract-check runtime semantics and cost budget; document debug/release behavior | H3 | planned | Policy + measured cost recorded | |

### Pillar C -- Performance and memory SLOs

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| C1 | Per-module ns/op, B/op, peak-at-N budgets on pinned CI hardware; weekly trend | H2 | planned | Budgets checked weekly; regressions filed as bugs | |
| C2 | Flat-peak gates beyond JSON: maps, builders, IO buffers, async queues | H2 | planned | Each subsystem has a flat-peak witness | |
| C3 | Public benchmark dashboard with regression alerts | H3 | planned | Dashboard live; alert path tested | |

### Pillar D -- Platform and ABI parity

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| D1 | Matrix: Windows x64/arm64, Linux glibc+musl x64/arm64, macOS x64/arm64; core modules required | H2 | planned | Matrix green for core modules | |
| D2 | FFI width/symbol/endianness audit on every runtime change (socket int64 as the template) | H3 | planned | Audit in CI; zero width mismatches | |
| D3 | Reproducible builds, pinned toolchains, archive hash in the release record | H3 | planned | Two independent builds match | |

### Pillar E -- Stability, scope, and 1.0

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| E1 | 1.0 compatibility policy: public-surface freeze, deprecation window (two minors), LTS line | H3 | planned | Policy approved; freeze snapshot recorded | |
| E2 | Per-module stability tiers (stable/beta/experimental) in the manifest | H3 | planned | Manifest carries tiers; docs generated | |
| E3 | "What stdlib is not" boundary doc; registry extension policy | H3 | planned | Boundary doc merged; registry rules agreed | |
| E4 | Dedup same-leaf public types/functions before 1.0 (`JsonValue` x2, `json_escape` x4, `build` x2) | H3 | planned | Same-leaf audit clean; api_freeze regenerated | |
| E5 | Registry boundary: optional domains (TLS, compression, DB) as packages; stdlib keeps primitives | H4 | planned | Boundary applied to the wishlist; no duplicate packages | |

### Pillar F -- Dogfooding

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| F1 | Self-hosted compiler builds and passes the stdlib corpus in CI; bootstrap parity tracked | H3 | planned | Selfhost CI lane green | |
| F2 | Stdlib-built tooling gap log (fmt/LSP/pkg); gaps become probes or issues | H4 | planned | Gap log active; closure rate tracked | |

### Pillar G -- Governance and release engineering

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| G1 | Quality SLO dashboard: escaped bugs, sanitizer/fuzz hours, perf/mem regressions, platform failures, API breaks | H2 | planned | Dashboard published and reviewed monthly | |
| G2 | Module ownership map and relay triage SLAs | H4 | planned | Map merged; SLA measured | |
| G3 | Release automation: "main contains the last release", compiler+stdlib pair CI, pin/version automation, no merge commits | H1 | in_progress | Automated checks catch the v0.65.5 branch-drift class | 2026-11-06 (block 339): `tools/check_release_state.ps1` verifies the latest stdlib tag is annotated and an ancestor of HEAD, `package.xi` is not behind it (may be ahead in release prep), no merge commits after the tag, `release-notes/v<ver>.md` + CHANGELOG entries exist, and `COMPILER_VERSION` is a concrete vX.Y.Z pin; wired into the CI static job with `fetch-depth: 0`. Negative tests: pre-tag HEAD and a missing tag both exit 1. Block 340: `tools/check_pair_state.ps1` verifies the compiler `COMPILER_VERSION` tag exposes `STDLIB_VERSION` naming a real stdlib tag; a one-release lag is a warning during the stdlib-first window unless `-RequireLatest`; `pair.yml` runs nightly. Current pair: compiler v0.65.6 -> stdlib-v0.65.6 == latest. Compiler answered via REL-20261106-1803-compiler: `STDLIB_VERSION` is canonical and released tags are immutable; `stdlib-v0.65.6` was moved (`06795c8` -> `02be60e` -> `6fdde4e`) after the compiler release, while the published asset bundles `06795c8`. Block 344: `release-locks/stdlib-v0.65.6.json` records the historical move as `known_moved`; `check_release_state.ps1` requires a lock and fails future moves, `check_pair_state.ps1` also checks the tag's `COMPILER_VERSION` and the lock, and `record_release_lock.ps1` records new tags without ever moving one. Remaining: compiler asset/manifest commit field + pin/version automation |
| G4 | Security policy: disclosure, constant-time/zeroization guidance, dependency review/SBOM | H4 | planned | Policy published; SBOM produced per release | |

## 3. Growth and expansion (post-1.0)

Growth is demand-driven and boundary-governed. Relay wishlists are **inputs**,
not commitments, and the default destination for new functionality is a
registry package, not stdlib. Policy starts now (H2); expansion execution
starts after 1.0 (H4) so the stability and SLO work is not diluted.

### 3.1 Stance

- **Ecosystem-first.** Optional domains (compression, DB, YAML/TOML/CBOR,
  HTTP/3, ...) ship as `xiom-*` packages or bindings; stdlib keeps the
  primitives everything needs.
- **Admission, not accumulation.** New public API is a cost: contracts,
  platforms, ABI, security, maintenance. Require evidence of at least two real
  consumers and no adequate registry package.
- **Incubate before graduating.** Prototype in a registry/incubator area with
  the same probes and contracts; graduate only after one release of soak at
  tier `experimental`.
- **Security-critical primitives are the exception.** Constant-time code,
  hashing, KDFs, RNG, and TLS framing decisions are cross-cutting and may
  belong in core even without two consumers.

### 3.2 Portfolio tiers

| Tier | Location | Stability | Rule |
|---|---|---|---|
| Core | stdlib | stable | SemVer guarantees, contracts, all platforms |
| Incubator | stdlib experimental or registry `xiom-labs` | experimental | may break with notice; probes + contracts |
| Ecosystem | registry `xiom-*` package | package SemVer | no stdlib dependency cycle; owned |
| Out of scope | documented | n/a | "not stdlib" with a rationale |

### 3.3 Admission test (all must hold)

1. Cross-cutting: at least two independent consumers (PULSE, engine, xvector,
   tooling) or a security/ABI reason.
2. No adequate registry package (or a binding is clearly the better answer).
3. No new external dependencies.
4. Ownership story: contracts and R3/R4 annotations; flat under the memory
   gates.
5. Platform matrix plan; no target-specific hacks.
6. Minimal documented API with a migration/deprecation plan.
7. A named module owner plus review capacity.
8. Tests: unit + probes + sanitizer/fuzz coverage for the domain.

### 3.4 Intake pipeline (relay wishlists)

1. Wishlist item arrives on the bus; triage within one lane cycle.
2. One-page problem statement: who needs it, why stdlib vs registry,
   alternatives.
3. Decide **accept-to-incubator / registry / defer / reject** and publish the
   decision on the item, so the bus sees outcomes.
4. Accepted: design note (API, ownership, perf/memory budget, platforms,
   security) plus a prototype with probes.
5. Graduate after one release of soak against the admission test.

### 3.5 Growth budget

- Cap net-new public API per minor release (for example, one module or a small
  function batch) so contracts and SLOs keep pace.
- No new module without an owner, a probe set, and a memory/perf budget.
- Before 1.0, allow only: bug/stability fixes, contract completion, security
  primitives demanded by a release blocker, and registry packages (which do
  not touch the stdlib surface).

### 3.6 Candidate portfolio (dispositions, not commitments)

| Area | Disposition | Notes |
|---|---|---|
| TLS / ALPN | decide in X3 | headline ecosystem gap; likely a blessed package plus core crypto primitives |
| Compression (brotli/zstd) | ecosystem (done) | the precedent to follow |
| Data formats (YAML/TOML/CBOR/MsgPack) | ecosystem | stdlib keeps JSON |
| HTTP/2, HTTP/3, WebSocket | split in X4 | framing/primitives in core vs package is a decision, not a default |
| Metrics/tracing facade | core facade or registry | no-dependency hooks only |
| Unicode/i18n/tzdata | registry data packages | optional data, not code |
| Numerics (linear algebra, decimals) | ecosystem | bigint/bigfloat stay core |
| WASM/Python/Node bindings | ecosystem | FFI/WASM ABI work |
| Formatter/LSP/pkg | ecosystem tooling | dogfood via F2 |

### 3.7 Growth KPIs (quarterly)

- **Adoption:** packages/projects depending on stdlib (PULSE, engine, xvector,
  external adopters).
- **Ecosystem:** registry packages, maintainers, downloads.
- **Surface discipline:** net-new public API per release; percentage with
  contracts.
- **Quality:** escaped bugs, sanitizer/fuzz hours, platform failures.
- **Docs:** generated coverage, cookbook recipes, migration guides.

### 3.8 X-initiative tracker

| ID | Initiative | Horizon | Status | Exit criterion | Evidence |
|---|---|---|---|---|---|
| X1 | Publish growth policy, tiers, admission test | H2 | planned | Policy merged; first relay triage uses it | |
| X2 | Incubator area with probes and contracts | H3 | planned | First incubator package graduates or retires | |
| X3 | TLS/ALPN decision: blessed package + core crypto primitives vs binding | H3 | planned | Decision, owner, prototype | |
| X4 | Protocol-layer boundary: HTTP/2, HTTP/3, WebSocket core vs package | H3 | planned | Boundary doc; first split implemented | |
| X5 | Data-format policy: JSON core; YAML/TOML/CBOR/MsgPack registry | H2 | planned | Policy merged; packages tracked | |
| X6 | Observability facade decision (no-dep metrics/tracing hooks) | H4 | planned | Decision + API sketch | |
| X7 | Ecosystem growth program: examples, templates, adoption docs | H4 | planned | Three external adopters; docs live | |
| X8 | API surface budget + quarterly growth review | H2 | planned | Budget in the release checklist; review minutes filed | |

## 4. Tracking conventions

- One status per initiative; update the row in the same commit as the evidence.
- `blocked` requires an item id (relay or issue) in the Evidence column.
- Horizon is a target, not a promise; slipping needs a one-line note in the row.
- Review weekly in the lane; monthly readiness-style review of the table.
- An initiative is `done` only with evidence: commit, run id, dashboard, or doc.
- Never close a row by lowering its exit criterion; amend the criterion first
  and record why.
- `tools/check_roadmap.ps1` runs in the CI static job and rejects duplicate or
  malformed IDs, bad horizons/statuses, empty exit criteria, and missing
  evidence on `in_progress` / `blocked` / `done` rows.
- Append a row to the review log (section 7) at every review; do not rewrite
  earlier entries.

## 5. Non-goals

- Feature parity with other standard libraries for its own sake.
- Public APIs without contracts, ownership annotations, and tests.
- Duplicating registry packages inside stdlib.
- Vanity coverage percentages as a quality proxy.
- Declaring 1.0 before the compatibility policy and deprecation window exist.

## 6. Immediate sequence

1. **RF-0** first: finish the release + PULSE path; flip readiness to 10/10.
2. Start **A1** (sanitizer corpus) and **A3** (JSON/parser fuzzing) in parallel
   with the release; they are the cheapest way to prevent the next m375/1704
   class.
3. Bring **A5** (allocator stats + per-subsystem memory gates) early: it makes
   every later memory claim testable without RSS sampling.
4. Draft **B1** (contract policy) and **G3** (release automation) for review;
   both unblock long-running work.
5. Only then open **E1/E4** (1.0 freeze + dedup); the surface must be stable
   before the freeze is credible.
6. Run **X1** (growth policy) and **X5** (data-format policy) in H2 so relay
   wishlists have a decision path; do not start expansion (**X2-X8**) before
   1.0, and keep the API-surface budget (**X8**) in the release checklist.

## 7. Review log

| Date | Event | Outcome |
|---|---|---|
| 2026-11-03 | Roadmap created; 	ools/check_roadmap.ps1 added and wired into the static CI job | RF-0 in_progress (blocked on v0.65.6 + PULSE); A-G and X1-X8 planned; next review when RF-0 lands |
| 2026-11-06 | B1 contract policy landed on snapshot 120 | `docs/CONTRACT_POLICY.md` + `docs/MODULE_OWNERSHIP.md`: 44 modules, 6,992 pub fns, 6,707 covered (95.9%), 285 EX-0 tail; `tools/check_contract_policy.ps1` green and wired into CI; B2 baseline corrected from 53.1% (module-smoke refs) to 95.9% global / 100% non-tail (gate 8) |
| 2026-11-06 | A3 fuzz wave: bigint/bigfloat, encodings, FFI + nightly schedule | `smoke_fuzz_bignum`, `smoke_fuzz_ffi`, `smoke_fuzz_encodings` green at 3x1000 local; nightly `fuzz.yml` (3 seeds x 2000); fuzz found `bigint_div_mod(-16,97)` remainder-sign bug, fixed in `xiom/num/bigint.xi` with `smoke_bigint` case 22; A3 stays in_progress until the first nightly run |
| 2026-11-06 | A1 sanitizer memory lane broadened to the A3 fuzz targets | `run_sanitizers.ps1` `-MemoryFiles`/`-LeakFiles`: memory 15 files, leak 12 baselined; local compile-only 15/15 + 12/12; leak budgets for the fuzz targets deferred to the first nightly ASan observation |
| 2026-11-06 | G3 release-state guard landed | `tools/check_release_state.ps1` (tag ancestry/annotation, package version, merge count after tag, release notes, CHANGELOG, concrete pin) wired into the CI static job with full history; negative tests exit 1; remaining G3 work is pair CI + pin/version automation |
| 2026-11-06 | G3 pair check landed; compiler relay opened | `tools/check_pair_state.ps1` + nightly `pair.yml` verify compiler `STDLIB_VERSION` names a real stdlib release tag (lag warns unless `-RequireLatest`); current pair v0.65.6 -> stdlib-v0.65.6; REL-20261106-1801-stdlib open with compiler to confirm invariant/timing |
| 2026-11-06 | B2 tail inventory landed | `tools/contract_tail_inventory.ps1` + `docs/CONTRACT_TAIL.md` enumerate the 285 EX-0 functions (7 modules) and cross-check per-module counts against `coverage_scan.ps1`; B2 moves to in_progress with a row-level reclassification list |
| 2026-11-06 | B2 first slice: ffi reclassified | 4 ffi rows moved from EX-0 to per-function EX-2 (dl shims) / EX-1 (diagnostic/dealloc); checker validates function/path against source; tail now 281 EX-0 + 4 per-function |
| 2026-11-06 | B2 second slice: thread reclassified | 5 thread rows moved to per-function EX-2 (scope) / EX-1 (sleep_ms, is_main_thread, thread_yield, thread_parallel_for); checker generic-parameter regex fixed; tail now 276 EX-0 + 9 per-function |
| 2026-11-06 | G3 tag-move defect confirmed by compiler reply | `stdlib-v0.65.6` peels to `6fdde4e`, original asset commit `06795c8` (via `02be60e`); added release locks + `known_moved` warning, lock checks in release/pair guards, and `record_release_lock.ps1`; v0.65.7 must be a fresh immutable tag at the fixed commit (REL-20261106-1803-compiler) |
| 2026-11-06 | B2 third slice: serialize/format | serialize 6 moved to per-function (EX-3 accessors, EX-1 generic/total); format 2 moved to per-function (print/println EX-1) and the 9 ANSI constant helpers got `ensures` clauses; coverage 6,716/6,992 (96.1%), tail 259 EX-0 + 17 per-function |

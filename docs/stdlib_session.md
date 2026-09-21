<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# XIOM Stdlib Session -- Handoff

## 0A. CONTINUE HERE -- handoff snapshot (updated 2026-09-20, after compiler R49)

**Repo**: `xiom-lang/stdlib` at `E:\xiom-lang\stdlib` (branch `main`).
Compiler pin: `COMPILER_VERSION` = **v0.60.0** (v0.60.1 and the pin predate
R43-R46; the nightly heavy CI already tests compiler `main`). NOTE: history
was rewritten this session (owner-authorized): every author/committer/tagger
is now `Lefteris Notas <lefterisnotas@gmail.com>`, `main` force-pushed to
HEAD `926e888`; every other clone must be re-cloned. The protected tag
`stdlib-v0.60.0` still carries the old tagger on the remote (its force-push
was rejected by tag rules -- owner action needed).

**SESSION 2026-09-20 (multi-param tranche closure + no-NASM runtime link fix)**
- Local main: `ebae67c` + `b4f2655` (runtime fallback linkage + probe),
  `820fae6` (module purpose lines/header fix), `fe92b84` (generator
  `-Timeout`), this docs commit. Not pushed (release lane decides).
- Item 1 DONE -- untested-surface multi-param tranche, R49, compile-only:
  the `-EmitOnly` scan is 47 module groups / 179 calls; the previously
  uncompiled 3..58 tranche is 14 modules / 138 calls, all OK:
  N=3 convert.overflow, math.chaos, math.number_systems (9);
  N=4 fmt, geom, net (12); N=5 ffi.c (5); N=6 ffi, math.queueing (12);
  N=7 test (7); N=11 format.textual (11); N=12 math.special,
  stats.probability (24); N=58 num (58, 44s). No module groups exist for
  N=8..10 / 13..57.
- `xiom.net` crosses the compiler's default 300s compile watchdog
  (COMPILEFAIL "compilation timed out"): with `--timeout 0` it compiles
  and links in 461s -- slowness, not a codegen defect. The generator now
  takes `-Timeout <sec>` (0 disables) and the README records it.
- FIXED stdlib-side: `runtime/xiom_runtime.c` `XIOM_NO_ASM` fallback stubs
  were `static`, so a no-NASM compiler build (the handoff recipe
  `cargo build --locked -p xiom` has `nasm` off by default) had no
  definitions for the stdlib's direct externs (`xiom.mem`, `xiom.ffi.c` ->
  `xiom_asm_memcpy/memset/memcmp`): `lld-link: error: undefined symbol`.
  Fallbacks are now externally linked (the branch compiles only when the
  NASM objects are absent, so no clash). Locked by
  `tools/probes/p_asm_fallback_link.xi` (RED before, link + run exit 0
  after); the ffi.c generator group passes after the fix. NOTE for the
  compiler lane: all session binaries so far were built WITHOUT
  `--features nasm`; build with it (NASM 3.02 is installed) to exercise
  the asm path.
- Website-session relay DONE (comment-only): `// Purpose:` lines in
  `core`, `async`, `bench`, `stats` (+ the missing `// XIOM -- Statistics`
  title); `error.xi` header mojibake `?` -> `--`. The five modules check
  clean through the probe gate (5/5, 8.5s).
- Gates on this final tree (R49): `check_modules` 509/509 (289.2s);
  corpus 949/949, 0 compilefail, 0 runfail (2792s, `-RetryFailed`);
  coverage ratchet floors53 OK; doc ratchet doc_baseline4 OK
  (6,984/6,984). `barename_scan` not re-run this session (last R49 run
  green; the diffs are comment-only plus the runtime C fallback linkage).
- Item 2 (contract wave / floors54) NOT started -- it is a full unit
  (new-shape probe -> clauses -> floors wiring -> check_modules +
  corpus); the queue below is unchanged.

**SESSION 2026-09-20 PART 2 (R52: @pre residual closed; collect contracts restored)**
- Compiler relay verified: R52 (`1fcb4855`, includes R51 `c235b3fe` --
  `@pre` walkers descend through Imply/Is -- and `a8bda203` L4) fixes the
  callee-mutation `@pre` residual; built from `git archive` per the recipe
  (`cargo build --locked -p xiom`, debug) ->
  `%TEMP%\kilo\stdlib_ws\xiom_r52.exe` (reports v0.61.0).
  `tools/probes/p_pre_capture_callee.xi` and `tools/probes/p_wave8_shapes.xi`
  compile + run exit 0.
- Item 3 DONE: restored the strong size relations in
  `collect/{list,queue,rbtree,tree,spatial,hash,intmap}`
  (ll_pop_front/back, workqueue_pop, deque_pop_front/back,
  rbtree_insert/remove, bst_remove, kdtree/quadtree/octree_insert,
  lhmap_remove, int_map_remove, string_map_remove). `lfu` never had an
  `@pre` size relation (nothing was weakened) and `fenwick` kept its wave-14
  relation throughout -- both already fully specified. `p_pre_capture_callee`
  moved from `known_failures/` to `tools/probes/`; `p_wave8_shapes` header
  updated to GREEN. Targeted smoke families 20/20 on R52 (130.1s).
- R52 gates (tree at `53fc651` + this docs commit): check_modules **509/509**
  (243.6s); corpus **949/949**, 0 compilefail, 0 runfail (**1437.1s**,
  `-RetryFailed`); coverage ratchet floors53 OK (global clauses 19.2%,
  pub-with-clause 18.9%); doc ratchet doc_baseline4 OK; barename **0 hits /
  509** (527.5s).
- Probe-corpus hygiene (NEW, open): a full `-Corpus tools/probes` run is
  157/175 on R52 -- 11 compilefail + 7 runfail, the IDENTICAL set on R49
  (re-ran the 18 on R49: same names and exit codes), so R52 introduces no
  probe regressions. Historical debug/evidence probes still sit in the
  corpus root, so the documented Probes gate cannot be green until they are
  curated out (not wired into CI). Detail: `docs/VERIFICATION_BASELINE.md`
  R52 section.
- The compiler lane verified both build configurations (default no-NASM and
  `--features nasm`); the `b4f2655` runtime fix keeps both linkable.

**R49 baseline state (2026-09-19, local main then `3f839e1`)**
- ALL GATES GREEN on the final tree: `check_modules` **509/509** (262.5s);
  corpus **949/949**, 0 compilefail, 0 runfail (**1525.7s**, `-RetryFailed`);
  coverage ratchet floors53 OK; `barename_scan` **0 hits / 509**
  (1162.8s). Runtime detection is trustworthy only after the
  `run_smokes.ps1` fix (`68e8324`); treat any older `runfail=0` as
  false-green.
- Coverage (floors53, wired in all workflows): **io 62.0%, string 60.0%,
  collect 60.7%** -- all key modules above the v1.0 60% gate; global 18.9%
  clauses / 18.9% pub-with-clause.
- API docs: **100%** (6,984/6,984 pub declarations carry `///` prose);
  `tools/doc_baseline4.json` is the 100% ratchet floor. New pub
  declarations MUST be documented or the ratchet fails.
- R44 same-leaf dedup COMPLETE (16 -> 0; empty audit baseline). R49 closed
  the relayed calls: direct `@pre` snapshots (`p_pre_call_capture`), module
  path/declared identity + freeze (`p_module_path_alias`; freeze 212
  missing -> 0), Result payloads (`p_result_payload_contract`) -- all three
  promoted to `tools/probes/`.
- OPEN compiler findings: `tools/known_failures/p_pre_capture_callee.xi`
  (R49 residual: ref-param `@pre` snapshots alias SCALAR FIELDS and
  computed-index Vec loops; method receivers and constant-index Vec work --
  this keeps `p_wave8_shapes.xi` red) and
  `tools/known_failures/p_sweep_single_param.xi` (R49-4 clang ISel crash on
  `@__unsafe_block_77`, IR deterministic, no hang).
- Contracts: strong `@pre` relations restored + verified in
  `collections.xi` (smoke 21/21), `rc` (6/6), `sync` (22/22); weak
  `@pre`-free clauses kept in `collect/{list,queue,rbtree,tree,spatial,
  hash,intmap,lfu,fenwick}` (each restored form aborted -- evidence in the
  residual file).
- Untested-surface generator `tools/gen_call_probes.ps1`
  (`-EmitOnly/-OnlyCalls/-Limit`): scan = 47 modules / 179 scalar
  multi-param never-referenced calls; the 1- and 2-call groups are compiled
  (32 OK; the single FAIL was the now-fixed os env link gap). Groups with
  3..58 calls are NOT yet compiled.
- Windows env link gap FIXED (`runtime/xiom_runtime.c` shims). CI actions
  pinned to full SHAs. Docs tooling: `doc_scan.ps1` + `doc_promote.ps1`
  (with `-Dedupe`).

**Verified state (2026-09-18)**
- Compiler main built three times this session via `git archive` + `cargo
  build --locked -p xiom`: `12148d43` (R46), `504fcc1e` (R46b, the
  qualified-receiver generic-method fix) and `306073ba` (R49, the
  `@pre`/path-identity/Result-payload fixes). All results below use R46b
  unless noted; the final gate battery uses R49.
- Corpus gates run green after every batch: R44 batches 1-3 and waves 12-15 =
  `check_modules` **509/509** + corpus **949/949** (runner file count;
  `docs/VERIFICATION_BASELINE.md` freeze says 950 -- the runner counted 949
  in all runs). **CORRECTION 2026-09-19:** those `runfail=0` numbers were
  false-green -- `run_smokes.ps1` passed `-RedirectStandardInput 'NUL'`,
  which PS 5.1 rejects, so the process never started and `$null` exit code
  was recorded as 0. Fixed in `68e8324` (empty-file stdin; failed start =
  `run=-997`). The true baseline was 938/949 with 11 runtime contract
  aborts; all were remediated stdlib-side (call-`@pre` clauses replaced with
  `@pre`-free equivalents + four inverted `remove` clauses fixed) and the
  confirmation run is **949/949, 0 runfail (2435.3s)** on R46b.
- Coverage (floors51): **io 62.0%, string 50.7%, collect 53.2%**; global
  18.3% clauses / **17.7% pub-with-clause**. Wave 14 added 38 collect
  clauses (btree/btreeplus/bloom/fenwick/cuckoo/avl/dag).
- R44 dedup COMPLETE: same-leaf conflicts **16 -> 0** (PHeap ->
  IntMaxHeap, SpscRing -> RingBuffer, IntervalTree -> IntervalSet, graph
  UnionFind -> GraphUnionFind, map IntMap -> HashIntMap, intmap StringMap ->
  OrderedStringMap, math Graph -> WeightedGraph, async Executor ->
  AsyncExecutor, timer Future -> TimerFuture, fmt FloatScan ->
  FormatFloatScan, collision Aabb/Sphere/Ray -> Collision*,
  geometry_3d Sphere/Plane -> Sphere3d/Plane3d).
  `tools/same_leaf_audit.ps1` gained a depth-aware inline-body parser
  (Regex/Match were false positives). smoke_geom_3d now constructs
  Sphere3d/Plane3d directly. The fmt rename surfaced a latent `scanf.xi`
  mismatch (it returned fmt's type under its own leaf name, masked by the
  same-name dedup); fixed with an explicit field copy.
- Compiler verification: `p_sweep_single_param.xi` STILL FAILS on R46 and
  R46b, NO HANG -- it is now a clang 22.1.8 crash
  (`Exception Code 0xC0000005`, `X86 DAG->DAG Instruction Selection` on
  `@__unsafe_block_77`); IR deterministic (4,596,577 bytes, identical
  sha256 on both). Evidence: `tools/known_failures/p_sweep_single_param.clang-crash.txt`.
  The old R45 "hang" was the debug driver being slow, not a hang.
- R46b qualified-generic-receiver finding: NEW probe
  `tools/probes/p_r46b_qualified_generic.xi` is green on R46 and R46b.
  Stdlib impact assessed as NONE: only `cell.Cell/RefCell`, `rc.Rc`,
  `mem.ManuallyDrop`, `cmp.Reverse` are called through module-qualified
  generic receivers, and none has a same-leaf twin.
- NEW findings this session: `p_result_payload_contract.xi` (a module with
  a scalar-payload Result contract AND a Vec-payload Result contract fails
  clang; blocks Err-payload clauses -- wave 13 used bare `result is Ok`
  only) and `p_os_env_set_link.xi` (Windows link gap: `setenv` undefined;
  `os.env_set`/`xiom.env.set_var` unusable on Windows MSVC) -- the env gap
  was FIXED 2026-09-19: `runtime/xiom_runtime.c` exports `xiom_env_set` /
  `xiom_env_unset` (`_putenv_s` on Windows, `setenv`/`unsetenv` elsewhere),
  `os.os`/`os.env` call the shims, and the moved probe
  `tools/probes/p_os_env_set_link.xi` round-trips set/get/remove; the six
  `smoke_env*` smokes + `check_modules` 509/509 pass.
- More compiler findings/status: compiler main **R49 (`306073ba`)** closed
  the direct call-`@pre` snapshot bug, the module path/declared-name identity
  bug (freeze test 2/2, 0 missing) and the Result-payload contract bug; the
  three repros moved to `tools/probes/` (`p_pre_call_capture`,
  `p_module_path_alias`, `p_result_payload_contract`). **Residual**
  (`tools/known_failures/p_pre_capture_callee.xi`): ref-param snapshots
  still alias scalar fields and computed-index Vec loops, so
  `collect/{list,queue,rbtree,tree,spatial,hash,intmap,lfu,fenwick}` keep
  weak clauses while `collections.xi`, `rc` and `sync` carry the restored
  strong ones (verified by smokes). `p_wave8_shapes.xi` stays red as the
  residual lock. R49 gates: 509/509 modules, corpus 949/949 (1525.7s),
  ratchet floors53 OK. `encoding/ascii85.xi` produced T001 in the compiler's
  combined-import gate (`stdlib_all_modules_compile_to_ir`); FIXED
  stdlib-side by fully qualifying the `xiom.convert.ascii85` calls (the
  bare alias bound to `num.convert`'s Option-returning `from_ascii85`) --
  that compiler test now PASSES against current main. Freeze gate evidence
  (current main): 212 frozen signatures missing = 154 resolver misses
  (`sha/md5/path/fmt/char/cmp/env/contracts/aes` moved; compiler-side
  `resolve_module_path`/manifest) + 58 drift (49 pre-existing + 9 from
  renames: `async Executor.*` x7, `net http_get/http_post` x2). Pinned
  checkout baseline is 203.
- CI: all third-party actions pinned to full SHAs per
  `sha_pinning_required` (checkout `11d5960a...`, upload-artifact
  `ea165f8d...`, rust-toolchain `6bed0761...`, cache `0057852b...`).
- Probes added: `p_r46b_qualified_generic`, `p_wave12_shapes`,
  `p_wave13_shapes`. Floors 49/50/51 dumped and wired (workflows now ratchet
  against `tools/coverage_floors51.json`).
- Untested-surface sweep: NEW generator `tools/gen_call_probes.ps1`
  (`-EmitOnly`, `-OnlyCalls`, `-Limit`; module-grouped probes). Scan found
  **47 modules / 179 scalar multi-param never-referenced calls**; compiled
  25 single-call + 8 two-call groups -> 32 OK, 1 FAIL (the os env link
  gap). The 3..58-call groups are not yet compiled.
- API docs prose: `tools/doc_scan.ps1` (coverage + ratchet) and
  `tools/doc_promote.ps1` (plain `//` -> `///` promoter) added; 2,223
  attached comment blocks promoted (4,714 lines, comment-only diff
  verified), documented pub decls 3,570 -> 5,793 of 6,984 (**82.9%**, was
  50.4%); `check_modules` 509/509 after the mass edit; baseline
  `tools/doc_baseline2.json`. Remaining 1,191 prose-less decls are
  concentrated in `iter/iter.xi` (136), `num` (119), `os` (85),
  `crypto` (72), `core` (68), `sort/sort.xi` (20), `bits/bits.xi` (28),
  `ptr/ptr.xi` (19).

**Next-session queue, in order**
1. Compiler lane follow-up (relay via the user): R49-4
   `p_sweep_single_param` clang ISel crash remains the only filed ISel
   blocker. When it lands: promote `p_sweep` to `tools/probes/` and
   re-baseline (check_modules + full corpus). Keep `p_sweep`'s current
   evidence unchanged until then. (The `@pre` scalar-field residual was
   fixed by R52 `c235b3fe`; the strong `collect/*` clauses are restored and
   `p_wave8_shapes` is green -- see PART 2 above.)
2. ~~Untested-surface generator: compile the remaining groups
   (`-OnlyCalls 3` .. `-OnlyCalls 58`, or `-Limit N` for triage) against
   the R49 binary; triage failures into `tools/known_failures/` with
   evidence and passes into `tools/probes/`.~~ **DONE 2026-09-20**
   (138/138 compile-only; the one failure was the fixed no-NASM runtime
   link gap; see the session block above). The single-param tranche stays
   blocked on item 1.
3. Coverage (optional push): payload-reading Result clauses are now
   allowed (R49-3); pre-validate new shapes in `p_waveN_shapes.xi`, then
   dump `coverage_floorsN+1.json` and wire it into all workflows + READMEs
   in the same commit.
4. Windows TLS/schannel (compiler FFI hardening) and tzdata phase 2 stay
   last; registry publish activation is the user's (dispatch-only
   `publish-registry.yml`). Every new pub declaration needs `///` prose
   (100% doc ratchet).
5. Probe-corpus curation: the full `tools/probes` run is 157/175 on R49 AND
   R52 (identical 18: 11 compilefail + 7 runfail; list in
   `docs/VERIFICATION_BASELINE.md` R52 section). Triage the historical
   debug/evidence probes into `tools/known_failures/` (still-open compiler
   findings) or an `evidence/` subdirectory the runner does not pick up, so
   the documented Probes gate can go green. Not wired into CI today.

**Recipes**
- Build a compiler ref: export it (`git -C E:\xiom-lang\xiom archive
  --format=zip -o <zip> <ref>`), expand to a temp dir, set
  `CARGO_TARGET_DIR=<temp>\target`, `cargo build --locked -p xiom`. GOTCHA:
  if you reuse a warm target dir, TOUCH all extracted sources first
  (git-archive mtimes can be older than the artifacts, so cargo skips the
  rebuild). Run with `XIOM_STDLIB=E:\xiom-lang\stdlib`. Built this session:
  R46 `12148d43`, R46b `504fcc1e`, R49 `306073ba`; binaries stashed under
  `%TEMP%\kilo\stdlib_ws\` (`xiom_r49.exe` is the current one).
- Gates: `./tools/run_smokes.ps1 -Compiler <exe> -Workers 8 -RetryFailed`;
  `powershell -NoProfile -File tools/check_modules.ps1 -Compiler <exe>`
  (this box has NO `pwsh` -- use `powershell`);
  `powershell -NoProfile -File tools/barename_scan.ps1 -Compiler <exe>`;
  `powershell -NoProfile -File tools/coverage_scan.ps1 -RatchetFile
  tools/coverage_floors53.json`;
  `powershell -NoProfile -File tools/doc_scan.ps1 -RatchetFile
  tools/doc_baseline4.json`.
- Compiler gate tests (run from the extracted compiler source):
  set `CARGO_TARGET_DIR` + `XIOM_STDLIB=E:\xiom-lang\stdlib`, copy
  `target\debug\xiom.exe` into `<extracted-src>\target\debug` (the test's
  `xiom_path()` resolves there), then
  `cargo test -p xiom-codegen --test stdlib_tests stdlib_all_modules_compile_to_ir`
  and
  `cargo test -p xiom-codegen --test stdlib_api_freeze_tests stdlib_api_freeze_no_removals`.
- The corpus takes 20-45 min with 8 workers when the compiler lane runs its
  e2e suite concurrently; check per-worker CSVs for liveness, not just the
  log (a low-row worker is usually CPU-starved, not stuck).
- No stdlib edits while a sweep is in flight; one fix = one probe = one
  verified rerun; stage explicit paths; pure-ASCII commits; verify
  `git log -1 --format='%an <%ae>'` prints Lefteris Notas
  <lefterisnotas@gmail.com> before every push. Local main is normally ahead
  of origin -- push only when the release lane asks.
- Key docs: `tools/README.md`, `docs/CI.md`,
  `docs/VERIFICATION_BASELINE.md`, `docs/STDLIB_READINESS_PLAN.md`
  (gates), `docs/STDLIB_BETA_LIMITATIONS.md`,
  `docs/SAME_LEAF_TYPE_CONFLICTS.md`, `docs/STDLIB_DEDUP_INVENTORY.md`.

## 0. START HERE -- current handoff (2026-09-16)

### 0.0 POST-SPLIT BOOTSTRAP -- read first if you are a new agent in `xiom-lang/stdlib`

This document migrated in the R0 repo split. The repo layout is normalized:

    xiom/          <- the module tree (was stdlib/xiom/); `use xiom.foo`
                      resolves to xiom/foo.xi at the repo root
    runtime/       <- the C/asm runtime (was stdlib/runtime/); owned by THIS
                      repo now -- the compiler's codegen references it, so
                      treat changes as cross-repo API changes
    tests/smoke/   <- the corpus (was examples/stdlib_smoke/): smoke_*.xi,
                      kat_*.xi, smoke_prop_*.xi, probe_*.xi
    docs/          <- the stdlib docs incl. this file
    package.xi     <- stdlib manifest

Inherited working rules (still valid):
- Do NOT edit the compiler repo (`xiom-lang/xiom`). Compiler bugs found
  while working here go to that repo's issue tracker with a MINIMAL `.xi`
  probe; keep a copy of the probe under `tools/probes/` so it
  survives, and note the compiler version/commit.
- Contracts are ACTIVE at runtime (violations abort); probe-first; one fix
  = one probe = one verified rerun; no edits while a sweep is in flight;
  batch-commit per family; pure-ASCII commits; stage explicit paths only.
- The coverage ratchet (gate #7) is a release gate -- see
  `docs/STDLIB_READINESS_PLAN.md` section 8; re-dump floors after every
  contract wave or new module.
- Beta scope/exclusions: `docs/STDLIB_BETA_LIMITATIONS.md`.

Tooling (ported 2026-09-17): `tools/` is the home -- `run_smokes.ps1` +
`run_smokes.sh` (contract runner; `-Compiler`/`--compiler`, filter, workers,
JSON, `-RetryFailed`), `coverage_scan.ps1` (ratchet; floors
`coverage_floors*.json`), `barename_scan.ps1` (509-module strict detector),
`check_modules.ps1` (check-only all modules), `modlist_all.txt`, and
`probes/` (versioned `.xi` locks only). The compiler pin is
`COMPILER_VERSION` (v0.60.0). CI (`.github/workflows/`) runs the R2 gates
against that pin; see `tools/README.md`.

GREENLIGHT (2026-09-16): the stdlib-side R0 deliverables are MET --
r47 sweep 947/947 + ratchet OK with the strict flip ON, corpus gate clean,
no open compiler findings from this lane, beta scope documented. The split
may proceed from a tagged commit. FREEZE HARDENING DONE (2026-09-17): the
post-split tooling was ported repo-relative, CI added, and the freeze sweep
on a clean compiler tag v0.60.0 build is 947/947 (strict) + 509/509 module
check + 0 bare-name hits + ratchet OK -- full record in
`docs/VERIFICATION_BASELINE.md`.

Probe index (keep these alive in `tools/probes/`; each proves a
specific lock -- re-run after any compiler bump):
- `p_enc_qual` (encoding qualification), `p_puny_parity` (punycode
  convention divergence), `p_b58_parity` (base58 delegation vectors),
  `p_b32_s5a/s5b` (same-leaf shim evidence, MZXW6=== through the shim).
- `p_ip_parity` / `p_ip_parity2` / `p_dns_parity` / `p_netip_parity`
  (ip-family delegation: 28+9 / 17+8 / 12+2+9 vectors, 0 mismatches).
- `p_payload_read` (R28 temporary `.value`; now expected CORRECT),
  `p_match_vec_codegen` (R29 match-arm Vec; now expected OK).
- `p_sync_sizeof` (strict-gate intrinsic binding), `p_path_chain`
  (R21b chain regression lock, green), `p_async_p5/p7/p9` (R23 reduced
  shapes, now green).
- Contract shape validations: `p_char_specs`, `p_char_specs2`,
  `p_wave5_specs`, `p_wave6_specs`, `p_wave6p3_specs`, `p_ansi_specs`,
  `p_net_specs`, `p_iter_specs`.

Lane boundary (pre-split history): this session owned `stdlib/**`,
`examples/stdlib_smoke/**`, and the docs listed below. A PARALLEL COMPILER
SESSION owned `crates/**` and occasionally edited `stdlib/runtime/`;
NEVER `git add -A` in the monorepo; stage explicit paths only. Branch:
`feat/architect`. After the split this boundary becomes the repo boundary.

State (round-62; HEAD 537014d4 + the compiler R28/R29 fixes; the r47
binary was built from the R28+R29 working tree and verified 947/947):
- **r47 sweep: 947/947 PASS + ratchet OK with strict_catalog_findings=true**
  (target_r47 = R28 90261793 + R29 bf627c2e + round-62 stdlib edits;
  tooling sweep47; corpus 947 files). r46 947/947, r45 944/944, r44
  940/940, r43 940/940, r42 940/940 and r41 936/937 are the prior rounds.
  The strict flip is ON and the corpus is fully green under the newest
  codegen.
- **Dedup closure (round 61):** `convert.base58.to_base58` delegates to
  `xiom.num.convert` with a pinned INT_MIN constant (p_b58_parity);
  punycode audited as NOT A TWIN (ACE-label vs RFC raw-payload
  conventions; p_puny_parity) and locked by the new
  smoke_convert_punycode. Remaining dedup: console surface (documented
  as NOT a duplicate), platform, net.address (semantics differ).
- **Contract waves:** wave 5 (+46 clauses, mostly REAL range specs: char
  predicate family, compare/collate sign bounds, collate_key length,
  bloom FPR) -> string 30.2% -> 39.5%, global 13.2% -> 13.8%; floors40.
  Wave 6 parts 1-3 (+78: iter lengths/counts, sync channel/barrier
  counts, 25 ANSI ESC-prefix specs, net ftp/port/cookie/address,
  natural-order sign bounds, unicode wrapper specs) -> global 15.3%
  clauses / 14.6% pub-with-clause; floors43. (Waves 1-4: 145 clauses,
  floors 32-39.)
- **Encoding qualification + dedup shims landed** (round-60): encoding
  loop reads -> `data[i]`, `_enc_*` triplet helpers; shims for
  convert.base16/base32/base64/base64url/percent over xiom.encoding.
- Open compiler findings: **none from the stdlib lane.** R28
  (temporary `.value`) and R29 (Vec in match arm) were logged this round
  and FIXED by the compiler lane (90261793 / bf627c2e), both re-verified
  by the stdlib lane on r47 (probes p_payload_read / p_match_vec_codegen,
  full sweep 947/947). R19/R20/R18/R16/R15b/R22/R23/R24/R25/R30 all
  FIXED. R16 fixed -> the string fast-path `(ptr as Int + n) as *UInt8`
  workaround can be revisited; R18 fixed -> payload-vs-param shapes usable.
NEXT QUEUE (ordered):
1. ~~Encoding qualification (flip unblocker)~~ DONE 2026-09-15 (1f4f0aad):
   strict flip verified green (r42 937/937). No stdlib work blocks it.
2. **Dedup:** base16/base32/base64/base64url/percent/base58/punycode
   resolved (rounds 60-61); ip family delegated round 62 (convert.ip +
   net.dns + net.ip v6 legs + net.net validator over net.ip4/ip6;
   p_ip_parity/p_dns_parity/p_netip_parity 0 mismatches; local v6 parser
   removed); os.term shimmed (stubs -> os.terminal, styles ->
   format.terminal). Remaining dedup: platform only; console surface and
   net.address are NOT duplicates (documented).
3. **Contract wave 7:** string/collect/io + broad dirs toward the 60% gate
   (wave 6 parts 1-3 landed: floors43, iter 9.8%, sync 29.1%, net 5.4%,
   format 13.0%, global 14.6% pub-with-clause). Pre-validate new shapes in
   a probe first; R18 is fixed, so payload `.value.len()` vs param `.len()`
   shapes are usable.
4. **Remaining capability:** TLS schannel binding (TLS_DECISION.md; v1.0,
   cross-repo once the compiler FFI hardening lands), TOML writer,
   stdlib parser fuzz harness, runtime symbol follow-up (20 delete
   candidates now live in this repo's `runtime/` -- confirm no dynamic
   references, then delete or marker them). Done: async stress +
   cancellation, runtime symbol audit, collection property smokes.
5. Re-run the full sweep after each batch; **r47 947/947 (strict) is the
   baseline to preserve** (r46 946 -> 947 with smoke_async_cancel).

POST-SPLIT ORDER OF WORK (first tasks in the new repo):
1. Land the stdlib CI: check-only compile of every module against the
   pinned released compiler, corpus runner over `tests/smoke/`, coverage
   ratchet, KAT gates (CI spec: release/infra lane -- ask for it if it was
   not copied into this repo); port the tooling as described in 0.0.
2. If not already done at freeze: one verification sweep freshly built
   from the split tag; record the numbers in the repo README/release notes.
3. Wave 7+ contract coverage toward the 60% key-module gate (ratchet must
   move with each wave; floors history 32..43 in the plan).
4. Runtime `runtime/` ownership tasks: the 20 definition-only delete
   candidates, then a refreshed symbol audit (script method in
   docs/RUNTIME_SYMBOL_AUDIT.md).
5. Platform dedup (last consolidation item), TOML writer, stdlib parser
   fuzz harness.
6. TLS/schannel (v1.0; needs the compiler repo's FFI hardening first).

Environment & tooling (pre-split monorepo paths -- post-split reader: see 0.0
for the ported layout; after the split the compiler binary comes from the
released artifact or the xiom repo's CI, not from `cargo build` here):
- Isolated binary build (preferred; ~30s warm):
  `$env:CARGO_TARGET_DIR="C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\target_rNN"; cargo build -p xiom`
  then use `...\target_rNN\debug\xiom.exe`. A fresh target dir is a
  from-scratch build (~10 min); reuse per round.
- Binary provenance: r39 = fresh build of a07507c4-era codegen;
  r40 = fresh build of R19-era codegen (PREDATES the R19 fix 0c1e3dff);
  r41 = fresh build of 1f4f0aad + the compiler lane's R21 WIP (936/937);
  r42 = fresh build of clean HEAD 6e7d72e5 + a2a456c4 + e6d31a1a
  (strict flip ON + R20 fix): 937/937, then 940/940 with the property
  smokes; r43 = HEAD f47beed3 + the R18/R16/R15b working tree: 940/940
  (strict); r44 = HEAD + R21d/R22 (percent shim green): 940/940; r45 =
  clean HEAD 8bc08cf0 (round 61 dedup+wave-5 stdlib edits applied after
  the build): 941/941; r46 = HEAD 9acb9bdd (R23+R24) + round-62 edits:
  947/947; r47 = R28 90261793 + R29 bf627c2e + round-62 edits: 947/947.
  Always check `git log -1` and
  `git status --short -- crates` before trusting a round's provenance;
  a dirty crates tree is normal (shared lane).
- Coverage ratchet (gate #7): stdlib_ws\coverage_scan.ps1
  [-Detail] [-DumpFloors coverage_floorsNN.json] [-RatchetFile ...];
  per-top-level-dir pub-coverage floors. Floors history: 32 (wave 1),
  34 (wave 2), 35 (TOML), 36 (section Q), 37 (tz), 38 (wave 3),
  39 (wave 4), 40 (wave 5), 41 (wave 6p1), 42 (wave 6p2), 43 (wave 6p3).
  Re-dump floors after any contract wave OR new module (new uncovered pub
  fns dilute the percentage and trip the ratchet otherwise). Post-split:
  port this to `tests/tools/` and re-point at the repo root (see 0.0).
- Sweep/verify tooling (copy + bump per round; r47 set current):
  stdlib_ws\{sweep_worker47.ps1, launch_sweep47.ps1, triage_round63.ps1,
  launch_verify38.ps1} + coverage_scan.ps1. 8 workers; per-file CSV rows;
  child stdin redirected from NUL (a stdin-reading smoke must not hang a
  worker). Triage runs the ratchet (gate #7; triage_round63 uses
  coverage_floors43.json). GOTCHA: the launcher APPENDS to results*.csv --
  delete sweepNN\results*.csv and errors*.log before a clean re-run.
- Bare-name scan (the strict-flip detector): stdlib_ws\
  {barename_worker47.ps1, launch_barename_scan47.ps1, modlist_all.txt} --
  compiles a `use xiom.X` probe for each of the 509 manifest modules and
  greps stderr for 'catalog body'. LAST RUN: r47, 2026-09-16 -> 0 hits.
  Expect 0 findings before declaring a compiler round clean. BLIND SPOT
  (round 60): a trivial probe never checks a module's ON-DEMAND bodies, so
  strict-only findings such as the bare sync size_of intrinsic do not
  appear; the full 947-file sweep with a strict binary is the detector of
  record for that class.
- Probes preserved: C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\probes\
  (p_*, probe_*, kat probes). Run verification with CWD = repo root so
  the CWD-relative stdlib root and the binary's baked manifest root are
  the same tree.
- Verification protocol: probe-first; any batch failure re-run SOLO
  before believing it; no stdlib edits while a sweep is in flight;
  one fix = one probe = one verified rerun; batch-commit per family.

Conventions / hazards (hard-won):
- PowerShell quoting: use SINGLE-QUOTED commit messages; `"` plus `->`
  in a double-quoted message breaks argument parsing.
- Contracts are ACTIVE at runtime (requires/ensures abort on violation);
  whole-body-unsafe fns need a requires (T007).
- Prefer explicit free-call forms for historical sugar-misresolve areas
  (char_at/trim are fixed now, but new param-receiver code should stay
  explicit where a free fn exists).
- R9 rule: always `use` the module you call; a full-path call to a
  never-imported module can corrupt at runtime.
- Pure-ASCII policy (ascii_guard); `repair --apply` can touch crates
  files -- revert those.
- Docs coupling: update STDLIB_READINESS_PLAN.md gate tags and this
  doc's newest section at session end; cross-boundary findings go to
  COMPILER_BUGS.md (shared with the compiler lane).

Historical detail: sections 1 .. 2.7 below are prior-session logs; the
newest status is sections 2.16 (round-58 flip worklist) and 2.17
(round-59: R19 fixed, alias isolation, flip re-held on encoding).
Key docs: STDLIB_READINESS_PLAN.md (phases T/E/O/C/S + section 9 status),
COMPILER_BUGS.md (open: R20/R18/R15b + order-independent resolution),
STDLIB_DEDUP_INVENTORY.md (progress + parity convention),
STDLIB_CONTAINER_TUNING.md (iteration order + hash-DoS posture),
STR_OWNERSHIP.md, ITEM_A_STDLIB_FINDINGS.md.

---

## 0.1 Historical "read first" (round-15 era, superseded above)

- docs/STDLIB_READINESS_PLAN.md -- this campaign's plan (phases T/E/O/C/S)
- docs/REPORT_TO_COMPILER_SESSION.md -- cross-boundary findings + compiler
  defect probes
- docs/STR_OWNERSHIP.md -- normative Str.from_cstring ownership convention
- Old sweep tooling lived under %TEMP%\kilo\stdlib_campaign\
  {launch_sweep.ps1,sweep_worker.ps1,reclassify.ps1} with the isolated
  binary in %TEMP%\kilo\tgt_std -- replaced by the stdlib_ws tooling
  described in section 0. GOTCHA (still true): module resolution scans a
  CWD-relative stdlib root AND the binary's baked CARGO_MANIFEST_DIR root;
  run from the repo root or an ISO junction so both resolve to one tree.

## 1. What landed this session (all committed)

1. **KAT corpus** (9 files, examples/stdlib_smoke/kat_*): RFC 4648 base64 +
   base32 + convert-twin parity lock, RFC 4231 HMAC-SHA256/512, RFC 5869
   HKDF TC1-3, RFC 8439 ChaCha20-Poly1305 keystream, NIST SHS SHA-2 family,
   JSONTestSuite subset, Kuhn-class UTF-8 decoder rejects. Status: 11/12
   green; kat_serialize_json_minimal blocked on json heap cluster; kat_kdf
   flaky-green (multi-call cluster), marked.
2. **Win locks** (handoff item 5 done): smoke_iter_zip_predicates,
   smoke_sync_arc_battery (atomics + Rc METHOD-call shapes -- prefix-call
   `Rc.clone(&r)` garbles receivers, do not "fix" back), smoke_string_bytecopy_locks.
3. **Real stdlib bugs FIXED**:
   - sha224/sha384/sha512 wrong digests -> C-backed one-shots in runtime
     (xiom_sha224_hash/xiom_sha384_hash/xiom_sha512_hash); NIST vectors green.
     Root causes were TWO: XIOM marshalling zero-offset store corruption and
     a wrong SHA-384 IV nibble (cbbb...ed8 not ed9) in the first C attempt.
   - base64url_encode heap overflow: partial-group tail advanced out by 4
     then wrote NUL one past malloc; locked by KAT.
   - smoke_log/smoke_os_ffi environment drift (hardcoded session dirs).
4. **CSPRNG groundwork**: runtime xiom_os_entropy (ProcessPrng/RtlGenRandom
   dynamic bind + /dev/urandom; zero new link deps) +
   crypto.os_secure_random_bytes. secure_random_bytes itself STILL legacy
   PRNG (security gap): flipping it AVs via a NEW compiler miscompile --
   see report 3b.1. Flip when their fix lands.
5. **Plan + convention docs** committed.

## 1.5. Continuation session results (2026-08-25, non-blocked roads)

1. **ChaCha20-Poly1305 interop FIXED** (was our top crypto defect): two
   poly1305.xi engine bugs -- _finalize limb serialization ignored intra-
   byte bit alignment; _bytes_to_limbs dropped bits 126-127. RFC 8439
   2.8.2 now byte-exact on ct AND tag (KAT un-gated, green). Reference
   oracle: probes/ref_aead.py (validated against the RFC first!).
2. **gzip >=4096 AV + wrong CRCs FIXED**: root cause = module-level
   [256]UInt crc table mis-materialization (reads all zeros + init heap
   overflow). Bitwise no-table impl now matches zlib exactly;
   smoke_stress_compress_gzip_large green again.
3. **StringBuilder shipped** (string/builder.xi + smoke): bare Vec[UInt8]
   API by necessity -- cross-module struct params and `self`-param prefix
   calls are compiler-broken (report 3b-2 items 9-11).
4. **Legacy quarantine + honest TLS footnotes** on des/md5/sha/https/jwt.

New compiler findings: report 3b-2 items 8-12 (module-array
mis-materialization with size-dependent AV; self-param methods invisible
to prefix calls; cross-module struct-param resolution failures; bare-name
injection inconsistency; bare-name wrong-overload binding on deflate).

## 1.6. Overnight continuation (2026-08-25, small hours) -- all committed

1. **Alloc-free search predicates** (string.xi): index_of/last_index_of/
   starts_with/ends_with rewritten onto shared byte-wise _matches_at --
   zero allocations per search. smoke_string_search locks found/miss,
   long-needle, empty-needle, multibyte-boundary cases.
2. **Decompression-bomb caps through the whole stack**: lz77/huffman/
   deflate/gzip each gain *_decompress_capped (per-symbol checks BEFORE
   allocation; huffman rejects lying declared length; gzip rejects
   over-cap ISIZE early). Uncapped names delegate with a 1 GiB default;
   aggregate facade passthroughs added.
   smoke_compress_bomb_guard: sub-size cap rejected, working cap
   round-trips byte-exact.
3. **os/args.xi shipped**: binds runtime argc/argv with [COPY] semantics;
   flag/--key=value/--key value/positional helpers over synthetic vectors;
   smoke_os_args green first run.
4. **Dedup inventory** (docs/STDLIB_DEDUP_INVENTORY.md): canonical twin
   table + verified-diverged notes + per-pair execution checklist.
5. **TLS decision** (docs/TLS_DECISION.md): bind schannel via FFI first,
   OpenSSL adapter second, homegrown TLS rejected.
6. **Extern-site ownership audit DONE**: 74 extern blocks / 45
   from_cstring sites / zero violations; one systemic caveat documented
   ([XFER-vec] subclass adopting local Vec buffers -- safe today,
   fragile under future Vec destructors). Full table in STR_OWNERSHIP.md
   section 6.
7. **lz77 investigated**: match detection WORKS in-pipeline (earlier
   3x-expansion reading was another bare-name binding artifact); ratio gap
   vs zlib (~9x on runs: 366 vs 41 bytes for 5000xA) is architectural --
   huffman container overhead + 130-byte match cap. Quality TODO, not bug.

### Night-session compiler findings (report 3b-3)
13. **Str-cast memcpy corruption**: routing str_concat through
    xiom_memcpy_dispatch with Str->ptr casts breaks CHAINED self-concat
    (wrong lengths from 3rd link; direct concats fine; pristine passes).
    Stdlib reverted to byte loops same-night; re-land after diagnosis.
14. **Runtime contracts are ACTIVE on round-15**: ensures clauses abort
    programs (exit 1 + "contract violated" message citing source line).
    str_concat's own length ensure caught finding 13 mid-flight. Expect
    contract aborts in sweeps wherever an ensure is genuinely violated.

### Verification protocol note
Sequential many-smoke batches occasionally yield NOLINE compile blips
(temp-name collisions?); ALWAYS rerun any batch-failure individually
before believing it. Solo reruns of every batch-NOLINE tonight passed.

## 1.7. Second overnight pass (2026-08-25 morning) -- non-blocked backlog drained

1. **Bomb caps completed for ALL codecs**: lz4 (per-block check,
   residual single-block overshoot documented) and snappy (varint
   declared-length early reject + per-literal/per-copy checks).
   Bomb-guard smoke extended; aggregate passthroughs added.
2. **snappy round-trip BUG FIXED**: copy2 element encodes max length 256
   but the compressor emitted matches up to 273 while advancing pos by the
   full length -- input bytes silently dropped, stream desynchronized from
   ~1000-byte inputs. Clamped emitted match to copy2 capacity.
   Caught by the new family round-trip smoke; per-size bisect probes
   snapq_*.xi.
3. **smoke_compress_crc32**: zlib-cross-checked vectors incl. classic
   123456789 check value + 5000-byte cyclic pattern (masked-string compare
   avoids the UInt32 cast hazard).
4. **smoke_compress_roundtrip_family**: direct byte-exact round-trips for
   lz77/huffman/deflate/zlib/snappy/lz4 at two sizes -- this is the smoke
   that caught snappy.
5. **kat_encoding_punycode**: RFC 3492 vectors via python-oracle; module
   verified fully conformant first run (encode + decode round-trips).
6. **docs/STDLIB_CONTAINER_TUNING.md**: Vec doubling-from-4, IntMap
   open-addressing/linear-probe/tombstones with 16-start/0.75-load/double
   growth, iteration-order UNSPECIFIED warning, hash-DoS seeded-siphash
   plan, guidance for new containers.

Final matrix: 26-target validation set green (two batch NOLINE transients
pass solo -- known harness flake, always rerun individually).

---

## 1.9. Round-17 stretch (2026-08-27) -- REAL deflate interop + flips re-verified

1. **compress/deflate.xi replaced with REAL RFC 1951** (stored + fixed
   producer, stored+fixed+dynamic consumer, caps threaded). gzip/zlib
   wrappers were already RFC-shaped -> the whole stack now emits
   INTEROPERABLE streams. Verified three ways: 9 python-zlib streams
   decode byte-exact (kat_compress_rfc1952), xiom output decompresses in
   python gzip (live cross-check), producer byte-exact vs python for
   fixed and stored. Old custom container removed (pre-1.0 break).
   All 8 compress-family smokes green.
2. **KAT breadth closed**: kat_num_bigint (python-oracle vectors),
   kat_crypto_sha_multiblock (55/56 + 111/112 boundaries),
   kat_convert_utf8_encoder, kat_net_parsers (RFC 3986/6890 ranges).
   All green on r17.
3. **Round-17 flip re-verification** (careful this time -- several
   earlier probes had been exercising legacy paths):
   FIXED: kdf cluster (KAT un-gated), Rc prefix reads, geom quat.
   PARTIAL: byte_at contextual OOB.
   STILL BROKEN: OS-entropy multi-draw (p_os_direct17 -- flip reverted
   same-day), Str-cast memcpy (re-land reverted same-day), module
   arrays, array_zip, json heap, CRT, SIMD.
   NEW: geom_vec/mat now COMPILE-fail (IR type mismatch) -- see report.
4. **Full r17 sweep: 887/927 PASS**.
5. Two new compiler findings (report 3b-4): #15 unparenthesized
   `expr as T` -> illegal instruction; #16 nested &mut push loses the
   final byte.

### A. REMAINING NON-BLOCKED (post-r17)
- [XFER-vec] -> [XFER-malloc] encoder migration (opportunistic)
- map_rehash API; seeded-siphash default hasher switch
- contract-coverage expansion; deflate dynamic-Huffman producer (quality)
## 1.8. DEFINITIVE remaining-work split

### A. REMAINING NON-BLOCKED (stdlib can do without compiler)
Small, mostly additive:
- KAT breadth: bigint/bigfloat spot values, net/url parser edge tables,
  utf8 ENCODER side vectors, SHA-512 multi-block long-message vectors
- Seeded-siphash DEFAULT hasher switch for Str-keyed maps (changes
  iteration order run-to-run -- will shake order-dependent smokes; pair
  with STDLIB_CONTAINER_TUNING.md promises)
- map_rehash API for tombstone-heavy workloads
- [XFER-vec] -> [XFER-malloc] opportunistic migration in encoder paths
- Contract-coverage expansion (runtime now ENFORCES ensures -- adding
  clauses doubles as bug discovery; case.xi wrappers already have them)
- Deflate quality project: real dynamic-Huffman blocks (current huffman
  container adds ~260B header; gzip of 5000xA is 366B vs zlib 41B)

### B. COMPILER-BLOCKED (hand to the compiler session; full detail in
REPORT_TO_COMPILER_SESSION.md 3b/3b-2/3b-3)
1. Same-name delegation crash (blocks ALL dedup execution; inventory ready)
2. Cross-module unsafe+extern+Vec miscompile (blocks OS-entropy default flip)
3. Multi-call+compare shapes AV/breakpoint (blocks kdf/json KAT un-gating)
4. json heap layer cluster (json KAT + stress serialize smokes)
5. UInt8->Int narrow-zext cast miscompile
6. byte_at contextual OOB read (builtin bound check)
7. Generic-method prefix-call receiver garble (Rc family)
8. Str-cast memcpy corruption in chained concats (memop re-land blocked)
9. geom nested &Vec[Vec[Float64]] param reads
10. CRT-layout AV cluster (iter_collect/array_slice/sort_by/url/core_box/regex x2)
11. Stack-cookie/SIMD illegal-instruction family (math_edge/pbkdf2 x2/argon2/bufreader)
12. clang-variant compile failures (ptr_offset/io_copy x2/read_int_float/hash_values/escape/captures x4/array_zip T001)
13. Silent arity mismatch / bare-name wrong-overload binding
14. Module-level array mis-materialization (size-dependent heap overflow)
15. `self`-param methods unreachable via prefix calls
16. Cross-module struct-param resolution failure
17. LET-array representation joint decision doc (their stage 4 owes us)
18. api_freeze harness path sync (their item B)
## 2. Defect ledger status

All defects from prior sessions are RESOLVED or reclassified into the
section 1.8 lists: ChaCha interop DONE, gzip AV root-caused and fixed
(crc table), deflate bare-name binding moved to compiler list item 13,
lz77 efficiency moved to non-blocked backlog (deflate quality project).
## 3. Compiler-facing queue (their side; do NOT work around)

See REPORT_TO_COMPILER_SESSION.md sections 3/3b/5. Headliners:
same-name delegation crash still MISSING from their readiness plan (blocks
all dedup); geom nested param reads; CRT-layout; json heap layer; stack-
cookie/SIMD fns; clang variants; array_zip T001; PLUS new: cross-module
unsafe+extern+Vec miscompile, multi-call compare shapes, UInt8->Int cast,
byte_at bound check, Rc prefix-call receiver garble, silent arity mismatch.

## 4. Verification protocol that worked

1. Build isolated binary from HEAD WORKTREE (never shared target/debug --
   compiler session holds uncommitted crates changes).
2. Full sweep via launch_sweep.ps1 (8 workers, per-file logs, snapshot
   list upfront) -> reclassify.ps1 parses printed exit lines.
3. Every fix verified by probe BEFORE commit; probes preserved under
   stdlib_campaign/probes for flip-green checks.
4. Mirror edited stdlib files into the verification worktree before
   running (dual-root gotcha above).

## 5. Next session queue (updated after overnight run)

1. ChaCha20-Poly1305 interop root-cause + fix (top stdlib crypto defect).
2. gzip >=4096 AV + deflate empty-return joint probe with compiler session.
3. Re-run sweep after compiler round-16 lands; verify geom/array_zip/CRT/
   stack-cookie clusters flip; un-gate kdf/json/blocked KAT asserts.
4. Flip secure_random_bytes to OS entropy once cross-module miscompile fixed.
5. StringBuilder + dealloc-free predicate rewrites (phase E1-E3).
6. Legacy cipher quarantine banners DONE; remaining: physical move to crypto/legacy/ post-delegation-fix.
7. lz77/huffman ratio improvement (real dynamic-Huffman deflate) -- quality project.
8. Container tuning + iteration-order docs; package.xi identity fix.

---

# ARCHIVE -- previous handoff (2026-08-23, evening; superseded by sections above)

## A1. Current state (verified 2026-08-23 evening, binary 6a442777 round-15)

**Round-15 verified GREEN (this session's quick battery, 14/23 previously-
blocked items):**

| Previously blocked | Now |
|--------------------|-----|
| smoke_core_binary_heap (Ord[T].compare dispatch -- interface injection fixed) | **GREEN** (pops 5,3,2,1) |
| smoke_math_numerical/analysis/calculus/integral/optimization (fn-typed Float64 thunks returned 0) | **GREEN** (thunk params now real double types) |
| smoke_math_finance (was 13) | **GREEN** |
| smoke_array_map (implicit-args [N]U result) | **GREEN** |
| smoke_array_len_empty (const-N stale across len calls) | **GREEN** |
| probe_zip_h/j/k (by-value `fn(T) -> Bool` tuple instantiations -- payload-extractor parens fix) | **GREEN** |
| smoke_array_edge (Option[&T] -> Option[T] from the stdlib session) | **GREEN** |
| probe_iter_terminals (ZipIter tuple predicates) | **GREEN** |

**Still failing (all pre-existing compiler queue, re-confirmed):**

- **geom matrix family -- nested &Vec[Vec[Float64]] param reads** (the
  one round-15 did NOT cover): smoke_geom_vec (57), smoke_geom_mat (4),
  smoke_geom_quat (18). Mono'd fn bodies read `m[1][0]` as garbage
  (probe_skew3/4: -4.0 bits for data that has no -4.0). User-space
  replicas with the same shape fail identically; locals in main are
  correct. Fix direction: the &Vec[Vec[Float64]] param's nested element
  read path (the "mono'd &[N]T body offset+1" family).
- **array_zip T001** ("cannot access field on non-struct type Int" --
  the [N](T,U) zip result element typing).
- **CRT-layout AVs (queue 5/7)**: smoke_iter_collect, smoke_array_sort_by,
  smoke_array_slice, smoke_convert_url, smoke_core_box,
  smoke_stress_regex_find, smoke_stress_regex_match_count,
  smoke_stress_serialize_jsonvalue_get, smoke_stress_serialize_json_parse_nested.
- **json heap layer (queue 4, 0xC0000374)**: smoke_stress_serialize_json_
  nested, json_parse_valid.
- **stack cookie (0xC0000409)**: smoke_math_edge, smoke_stress_crypto_
  argon2_basic, pbkdf2, pbkdf2_iterations, smoke_stress_io_bufreader
  (0xC0000409/0xC0000791).
- **clang variants (queue 6, COMPILEFAIL)**: smoke_ptr_offset, smoke_io_copy,
  smoke_stress_io_copy_file, smoke_stress_io_read_int_float,
  smoke_hash_values, smoke_convert_escape, smoke_stress_regex_captures x4.
- **smoke_error2 has-mid layout flip** (round-13 era, deterministic per
  source; chain-only probes pass -- don't chase, verify via
  probe_err_chain2).

## A2. The stdlib session's 14 commits (2026-08-22, all verified)

Full details in the previous handoff (f745736a). Summary:

- RefCell.replace `&mut self` (d904282f)
- array first/last/get/get_mut: Option[&T] was value-boxed by the mono
  (payload = element VALUE, call sites auto-deref -> AV). Switched to
  Option[T] (Vec.get-consistent) + smokes realigned (dbbf5eab)
- unary-minus on nested index parenthesized at 10 sites
  (linear/approximation/factorial/finance/numerical) (92748d7c)
- round(-3.5) ties-away-from-zero: 2 smoke expectations realigned (same commit)
- sync Arc/AtomicInt/AtomicBool constructors: `ptr.write` module prefix
  collided with the `ptr` FIELD (phantom receiver injected, ABI
  mismatch); fixed with deref-assign `*(p as *Int) = v` (ba6a045b)
- compress aggregate facade: RLE-based duplicates with empty-trapping
  requires replaced by sublib delegates (-428 lines) (7c735de3)
- base64url_decode ensures: padded bound (len/4)*3 -> floor(len*3/4)
  (954a11f0)
- serialize.is_valid_bytes: implemented (was `return true` stub) (6b2f489d)
- str_slice/str_concat: byte-copy via byte_at (was xiom_char_at as UInt8
  -> multibyte truncated) (9fb83acd)
- str_lower/str_upper: byte-safe ASCII mapping (multibyte passthrough) --
  unblocked the idna pipeline (c607b42a)
- BinaryHeap push/pop `&mut self` (c607b42a; the Ord dispatch part was
  round-15's)
- regex Regex.replace_all: bare find_all leaf-matched the method; now
  engine.regex_find_all (1db132e9)
- Smoke realignments: regex family to the engine's documented minimal
  syntax (no alternation/groups), string family inputs to `\u{...}`
  escapes, byte_at OOB to 0, array smokes to VAR literals (M33
  let->Vec)

**Convention reminders (hard-won):**
- stdlib files CRLF on disk; git autocrlf handles working-copy flips
- byte-copying string fns MUST use byte_at, never xiom_char_at as UInt8
- module prefixes colliding with receiver FIELDS misresolve (the ptr
  family) -- use deref-assign
- aggregate facade modules (compress.xi) must delegate to sublibs
- by-value self methods that mutate must be &mut self
- `\u{...}` escapes produce proper UTF-8 now (raw literals too) --
  multibyte test data can use them in ASCII files
- the runtime's internal string encoding is standard UTF-8 since
  round-14b -- the FC BC / low-byte truncations are gone EXCEPT in the
  remaining mono'd &param nested-read paths
- pure-ASCII policy enforced by the commit hook; tools/ascii_guard.py
  repair --apply also touches crates/ files -- revert those

## A3. Remaining compiler queue (from the compiler session's consolidation)

Their docs (751f0799) carry the full ~40-item queue. Stdlib-relevant:
1. geom nested &Vec[Vec[Float64]] param reads (above -- the biggest
   remaining stdlib-facing item)
2. CRT-layout clang -O2/MSVC-CRT family (queue 5/7; SIMD flags /
   clang-variant matrix is the fix target)
3. json heap layer (queue 4)
4. clang codegen variants (queue 6)
5. Bounded/Ord builtin matching residuals (queue 7 -- Ord works in the
   heap now; the user-space `Ord[Int].compare` remains unreachable)
6. array_zip T001 (checker tuple-array element typing)
7. stack-cookie fns (crypto pbkdf2/argon2, math_edge, io_bufreader)

## A4. PREVIOUS next-session queue (superseded -- see section 5 above)

1. Kick off the full sweep on the round-15 binary (sweep3.ps1,
   background, ~1.5h -- do NOT edit stdlib files while it runs).
2. Re-verify the geom matrix family + array_zip after the compiler's
   next round; if the nested &Vec[Vec[Float64]] param reads land, the
   stdlib's is_skew_symmetric etc. should flip green without changes
   (the stdlib code is verified correct).
3. Triage whatever the sweep reveals beyond the known clusters.
4. When the CRT-layout family lands, re-verify the array family
   (slice/fold/sort_by) + iter_collect + the regex/serialize AVs.
5. Consider promoting the probe coverage to permanent smokes:
   zip tuple predicates (probe_iter_terminals), the string byte-copy
   fixes, the sync constructor fixes -- a smoke_iter_zip_predicates and
   smoke_sync_arc_battery would lock the round-14c/15 wins in.
6. Update this doc at session end.

## 1.10. Production-grade stretch 3 (2026-08-28) -- maps, dynamic deflate work

1. **IntMap map_rehash shipped** (collections/map.xi): in-place rebuild
   clearing tombstones after delete-heavy workloads. smoke green.
2. **Struct-param resolution CONFIRMED FIXED on r17** (finding 3b-2 #10
   closed): fresh p_struct_param + p_mutex_xm probes pass cross-module
   by-value and by-ref struct params. Unblocks TLS/SSPI-style FFI APIs.
3. **Dynamic-Huffman work (reader hardening + producer research)**:
   - FIXED two real reader bugs: canonical zero-length counting (shifted
     every code; silent corruption of any dynamic table with unused
     symbols) and the CL-table prefill+append double-fill (38 entries).
   - Reader now decodes canonical dynamic tables WITHOUT repeats
     (round-trip proven); zlib-style 16/17/18 repeat codes are REJECTED
     LOUDLY (no silent corruption) -- focused follow-up with
     pydec6/7/8 probes as ground truth.
   - KAT gained a TRUE BTYPE=10 vector asserting the exact rejection.
   - Dynamic PRODUCER built as a probe (uniform-length construction):
     self-consistent round-trips, header parses in python, but python
     zlib still rejects the stream (invalid code lengths set) -- stays
     out of stdlib until that is resolved.
4. **Full re-sweep after the deflate replacement: 888/928 PASS** -- zero
   regressions from the RFC 1951 format swap.
5. Seeded-siphash default hasher remains parked: needs the CSPRNG flip
   (still compiler-blocked) for a real per-process key.

### A. REMAINING NON-BLOCKED (updated)
- deflate repeat-code reader support (focused item, probes ready)
- dynamic-Huffman producer validity fix (zlib-compatible code lengths)
- [XFER-vec] encoder migration; contract-coverage expansion
- map_rehash DONE; struct-params DONE (compiler)

## 2.0. Round-20 sync (2026-09-09) -- ordered remaining-work queue

> Compiler rounds 18-20 have landed on feat/architect since section 1.10
> (HEAD = 223603ce): BUG 57 + follow-ups (nested Vec ctor element
> registration, per-fn map scoping, M58 module-level mutable arrays),
> Stage 3 catalog body type-checking (Item A), literal-truncation `as`
> warning (finding #15 as a compile-time warning). Compiler-lane re-sweep
> on 034b65a6: geom vec/mat/quat/2d/3d/collision all green. Their
> stdlib-lane report received (5 items). This section = the ordered
> remaining-work queue + verified facts.

### 2.0.1 Facts verified this session (correct the record)

- **Runtime OS-CSPRNG binding EXISTS** (contradicts their report's
  "no OS-CSPRNG binding"): xiom_runtime.c ~6000-6045 defines
  `xiom_os_entropy` (ProcessPrng on bcrypt.dll -> RtlGenRandom/
  SystemFunction036 on advapi32.dll, both dynamically bound, zero new
  import deps; /dev/urandom on Unix), extern declared crypto.xi:44,
  and `os_secure_random_bytes` (crypto.xi:2078, same module as the
  extern, degrade-to-legacy fallback) is implemented. Their "not in the
  245 exported symbols" scan is either stale or name-based (they looked
  for static imports like BCryptGenRandom; the dynamic bind hides those).
  ACTION: verify the symbol actually lands in the isolated binary
  (dumpbin/link dump) during Q4 -- if it does NOT, that is the real
  packaging defect and the fix is stdlib-runtime wiring, not crypto.xi.
- **REAL security gap, chain now fully documented**: secure_random_bytes
  (crypto.xi:2125) -> math.random_range -> math.random() -> math._rng_state
  which starts at the literal 12345 (math.xi:98, Park-Miller LCG). Nothing
  seeds it on the crypto path (only math.seed_rng callers are
  optimization/operations_research/machine_learning with fixed constants
  7/13/42). => ALL crypto key/nonce/IV material is byte-identical across
  every process run TODAY. Consumers (flip ripple): aead.xi:75,
  cipher.xi:855, keyx.xi:33/92, sign.xi:30, rng_crypto.xi (6 sites),
  rand.xi:481.
- **T007 rule confirmed** (crates xiom-check lib.rs:3613): a fn whose
  whole body is one `unsafe {}` block must declare `requires`; accepted
  minimal shape is `requires: true`. Catalogued sites: io.xi print (57)/
  println (63)/time_now (403)/sleep (409). Same shape NOT in their catalog
  but identical: thread.xi yield_now (124). Sweep for any others at Q2.
- **io.xi ~354 latent type error identified**: pub fn rename (347) shares
  its name with extern C rename (io.xi:20); the Stage-3 body checker binds
  the bare call to the wrapper, typing the RHS as Result[Unit, IOError]
  against `let rc: Int32`. No #[link_name] support exists in crates.
  Fix candidates: (a) tiny runtime shim xiom_rename in xiom_runtime.c
  (precedent: the xiom_stat_* family), or (b) verify extern-vs-fn
  resolution with a 10-line probe and restructure accordingly. pub fn exit
  (363) is the same collision shape (but has requires, was not flagged) --
  probe it too.
- Gated-test ledger as of HEAD: the ONLY KNOWN-COMPILER-CLUSTER kat file
  left is kat_serialize_json_minimal (json heap layer, their stage 4).
  kdf was un-gated on r17. smoke_string_bytecopy_locks line 44: the
  contextual byte_at case stays gated (partial fix). kat files total 15,
  all committed.

### 2.0.2 Ordered queue (execute in this order)

**Q1 -- Item-A deadline fixes (do FIRST: their warnings flip to hard
errors and would block every later compile of stdlib).** Add `requires`
to whole-body-unsafe fns: io.xi print/println/time_now/sleep (semantic
clauses where cheap: sleep requires ms >= 0; print/println/time_now
`requires: true` with a comment), thread.xi yield_now, then run the
checker over stdlib/xiom/** and fix every remaining T007 + latent type
error it reports (their catalog was io-focused; Item A will hit all).
Fix the io.rename collision per 2.0.1 (probe first). Re-run the io smoke
family + smoke_thread_* + anything touching io.fs/rename afterwards.

**Q2 -- Geom un-park + consumer re-sweep (verification only, code is
correct).** On an isolated HEAD binary run: smoke_geom, smoke_geom_vec,
smoke_geom_mat, smoke_geom_quat, smoke_geom_2d, smoke_geom_3d,
smoke_geom_collision. This covers curves/bezier consumers
(smoke_geom_collision chk_curves: bezier_quad/cubic/derivative;
smoke_geom_2d chk_curves: geometry_extended.bezier_curve) and the
matrix.det/trace/rank consumers in smoke_geom_mat, plus xiom.geom.linear
via smoke_geom_vec. Un-park geom in the B-list below and in
REPORT_TO_COMPILER_SESSION.md (BUG 57 family + M58 CLOSED). Re-run the
flip-green probes their rounds should have fixed: p_crc_int2 (module
arrays), probe_byte_at_context + the gated smoke_string_bytecopy_locks
contextual case, cl_5 (Str-cast memcpy -- re-test before believing; their
report did not claim it fixed).

**Q3 -- CSPRNG completion (security-critical; the current "CSPRNG" is a
deterministic LCG, see 2.0.1).**
  a. Re-run probe p_os_direct17 (multi-draw OS-entropy) on the round-20
     binary. If green: flip secure_random_bytes to the os path (keep the
     degrade-to-legacy fallback), then run the rng/crypto smoke family
     (smoke_stress_rand_*, rng smokes, keyx/sign/aead consumers).
  b. If still breakpointing: do NOT ship deterministic keys silently --
     apply the interim time-seed (crypto.xi seeds math._rng_state once
     from an extern time/clock draw on first secure_random_bytes call;
     precedent rand.xi StdRng.new), document honestly, and hand the
     compiler lane the exact remaining shape with the probe.
  c. Docs: seeding source + reseed policy on crypto.xi/rng_crypto.xi/
     rand.xi headers; loud "not for keys" note on any still-legacy path.
  d. New smoke locking non-determinism (two consecutive draws differ;
     canary that a constant seed would fail).
  e. After the flip: un-park the seeded-siphash DEFAULT hasher switch for
     Str-keyed maps (needs a real per-process key).

**Q4 -- Fresh full sweep + re-triage on HEAD.** Last full sweep was
888/928 on r17; compiler rounds 18-20 landed since (Stage 3 body
type-checking may surface NEW stdlib-lane errors beyond the io.xi one --
fold those into Q1/Q2). Publish the new pass/fail baseline, refresh the
defect ledger, and verify xiom_os_entropy is in the isolated binary's
export list (answers the compiler lane's 245-symbols claim). Update
stdlib_session.md + REPORT_TO_COMPILER_SESSION.md from the results.

**Q5 -- LET-array joint decision input (they owe the doc; our input
requested).** Provide the stdlib-lane position + usage census for the
M33 let->Vec vs &[N]T representation decision: enumerate stdlib/smoke
shapes that depend on let-bound array semantics, and the fallout list if
let arrays become Vec. Do NOT decide unilaterally; this is their Stage 4
gate for the remaining [N]T-dependent fixes.

**Q6 -- Non-blocked backlog drain (readiness-plan gates still open).**
Contract-coverage expansion (>=60% pub-fn on collections/string/io,
every touched fn -- contracts are runtime-enforced now; pairs with Q1);
deflate dynamic-Huffman PRODUCER validity (python-zlib must accept the
stream -- probes pydec6/7/8; do NOT land until it does) + repeat-code
reader follow-up; [XFER-vec] -> [XFER-malloc] encoder migration;
runtime symbol bind-or-delete audit (~175 orphaned exports; folds in the
Q4 export verification); tzdata phase 1 via OS timezone FFI (UNBLOCKED:
struct params confirmed fixed on r17); TOML + CSV modules (toolchain eats
its own xiom.toml); Phase S: property tests for collections + coverage
ratchet; async stress suite (10k fibers, cancellation storms). Parked
until compiler: same-name delegation crash (dedup execution, legacy
cipher physical move, namespace cleanup), json heap layer (json KAT +
stress serialize smokes stay gated as flip-green locks), CRT-layout AV
cluster, SIMD/stack-cookie fns, array_zip T001, Str-cast memcpy re-land.

**Q7 -- Cross-lane replies + housekeeping.** Answer their 5-item report:
(1) OS-entropy: evidence above (binding exists; verify export; flip per
Q3a), (2) Round-19 catalog: Q1 owns it, (3) geom: Q2 owns it,
(4) LET-array: Q5 owns it, (5) e2e flake: acknowledge -- shared
xiominput.ll CWD races; adopt serialized temp outputs wherever the stdlib
session touches the harness (our sweep already reruns batch failures solo).
Verify current branch/worktree + commit Q1-Q3 batches per the
verification protocol (isolated binary from HEAD worktree, dual-root
gotcha, probe-before-commit).

## 2.1. Round-20 execution log (2026-09-09) -- Q1-Q5 results, all committed

Commits: fb7b3da0 (io family), fa9bb3da (T007 sweep), 99fe1cc2 (smoke
keyword repairs), 2eceec27 + 01ffe1da (COMPILER_BUGS.md entries R1-R4),
077b1fdf (CSPRNG interim seeding). All verified on the round-20 binary
(target/debug/xiom.exe built 2026-09-09 20:13 = HEAD 223603ce + clean
crates; protocol note: compiler session's temp worktrees are gone -- this
session used the in-tree debug binary with CWD = repo root so both module
roots resolve to the same stdlib).

**Q1 DONE -- Item-A deadline cleared.** Round-19 catalog findings closed:
io.xi print/println/time_now/sleep T007 + 354:42 rename collision. Two
runtime shims added to xiom_runtime.c: xiom_rename (MoveFileExA +
MOVEFILE_REPLACE_EXISTING on Windows = POSIX replace semantics; removes
the extern/pub-fn name collision the catalog typed as Int32 =
Result[Unit, IOError]) and xiom_process_exit (same collision removal for
exit). io.sleep Windows LINK BUG fixed (usleep does not exist on
MSVC/Windows): now routes through xiom_thread_sleep_ms. fs.xi fs_move
canonicalized to the atomic io.rename (was copy+delete, BUG 22 #15/26
workaround; round-20 rename verified correct); dead extern dropped.
T007 mechanical sweep (scanner mirrors xiom-check
block_is_single_unsafe) cleared 128 whole-body-unsafe fns to ZERO hits:
semantic requires where real (io.sleep ms>=0, br_seek Int32-range +
valid FILE*, ptr_read_*/ptr_write_* p != null, pipe_close fd>=0,
Rc/Weak/cell/sync/mutex/condvar/once/barrier/atomics handle clauses,
wstring/args null+range), requires: true where the fn is total by type
invariant or a graceful-Err FFI API (fallback fns carry no semantic
contract). Re-verified: family probes compile with ZERO T007 warnings;
runtime regression batteries (io/thread/sync/memory/math/collections
smokes) all green. Also fixed 4 smokes broken by the round-19/20 keyword
enforcement of `as` (var as -> asin_v).

**Q2 DONE -- geom un-parked; flip-green re-checks.** smoke_geom + vec +
mat + quat + 2d + 3d + collision all green (curves/bezier + matrix
det/trace/rank consumers included). byte_at contextual OOB STILL BROKEN
(new probe: returns 4 after preamble) -> COMPILER_BUGS.md R1, stays
gated. M58 residual: module-level mutable-array LITERAL INITIALIZER still
emits invalid IR (store ptr vs [256 x i64]) -> R2; no stdlib module needs
that shape (all tables const). Chained str_concat byte-loop path green.
YamlValue "non-exhaustive match" 0:0 W000s = checker false positives
(all variants covered; block-arm/return analysis gap) -> R3.

**Q3 DONE -- deterministic-CSPRNG gap closed (interim), flip still
compiler-blocked.** Re-created p_os_direct17 as p_os_direct20 + bisect:
single cross-module os_secure_random_bytes draw + reads = OK; SECOND
draw corrupts byte reads of either Vec (0xC0000005) in-frame or
cross-frame -> COMPILER_BUGS.md R4. The full secure_random_bytes flip is
therefore still BLOCKED (their de-scope claim answered with the bisect:
the symbol links fine; the defect is second-call Vec-slot corruption).
Interim landed (no workaround; honest + tracked): one flag-gated
os_secure_random_bytes(8) draw per process seeds math._rng_state on first
secure_random_bytes call. The fixed-seed-12345 determinism (every key
byte-identical across all runs) is GONE: draws differ in-process and
cross-process (locked by
smoke_stress_crypto_secure_random_seeded; consumers + existing crypto
smokes green). Generators still LCG: headers now say NOT a CSPRNG, keys
must not derive from this path until the compiler fix + full flip.
Un-park item: seeded-siphash default hasher STILL waits on the full flip.

**Q5 DONE (input) -- LET-array census.** stdlib + smokes contain ZERO
let-bound fixed arrays (0 sites); all 69 fixed arrays are `var` FFI
staging buffers (net/socket/websocket/io/crypto/buffer/pipe/hash lead),
plus 85 [N]T / &[N]T params. Position for the joint doc: a let->Vec
representation change has NO stdlib/examples surface today; the var
[N]T staging buffers (address-stable &buf[0] for extern calls) are the
impactful class if var semantics ever change -- record that in their
Stage 4 doc.

**Q4 in flight at doc time**: full 933-smoke sweep on 8 workers
(sweep_worker.ps1 + launch_sweep.ps1 in the probes dir; results CSV per
worker). Triage against the ledger below when it lands.

**Refreshed blocked ledger (compiler lane; COMPILER_BUGS.md R1-R4):**
byte_at contextual OOB; M58 initializer store; OS-entropy multi-draw
(R4 -- flips CSPRNG + siphash when fixed); same-name delegation crash
(dedup execution, legacy cipher move); json heap layer (json KAT +
stress smokes stay gated); Str-cast memcpy chained concat (memop
re-land); CRT-layout AV cluster; SIMD/stack-cookie fns; array_zip T001.
Catalog noise to ignore while Item A matures: undefined variable
io/string/size_of/alloc, unknown fn() -> T type, yaml 0:0 exhaustiveness.

**Deferred backlog notes:** [XFER-vec] -> [XFER-malloc] migration has 10
concrete sites (crypto.xi:342 sha256_hex, string casefold:163,
collate:92, compat:128, ea_width:287, normalize:206, unescape:51/74,
unicode:992, misc glob:45). CONVERSION CAVEAT verified before touching:
Vec buffers come from the @realloc intrinsic; allocations made inside
unsafe blocks route to the guard arena (xiom_guard_alloc) -- free via CRT
only after confirming the buffer was built in safe code; otherwise keep
the documented "SAFE today" posture. Contract-coverage expansion (Q6)
next; stale BUG-56 NOTE comments on io.xi fs fns can be retired once
requires are restored there (Str-param contract reads verified working on
round-20 via io.rename).

## 2.2. Round-21 close (2026-09-09 evening) -- CSPRNG flip landed; 933-sweep triage complete

**R4 flip DONE (7148b615).** Compiler lane fixed the guard-arena escape
(041e8bb3; root cause: confined-block Vec growth past the initial 16-byte
buffer migrated main-heap Vecs into the discarded arena -- the stdlib
"second-call" framing was incidental). Verified on the current binary:
p_os_direct20/p_os_double/p_os_twoframes all green with differing draws;
5000-byte multi-draws (the true trigger) pass. secure_random_bytes now
delegates to os_secure_random_bytes (OS-entropy CSPRNG, ProcessPrng/
RtlGenRandom or /dev/urandom); the OS-seeded LCG remains ONLY as the
documented no-OS degraded fallback. Headers updated (crypto.xi +
rng_crypto.xi: CSPRNG status restored with the degraded-mode caveat);
lock smoke strengthened (5000-byte growth-escape draws). Consumers
(aead/cipher/keyx/sign/rng_crypto/rand + kdf/mac/hash/curves smokes) all
green. Un-park item: seeded-siphash DEFAULT hasher switch is now
UNBLOCKED (real per-process key available) -- next backlog candidate.

**Q4 sweep: 933 files -> 903 PASS at sweep time.** All 16 runfails are the
catalogued compiler clusters (json heap x6, CRT-layout x6, stack-cookie
x4) -- ZERO new stdlib regressions from the Q1-Q3 contract work. The 18
compilefails triaged to:
- 12 known (clang-variant/T001/stack-cookie families: array_zip,
  convert_escape, hash_values, ptr_offset, io_copy, argon2_basic,
  io_copy_file, read_int_float, regex_captures x4)
- 6 NEW, of which 4 FIXED stdlib-side this session:
  * smoke_env_edge/env_var -> env.get_var (env.var was unparseable: 'var'
    reserved at call sites; renamed module fn, only 2 callers)
  * smoke_math_algebra_ext -> module_theory param 'module' renamed
    module_set (keyword param broke every call; group_theory twin works)
  * smoke_stress_crypto_rsa_keypair -> 'var pub' local renamed pub_key
    (keyword local inside the fn poisoned cross-module calls; module
    compiled fine)
  * smoke_net_http2 m.type -> m.kind after net/mime MimeType.type +
    Link.type renamed to kind (reserved field was unreadable); empty-
    parts build check removed (cross-module struct types unspellable);
    then blocked at CODEGEN by invalid GEP indices (R6, compiler lane)
  * machine_learning metric_recall 'var fn' renamed fn_count (R7 family)
- 2 COMPILER-BLOCKED, catalogued with full evidence:
  * smoke_net_address (R5): address.xi is CORRECT (whole-file probe
    passes) but cross-module Option[Address] returns come back with all
    Str fields empty; shape-specific, replicas pass. Flip-green lock.
  * smoke_net_http2 (R6): invalid getelementptr indices in the
    mime/multipart/sse graph at codegen; isolated mime consumer green.
    Flip-green lock.
Keyword-poisoning family (R7) recorded for the compiler lane: reserved
words in fn-body locals/params parse (context-dependent enforcement) but
break cross-module calls to the enclosing fn. Stdlib is now clean
(scan: only soft-keyword 'move' remains in game_theory, verified usable).

Post-fix expected baseline: 907/937 green; the 30 non-green files are
100% catalogued compiler-lane items with flip-green locks + probes.

**Handoff state:** branch feat/architect, all work committed. Next-session
queue: (1) seeded-siphash default hasher switch (now unblocked by the
flip; pairs with STDLIB_CONTAINER_TUNING.md -- will shake iteration
order), (2) contract-coverage expansion + retire remaining stale notes,
(3) XFER-vec migration per the caveat above, (4) re-run the 933-sweep on
the compiler lane's next round for R5/R6 flips + json/CRT/stack-cookie
families, (5) deflate dynamic-Huffman producer quality project.

## 2.4. Rounds 26-29 verification (2026-09-10 evening) -- R5/R6/CRT/KDF flips; R7/R8 found

Verified on a fresh isolated build of round-29 HEAD (temp target dir).
Compiler rounds 26 (json P2), 27 (R5/R6), 28 (CRT), 29 (KDF/stack-cookie)
flipped most of the ledger red->green:

- kat_serialize_json_minimal: UN-GATED and GREEN (marker updated).
  json family: parse_valid (was heap-corrupt), parse_nested, jsonvalue_get
  all green. STRESS JSON NESTED still red: new compiler defect R7 --
  generic-container mono truncates large V: Map[K,JsonValue].values[i]
  comes back garbage (p_map_key_probe), while direct Vec[JsonValue] works
  (p_vect_json). Bisect: push of V inside a generic fn writes wrong width
  (p_gp_a: 1.09e-311) and Vec[V].new() inside a generic ctor yields a
  corrupt vec whose later push AVs (p_gp_b/p_gp_c). Catalogue R7 with
  probes; no stdlib-side fix (code correct).
- R5 + R6 FIXED (root cause: benchmark-graph module pollution dragging a
  colliding `Address` type into every stdlib compile; catalog root-scoped
  lookup + import-scoped bare-type resolution). smoke_net_address and
  smoke_net_http2 GREEN end to end.
- CRT family: smoke_array_slice, smoke_core_box,
  smoke_stress_regex_find GREEN. smoke_stress_regex_match_count still AV
  (not in their round-28 scope).
- KDF/stack-cookie: smoke_stress_crypto_pbkdf2 (+_iterations) GREEN.
  smoke_math_edge still traps (their next round).
- Compiler-lane handoffs CLOSED (ef15043d): stdio FILE* accessors added
  (stdin_file/stdout_file/stderr_file; the FD-as-FILE* trap) + bufreader
  smoke fixed; argon2 smoke 5-arg fix; convert_url fixture restored
  (\u{00E4} input). All three green.
- R8 catalogued: char_at contract codegen. The old ensures'
  `s.char_count()` (free fn in method syntax) evaluated 0 -> aborted every
  Some return (hit via json build); the correct byte-domain `s.len()`
  version instead corrupts the stack for method-position `.char_at` (the
  builtin Char overload in xiom.misc.glob) -- 0xC0000409 at the first
  wildcard loop. Clause REMOVED with an in-file PENDING note (body guard
  unchanged) pending their contract-codegen fix.

Dedup state unchanged (misc.soundex + string.glob shims + rc move landed
earlier today; see 2.3/STDLIB_DEDUP_INVENTORY.md). Full 933-smoke sweep
on round-29 launched; triage lands on top of this section. Queue after
triage: R7/R8 once fixed, seeded-siphash switch, next dedup units.

## 2.5. Round-29 full sweep results + R9 (2026-09-10 late evening)

Sweep: 935 rows -> 916 PASS / 7 RUNFAIL / 12 COMPILEFAIL. vs r20: 19
FLIPS (R5/R6, CRT slice+core_box+regex_find, KDF x2, json family, argon2
and more), 3 regressions investigated:
- smoke_stress_serialize_large_json: REAL r29 codegen regression (erased
  Option slot for concrete Option[JsonValue]; catalogued R7 follow-up).
- smoke_string_glob: REAL defect, but stdlib-side -- the glob shim was the
  only shim WITHOUT `use` of its target module; consumers importing only
  the shim crashed 0xC0000409. Fixed 1e099b84 (`use xiom.misc.glob;`),
  verified 3x, vectors folded into smoke_string_glob (parity smoke
  retired per the twin-vs-vectors convention).
- smoke_error2: flaky-by-source (green solo; known has-mid layout flip).

Remaining reds are 100% compiler-catalogued: clang-variant compilefail x11
(array_zip, convert_escape, hash_values, io_copy, ptr_offset,
io_copy_file, read_int_float, regex_captures x4), math_edge,
regex_match_count, serialize_json_nested + large_json (R7/R7-follow-up),
+ error2 (flaky). Effective post-fix: ~919/935.

Also landed this round: io.open/io.close FILE* wrappers (BufReader had NO
public file-open API; only stdin_file()) + file-based
smoke_stress_io_bufreader (deterministic; the old one blocked harnesses on
stdin -- all future sweep workers should redirect stdin).

NEW compiler finding R9 (catalogued with repros): full-path calls to a
module that was never imported crash at runtime (0xC0000409) -- caller
shape (p_x1/x2/x4/x6, p_sdx/p_lev_shim_first; same on r25+r29) and the
shim-internal shape (now fixed stdlib-side). Direct call to the canonical
first masks it. Resolver must hard-error, not corrupt.

Next queue (unchanged priority): R7/R8/R9 when their rounds land;
seeded-siphash default hasher; legacy crypto/legacy/ move; namespace
cleanup (62 collections/ files declare xiom.collect.*); contract-coverage
wave + published number; dedup continuation (endian trio, base32/ascii85/
percent/punycode, ip4/ip6, terminal, platform).

## 2.6. Compiler rounds 30-31 verification (2026-09-11) -- R7/R8/math_edge/regex flips; R8-followup + R10 found

Fresh isolated build at HEAD (8d73a8a6). Compiler fixes verified green:
R7 (json nested + large_json + the erased-Option regression), R8 (char_at
contracts + method-position sugar), math_edge (shl/shr), regex family
compile fails, interface-dispatch arity validation.

Stdlib-lane actions (commit 31943d7a):
- char_at in-range ensures RESTORED (byte-domain; method + free + glob
  verified). The R8 PENDING note is gone.
- Regex smokes realigned to the honest surface: Result unwrap on
  Regex.new; captures = whole-match only; get_named = None (documented
  stub). 4 of 5 captures smokes green; captures_get blocked by R10.
- Regex.match_count bug FIXED: it used the legacy local find_all (2)
  while Regex.find_all uses the engine (3); now counts its own find_all.
- engine.xi + regex.xi converted to the free-call string.char_at(s,pos)
  form (18+15 sites; per the compiler-lane guidance).
- hash_value fixed: stale 0-arg interface dispatch -> by-value concrete
  dispatch (hasher interface has no impls yet); hash family green.
- io.parse_int/io.parse_float exposed (deterministic cores of the stdin
  line readers); smoke_stress_io_read_int_float rewritten to pin them.
  Used string.str_trim because method `.trim()` on a Str PARAM is still
  corrupt on this compiler -> catalogued as R8 follow-up (probe
  p_strparam2).

New compiler findings (catalogued):
- R8 follow-up: method-position sugar for OTHER free fns (trim) on Str
  params still corrupts; free-call form works.
- R10: Vec[Option[struct-with-Str]] element reads AV (local mirror
  repro); blocks Captures.get / smoke_stress_regex_captures_get.

Remaining reds after this round: smoke_stress_regex_captures_get (R10),
ptr_offset + convert_escape + array_zip (their next rounds), error2
(flaky-by-source). Everything else in the last sweep is now green or
flipped: effective ~925/935 with only the four catalogued items left.

Queue next: R10/R8-followup when fixed; the A/B/C/D readiness items from
STDLIB_READINESS_PLAN.md section 9.2 (seeded-siphash first).

## 2.7. Round-32 verification + seeded-siphash delivered (2026-09-12)

Compiler fixes verified GREEN on a fresh build at HEAD (Stage 2c slices,
LET-array P2/P3 also landed): R8 follow-up (029bdb77 -- trim on Str
params works again; io.parse_int/parse_float reverted to natural
s.trim()), R10 (captures_get green), ptr_offset + convert_escape
(195a5d6a), array_zip (2b808bb2). ALL previously catalogued compiler items
from the r29 sweep are closed; remaining known-red across the corpus:
smoke_error2 (flaky-by-source, green solo) + the R9 latent shape
(full-path calls without an import -- no shipping consumers).

Readiness item A2 DELIVERED (b6df21b7): per-process OS-entropy seeded
SipHash-2-4 as the StringMap default:
- siphash.xi core -> pointer+len signature (Vec AND Str hash with zero
  copies); reference vectors re-verified byte-exact; per-process key pair
  lazily seeded from xiom_os_entropy with a documented time-derived
  degraded fallback; explicit-key APIs unchanged.
- stringmap.xi _hash_str -> seeded siphash masked to 63 bits; smoke +
  container + cross-collections batteries green.
- Iteration order for StringMap now VARIES run-to-run by design;
  STDLIB_CONTAINER_TUNING.md iteration-order + hash-DoS sections updated
  (generic HashMap[K,V] seed rollout noted as follow-up).
- Verified: Vec==Str path, in-process determinism, cross-process
  variation, vector KATs.

Queue next (readiness section 9.2): legacy crypto/legacy/ move;
namespace cleanup (62 collections/ files declare xiom.collect.*);
contract-coverage wave + published ratchet number; dedup continuation
(endian trio, base32/ascii85/percent/punycode, ip4/ip6, terminal,
platform); capability items (CSV/TOML/tzdata/async-stress/TLS); fresh
full sweep on r32 for the definitive baseline.

## 2.8. Round-32 baseline sweep + ordered queue execution (2026-09-12 evening)

All six ordered items executed; commits are listed per item.

1. **r32 baseline sweep (definitive, isolated clean-HEAD binary).**
   934 files -> 927 PASS / 3 RUNFAIL / 4 COMPILEFAIL. 18 flips vs r29
   (math_edge, regex family x4, ptr_offset, convert_escape, array_zip,
   write/read_int_float, io_copy x2, json nested + large_json,
   captures_get, bufreader, capture len/named, glob; smoke_error2 green
   this round). ZERO old-defect reds remain. The 7 reds are three NEW
   compiler regressions that entered between the r30 and r31 builds --
   all solo-reproduced and minimized, logged in COMPILER_BUGS.md:
   - R11 `.filter()` lazy adapters return EMPTY (predicate never
     consulted; even `true` -> 0). Impact: smoke_iter_pipeline,
     smoke_iter_filter, smoke_iter_chained_adapters. Probe
     p_iter_filter_r32 + stage-wise p_iter_pipeline_r32.
   - R12 `into.into_float(7)` emits a self-recursive
     `@tower.Int.to_float(i64 %ptr, i64 %val)` wrapper (clang: ptr vs
     i64). Impact: smoke_convert_traits. Probe p_ct_tower2.
   - R13 tuple identity split Tuple__Int__Int vs Tuple__UInt64__UInt64
     for `(UInt64, UInt64)` returns. Impact: smoke_hash_farm,
     sleep_hash_spooky, smoke_hash_t1ha_metro. Probe p_hash_tuple.
   All three reproduce on r31/r32 and are green on r29/r30; stdlib side
   untouched. Committed 0dc8d90a (r32 CSVs in stdlib_ws\sweep32;
   comparison via compare_r29_r32.ps1).

2. **Legacy quarantine physically complete** (0dc8d90a + 8ea8e324):
   crypto/{des,md5,sha}.xi -> crypto/legacy/ with physical-location
   headers. Module names stay frozen (`xiom.des`, `xiom.crypto.md5`,
   `xiom.crypto.sha`) so the api_freeze imports and all callers are
   unchanged; docs/STDLIB_MANIFEST.md paths synced. Verified by
   p_legacy_modules (des round-trip + md5_hex + sha256) and the 41-file
   crypto battery (all green).

3. **Namespace wave 1** (0d63c6b0): all 61 `xiom.collect.*` modules moved
   `stdlib/xiom/collections/` -> `stdlib/xiom/collect/` (directory ==
   module; the compiler's own stdlib_tests path list already expected
   collect/); the `xiom.collections` aggregate stays at
   collections/collections.xi. Manifest + NAMING_CONVENTIONS +
   SCALING_ARCHITECTURE synced; 100/100 container smokes green.
   Memory quartet deferred to wave 2.

4. **Contract-coverage wave 1 + gate #7** (69a07b7e): 40 new clauses on
   touched io/string/IntMap/StringMap fns, every shape pre-validated in
   p_contract_shapes (10/10) before touching stdlib. Coverage published:
   global 1007 clauses / 8627 fns = 11.7% (pub-with-clause 636/6465 =
   9.8%); io 29.6% -> 38.9%, string 12.4% -> 17.1%, collect 2.0%
   (container family untouched -- wave 2). Verified by a 429-file
   consumer battery with ZERO contract fallout (only the 4 known
   compiler regressions red). Ratchet mode added to coverage_scan.ps1:
   floors dumped to coverage_floors32.json, positive run RATCHET: OK,
   negative run RATCHET FAILED exit 1.

5. **Dedup endian trio unit** (9616b72f): convert/endian is now a
   delegating shim over serialize.endian (writers/readers) +
   bits.byte_swap64; frozen 8-byte Int surface preserved. Parity locked
   twin-vs-vectors in smoke_convert_endian (short 1..7-byte reads,
   >8/empty -> 0, negative two's-complement, round-trips; checks
   26-31). Pre-validated alias-call + ref-forwarding (p_alias_call,
   p_ref_forward, p_u64_cast). All four endian smokes green. ip4/ip6
   audited: NOT a blind shim (Result/Vec[UInt8] vs
   Option/Vec[UInt16]) -- queued as a translation unit.

6. **Capability: CSV landed** (e398df2f): new `xiom.serialize.csv`
   (RFC 4180 reader/writer: quoted fields, doubled quotes, embedded
   newlines, CR/LF/CRLF, custom delimiter, Err on unterminated quotes,
   CRLF writer) + smoke_serialize_csv (13 vector groups incl.
   round-trips), green first run. TOML/tzdata/async-stress/TLS remain
   the capability queue.

**Post-queue r33 verification (compiler b8e2fa43).** The compiler lane's
committed Stage 3 Item A step 1 superseded the phase-1 WIP that caused
R11/R12/R13: all three probes are green on a fresh r33 build and the full
935-file sweep is **935 PASS / 0 RUNFAIL / 0 COMPILEFAIL** -- the
definitive all-green baseline (sweep33 CSVs preserved).

Next: namespace wave 2 (memory quartet); contract wave 2 (collect
containers); dedup next units (base32/ascii85/percent/punycode, ip4/ip6
translation); TOML; re-sweep when the compiler lane's R9 work commits.

## 2.9. Continued readiness push (2026-09-12, part 2)

1. **Namespace wave 2** (78b107fb): memory quartet moved to aligned dirs
   (alloc/alloc.xi, cell/cell.xi, mem/mem.xi, ptr/ptr.xi); manifest +
   STDLIB_GENERICS/STR_OWNERSHIP docs synced; 35/35 memory smokes green.
2. **Fast-path re-land + R16** (a47ac737): re-probed the reverted memcpy
   fast path (night-session finding 13). Root cause isolated as R16 --
   `ptr + int` used directly as an argument miscompiles (probe trio
   p_str_memcpy{,2,3}.xi; the Int-cast workaround produces the right
   address). str_concat + sb_to_str re-landed through
   xiom_memcpy_dispatch with the workaround; p_fastpath_live + the string
   subset + full r34 sweep (935/935) green. Gate #4 perf item closed.
   (Sweep r34 also confirmed the new smoke_serialize_csv is in-corpus.)
3. **R15 + dedup audit** (e42520c1): the base32 shim attempt crashed --
   leaf-qualified codegen keys collide for same-leaf modules with
   same-name fns (convert.base32 vs encoding.base32), binding a wrong
   0-arg stub; logged as R15 with IR evidence and the probe pair
   (p_b32_shim crash vs p_b32_canonical green; the endian shim is the
   control -- same leaf, different fn names, green). ascii85 audited:
   ALREADY layered (convert canonical, encoding wrappers) -- no action.
   percent/punycode and the base16/base64/base58 family are R15-gated;
   base32 reverted to its local implementation. Base32 decoder parity
   vectors added to smoke_convert_base32.
4. **Contract wave 2**: 83 clauses across 56 collect containers -- every
   clause shape pre-validated (p_contract_shapes, p_contract_shape_bool,
   p_contract_shape_mut) and every size/clear body reviewed for
   non-negativity (including the two ring-buffer subtraction sizes and
   uf_component_size's 0-on-missing). collect pub-coverage 2.0% ->
   18.9%; global 12.6% clauses / 11.1% pub-with-clause. Floors refreshed
   to coverage_floors34.json (ratchet positive verified). The r35 full
   sweep is 935/935 green (definitive gate).

Next queue: contract wave 3 (collect depth + string/io), TOML, ip4/ip6
translation unit, console/os.terminal/os.term + platform audits, and --
once the compiler lane fixes R15 -- consolidate base32/percent/punycode
+ base16/base64/base58 behind shims.

## 2.10. Item A stdlib findings burn-down (2026-09-12, part 3)

The compiler lane shipped the catalog-body checker (Item A step 2,
843a5a88) plus the per-site stdlib report (docs/ITEM_A_STDLIB_FINDINGS.md,
695af0f0: 237 findings / 0 hard errors; D1-D6 marked compiler-side).
Stdlib burn-down on committed HEAD (b71d839f):

- **237 -> 0 findings, 17 -> 0 parse errors.** The compiler lane's round-56
  D1-D6 + R14 fixes closed their side; the last stdlib line was
  `xiom.time:232`'s non-operator `<=>` in an ensures, replaced with the
  exact `result.is_ok == (self.secs > earlier.secs || (self.secs ==
  earlier.secs && self.nanos >= earlier.nanos))` (the handed `secs >=`
  form was wrong for the equal-seconds nanos-borrow edge; probe
  p_duration_since covers all five branches). The in-tree measure
  `cargo test -p xiom-check catalog_corpus_is_clean -- --ignored
  --nocapture` now PASSES -- is_clean() is true, so the compiler lane's
  flip (strict_catalog_findings default + #[ignore] removal) is unblocked.
  Full r36 sweep 935/935 PASS, coverage ratchet OK, 39/39 time smokes.
- **D2.1 unsafe confinement (~112 sites):** scattered extern calls got the
  whole-fn `requires: true` safe-wrapper pattern (core/string/time/rand/
  num/math/simd/geom/misc/hash/crypto/...); single calls and all raw
  casts got local `unsafe { }` blocks (simd, sync, rc, park, collections,
  io.open).
- **T003/T007:** mem_copy/mem_set/mem_move, ptr null/null_mut/from_ref/
  from_mut, mem.swap, siphash x4, cell release x2, async_yield_now.
- **T006:** io stdio accessors now declare Int-returning externs (no raw
  pointer tail).
- **Numeric mixing (~22):** explicit casts in math, approximation,
  trigonometry, geom.*, stats.histogram, rand.
- **Missing returns:** json object/array parse loops, convert json
  validators, ffi_check_ptr, ffi c_memcpy, os.err perror,
  numerical.optimize_simplex (a genuinely missing brace fixed).
- **Individual bugs:** regex.syntax `.unwrap()` cascade x10, rand uuid
  hex `.unwrap()` x2, os Pipe.read capacity -> len, crypto curves/cipher
  Result handling, compress decompress_gzip_str -> Str::from_utf8,
  char currency/math literals ('GBP'/'+/-' mangling), legacy Slice shape
  reconcile, finance `var` -> value_at_risk (reserved keyword), 5 stray
  top-level braces (assert/base64/base64url/ascii85/idna), yaml_lite
  match wildcards, thread.park null compare, hasharray/intmap dup sizes.
- **Verification:** re-measure = `cargo test -p xiom-check
  catalog_corpus_is_clean -- --ignored --nocapture` (isolated
  CARGO_TARGET_DIR); full **r36 sweep 935/935 PASS**, coverage ratchet OK.

## 2.11. Round-56 interplay: <=> closed, R15 re-tested, TOML v1 landed

- **Item A closed on the stdlib side.** `xiom.time:232`'s non-operator
  `<=>` replaced with the exact active contract (`result.is_ok ==
  (self.secs > earlier.secs || (self.secs == earlier.secs &&
  self.nanos >= earlier.nanos))`; probe p_duration_since covers all five
  branches). The in-tree `catalog_corpus_is_clean` test now PASSES ->
  is_clean() true; the compiler lane's strict flip is unblocked.
  Runtime: 39/39 time smokes green.
- **R15 re-tested on round 56 (target_r37): NOT fixed.** The same-leaf +
  same-name shim now compiles but returns a SILENT EMPTY value for the
  same-name fns (`base32_encode` -> ""; differently-named `base32hex_*`
  legs are correct). Shim reverted again; encoding-family consolidation
  stays gated; evidence + probes in COMPILER_BUGS R15.
- **R17 found (round-56 regression, critical):** R14's concat-operand
  fallback misclassifies NESTED-index Str elements (`rows[0][0]`) as
  integers -- smoke_serialize_csv prints pointer values on r37 (green on
  r34); minimal probe p_nested_index_concat. Blocks the definitive r37
  sweep until the compiler lane fixes it; r36 (r34) remains the last
  all-green baseline. Details in COMPILER_BUGS R17.
- **TOML v1 landed:** `xiom.serialize.toml` (reader subset: comments,
  `[table]`/`[a.b]`, bare/quoted keys, basic literal strings + escapes,
  ints with `_`, floats, bools, typed arrays, section-qualified getters,
  line-numbered errors) + smoke_serialize_toml (vectors + 6 error paths).
  Green on both r34 and r37; manifest updated. Remaining capability gaps:
  tzdata phase 1 and TLS schannel.

## 2.12. Round-57: R17 verified, section Q (import discipline) closed

- **R17 verified fixed** on target_r38 (round-57): p_nested_index_concat
  and p_iter_pipeline_r32 exit 0; smoke_serialize_csv green again. Full
  r38 sweep launched as the definitive runtime gate (936 files, now
  including smoke_serialize_toml).
- **Section Q closed:** under the faithful isolated contexts (93df90b5),
  the gate showed 149 import-discipline findings (xiom.os 100,
  net.https 21, log 12, collections 8, crypto 3, encoding 3, simd 2).
  Fixed in 0de47e11: imports for os (env/io/string/core),
  net.https (string), log (io), simd (math); collections declares the
  realloc/free externs its `@realloc`/`@free` intrinsic calls need in
  scope; crypto declares malloc/free; encoding.percent_encode uses the
  bare same-module `url_encode` (self-qualification is now rejected).
  Re-measure: **0 findings / 0 hard errors / 0 parse errors, test
  PASSES** -- the strict flip is unblocked again. 76/76 targeted smokes
  green; ratchet floors refreshed to coverage_floors36.json.
- **R15 stays open:** round-57's qualified-first symbol attempt fixed the
  local repro but duplicated `@network.ping` emission (e2e_m34_j08), was
  reverted; the real fix needs module-scoped alias plumbing. Encoding
  family (base32/percent/punycode + base16/base64/base58) stays gated.

## 2.13. tzdata phase 1 landed (2026-09-14)

- **`xiom.time.tz`**: DST-aware OS local offset via the C runtime
  (`_localtime64_s` + `_mkgmtime64`; offset = mkgmtime(local(t)) - t).
  API: `tz_offset_secs_at(epoch)`, `tz_local_offset_secs()`,
  `tz_is_dst()`, `tz_local_epoch_secs()`, `tz_local_now()`. Documents the
  honest scope: host zone only, no historical/arbitrary-zone data
  (phase 2 = tzdata files).
- `xiom.time` gained `datetime_from_epoch(epoch)` (public wrapper over the
  calendar decomposition); `local_now()` stays the UTC alias with a
  pointer to `xiom.time.tz`.
- Probe-first: p_tz_ffi validated the struct-tm offsets (sec/min/hour/
  mday/mon/year at 0/4/8/12/16/20, isdst at 32; 4-byte Int32 reads, not
  8-byte Int) and the mkgmtime difference on the host (+10800s DST).
- Verification: smoke_time_tz green (offset alignment/range, offset_at
  round-trip, sane local DateTime); 40/40 time smokes green; corpus gate
  still CLEAN (0/0/0); ratchet floors refreshed to coverage_floors37.json
  (tz diluted time 13% -> 12.4%; global 12.0% with TOML+tz).

## 2.14. Contract wave 3 + R18 (2026-09-14)

- Wave 3: 22 clauses, every shape pre-validated in p_wave3_shapes --
  `str_slice` exact-length under valid bounds + clamped bound; empty
  needle => result for contains/starts/ends; `result == (len == 0)` for
  the three is_empty variants; `prefixes/suffixes/needles.len() == 0 =>
  result == false` for the *_any family; str_rindex_of Some-bounds;
  title/swap byte-length locks; 9 collect capacity fns `>= 0`.
  Result: string 17.1% -> 22.4%, collect 18.9% -> 20.8%, global
  13.6% clauses / 12.3% pub-with-clause. 173/173 targeted smokes green;
  floors refreshed to coverage_floors38.json.
- R18 logged (COMPILER_BUGS): contract false positive for
  `result is Some => result.value.len() <= s.len()` -- the constant-bound
  payload form passes, so the payload getter is fine; comparing against a
  param's `.len()` always violates. No landed clause uses the shape; the
  probe p_wave3_opt is preserved as the negative lock.

## 2.15. Round-57 follow-up: strict flip PASSES, r39 937/937, R19/R15 status

- **Strict flip landed (42943cd2)** and the now-un-ignored gate PASSES on
  the current stdlib: `cargo test -p xiom-check catalog_corpus_is_clean`
  (no `--ignored`) -> 1 passed, 0 findings under hard-error strictness.
  Section Q import discipline stayed at 0 through waves 3 + tz.
- **r39 full sweep: 937/937 PASS / 0 RUNFAIL / 0 COMPILEFAIL**, coverage
  ratchet OK (target_r39 = flip + R15 definition-side fix + codegen WIP).
- **R19 found + worked around:** the r38 sweep showed
  smoke_stress_path_components clang-failing (`ptr.replace_Str` stores the
  Str as i8). It reproduced on r34 and r38 binaries against the current
  stdlib graph, i.e. triggered by my `os -> core` import pulling
  `core -> mem -> ptr` into the closure; `core.xi`'s `use xiom.mem;` was
  UNUSED, so dropping it fixed the smoke (51/51 battery green). Logged
  with IR evidence; the generic store miscompile remains latent for real
  `mem.replace[Str]` callers.
- **smoke_bigfloat** also failed compile in the r38 sweep from a duplicate
  leaf alias (`xiom.num.bigfloat` + `xiom.bigfloat`); the redundant
  aggregate import was dropped, green solo. Both r38 reds were re-run
  green and are included in the r39 937/937.
- **R15:** partially fixed by a07507c4 -- Str-returning same-name
  delegation is now correct (base32_encode/base32hex_encode print the
  right values through the shim); Result-returning legs still deliver an
  empty-payload Err to the shim consumer and smoke_convert_base32 still
  AVs (p_b32_residual probe). Logged as **R20**; shim reverted, local
  impl green on r40. Encoding dedup stays gated.
- **R18** (payload-vs-param contract false positive) remains compiler-side;
  no landed clause uses the shape.

## 2.16. Round-58 follow-up: bare-name worklist ZERO; strict flip re-ready

- **Detector built:** a per-module import probe (`use xiom.X` alone)
  exposes that catalog body under its own imports, exactly like the
  isolated corpus gate. Swept all 509 manifest modules with 8 workers
  (`stdlib_ws\barename_worker.ps1` + `launch_barename_scan.ps1`).
  First pass: 13 unique findings in 5 modules.
- **Fixes (all 13):** core `zeroed` -> qualified `mem.zeroed[T]()`;
  os dropped its unused libc `rename` extern; `fs_ffi.chmod` ->
  `chmod_path` (smoke_os_ffi updated); console stdio externs harmonized
  to `-> Int` + casts (no more shadowing io's accessors); collections
  `vec_sort_by` -> local insertion sort (keeps the Int-comparator API);
  `bucket_idx` -> `*key as Int`; `use xiom.hash as hsh` to dodge the
  collect.hash/crypto.hash leaf shadowing; `crypto.md5_bytes` wrapper
  for `mac._hmac_digest` (dotted `crypto.md5` resolved to the legacy
  module).
- **Verification:** 509/509 probes -> 0 catalog-body findings;
  101/101 targeted battery (core/mem/collections/io/console/os_ffi/
  crypto-hmac); corpus gate green; **r40 full sweep 937/937 PASS +
  ratchet OK** (definitive runtime gate).
- **Note:** the earlier R19 "workaround" (removing core's mem import) is
  superseded: mem is imported and `zeroed` is called qualified. R19
  (generic ptr store) remains compiler-side; watch closures pulling
  core+mem+ptr. To keep BOTH the flip class and R19 quiet, os.xi now
  uses `convert.int_to_string(ts)` instead of `core.to_string(ts)` and no
  longer imports core -- core/mem/ptr stay out of the os/path closure
  (509-probe scan 0, path_components green, 101/101 battery, gate green).

## 2.17. Round-59 (2026-09-14): R19 fixed, catalog alias isolation, flip re-held on encoding

- **R19 FIXED (0c1e3dff):** the deref-store path stripped ALL `*` from the
  pointee type (i8** became i8), so `ptr.replace_Str` emitted
  `store i8 %ptr, i8**` (clang ptr/i8 mismatch, reached via
  `mem.replace[Str]`). It now strips exactly one star (stmt.rs deref
  assign + call.rs ptr.write/read); locked by e2e_m73_ptr_replace_str.
  Stdlib consequence: the earlier core-mem workaround is obsolete --
  core.xi already imports mem again for the qualified `mem.zeroed[T]()`;
  os.xi remains on `convert.int_to_string` so core/mem/ptr stay out of
  the os/path closure (belt and braces; both shapes are now safe).
- **Catalog alias isolation (same commit):** flush_catalog_bodies checks
  each body under its own use bindings, closing the corpus alias hijack
  (`use xiom.collect.hash` shadowing collections' own hash_combine).
- **Flip re-held -- the last stdlib blocker is encoding qualification.**
  Strict stdlib-exec is 85/85, but the wider e2e surface exposed an
  order-dependent bare/method resolution class:
  `xiom.encoding:151,156,162,244,249` -- `write_base64_triplet(buf, ...)`
  can bind a same-named fn from another module whose first param is Box,
  and `data.get(i).value` can bind a UInt8-returning `get`. In the
  corpus's load order the correct signatures win, so the gate stays
  clean. Stdlib fix = qualify/rename (queue item 1); compiler follow-up
  (queued) = scope-first, load-order-independent resolution.
- **No full sweep was run after 0c1e3dff** (codegen changed: rebuild
  target_r41 first). r40 937/937 at 4d071961 remains the last baseline.
  Next session: land the encoding qualification, re-run the 509-probe
  scan + encoding battery + full r41 sweep, then report flip-ready.
- New committed probes/locks from the compiler lane: e2e_m73_ptr_replace_str,
  m34_j08 + m65/m71/m72 locks green; checker 188/188, feature-reg 510/510,
  stdlib-exec 85/85 (+2 ignored), e2e 2320/2320.

## 2.18. Round-60 (2026-09-15): encoding qualification landed -- flip unblocker cleared (r41 sweep pending)


- **`encoding.xi` qualified (the only open flip blocker from 2.17):**
  - all 28 in-bounds loop reads `data.get(i + n).value` -> `data[i + n]`
    (base64_encode 151/156/162, base64url_encode 244/249/255/258,
    hex_encode 325, hex_encode_upper 364, utf8_decode 506/526/531/532/
    538/539/540/554/567, utf8_valid 584/603/608/609/616/617/618) --
    removes the method-wildcard `get` -> UInt8-returning candidate class.
  - private helpers renamed to unique names:
    `write_base64_triplet` -> `_enc_write_base64_triplet` and
    `write_base64url_triplet` -> `_enc_write_base64url_triplet`
    (definition + call sites 151/167 and 244/260) -- removes the bare-name
    same-name candidate class (Box-first-param twin).
- **Verification (target_r40 binary, CWD = repo root):**
  - new probe `probes\p_enc_qual.xi` (imports `xiom.encoding` + all encoding
    submodules; RFC 4648 tails, url alphabet `0xFB 0xFF -> "-_8"`, hex both
    cases, url/percent, utf8 2/3/4-byte + overlong/truncated/surrogate/
    >10FFFF rejects, base32 sibling): green pre-edit and post-edit.
  - encoding battery 16/16 PASS (13 `smoke_encoding*` / `smoke_stress_encoding*`
    + 3 `kat_encoding_*`), zero catalog-body findings in stderr.
  - 509-module bare-name scan: 0 findings.
  - corpus gate `cargo test -p xiom-check catalog_corpus_is_clean -- --nocapture`
    (isolated target_r40): 1 passed / 0 failed, 46.1s.
- NEXT: full r41 sweep (rebuild binary + tooling 41) -> then flip-ready
  report to the compiler lane (COMPILER_BUGS note + section 0 refresh).
- **r41 sweep (target_r41 = HEAD 1f4f0aad + compiler-lane working tree:
  R21 scope-first resolution + strict_catalog_findings: true): 936/937 PASS
  + ratchet OK.** Two NEW reds triaged:
  - `smoke_sync_arc_battery` -- STDLIB, fixed this round: strict turned the
    on-demand `catalog body [xiom.sync]: undefined variable 'size_of'`
    warnings into hard errors. `xiom.sync`/`xiom.thread`/`xiom.reflect`
    called the bare intrinsics without a binding; explicit
    `use xiom.core.size_of;` added (+ `align_of` in reflect), locked by
    `probes\p_sync_sizeof.xi`; sync/thread/reflect smokes green after.
    The 509-probe scan cannot see this class (trivial probes never check
    on-demand bodies) -- the strict-binary sweep is the detector.
  - `smoke_stress_path_join` -- COMPILER (R21 regression): chained method
    call on a method-call result loses the receiver type
    (`p.join("a").join("b")` -> `cannot call 'join'`); minimal probe
    `probes\p_path_chain.xi` is green on r40 and red on r41 with a passing
    single-join control. Reported in COMPILER_BUGS round-60, not fixable
    stdlib-side.
- **Flip status: stdlib side READY.** Encoding qualified, scan 0, corpus
  gate clean, r41 936/937 with the only red owned by the compiler lane.
- **Dedup re-land (R20 fixed, a2a456c4): 4 shims LANDED, 3 deferred.**
  - Landed (all shared bodies byte-identical to the canonical; each shim
    imports its target via an `as` alias and keeps the legacy 4-fn surface):
    `convert.base16` -> `encoding.hex`; `convert.base32` ->
    `encoding.base32`; `convert.base64` -> `encoding.base64`;
    `convert.base64url` -> `encoding.base64` byte legs (str wrappers stay
    local -- no url-safe str variants on the canonical).
  - Locks green: smoke_convert_base16/base32/base64, kat_convert_base64_parity,
    kat_encoding_base32/base64_rfc4648, smoke_encoding_hex/base64 + url
    stress; p_b32_s5a/s5b now print `B-enc=MZXW6===` through the shim.
  - Deferred behind the NEW compiler finding **R22** (catalog same-leaf
    CONSUMER aliases): `convert.percent` stays local (unique full-URL mode;
    with the shim, `percent.percent_encode` bound `xiom.encoding.percent`
    component mode -- probe p_pct_probe; `use ... as cvt` returned "");
    punycode/base58 also deferred (divergent surfaces + same consumer
    shape). Explicit consumer alias of a catalog module AVs (0xC0000005,
    pre-existing on r40; p_b32_alias/p_b32_encalias).
    **R22 CLOSED (r44, compiler 907a728a + a5e8b1dc):** explicit-alias shapes fixed on
    r43; the leaf-qualified binding fixed by the deterministic module-
    collision work on r44. The **percent shim LANDED**: component + decode
    legs delegate to `encoding.percent`; `percent_encode` stays local
    (unique full-URL mode). r44 verification: p_pct_probe both alias forms
    correct, smoke_convert_percent + percent/ascii85 green, full sweep
    940/940 + ratchet OK, corpus gate 41.7s. base58 still deferred
    (num.convert.to_base58 INT_MIN divergence); punycode still needs an
    API translation pass.
  - **r42 re-sweep with the shims: 937/937 PASS + ratchet OK; corpus gate
    clean (142s).** Dedup inventory updated with the landed/deferred split.
- **Contract wave 4 (2026-09-15): +61 clauses, floors coverage_floors39.json.**
  - Pre-validated shapes in `probes\p_wave4_shapes.xi` (Option-implies for
    to_digit/from_digit with invalid radix, `len_utf8` 1..4 through all four
    UTF-8 lengths, rotate length-preservation, Option/value bounds).
  - string: distance-family non-negativity (damerau/osa/levenshtein/
    edit_distance + limited, lcp/lcs/lcsuffix, ngram_count, hamming with the
    `a.len() == b.len() =>` guard -- the plain `>= 0` clause was WRONG and
    caught by smoke_string_hamming), unicode counts/grapheme stepping/
    combining/bidi/ea width, char.xi radix guards + len_utf8 bounds,
    combinatorics rotate `result.len() == s.len()`, template placeholder
    count. string 22.4% -> 30.2%.
  - collect: heights (avl/bst), pool in-use/available, graph degree/component
    count, uf_find (`x in range => result >= 0`; the plain clause was WRONG
    for the documented -1 sentinel and caught by smoke_collect_unionfind),
    uf_components, tinylfu/cms estimates, radix longest prefix, dag node id.
    collect 20.8% -> 23.4%.
  - io: args/BufReader.lines/read_line/read_line_trim/stdin_read_line/
    read_all_stdin/fs_temp_dir length clauses. io 38.9% -> 45.4%.
  - Global: clauses/fns 13.6% -> 14.2%, pub-with-clause 12.3% -> 13.2%.
  - Verification: targeted battery green after the two contract fixes;
    **full r42 sweep 937/937 + ratchet OK (floors39)** at wave-4 close
    (940/940 after the collection property smokes landed; see below);
    canonical corpus gate `cargo test -p xiom-check catalog_corpus_is_clean`
    PASS (64.1s; a mid-session retry had failed only because the compiler
    lane's in-flight catalog.rs WIP did not compile -- the prebuilt gate
    binary was green throughout, and the canonical rebuild is green at
    session end).

## 2.19. Round-61 stdlib (2026-09-16): dedup closure audit + contract wave 5

- **Dedup closure:**
  - `convert.base58.to_base58` now delegates to `xiom.num.convert.to_base58`
    (probe p_b58_parity: identical for 0/1/57/58/255/-1/-10/-58/INT_MAX/
    -INT_MAX) with a pinned INT_MIN constant ("-NQm6nKp8qFD"; num's
    negation overflows). from_base58, the byte legs and base58check stay
    local. smoke_convert_base58_62 extended with 8 delegation vectors.
  - punycode audited = NOT A TWIN: same module leaf and fn names but
    ACE-label (convert) vs RFC 3492 raw-payload (encoding) conventions --
    probe p_puny_parity shows 10/16 shared vectors differ by convention,
    not by bug. Both stay; NEW smoke_convert_punycode pins the convert-side
    convention (16 vectors incl. uts46/is_valid forms: Unicode input is
    invalid, ACE/ASCII are valid).
  - Remaining dedup queue: ip4/ip6 (API translation), console/os.terminal,
    core.platform/os.platform.
- **Contract wave 5 (+46 clauses, REAL specs largely):** char.xi predicate
  family gets `ensures: result == <range expression>` (is_alphabetic,
  is_alphanumeric, is_ascii, is_control, is_digit, is_lowercase,
  is_uppercase, is_numeric, is_punctuation, is_whitespace, is_letter,
  is_control_char, is_hex_digit, is_binary_digit, is_octal_digit,
  is_currency, is_math_symbol, is_emoji, is_combining_mark, is_symbol,
  all is_ascii_* aliases, is_uppercase_ascii/is_lowercase_ascii,
  to_ascii_upper/lower, is_whitespace_or_separator); compare/collate sign
  bounds (-1..1) and collate_key length preservation; bloom false-positive
  rate >= 0.0. Shapes validated across codes 0..0x2800 + emoji/separator
  blocks (p_char_specs, p_char_specs2, p_wave5_specs). string 30.2% ->
  39.5% pub-covered, global 13.2% -> 13.8%; floors40.json.
- **r45 sweep (clean HEAD + the compiler R18/R16/R15b/R22 fixes):
  942/942 then 944/944 PASS with the async stress + bloom/persistent
  property smokes + ratchet OK** (corpus 940 -> 941 -> 942 -> 944);
  corpus gate clean (77.9s).
- **Async stress suite (capability gate, 2026-09-16): NEW
  smoke_async_stress.xi** -- 2000-task executor storm with side-effect
  verification, 2000 channel send/try_recv FIFO pairs, 1000-item broadcast
  ordering, 200-timer wheel fire/cancel storm (exactly 100 fire, no
  double-fire), stopwatch + async-io locks. NEW compiler finding **R23**:
  the executor's stored-fn invocation AVs in reduced program shapes
  (probes p_async_p5/p7/p8/p9/p10; a renamed copy of smoke_async plus the
  2000-spawn scale works), so the smoke keeps the full async surface and
  scales counts; logged in COMPILER_BUGS with the minimal repro.
- **Collection property smokes extended (2026-09-16):**
  smoke_prop_collect_bloom (no false negatives over 500 LCG keys, rate in
  [0,1] and non-decreasing, clear empties the filter) and
  smoke_prop_collect_persistent (PVec/PMap structural persistence: every
  update returns a new version and leaves the old one unchanged, lengths
  and values consistent, remove persistence). Corpus 944.
- **Contract wave 6, part 1 (2026-09-16, +16 clauses, floors41):**
  iter length/count specs -- `iter_count == v.len()`,
  `iter_count_if <= v.len()`, filter/take/skip/dedup/unique `len <=
  v.len()`, `iter_scan == v.len() + 1`, `iter_cycle == v.len() * n`
  (n >= 0), `iter_repeat == n` (n >= 0), reverse/sort length equality,
  fold1 None/Some shape; sync counts -- `barrier_count >= 1` (clamped at
  construction), `channel_len >= 0`, `channel_capacity >= 0`.
  Validated in p_iter_specs (empty/single/dup/negative vectors) +
  p_wave6_specs (channel capacity clamp, barrier clamp). iter 9.8%,
  sync 29.1%, global 14.9% clauses / 14.0% pub-with-clause; floors41;
  r45 sweep 944/944 + ratchet OK.

## 2.20. Round-62 stdlib (2026-09-16): ip/dns dedup delegation + R28/R29 compiler findings

- **IP family delegated (dedup gate):** `convert.ip` validators +
  dotted-quad parser delegate to `net.ip4`/`net.ip6` (parity: p_ip_parity
  28 vectors, p_ip_parity2 9 vectors, 0 mismatches); `net.dns`
  dns_parse_ipv4/ipv6 + dns_ipv4_to_str/dns_ipv6_to_str delegate as well
  (parity: p_dns_parity 17 parser + 8 formatter cases, 0 mismatches).
  `net.ip.ipv6_parse`/`ipv6_to_string` now delegate too (p_netip_parity:
  12 v6 vectors + 2 formatter sets, 0 mismatches) and the local v6 parser
  (`_parse_v6` + `_parse_groups` + `_dcolon_index`, ~140 lines) is REMOVED;
  `net.net.is_valid_ipv4` delegates to `net.ip4` (9 vectors, 0 diffs).
  The combined canonicalizer, permissive v4 formatter, raw-bytes form,
  and dns_reverse_ipv4 stay local (unique semantics).
- **R28 (compiler, logged then FIXED 90261793):** reading `.value` off a
  TEMPORARY aggregate Option (call result) returned a Vec with zeroed data
  (Int payloads and named locals fine; match fine). Found via the parity
  probes (probe p_payload_read.xi; re-verified correct on r47).
- **R29 (compiler, logged then FIXED bf627c2e):** building a Vec inside a
  match arm over a `Result[Vec[...]]` payload broke clang codegen
  (`%struct.Vec` type mismatch); minimal repro p_match_vec_codegen.xi
  (`conv_match` failed, `conv_named` compiled). Worked around in
  net.ip.ipv6_parse; re-verified both shapes green on r47 (m83 lock).
- **os.term shimmed (2026-09-16):** `term_is_tty`/`term_width` delegate to
  `os.terminal` (single "unknown" stub policy) and the four basic style
  sequences delegate to `format.terminal.ansi_*` (identical bytes);
  clear/cursor/256-color stay local. io.console vs os.terminal are NOT
  duplicates (I/O surface vs termios/pty) -- documented, no shim.
- **Contract wave 6 part 2 (+31):** the 25 format.ansi builders get
  `result.byte_at(0) == 27` (every builder must emit an ESC-prefixed
  sequence; validated for all of them incl. clamped/negative/rgb/256
  cases in p_ansi_specs); net gets real specs -- `ftp_default_port == 21`,
  ftp reply-class predicates (`result == (code >= 200 && code < 300)` /
  1xx), `cookie_jar_size >= 0`, `address_port >= 0` (0 for unparsable,
  incl. "host:-1"), `is_valid_port == (p > 0 && p <= 65535)`
  (p_net_specs 19 checks). Global 15.2% clauses / 14.5% pub-with-clause;
  floors42; r46 sweep 944/944 + ratchet OK.
- **Contract wave 6 part 3 (+7):** misc.natural sign bounds
  (-1..1 for natural_compare / ignore_case / numeric, p_wave6p3_specs
  8+ sign checks) and unicode wrapper specs (`unicode_is_wide ==
  (ea_width == 2)`, NFC/NFKC quick-checks == (normalize(s) == s),
  `unicode_is_emoji == emoji.unicode_is_emoji`). Global 15.3% clauses /
  14.6% pub-with-clause; floors43.
- **Collection property smokes completed (2026-09-16):**
  smoke_prop_collect_rbtree (512-key LCG shuffle: inorder strictly
  ascending + exact sequence, size/get/contains/min/max, preorder/
  postorder completeness, even-key removals keep BST order) and
  smoke_prop_collect_hashchurn (1000-key array model vs LhMap through
  bulk insert / overwrite / remove-third / 2000 mixed LCG ops with full
  model verification). Corpus 944 -> 946; r46 sweep 946/946 + ratchet OK.
- **Async cancellation validated (2026-09-16):** NEW smoke_async_cancel.xi
  -- executor_shutdown drops 1000 pending tasks (none run afterwards,
  tasks==0 stable), timer-wheel cancel-all fires nothing, selective
  cancel fires exactly the survivors, unknown cancel ids are no-ops
  (note: timer ids are monotonic per wheel, not deadlines), channel close
  drains FIFO then recv/try_recv return None and send/try_send fail.
  R23 re-verified FIXED on r46 (p_async_p5/p7/p9 reduced shapes green).
  Corpus 946 -> 947; final r46 sweep 947/947 + ratchet OK (floors43).
- **R28/R29 re-verified FIXED on r47:** `p_payload_read.xi` B b0=1 (was 0),
  `p_match_vec_codegen.xi` P_MATCH_VEC_CODEGEN OK (both shapes); full r47
  sweep 947/947 + ratchet OK. Open stdlib-lane compiler findings: none.
- **Beta scoping (for the R0 split):** NEW docs/STDLIB_BETA_LIMITATIONS.md
  -- shipped surface, v1.0 exclusions (TLS, tzdata, TOML writer, parser
  fuzz, platform), intentional divergences (punycode, console/terminal),
  R28/R29 user-facing workarounds, operational notes. The stale R0 WIP
  blocker in RELEASE_INFRA_PLAN.md is corrected (stdlib WIP committed).
- Verified on r46 (HEAD 9acb9bdd = R23+R24): net/ip/dns/term smokes + all
  parity batteries green; **full r46 sweeps 944/944 -> 946/946 + ratchet
  OK** (floors41 during the delegation rounds, floors42 for wave 6p2,
  floors43 for wave 6p3 + property smokes).

## 2.21. Post-split round (2026-09-17): tooling, CI, freeze baseline, wave 7

- **Tooling ported to `tools/` (repo-relative, per REPO_MIGRATION_RUNBOOK
  6.1):** `run_smokes.ps1` + `run_smokes.sh` (`-Compiler`/XIOM_COMPILER/PATH
  resolution; filter/workers/JSON/RetryFailed; always exports
  `XIOM_STDLIB=<repo root>`), portable `coverage_scan.ps1` (ratchet +
  dump), `barename_scan.ps1`, `check_modules.ps1` (check-only via `use`
  probes; a bare module file cannot be `--check`ed -- script mode wraps it
  in implicit main), `COMPILER_VERSION` (= v0.60.0), `tools/README.md`.
  713 tracked probe run captures (.out/.err/.log) dropped; `tools/probes/`
  now versions only `.xi` locks.
- **CI added (`.github/workflows/`):** `ci.yml` (PR: ratchet + compiler
  build from the pin + check-modules + bare-name + KAT gate, ubuntu),
  `heavy.yml` (weekly full corpus win+linux; scheduled runs test compiler
  main as a drift detector), `release.yml` (tag stdlib-v*: validate
  package.xi identity/version/compiler range -> gates -> tarball +
  SHA256SUMS + build-provenance attestation -> GitHub Release ->
  STDLIB_VERSION pin PR). Reusable compiler build in
  `.github/actions/build-compiler` (anonymous: xiom is public).
  `publish-registry.yml` added (dispatch-only until staging verified):
  `xiom pkg publish` with XIOM_REGISTRY / XIOM_REGISTRY_TOKEN, compiler and
  package from public release assets. Credentials policy -- org secrets;
  `XIOM_RELEASE_TOKEN || GITHUB_TOKEN` for writes; XIOM_CROSS_REPO_TOKEN no
  longer needed; minisign deferred in favour of attestations -- see
  `docs/CI.md`.
- **`package.xi` fixed:** identity `xiom-std`, version 0.60.0, license,
  `compiler = ">=0.60.0 <1.0.0"` (the old xiom-bench/xiom-std dep was
  stale). README.md, CHANGELOG.md, cliff.toml added.
- **Freeze verification (post-split order item 2, DONE):** clean build of
  compiler tag v0.60.0 (tag predates the resource-asset fix e3714884; the
  asset dir was copied from main and the CI action carries the same
  documented workaround) -> strict sweep **947/947**, check-modules
  **509/509**, bare-name **0 hits**, ratchet OK floors43. Record:
  `docs/VERIFICATION_BASELINE.md` + `docs/baselines/`. Post-runtime-trim
  re-run: 947/947 again.
- **Contract wave 8:** 26 clauses -- unicode display-width bounds
  (truncate <= len, pad >= len, slice <= len), fixed script/category code
  lengths (4/2), numeric Option value bounds (`result is Some =>
  result.value >= 0`/`>= 0.0`), boundary-scan length bounds, and collect
  pop/remove `@pre` size relations (ll/workqueue/deque pops; int_map/
  string_map/lhmap/bst removes). NEW `p_wave8_shapes.xi` validated the
  implication + `@pre` + `result.value` shapes first. collect 29.7% ->
  **30.8%**, string 40.5% -> **44.6%**, global 16.1% clauses / **15.4%**
  pub-with-clause; floors45. Battery: 206 smokes green (unicode 3,
  collect 101, string 102).
- **Runtime audit re-run (dynamic pass added):** the hot-reload family is
  live dynamic ABI (tools/xiom_hot_host.c GetProcAddress + codegen thunks),
  so it stays; 9 definition-only symbols deleted (asm sha stub, async us
  helper, channel_close, f128 norm, f256 is_one, guard depth/armed,
  threadpool_shutdown, trampoline_clear_returned); 11 hot symbols annotated
  in `runtime/xiom_hot_reload.c`; audit doc updated with the re-run.
- **Contract wave 7:** 25 clauses across collect (constructors
  field/length specs, Option.is_some == query relations, post-remove
  absence, iter/order length equalities); NEW `p_wave7_shapes.xi` probe
  validated every new shape first. collect 23.6% -> **29.7%**, global
  15.7% clauses / **15.0%** pub-with-clause; floors44 dumped and wired
  into CI/README.
- **Dedup finding:** two unlisted collect twin pairs (`hash/linkedhash`,
  `cache/lru`) are API translation units -- XIOM has no cross-module type
  aliases, so no thin shim; inventory updated.
- **Contract wave 9:** 22 clauses -- combinatorics (length equalities for
  shuffle/seeded-shuffle/interleave/reverse_words, count bounds for
  chunk/chunks_reverse/windows/chunk_bytes/unique_chars/frequencies/
  char_set, most_frequent Some-implies-nonempty, permutation count
  bounds) and io (parent_path Some-length, BufReader/BufWriter
  constructor field equality, read_file_bytes/list_dir_recursive/
  read_file_lines Ok-length). string 44.6% -> **48.5%**, io 45.4% ->
  **50.9%**, global 16.3% clauses / **15.7%** pub-with-clause; floors46.
  Battery: 241 smokes green (string 102, io 139).
- **R45 verification (compiler main `483f283e`, 2026-09-17):** all four
  codegen probes pass (`p_x25519_keypair_codegen`, `p_http_resp_codegen`,
  `p_async_read_line_codegen`, `p_match_vec_codegen`) and check-modules is
  509/509 -- but the single-param sweep repro is NOT fixed: with a fresh
  process it either fails codegen fast or HANGS (>5-15 min, no output,
  several attempts) on `tools/known_failures/p_sweep_single_param.xi`.
  Handed back to the compiler lane (needs a fresh minimal hang repro).
  Note: release tag `v0.60.1` predates R43/R45, so `COMPILER_VERSION`
  stays `v0.60.0` until a release contains them; nightly already tests
  main.
- **Contract wave 11 (2026-09-17):** 4 constructor clauses on
  `collect/concurrent.xi` (mpmc/mpsc/spmc queues `cap >= 1`, concurrent
  stack `items.len() == 0`), runtime-exercised by smoke_collect_concurrent
  and smoke_collect_mpmc; collect battery 101/101; global 16.6% clauses /
  16.1% pub-with-clause; floors48.
- **R44 same-leaf conflicts inventoried (2026-09-17):** NEW
  `tools/same_leaf_audit.ps1` (repo-relative, read-only) + generated
  `docs/baselines/same-leaf-conflicts.md`: 313 pub-type declarations,
  40 multi-declaration leaves, **16 with genuinely different shapes**
  (Executor, Future, Graph, UnionFind, PHeap, IntervalTree, IntMap,
  StringMap, SpscRing, FloatScan, Aabb/Sphere/Ray/Plane, Regex/Match) and
  24 shape-identical duplicates (benign for codegen, dedup candidates).
  Dispositions/rules: `docs/SAME_LEAF_TYPE_CONFLICTS.md`. This is the
  stdlib worklist for the compiler R44 qualification slice.
- **Compiler findings resolved (2026-09-17, compiler R43/R44):**
  `x25519_keypair` was a compiler guard bug on reference-typed locals
  (`&v` where `var v = b` is a reference binding); FIXED in R43
  (`274184be`), verified locally against a build of that commit
  (probe p_x25519_keypair_codegen compiles + runs 0). `http_parse_response`
  was NOT a compiler ABI bug: `net.net.HttpResponse` (2 fields) and
  `net.http.HttpResponse` (3 fields) both injected as bare
  `%struct.HttpResponse` (R44 same-leaf collision); FIXED stdlib-side by
  renaming the legacy type to `NetHttpResponse` -- probe compiles+runs on
  v0.60.0, the fuzz harness regains `http_parse_response`, net battery
  11/11 and check-modules 509/509 green. R44 inventory: 40 same-leaf
  non-generic pub-type groups stdlib-wide; wholesale compiler
  qualification broke 6 smokes + 2 shape-triage smokes, so a dedicated
  compiler+stdlib slice is the path (compiler docs/COMPILER_BUGS.md R44).
  Compiler-side `stdlib_execution_tests` tree/cache contract reds are
  stale-checkout drift: both smokes pass in this repo.
- **Untested-surface sweep (2026-09-17):** reference scan over tests/ +
  xiom/ found **1010/5777 public fns never referenced anywhere**. The
  zero-arg subset (72; blocking/exit functions excluded) is now
  compiled+run by NEW `tools/probes/p_never_called_zeroarg.xi`; it found
  that `x25519_keypair` FAILS CODEGEN on v0.60.0 ("cannot take a reference
  to 'v': it is already a reference") -- minimal probe
  `tools/probes/p_x25519_keypair_codegen.xi` for the compiler lane. The
  other 71 calls compile+run green. Follow-up: generated call probes for
  the arg-taking subset (expect more findings of this class). The
  single-param tranche (139 calls, 54 modules) hits an OPEN codegen
  interaction: `Tuple__Int__Int` returned where `Tuple__Int__Bool` is
  expected; subset bisection is non-monotone, so the full repro is kept at
  `tools/known_failures/p_sweep_single_param.xi` for compiler triage.
- **Parser fuzz harness + http finding (2026-09-17):** NEW
  `smoke_stress_fuzz_parsers.xi` -- 600 deterministic generated/mutated
  inputs against json/toml/csv/url parse (+ writer round-trip stability)
  and http header totalness; reproduces from a fixed seed. While building
  it: `http_parse_response` had NEVER been exercised by any smoke and FAILS
  CODEGEN on compiler v0.60.0 (clang "invalid getelementptr" on
  `%struct.HttpResponse` field 2; the struct has a `Vec[(Str, Str)]`
  field). Minimal probe kept at `tools/probes/p_http_resp_codegen.xi`;
  the harness now includes the call (resolved 2026-09-17 by the R44
  stdlib rename `net.net.HttpResponse` -> `NetHttpResponse`); follow-up:
  sweep never-exercised public functions for the same latent class.
- **TOML writer shipped (2026-09-17):** `toml_write(t: &TomlTable) -> Str`
  emits the v1 subset -- root keys first, `[section]` blocks in
  first-appearance order, the five reader escapes, quoted keys when not
  bare, float markers (`.0` / scientific) so floats re-parse as TFloat.
  Round-trip locked by NEW `smoke_serialize_toml_write.xi` (all 7 value
  kinds + escapes + quoted key + empty table); serialize battery 24/24.
  Removed from the beta limitations page.
- **Contract wave 10:** 18 clauses -- rbtree full surface (constructor
  size, insert/remove `@pre` size relations + membership, get
  is_some==contains, min/max Some-iff-nonempty, inorder/preorder/
  postorder length == size) and cache (LRU/LFU/ARC constructor field
  specs, get is_some==contains, put-membership invariants). collect
  30.8% -> **34.4%**, global 16.6% clauses / **16.0%** pub-with-clause;
  floors47. Battery: 101/101 collect smokes green.
- **Platform dedup audit (2026-09-17): NOT duplicates.** `xiom.platform`
  (core/platform.xi; ergonomic os_name/is_windows/is_bsd/newline/path_sep/
  cpu_count/os_version, consumed by smoke_platform) and `xiom.os.platform`
  (platform_* prefixed surface + hostname/user, consumed by smoke_os_env)
  have disjoint names; core/platform already delegates to xiom.os/env, so
  there is no duplicated logic. Documented in the dedup inventory; the
  file/declaration mismatch (core/platform.xi declares xiom.platform) is a
  coordinated hygiene follow-up, not a blocker.
- Commits this round (local): 66cd23b, 547a164, 4fe005e, 1e2db86, 9dab881,
  d6449a4, plus the wave-7/dedup commit.

## 2.22. Compiler R46 report ingested (2026-09-18) + verification status

Compiler lane (from the xiom repo session):
- **R46 `12148d43` -- bench graph clang-clean.** Three same-leaf-family
  defects fixed with locks: (a) generic same-leaf collisions
  (`benchmark.generics.Box[T]` vs `generics_hard.Box[T]` collapsed into one
  bare `%struct.Box`) -- the R39 triage now includes generic types but
  splits only conflicting shapes, so identical generic re-declarations
  keep leaf-derived keys (lock m88); (b) a bare literal that is both a
  struct and an enum variant (`Node(value,left,right)` vs
  `benchmark.memory.Node`) is disambiguated by the literal's field names,
  struct preference preserved when both match (lock m89); (c) mono tuple
  params now name elements with the concrete substitution for the current
  function (m87 extended; a broader lookup regressed m44/m48, so it stays
  deliberately narrow). Hardening in the same slice: mono symbol names
  sanitize concrete type parts; bare variants inside method bodies resolve
  leaf-scope-first.
- **Verification:** `clang -c` on the bench IR exits 0; bench IR
  deterministic at 5,808,645 bytes (budget 6.3 MB); e2e 2337/2337 with the
  stdlib checkout active; feature-reg 510/510; checker 194/194; perf 2/2;
  robustness 63/63; pkg/dbg/lsp/mcp 63/34/44/39; release build clean.
  `stdlib_execution_tests` remains 83/85 -- the two pre-existing
  tree/cache contract reds are stale-checkout drift (both smokes pass in
  THIS repo).
- **NEW compiler open finding (not bench-gating):** cross-module calls to
  generic methods on a module-qualified receiver
  (`main -> h.Box.pack[Int](42)`) and generic methods whose type arg is
  inferable only from the receiver (`is_sealed[T]` on `Box[Int]`)
  fall back to erased stubs returning `zeroinitializer`. Repro + fix shape
  live in the compiler `SESSION.md`. STDLIB ACTION: check whether any
  stdlib module or smoke calls generic methods through a module-qualified
  receiver; if so, add a probe to this repo.
- Remaining compiler queue: R44 same-leaf class (waits on the stdlib dedup
  + qualification slice), then Stage 5's clap migration, LSP
  incremental/cross-file index, fmt inline comments, cargo-vet.

Stdlib status after this session (actionable list in 0A): waves 7-11
landed; TOML writer + parser fuzz harness shipped; runtime symbol audit
closed (9 dead symbols deleted, hot-reload ABI annotated);
untested-surface sweep built (1010/5777 never referenced; zero-arg subset
locked by `p_never_called_zeroarg.xi`); R44 worklist generated (16 real
conflicts, 24 benign, `docs/SAME_LEAF_TYPE_CONFLICTS.md`); CI credentials
policy applied (`docs/CI.md`, attestations, dispatch-gated registry
publish). The single-param sweep repro remains the one open
stdlib->compiler handoff (fails/hangs on main R45 `483f283e`; repro and
current evidence in `tools/known_failures/README.md`).


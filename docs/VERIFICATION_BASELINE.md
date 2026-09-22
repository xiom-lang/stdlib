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

## R49 compiler update (2026-09-19) -- relayed bugs closed

Compiler main `306073ba` (R49) fixed three stdlib-relayed findings:

- call-`@pre` direct snapshots (`0f2213bc`): `p_pre_call_capture.xi` runs
  clean (exit 0); lock `e2e_m95`.
- module path/declared-name identity + freeze gate (`82041941`, `e2e_m99`):
  all 19 mismatched path imports `--check` clean; `stdlib_api_freeze_tests`
  2/2 (was 212 missing -> 0).
- Result-payload contracts (`306073ba`, `e2e_m100`):
  `p_result_payload_contract.xi` compiles clean.
  All three repros were **moved to `tools/probes/`**.

Empirical residual (filed as `p_pre_capture_callee.xi`): ref-param snapshots
still alias SCALAR FIELDS and computed-index Vec loops, so the stdlib keeps
`@pre`-free clauses in `collect/{list,queue,rbtree,tree,spatial,hash,intmap,
lfu,fenwick}`. Restored and verified with R49 (smokes + gates):
`collections.xi` (method receivers), `rc`/`sync` clone counters (direct
field increments).

**R49 gate results:** check_modules **509/509** (262.5s); corpus **949/949**,
0 compilefail, 0 runfail (**1525.7s**, 8 workers, `-RetryFailed`); coverage
ratchet floors53 OK. `p_wave8_shapes.xi` stays red at its scalar-field
clause as the residual lock.

## R52 compiler update (2026-09-20) -- @pre residual closed; collect contracts restored

Compiler main `1fcb4855` (R52; debug build from `git archive`, binary
`%TEMP%\kilo\stdlib_ws\xiom_r52.exe`) includes R51 `c235b3fe` -- the `@pre`
walkers descend through Imply/Is so implication-wrapped clauses emit entry
snapshots -- and `a8bda203` (L4: `@pre` `.len()` receivers, range-shadowing
for-in). The callee-mutation residual is gone: `p_pre_capture_callee.xi` and
`p_wave8_shapes.xi` both compile and run exit 0, so the former is **moved to
`tools/probes/`** and wave-8 is now a live lock.

The strong size relations weakened by `81eba6f` were restored in
`collect/{list,queue,rbtree,tree,spatial,hash,intmap}`
(ll_pop_front/back, workqueue_pop, deque_pop_front/back,
rbtree_insert/remove, bst_remove, kdtree/quadtree/octree_insert,
lhmap_remove, int_map_remove, string_map_remove). `lfu` never had an `@pre`
size relation (nothing to restore) and `fenwick` kept its wave-14 relation
throughout. Targeted smoke families 20/20 on R52 (130.1s).

**R52 gate results:** check_modules **509/509** (243.6s); corpus **949/949**,
0 compilefail, 0 runfail (**1437.1s**, 8 workers, `-RetryFailed`); coverage
ratchet floors53 OK (global clauses 19.2%, pub-with-clause 18.9%); doc
ratchet doc_baseline4 OK; barename scan **0 hits / 509** (527.5s).

**Probe-corpus hygiene (open):** a full `-Corpus tools/probes` run is
157/175 on R52 -- 11 compilefail + 7 runfail, an IDENTICAL set on R49
(verified by re-running the 18 on R49: same names, same exit codes), so R52
introduces no probe regressions. The red files are historical debug/evidence
probes (`p_regex_dbg*`, `p_puny_parity`, `p_fnref`, `p_async_read_line_codegen`
0xC0000409, `p_generic_push`/`p_gp_b`/`p_gp_c` 0xC0000005, ...). The
documented Probes gate cannot be green while they sit in the corpus root;
curate them into `tools/known_failures/` or an evidence subdirectory next
session (the probe run is not wired into CI).

**CURATED 2026-09-21.** The 11 historical/evidence probes moved to
`tools/probes/evidence/` (justification table in its README: stale APIs,
superseded shapes, or deliberate parity evidence) and the 7 open findings to
`tools/known_failures/`: `p_hash_probe` (hasher-interface `Self` argument),
`p_async_read_line_codegen` (0xC0000409 at EOF), `p_generic_push`/`p_gp_b`/
`p_gp_c` (R7 generic-ctor push legs), `p_fnref` (function-value identity
needs a compiler ruling), and `q1_verify_all` (compiles with `--timeout 0`;
watchdog/perf, not correctness). The probes root is green after the move.

## R54 compiler update (2026-09-21) -- R49-4 fixed; single-param surface compiles

Compiler main `7837b194` (R54; debug build from `git archive`, local binary
`%TEMP%\kilo\stdlib_ws\xiom_r53.exe`) changes large fixed arrays to emit
memset + address access instead of the crashing aggregate zeroinit /
whole-array loads. `tools/known_failures/p_sweep_single_param.xi` compiles
and links in ~51s (previously a clang ISel `0xC0000005` on
`@__unsafe_block_77`, IR deterministic). The surface is promoted as a
runtime-guarded lock (`tools/probes/p_sweep_single_param.xi`: the calls sit
behind an `XIOM_SWEEP_RUN` env guard, so they type-check and codegen but
never run -- the generated arguments are unsafe to execute); the raw call
set and its crash header are archived in `tools/probes/evidence/`. A fresh
scan (`gen_call_probes.ps1 -MinParams 1 -MaxParams 1`) is 60 modules /
239 calls. The compiler lane also verified both nasm and no-nasm builds.

**R53/R54 gate results (stdlib tree after wave 17 + probe curation):**
check_modules **509/509** (845.2s under load); corpus **949/949**, 0
compilefail, 0 runfail (**1832.7s**, 8 workers, `-RetryFailed`); probe
corpus **159/159** (449.9s); coverage ratchet floors54 OK; doc ratchet
doc_baseline4 OK; barename scan **0 hits / 509** (819.9s).

## R58 compiler update (2026-09-21) -- R55-R58 batch; probe corpus 160/160

Compiler main `5bdffaad` (R58; debug build from `git archive`, binary
`%TEMP%\kilo\stdlib_ws\xiom_r58.exe`) carries R55 `8e618626` (module-scoped
generic factory type args), R56 `334ea254` (container-payload ABI for
Map/container elements: inline 32-byte Vec headers in slots), R57 `f2017fa0`
(aggregate payload unboxing in `?` for tuple-payload Results) and R58
`5bdffaad` (Str payload resolution for unwrap/unwrap_or on call receivers).
The compiler-lane leftovers L6-40, L5-40, L3-50 and L8-14 are RESOLVED
(e2e_m110-m113); no stdlib gate depended on them.

**Gate results on the stdlib tree:** check_modules **509/509** (943.2s under
load); corpus **949/949**, 0 compilefail, 0 runfail (2996.5s, 8 workers,
`-RetryFailed`); probe corpus **160/160** (348.3s); coverage ratchet floors54
OK; doc ratchet doc_baseline4 OK; barename **0 hits / 509** (585.3s).

**known_failures re-triage on R58 (9 files, compile+run):**
`q1_verify_all` is FIXED -- the 36-import graph now compiles inside the
default 300s watchdog (the R55-R58 batch also closed the watchdog class), so
it is promoted to `tools/probes/`. Still open and unchanged on R58:
`p_hash_probe`, `p_async_read_line_codegen` (0xC0000409 at EOF),
`p_generic_push`/`p_gp_b`/`p_gp_c` (generic-ctor push legs), `p_fnref`, plus
the two generated-tranche findings `p_result_tuple_vec_loop` and
`p_ref_tuple_mangle` -- identical error signatures to R54, so they are NOT
part of the L6-40/L5-40/L3-50/L8-14 set and need their own compiler-lane
fix. The refs generated tranche re-ran on R58: 110/112, the same two
failures. The struct generated tranche re-ran 121/123 (same two findings).

**Wave 18 (2026-09-21, on R58):** 38 clauses across `xiom.sort` /
`xiom.search`, pre-validated by `tools/probes/p_wave18_shapes.xi`
(cross-module predicate calls in postconditions, Option payload index
bounds, position bounds, tuple-return field bounds, Vec length sum/bound,
`@pre` length on `&mut Vec`, Str-parameter match-window bounds). sort
0% -> **31.9%**, search 0% -> **62.2%**, global 19.2% -> **19.8%**
pub-with-clause; `coverage_floors55.json` wired in the same commit
(`a3fe12a`). Post-wave gates: check_modules **509/509** (352.1s); corpus
**949/949**, 0 compilefail, 0 runfail (**1643.4s**); probe corpus
**161/161** (350.2s); floors55 ratchet OK; targeted sort/search smoke
families 9/9.

**Wave 19 (2026-09-21, on R58):** 37 clauses across `xiom.bits` (bit_get/
parity disjunctions, popcount/clz/ctz/bit_width/leading-ones/trailing-ones/
count_* 0..64 bounds, nibble 0..15, unpack byte-range tuples,
`bitfield_mask` implication, scan -1..63, rotate-carry flags, bitarray
counts), pre-validated by `tools/probes/p_wave19_shapes.xi`. bits
0% -> **36.6%**, global 19.8% -> **20.3%** pub-with-clause;
`coverage_floors56.json` wired in the same commit (`84b3407`). Post-wave
gates: check_modules **509/509** (260.9s); corpus **949/949**, 0 compilefail,
0 runfail (**1513.9s**); probe corpus **162/162** (343s); floors56 ratchet
OK; targeted bits smoke families 10/10.

## R61 compiler update (2026-09-22) -- all remaining findings closed; probe corpus 169/169

Compiler main `ff293f8e` (R61, with the R59/R60 `2aad5ecd` fixes and the
rulings `bc63df54`; binary `%TEMP%\kilo\stdlib_ws\xiom_r61.exe`):
- **R59/R60** fixed the two generated-tranche findings (match-slot leak into
  loop bodies; tuple element naming): `p_result_tuple_vec_loop` and
  `p_ref_tuple_mangle` now run green.
- **R61** fixed the R7 generic-constructor residual (e2e_m116):
  `p_generic_push`, `p_gp_b`, `p_gp_c` compile and run (`A=[42]`,
  `B=["tree"]`, `C=[9]`).
- **R61 rulings**: `p_hash_probe` is a loud unsupported-feature rejection
  (e2e_m117: interface-typed parameters erase to i64; aggregate arguments
  now `error[C001]` instead of silently returning a wrong value);
  `p_fnref` is a language-spec question (function-value identity);
  `p_async_read_line_codegen` was a stdlib fd/FILE* misuse, fixed in
  `xiom.async.io` (commit `71789f0`: `xiom_read`/`xiom_write` take over from
  the fd-as-FILE* casts in `async_read`, `async_write`, `async_read_line`
  and `async_read_until`).

`tools/known_failures/` holds **no open findings**; the six resolved probes
were promoted to `tools/probes/` and the two ruled ones archived in
`tools/probes/evidence/`. All generated tranches re-ran 100% on R61: refs
**112/112**, structs **123/123**, fns **123/123**.

**Wave 20 (2026-09-22, on R61):** 44 geom vector clauses pre-validated by
`tools/probes/p_wave20_shapes.xi` (component mirrors for Vec2/3/4,
dot/cross identities, norm/distance non-negativity, lerp mirrors, neg/abs,
min/max component bounds); geom 0% -> **10.6%**, global 20.3% -> **21.0%**
pub-with-clause; `coverage_floors57.json` wired in the same commit
(`385e1e4`).

**R61 gate results (final tree):** check_modules **509/509** (287.3s);
corpus **949/949**, 0 compilefail, 0 runfail (**2842.8s**); probe corpus
**169/169** (652s); barename **0 hits / 509** (1448.1s); floors57 ratchet
OK; doc ratchet OK; targeted geom smoke families 8/8; async smoke families
3/3.

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

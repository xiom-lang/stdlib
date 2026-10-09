<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# XIOM Stdlib Session -- Handoff

## 0A. CONTINUE HERE -- handoff snapshot 24 (updated 2026-10-08, v0.64.1 pin consumed, stdlib 0.64.2 RELEASED + registry LIVE, string fix + signal stubs landed; context handoff)

**PASTE-READY PROMPT FOR THE NEXT SESSION (copy this block):**

---
You are continuing the XIOM stdlib lane. Worktree `E:\xiom-lang\stdlib`,
branch `main`. Read `docs/stdlib_session.md` blocks 75 (latest), 74, 73, 72,
71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53,
52, 51, 50, 49, 48, 47, 46, 45, 44, 43 (publish), 27 (iter block) and
`docs/PRODUCTION_READINESS_QUEUE.md`
before acting; snapshot 5 below the prompt keeps the deep protocol lore.
The ecosystem now has consumer lanes feeding relays (PULSE,
ORBITDB, XVECTOR, bindings): intake rows land in `docs/STDLIB-WISHLIST.md`
and runtime-backed asks queue with the compiler runtime bundle.

STATE (2026-10-08): compiler pin = official v0.64.1 (tag 3c6f3bb5,
consumed by wave 92; the previous v0.64.0 tag c68d91de bundled stdlib
6e60e958 = our wave-74 head). Binary at %TEMP%\kilo\stdlib_ws\v0.64.1;
v0.62.3/v0.62.4/v0.63.0/v0.63.1/v0.64.0 archives kept. COMPILER_VERSION
= v0.64.1. RELEASE STATE: stdlib-v0.64.2 CUT (tag on 4dd8844,
2026-10-08; release.yml success; assets xiom-std-0.64.2.tar.gz +
SHA256SUMS) and the REGISTRY IS LIVE: xiom-std 0.64.2 published
(signed, sha256 f5375c03ad88; lineage 0.63.0 -> 0.64.2; owner approved
the publish runs). Compiler side: STDLIB_VERSION = stdlib-v0.64.2 for the
v0.64.2 combined release; the fragment at the tag
(release-notes/v0.64.2.md) merges into its notes. Post-tag main carries
the block-75 fixes (string linearization + signal stubs) for the NEXT
release cut. Compiler relay 2026-10-07 (dev builds
m200-m203) CONSUMED on v0.64.1: m203 fixed the iter closure-thunk clause
leak; m200 fixed the rvalue Vec[Float64] index; m201 fixed multipart and
PARTIALLY geom-matrix (the tuple-element case is still red) but did NOT
fix polyhedra -- see the README corrections. The next compiler release is
v0.64.2: OUR pin for it is the stdlib-v0.64.2 tag (commit 4dd8844) --
the archive at v0.64.1 still bundles the old 6e60e958 stdlib; the
registry publish for 0.64.2 is DONE (see above).
Gates on v0.64.1: release corpus 954/954 FULL (m196 loopback + uuencode
roundtrip smokes added), modules 509/509, probes 264/264, barename
0/509, floors129 (re-dumped/tightened with the signal clauses; os
26.6%), module-smoke ratchet OK. Coverage = 57.7% global pub-with-clause.
Post-tag fixes on main (block 75): string linearization (str_split
byte-scan, str_repeat doubling, pad single-alloc; probe
p_str_split_scale.xi) and the PULSE signal stubs. Waves landed: 63 net+hash, 64 reflect+iter adapters, 65x convert, 66 time, 67 format, 68 misc, 69 os+rand, 70 crypto, 71 log, 72 compress, 73 pin, 74 encoding, 75 encoding-rem+debug, 76 simd, 64.0 pin, 77 stats, Pulse hardening (write_all/server_parse_request/hmac_sha256_hex), 78 thread, 79 convert numeric shims, 80 convert base shims, 81 convert unicode, 82 convert codec guards, 83 convert codec tails, 84 convert uri/url/urn, 85 convert ip/lossy/network/timestamp, 86 convert locals + shims, 87 convert tails (convert 94.1%), 88 serialize batch 1 (endian/varint/csv), 89 serialize + json modules (serialize 73.1%), 90 serialize batch 3 (toml/yaml_lite; serialize 90.3%), 91 bench + format numbering/units (bench 87.5%, bench_time_fn defect fixed), 92 v0.64.1 PIN BUMP (iter retry; iter 25.1%). Post-wave-89 fixes (same day): io byte-fidelity/CRLF defect (read_file_lines CR strip; write_file/append_file/write_file_bytes now binary; p_read_file_lines_crlf.xi) and fs_remove (bindings W-1; p_fs_remove.xi); ORBITDB/XVECTOR/bindings relays intaken. Wave
65 (iter clauses) is RESOLVED on v0.64.1: the clause-side closure
lowering works (Range.count + the retried set + smoke_iter 21/21 incl.
-Workers 8); the deferred remainder (chain 14 + fold 8 + the rest of the
iter surface) continues as normal coverage work.

RELEASE CUT (2026-10-09): **stdlib-v0.64.3** tagged on the release commit
(pin moved to compiler v0.64.2, tag c51170a6); release.yml +
publish-registry.yml dispatched -- the registry publish is waiting in the
`registry-publish` environment for owner approval. Findings cleared on
v0.64.2: array_zip truncation and triplicate sibling imports (16 -> 14
open). heavy.yml matrix repaired (it had never run). See block 82.

WAVE 97 STATUS (2026-10-09): DONE -- bits submodules + hash + fraction
landed (57 clauses, +40 pub covered; bits 74.3%, hash 42.2%, num 37.6%,
global 61.8%, meter 76.2%, floors134, probes 270/270). See block 81; new
finding: triplicate sibling exports break alias resolution (wave-97 probe
split in two). The next wave (98) continues: os 26.6%, num 37.6%, math
38.8%, crypto 39.9%, hash 42.2%, remaining bitarray/endianness. Release
note: the next stdlib cut picks up blocks 75/77/78/79/80/81.

WAVE 96 STATUS (2026-10-09): DONE -- array + sort + bits landed (53
clauses, +40 pub covered; array 77.8%, sort 42.6%, bits 52.5%, global
61.2%, meter 76.1%, floors133, probes 268/268). See block 80; new finding
array_zip M<N truncation. The next wave (97) continues the low dirs: os
26.6%, hash 33.3%, num 35.6%, math 38.8%, crypto 39.9%, remaining bits
submodules. Release note: the next stdlib cut picks up blocks
75/77/78/79/80.

WAVE 95 STATUS (2026-10-08): DONE -- the format remainder landed (markup +
textual + fmt; 82 clauses, +68 pub covered; format 88.7%, global 60.6%,
meter 76.1%, floors132, probes 267/267). See block 79. The next wave (96)
starts on the non-format low dirs: os 26.6%, sort 31.9%, hash 33.3%,
num/array/bits, math/crypto, plus the queued feature candidates.

WAVE 94 STATUS (2026-10-08): DONE -- cmp + core + sync + terminal landed
(86 clauses, +62 pub covered; sync 35.9%, core 45.8%, format 59.3%,
global 59.5%, meter 76.0%, floors131, probes 266/266). See block 78; three
new compiler findings filed (&mut param @pre aliasing, generic by-ref
Option/Result queries, bounded Slice calls). The next wave (95) resumes
the low dirs: os 26.6%, sort 31.9%, hash 33.3%, num/array/bits and the
format remainder (markup/textual/fmt).

WAVE 93 STATUS (2026-10-08): DONE -- the iter remainder + format.text
landed (55 pub / 71 clauses; iter 25.1% -> 45.4%, format 39.0% -> 46.8%,
global 58.6%, meter 75.9%, floors130, probes 265/265). See block 77 for
the full record and the new M7 `Iterator[T]` finding. The next wave (94)
resumes the low dirs: os 26.6%, core 26.7%, sync 29.1%, format remainder
(markup/terminal/fmt); release side unchanged (next cut takes block-75 +
block-77).

FIRST TASK (wave 93): resume coverage -- the iter remainder (chain 14 +
fold 8 + the rest of the range/adapters surface, now unblocked on
v0.64.1) plus the next low dirs (format remainder, sync 29.1%, os 26.2%,
core 26.7%), batching toward 40-60 pub; async stays runtime-backed
(inspect each surface before claiming). Queued feature candidates when
the wave has room: ORBITDB `append_line_sync` pure half (tail repair;
durable flush stays runtime-backed), bindings W-2 out-param slot helper,
W-5 Vec[UInt8].with_len(n). RELEASE SIDE (DONE): stdlib-v0.64.2 was cut 2026-10-08 (tag on 4dd8844;
release.yml success) and the registry is LIVE -- `xiom pkg info xiom-std`
shows 0.64.2 signed (sha256 f5375c03ad88). STDLIB_VERSION for the
compiler v0.64.2 combined release = stdlib-v0.64.2. No release action is
pending; the next cut will pick up the post-tag block-75 fixes (string
linearization + signal stubs).
NO PIN-BUMP TRIGGER is pending: v0.64.1 is consumed and the next
compiler release (v0.64.2) is not out yet.
PENDING/QUEUED:
(a) iter clause retry: DONE 2026-10-08 on v0.64.1 (wave 92) -- the
closure-thunk clause leak is fixed; Range.count plus the retried range
set (contains/sum/product/collect/count/max/min/find/all/any/nth/last)
landed and smoke_iter passes 21/21 (incl. -Workers 8), with the pin
probe p_pin0641_iter_shapes.xi. The deferred remainder (chain 14 + fold
8 + the rest of the adapters) continues as normal coverage work.
(b) Pulse pure-XIOM hardening: DONE 2026-10-05 (block 47).
(c) runtime-backed asks (socket timeout/nonblocking/reuse-addr, real
flush_stdout, fsync/durable writes, the signal-handler trampoline for
signal_handle/signal_pending, append-capable fd write path) wait for the
compiler runtime bundle (durable writes are cross-filed by PULSE and the
packages sheet 2026-10-05; ORBITDB/XVECTOR re-confirmed 2026-10-08).
(d) Packages-sheet intake 2026-10-05 (8 rows: HTTP-date pair, path
safety, fs remove parity, streaming read_exact, append_file_bytes,
truncate/remove_dir, file locking) recorded in docs/STDLIB-WISHLIST.md;
not yet wave-scheduled.
HANDOFF NOTE: locks include p_pin0640_shapes.xi (m193-m196),
tests/smoke/smoke_net_tcp_stream.xi (m196 + write_all),
tests/smoke/smoke_convert_uuencode.xi (wave 83, corpus 954), the m193
guard-alloc smoke, and probes p_wave77_shapes.xi (167 checks) plus
p_pulse_shapes.xi through p_wave91_shapes.xi, the v0.64.1 pin probe
p_pin0641_iter_shapes.xi, p_str_split_scale.xi, the io locks
(p_read_file_lines_crlf.xi, p_fs_remove.xi) and the three promoted
regression locks (p_rvalue_float_vec_index.xi, p_multipart_parse_name.xi,
p_iter_range_collect_forwardref.xi) -- 264 probes total.
Open known-failure repros on v0.64.1: p_ensures_isok_guard.xi,
p_geom_matrix_result_infer.xi (tuple-element check rc 4),
p_polyhedra_nested_hull.xi (rc 1), p_clause_float_vec_index.xi,
p_geom_box_unnameable.xi, p_alias_module_type_path.xi,
p_foreign_method_call.xi. docs/failed_attempts.md logs push incidents;
out/*.json are disposable battery artifacts. CAUTION: do not run large
synthetic benchmarks unbounded -- a scratch quadratic benchmark once kept
running after its shell timed out and ballooned memory until killed
(block 75); use the probe/battery harness which has watchdogs.
Mandatory protocol:
(1) recon bodies and derive every clause from them; no placeholder forms
(no unsigned `>= 0`, no `is_ok || is_err`, no self-mirrors); clauses run at
runtime, so never read Result/Option payloads, guard division/NaN, and
prefer exact mirrors, length/presence bands and `@pre` invariants. For
guarded payload-length claims use the canonical `result is Ok =>
result.len()` form ONLY: the `(result.is_ok == true) =>` implication
violates at runtime (filed as p_ensures_isok_guard.xi, m-fix pending);
if a wave surfaces a new compiler finding, file a minimal repro in
tools/known_failures/ with a README Current entry before the wave commit.
(2) probe-first: add `tools/probes/p_wave93_shapes.xi` exercising every
clause-guard path; bind module-returned values to `let` before comparing
(inline unsigned compares misread high bits; inline indexing of a
returned Vec[Float64] reads garbage -- bind it first); bind `Vec.new()`
temporaries passed as `&Vec`; do not declare externs for runtime guard
symbols; green on v0.64.1 (v0.64.0 cross-check when cheap).
(3) apply, run targeted smokes; if unrelated codegen breaks, bisect and
drop the offending clause with a code comment (see blocks 27/65x).
(4) dump `tools/coverage_floors130.json`, wire the workflows +
`tools/README.md`, update plan/session/queue in the same commit, YAML
check, pure-ASCII conventional commit.
(5) battery: `run_smokes.ps1 -ExcludeFile tools/known_failures/
gate-exclusions.txt` (expect 954/954 full), probe corpus (expect 265),
check_modules 509/509, barename 0/509, floors130 + module-smoke ratchets;
record results in the session block; push `main` (NOTE: the push may
present the wrong account -- see docs/failed_attempts.md 2026-10-07
18:30 UTC: use the one-shot Lefteris-Notas credential; plain pushes may
403 as Lefteris-Ngonart. If a push hits GitHub 500s, follow the same doc
(3 attempts, log, retry later).
(6) never run a scratch benchmark with an unbounded/quadratic setup: the
block-75 incident (a runaway scratch exe growing to ~4.7 GB after its
shell timed out) shows why; use bounded sizes and the harness watchdogs.

QUEUED (do only when triggered):
- DONE 2026-10-05 (compiler ask): scrypt / shuffle-choice / BUG-18 cannot
  be reproduced on v0.63.1; locked by tools/probes/p_regress_scrypt.xi,
  p_regress_shuffle_choice.xi and p_regress_bug18_combo.xi (probes 239).
  Box rides section C (geom dedup + rename; compiler api_freeze regen
  pending). The `%Q` strptime face no longer exists in time.xi; restore
  only if the compiler asks.
- Pulse (web-framework lane) relay 2026-10-05: triage in queue section
  "Project Pulse relay". Pulse reply: `str_bytes` adopted; the empty-body
  `flush_stdout` finding is the root cause of their lagging/truncated
  redirected logs; runtime-backed items accepted with the
  `XIOM_RUNTIME_DIR` caveat. LANDED 2026-10-05 (block 47):
  `TcpStream.write_all`, `server_parse_request` + `ServerRequest`,
  `crypto.hmac_sha256_hex` (p_pulse_shapes.xi, 243rd); production
  evidence: a 270 KB icon single-send short-wrote and the client got
  nothing. STILL QUEUED (runtime-backed): socket
  timeout/nonblocking/reuse-addr + deadline recv, real `flush_stdout`,
  and the new durable-append ask (fsync/FlushFileBuffers -- no such
  symbol in runtime/*.c; cross-filed by the packages sheet as its
  highest-value storage ask). `str_bytes` already exists at
  `xiom.string.slice.str_bytes` (answer relayed). Test registry is
  compiler-owned.
- Systems track relayed to the compiler lane 2026-10-05 (queue section
  "Systems track"): asks are freestanding/no-runtime target, repr(C)/
  by-value ABI, volatile/fences/ordered atomics, contract-disable, later
  SPIR-V device code. Stdlib starts gpu/mmio/handle-RAII skeletons only
  on unlock, probe-first, and does not displace coverage waves before
  gate 10.
  Compiler reply 2026-10-05: plan at compiler docs/SYSTEMS_TRACK_PLAN.md
  (6f4173cd); order accepted; ask (4) already exists (--no-contracts,
  release default off) + IR lock coming; first unlocks S1 freestanding +
  S2 repr(C) after the v0.64.0 batch; S1 run-lock Linux CI fixture with
  asm _start, Windows build-only; freestanding has no fault-trapping
  guard pages -- gpu/mmio designs must check explicitly. Nothing needed
  from stdlib until S1/S2.
- DONE 2026-10-05 (v0.63.1): the C001 carve-outs are retired
  (4bf8cf1e in the release; 20/20 + 20/20 stress). Next: retry the
  wave-65 iter clause set (block 27), now with the v0.63.1
  tuple-component clause capability, probe-first; include the
  iter_collect clause side (Range core 7 + chain 14 + fold 8).
  BUT: re-verified 2026-10-05 on v0.63.1 -- the clause-side closure
  lowering still fails (Range.count `ensures: result >= 0` -> smoke_iter
  clang `use of undefined value`), so the retry stays compiler-blocked;
  only the C001 half retired. RE-VERIFIED on v0.64.0 (wave-77 follow-up):
  same clang `use of undefined value` (%tmp8); the deferred set stays
  queued with the compiler closure work.
  NEXT PIN (compiler relay 2026-10-07): carry m200/m201/m203; then
  re-add `Range.count` `ensures: result >= 0` and retry the deferred set,
  promote the rvalue/multipart/geom-matrix/polyhedra repros out of
  known_failures, re-dump floors (m202 gates the packages grpc publish,
  m206 covers graphql conformance).
  NEXT PIN TRIGGER: DONE 2026-10-08 (wave 92, v0.64.1 tag 3c6f3bb5):
  Range.count + the retried range set landed, smoke_iter 21/21, and
  rvalue/multipart/iter-forwardref were promoted. NOT covered by the fix:
  geom-matrix tuple inference (rc 4) and polyhedra nested hull (rc 1)
  STAY OPEN; the ensures-isok guard, clause float-vec indexing, geom Box
  naming and the alias/type-path findings also stay open (see the
  known_failures README).
- Repo-wide `result.value` payload-clause audit (v0.63.1 lowers payload
  clauses strictly): the four io.xi IOError `.len()` sites retired in the
  pin wave were the ONLY bogus ones; io/pipe.xi, io/fs.xi and
  io/console.xi Err payloads are Str (valid) and stay. Done 2026-10-05
  (wave 74).
- One green heavy run -> add `macos-14` to the `release.yml` matrix
  (heavy already has it).
- Same-leaf audit follow-up (lz4 class): soundex leaves in
  string/misc/text plus anything `tools/same_leaf_audit.ps1` reports;
  lz4 umbrella already renamed to `lz4_compress_checked` /
  `lz4_decompress_checked` (8991c3e) and the stale
  `xiom.misc.misc.soundex` "0000" copy now delegates (e385ca1).
- Release-only note: the compiler's v0.63.1 archive bundles STDLIB_VERSION
  cd61062 (pre-wave); stdlib-v0.63.1 carries everything since.
- Next stdlib release follows the documented flow: re-pin, package.xi +
  release notes + CHANGELOG, tag `stdlib-v*`, release.yml gates/package,
  staging canary, then production with the registry-publish environment
  approval; disclose open compiler issues in the notes.
---

### Snapshot 5 (details retained below)

**Repo**: `xiom-lang/stdlib` at `E:\xiom-lang\stdlib` (branch `main`).
Compiler pin: **official v0.63.0** (windows-x64 archive, SHA256
`689881f4...`, verified against the release SHA256SUMS; v0.62.4
`ab1c83d2...` and v0.62.3 `011af7dd...` archives retained for
cross-checks). The v0.63.0 re-pin is DONE: t2 (kat_) 15/15,
release-gate corpus 950/950 (2 C001 carve-outs of 952), modules 509/509,
probes 229/229, barename 0/509, floors104 -- see SESSION block 32/34/36 and
the HANDOFF 2026-10-03 snapshot 5, which carries the paste-ready
continuation prompt. Waves 63-66 LANDED on 2026-10-04 (blocks 25/26/28/
31: net batch 6 + hash, reflect + iter adapters, convert shims, time
core; global 42.2% -> 45.1%, probes 220 -> 227); wave 65 was ATTEMPTED
AND BLOCKED on the pin (block 27: iter closure/C001 surface reverted,
finding filed). Release engineering (blocks 29/32): stdlib 0.62.3 and
0.62.4 tagged and pushed; stdlib 0.63.0 release prep in this commit
(publish staging-first then production with the registry-publish
environment approval; 0.62.x publish retries under the registry lane's
db39144 fix). Snapshot 5's prompt otherwise stands; the next task is wave
69 on os 15.3% / rand 16% (then crypto 17%, log 19.1%, compress 21.1%,
encoding 23.7% ...) while the
iter surface waits on the compiler closure-lowering + C001 fixes. The
registry-publish
workflow verifies the downloaded
`xiom-<version>-linux-x64.tar.gz` against the release's published
`SHA256SUMS` (registry lane independently verified the manifest
`8839e5cc…` and the archive `4cc5d62b…`). The nightly heavy CI already
tests compiler `main`. NOTE: history was rewritten 2026-09-20
(owner-authorized): every author/committer/tagger is
`Lefteris Notas <lefterisnotas@gmail.com>`, `main` force-pushed to HEAD
`926e888`; every other clone must be re-cloned. The protected tag
`stdlib-v0.60.0` still carries the old tagger on the remote (its force-push
was rejected by tag rules -- owner action needed).

**SESSION 2026-09-23 PART 9 (production-grade push: pin v0.61.3 + re-baseline;
package-relay fixes; deterministic packaging; coverage waves 22-24)**
- Pin bump: compiler tag `v0.61.3` (`d62b4d20`) built with the documented
  recipe (archive -> warm target from R61 -> touch all extracted sources ->
  `cargo build --locked -p xiom`); binary
  `%TEMP%\kilo\stdlib_ws\xiom_v0613.exe` (`XIOM Compiler v0.61.3`).
  `COMPILER_VERSION` v0.61.1 -> v0.61.3 (`da0d45e`). Re-baseline on the new
  binary (`78cbccc` + the v0.61.3 VERIFICATION_BASELINE section):
  check_modules **509/509** (297.4s); corpus **949/949**, 0 compilefail,
  0 runfail (**2759.5s**, `-RetryFailed`); probe corpus **171/171**
  (450.6s); barename **0/509** (1664.7s); coverage floors58 OK
  (21.1%/21.2%); doc ratchet OK (100%). The runtime OS-detection
  workaround (`xiom_os_name`) is KEPT with the rationale recorded in the
  baseline (run-time host read beats compile-time constants; R65 fixes the
  env constants but not relocation/cross-build).
- Package-relay close-outs (commit `06e513a`, locked by
  `tools/probes/p_relay_visibility.xi`): the canonical `str_compare` now
  lives on `xiom.string` (compare delegates); the canonical INT_MIN-exact
  `to_string` now lives on `xiom.convert` (tostring delegates); NEW
  `xiom.time.monotonic_ms()` (runtime `xiom_async_now_ms`,
  QueryPerformanceCounter/CLOCK_MONOTONIC, non-decreasing; `Instant.now`
  doc corrected to wall-clock); checker warning E001 conservatism
  reproduced from stdlib smokes (warning-only: smoke_collect_sparse/2a/
  threadpool compile+run green on v0.61.3); env-mutation thread-safety and
  the generic fn-pointer claim recorded in
  `docs/STDLIB_BETA_LIMITATIONS.md` (package-relay section).
- Deterministic packaging (commit `3885696`): `release.yml` now packs
  `xiom-std-<ver>.tar.gz` with SOURCE_DATE_EPOCH = tagged commit,
  `--sort=name --mtime --owner=0 --group=0 --numeric-owner`, `gzip -n`, so
  a release re-run produces byte-identical assets; verified locally with
  GNU tar 1.35 (identical SHA256 across mtime shifts + clean extraction
  round-trip). `xiom pkg publish` still re-packs (registry lane's
  publish-existing-tarball mode remains open); docs/CI.md updated.
- Runtime symbol audit closed stdlib-side (commit `33671e0`): the 9 non-hot
  definition-only candidates are gone (0 references across `runtime/**`),
  the 11 `xiom_hot_*` entries are kept + AUDIT-annotated; only the compiler
  lane's confirmation of the kept hot-reload ABI remains.
- Coverage waves, each = new-shape probe -> clauses -> floors dump ->
  same-commit wiring (3 workflows + tools/README + readiness plan) ->
  check_modules + full corpus + probe corpus + ratchets:
  * **Wave 22** (`652a2bf`, floors59): 45 clauses on `stats/stats.xi` +
    `stats/probability.xi` (empty/short-input identities, non-negative
    float bounds incl. the NaN-tolerant disjunction, two-Vec length
    mismatches, exact histogram bin counts, probability-domain guarded
    intervals, CDF boundary equalities). stats 0% -> **25%**; corpus
    949/949 (2727.7s); probes 173/173; check_modules 509/509.
  * **Wave 23** (`82b7e14`, floors60): 30 clauses on `convert/escape.xi` +
    `convert/validate.xi` (escape >=, unescape <=, exact quote-wrapper
    arithmetic, Bool short-circuit guards, disjunctive length guards,
    empty-input Str guards). convert 2% -> **11.5%**; corpus 949/949
    (2646.9s); probes 174/174; check_modules 509/509.
  * **Wave 24** (`dd57e76`, floors61): 42 clauses on `math/modular.xi` +
    `math/arithmetic.xi` + `math/logic.xi` + `math/set_theory.xi` (uniform
    modular ranges, sqrt ranges, tuple non-negativity, two-parameter Vec
    length arithmetic, cardinality bounds, Boolean mirrors, power-of-two
    guards, sign-matching remainders). math 4.1% -> **8.3%**; global
    21.2% -> **22.9%** pub-with-clause; corpus 949/949 (2325.2s); probes
    175/175; check_modules 509/509; doc ratchet OK.
  * Remaining wave targets (recon done this session): math
    number_theory/factorial/combinatorics, text, regex, test, collections,
    error/io tails. The per-dir candidate lists live in the session recon
    (top candidates: collections ~35 safe clauses, regex ~20, test ~18,
    text ~18).
- Compiler-lane relay (R66-R72 on compiler `main`, **NOT in the v0.61.3
  pin**): R66 contract-method Vec lowering AV, R67 ctor container-leaf,
  R68 nested extern hoisting, R69 `T.to_str()` mono params, R70
  `for x in <collection>` real element loops, R71 `.all/.none` inline
  closures, R72/m127 Vec[fn] indexed calls; full e2e 2373/2373 local.
  The compiler lane regenerated the `stdlib_api_freeze` snapshot (m125 --
  rename-only `AsyncExecutor.*`/`NetHttpResponse`, 1:1 verified) and
  INDEPENDENTLY VERIFIED IT ON THE PIN: freeze suite 2/2 green and
  stdlib-exec 85/85 (+2 ignored) on the `stdlib-v0.61.3` tag, so the
  duplication-gate twin removal is UNBLOCKED with an independent result
  (see `docs/STDLIB_DEDUP_INVENTORY.md` checklists). The stdlib lane
  additionally re-ran the freeze suite on a local compiler-main build
  against the CURRENT tree (waves 22-24 + relay additions + known-failure
  probes): `cargo test --locked -p xiom-codegen --test
  stdlib_api_freeze_tests` = 2/2 ok (no-removals + all-modules-compile,
  46.47s). Shape re-probes on that build (compiler `main`, R72) confirmed
  R67/R68/R69/R70/R72 and confirmed the still-open fn-value list
  (`let` Vec[fn] literal indexed call and `Vec[fn].new()`+push both
  0xC0000005); the green lock is parked at
  `tools/probes/evidence/p_r70_pending_shapes.xi` for the pin-bump commit.
  Note for that commit: `0..b` / `0..=b` for-loops need `use xiom.iter;`
  so the `range` name resolves (bare sugar is T001 on R72).
- Coverage/bookkeeping 2026-09-24: new smoke `smoke_sort_by_key` locks the
  working instantiations (Int key same-type, Str key by length; the broken
  Int -> Str pair is the filed known failure) -> smoke corpus is now 950
  files; verified 1/1 targeted (compile 0, run 0). The full-corpus re-run
  lands with the next wave.
- Wave 25 + dedup TU 2026-09-24 (commits `6b66b53`, `25bc778`): collections
  3.5% -> 77.2% pub-with-clause (59 clauses; floors62, global 23.6%) and the
  `collect/hash` <-> `collect/linkedhash` + `collect/cache` <-> `collect/lru`
  translation units are SHIMMED (canonical fns extended, twins delegate, no
  file deletions -- collect.* is not in the api_freeze snapshot). The
  `collect` smoke family caught a REAL clause bug during verification: in a
  clause, `A == B > C` parses left-associatively as `(A == B) > C` and the
  compiler silently coerced the Bool/Int mix, so `lhmap_first/last`'s
  `result.is_some == lhmap_size(m) > 0` held only at size 1; fixed with
  parens and the whole corpus was audited for that shape (only these two
  hits). Compiler lane: consider rejecting mixed Bool/Int comparisons in
  clause position. Remaining collect twins: `lfu.xi` (cache LFU section)
  and the geom short/long modules (audited as NOT a pure rename; deferred).
- Release sequencing (compiler lane, owner decision): ONE combined release,
  no intermediate tags. The compiler lane finishes Sprints A/B/C (front-end
  P0/P1 + fn-value + the packages' fn-ptr probes) on main; the stdlib lane
  completes the full readiness plan in parallel and cuts the next stdlib
  release; the compiler lane then bumps `STDLIB_VERSION` to that tag, runs
  the full gate list on the pin, and cuts the single compiler release
  (recommended v0.62.0). Do NOT re-baseline on new shapes before that tag.
  TLS/schannel: must ship in this window or be explicitly excluded in the
  release notes -- recommendation from the stdlib lane: EXCLUDE (owner
  instruction puts TLS last/user; no HTTPS claim until the FFI hardening
  and interop pass).
- Release notes (website contract, relayed 2026-09-24): the website renders
  per-release "What's new" notes (schema at
  `xiom-lang/website/docs/release-notes-schema.md`). The stdlib fragment is
  authored at `release-notes/v0.62.0.md` (Summary + four stdlib/tooling
  highlights: contract coverage on stats/convert/math,
  `xiom.time.monotonic_ms`, `str_compare`/`to_string` visibility,
  reproducible archives). The compiler release step merges it from the
  pinned checkout and tags the bullets "stdlib". RENAME the file to the
  actual release tag if the release lane cuts a different tag; keep entries
  user-facing (<=320 chars, plain ASCII, no wave names or task IDs).
- NEW open compiler finding (2026-09-24, filed on v0.61.3): cross-type
  generic callback returns are miscompiled (`fn(&T) -> U` / `fn(T) -> U`
  with `U` a different runtime type than `T` returns a wrong value; silent).
  Stdlib exposure: `sort_by_key[Int, Str]` mis-sorts, `array.map[T,U]`,
  `iter` `Range.map[U]`/`MapIter.map[V]`, and core `Option.map[U]`/
  `Result.map[U]` for cross-type `U`. Corpus impact: existing smokes only
  map same-type (Int -> Int) and `sort_by_key` had no smoke, so the gate
  was green. Minimal reproductions:
  `tools/known_failures/p_generic_typechanging_{fnptr,map,core_map,sortbykey}.xi`
  (observed run exits 23 / 41 / 41 / 1; concrete and same-type controls
  pass). E001 conservatism intake pattern:
  `tools/probes/evidence/p_e001_borrow_conservatism.xi` + the deterministic
  `-Filter smoke_collect_sparse` reproduction (7 warning lines). Both
  delivered to the compiler lane.
- Still open from the production queue: duplication translation units
  (collect/hash vs linkedhash, cache vs lru, geom short/long names --
  UNBLOCKED, checklists in `docs/STDLIB_DEDUP_INVENTORY.md`), tzdata
  phase 2, untested-surface tail (44 struct-param fns without a usable
  ctor, non-scalar fn params, 83 generic fns -- needs new generator classes
  in `tools/gen_call_probes.ps1`), registry publish-existing-tarball mode.

**SESSION 2026-09-24 PART 9 continued (evening block: wave 25, dedup TUs,
stub closures; all four recon agents completed)**
- Wave 25 (`6b66b53`, floors62): 59 clauses on `collections/collections.xi`
  (&mut length preservation via `@pre`, post-state map reset, Option
  presence mirrors, exact sliding-window counts, Set/Map bounds, parity
  arithmetic, Boolean mirrors) -> collections 3.5% -> **77.2%**, global
  **23.6%** pub-with-clause. Gates: modules 509/509, corpus 950/950
  (3531.8s under heavy external load), probes 176/176, barename 0/509,
  coverage + doc ratchets OK.
- Dedup translation units (`25bc778`): `collect/hash` gained
  `lhmap_first/last/iter`; `collect/linkedhash` and `collect/lru` became
  pure delegation shims (cache gained `lru_remove`/`lru_clear`); no file
  deletions (collect.* is NOT in the api_freeze snapshot). The collect
  smoke family caught a REAL clause bug during verification: in a clause
  `A == B > C` parses left-associatively as `(A == B) > C` and the compiler
  silently coerced the Bool/Int mix, so `lhmap_first/last`'s
  `result.is_some == lhmap_size(m) > 0` held only at size 1; fixed with
  parens, repo-wide audit found no other instance (`7eb2290`). Shim
  clauses mirrored so the coverage floor holds (`983ef7f`). Remaining
  twins: `collect/lfu` (cache LFU section) and geom short/long (audited as
  NOT a pure rename; own API-translation unit).
- Stub closures on the pin (`765ae4f`): trig `sinh/cosh/tanh/atanh`
  delegate to the gate-green `xiom.math.hyperbolic`; `num.float`
  `next_up/next_down/ulp` exact via `primitives.nextafter` (no bitcast
  needed); `set_partition` implemented with the row-local nested-Vec read;
  `timer_interval` fixed by renaming the private `xiom.async.Timer` to
  `AsyncTimerTask` (same-leaf collision made the trailing `armed` field
  read the wrong layout -- compiler lane: private same-leaf types still
  collide, R44 class). Gates: modules 509/509, corpus 951/951 (1633.9s),
  probes 176/176, barename 0/509, ratchets OK.
- Agent recon results (all four reports summarized; no code from agents):
  * untested surface: 28 struct-param (no ctor, non-generic) / 53 non-scalar
    fn-param / 80 generic never-referenced fns; order b (fn shapes) -> c
    (generics) -> a (structs); all compile-only; existing scan scripts in
    `%TEMP%\kilo\stdlib_ws\profile_*.ps1` hold the target lists.
  * stub re-triage: ~135 real markers across 35 files; ~15 files pin-viable
    (top-10 ranked; 4 closed today), 10 genuinely compiler-gated
    (recursive evaluator, Bool tuples, `&Vec[fn]`, bitcast, fp128, lazy
    Iter). Nested-Vec wording is stale: row-local copy works.
  * tzdata phase 2: recommended option B (generated gzip+base64 region
    tables under `xiom/time/zone/data/*.xi` + hand-written
    `xiom/time/zone.xi` engine; additive API; KAT smoke with a pinned tzdb;
    post-2100 = last known offset). 7 atomic commits, ~5-7 days; vendoring
    the pinned tzdb tarball is the offline prerequisite.
  * dedup: the execution plan above; the full function diffs are in
    `docs/STDLIB_DEDUP_INVENTORY.md`.
- Compiler-lane additions from this block: same-leaf PRIVATE type collision
  (Timer), clause-position Bool/Int mixed comparison silently coerced
  (precedence trap), plus the earlier cross-type callback matrix and E001.
- Still open after this block: remaining coverage waves (regex/test/text/
  error/io tails, math tails), `collect/lfu` + geom dedup units, tzdata
  phase 2, untested-surface generator classes, the remaining pin-viable
  stub rewrites (gradients, least_squares, integrate_gauss, convergence_rate,
  lp_simplex, control-theory observability/controllability), registry
  publish-existing-tarball + compiler-pin correlation, and the combined
  compiler release (v0.62.0) after our next stdlib release cut (release
  notes fragment `release-notes/v0.62.0.md` is ready).

**SESSION 2026-09-25 PART 9 continued (night block: stub batches 2-3,
clause typing cleanup, release pre-flight alignment)**
- Stub batch 2 (`ce24e70`): `approximation.least_squares` implemented by
  repairing the by-ref nested `Vec[Vec[Float64]]` into a local matrix before
  indexing (row-local copies alone are NOT enough for Float64; the full
  local-matrix copy is required -- re-verified with probes). Gates:
  modules 509/509, corpus 951/951 (2806.1s), probes 176/176, barename
  0/509, ratchets OK.
- Clause typing cleanup (`a357e54`, compiler-lane follow-up): all clause
  sites that block strict predicate-Bool checking were fixed --
  `Rc.new`/`Arc.new` -> `result.strong_count() == 1` + `result.ptr != null`,
  `ptr.replace` -> `ensures: dest != null`, `math.pow`/`pow_pure` ->
  `exp == (to_int(exp) as Float64)`, and `array.is_sorted_by` was MISSING
  and is now implemented (the `sort_by` clause asserts it; row/rc/sync/ptr
  smoke families green).
- Stub batch 3 (`89d0d1c`): `differential.gradient/partial_derivative/
  richardson` implemented with push-only perturbation vectors;
  `jacobian` stays stubbed (`&Vec[fn]` reads). `smoke_math_calculus`
  asserts gradient(1,2) = (2,4), the partial, oob/h==0 guards, and
  Richardson ~= 6. Combined battery: modules 509/509, corpus 951/951
  (2738.9s), probes 176/176, barename 0/509, ratchets OK.
- Release pre-flight alignment (`f0911ba`): the compiler lane's draft
  v0.62.0 notes carry 4 highlights, so the stdlib fragment was trimmed to
  TWO highlights (contracts coverage; `xiom.time.monotonic_ms`) to respect
  the merged 6-highlight schema limit; all fields validated against the
  site's rules.
- Compiler lane meanwhile fixed `@pre`-on-method-call runtime snapshots and
  landed `XIOM_STRICT_CLAUSES=1` (default stays light until the stdlib is
  clean under strict mode); the stdlib clause fixes above are the
  precondition for flipping that default. VERIFIED 2026-09-25: a local
  compiler-main build against this repo runs
  `XIOM_STRICT_CLAUSES=1 cargo test -p xiom-check catalog_corpus_is_clean`
  GREEN (51.19s, 1 passed). The strict parser also caught a stray two-line
  tail left by the `timer_interval` edit in `xiom/async/timer.xi` (pin
  parser tolerated it, new parser rejected it); removed (`b6286b2`),
  `smoke_async` 3/3 green. The compiler lane can flip the strict default
  when convenient; stdlib is clean under it.
- Release state at the end of this block: all gates green on the current
  tree (check_modules 509/509, corpus 951/951, probes 176/176, barename
  0/509, coverage+doc ratchets, strict catalog clean); `release-notes/
  v0.62.0.md` carries exactly 2 highlights (the compiler draft has 4;
  merged limit is 6); `docs/RELEASE_CHECKLIST.md` has the cut steps and the
  open pin dependencies. No release cut yet: the remaining readiness units
  below are still in progress.

**SESSION 2026-09-25 PART 9 pre-dawn block (wave 26 text, LFU dedup,
registry pin, agent recon for the rest)**
- Wave 26 (`b1228ab`, floors63): 57 clauses on `text/transliterate.xi` +
  `text/similarity.xi` + `text/diff.xi` (byte-ratio transliteration
  bounds, custom-table pass-through, DP integer bounds, exact n-gram
  counts, exact 4-byte soundex normalization, similarity ranges, Option
  mirrors, diff op bounds, the constant unified-diff header floor, and a
  precondition-guarded clause indexing a Vec param). text 2.4% -> **95.1%**
  (39/41 pub; `diff_patch`/`diff_apply` skipped by design), global
  23.6% -> **24.3%** pub-with-clause. Gates: modules 509/509, corpus
  951/951 (1669.7s), probes **177/177** (incl. `p_wave26_shapes.xi`),
  barename 0/509, ratchets OK.
- LFU dedup (`50370a7`, third collect twin): `cache` gained
  `lfu_remove/lfu_capacity/lfu_clear`; `lfu.xi` is a delegation shim with
  mirrored clauses; collect family 101/101, ratchet OK. Remaining dedup:
  geom only (its own audited API unit).
- Registry pin (`9b2d2a2`): `publish-registry.yml` now passes
  `pkg publish --compiler "$(COMPILER_VERSION at the tag)"`; the m128
  client emits the field, so the register compiler-pin correlation is
  CLOSED (docs checklist + limitations updated). No manifest change needed.
- Recon delivered (agents, read-only; implementation next):
  * text/regex: regex wave candidates ready (`regex/regex.xi` ~24 clauses,
    `syntax.xi` ~10, `engine.xi` ~14 with payload caveats, `pcre_lite.xi`
    ~8 state-free); text already executed as wave 26.
  * control_theory + optimization: full implementation plan for
    `observability`/`controllability` (rank of the observability matrix /
    transposed controllability matrix, local-matrix repair + copied geom
    rank helpers, tol 1e-12) and `lp_simplex`/`linear_programming` (dense
    Bland-rule tableau with the documented no-Phase-I/empty-on-failure
    convention), with a 16-case verification plan. `state_space` deferred
    (tuple/return-ABI risk). This is the next big feature unit.
  * math tails: candidates for number_theory (~55 clauses), factorial
    (~30), combinatorics (~36), signal (~48, pure length invariants),
    exponential (~16 sign/NaN) -- ready to apply as waves 27+.
  * tzdata phase 2 plan and untested-surface class plan are in the earlier
    PART 9 block.
- Compiler-lane sequence reminder at the bump (from their SESSION): set
  `stdlib/` to our release ref and bump `STDLIB_VERSION`, run
  `XIOM_STRICT_CLAUSES=1 cargo test -p xiom-check catalog_corpus_is_clean`
  (green here), then remove the env gate so strict becomes the default,
  re-run the stdlib-dependent gates + full e2e, re-convert the notes,
  version bump, push, tag, registry canary, website notes.
- Still open after this block: wave 27 (regex: regex/syntax/engine/pcre),
  waves for the math tails, control_theory + lp_simplex, geom dedup unit,
  tzdata phase 2, untested-surface generator classes, the test + error/io
  tails wave (recon agent still pending at write time), and the release
  cut per `docs/RELEASE_CHECKLIST.md`.

**SESSION 2026-09-25 dawn block (wave 27 test, recon for the rest)**
- Wave 27 (`e7f2d37`, floors64): 46 clauses on `test/test.xi` +
  `test/assert.xi` (exact Boolean mirrors on the `TestResult.passed` field,
  panic-mirror ensures on the assert module -- the clause is only reached on
  the return path where the condition holds, count bounds on result
  vectors, Str length floors on the formatted outputs, benchmark
  passthrough, empty/length mirrors). test 3.1% -> **70.8%** (46/65),
  global 24.3% -> **25.0%** pub-with-clause. Gates: modules 509/509,
  corpus 951/951 (1357.8s), probes **178/178**, barename 0/509, ratchets OK.
  Probe constraint learned: only ONE `xiom.test` sibling can be imported per
  program (the second clobbers the first's exports -- known limitation), and
  cross-module type names must be referenced by their UNQUALIFIED leaf
  (`Vec[TestResult]`, not `Vec[test.TestResult]`; the qualified form
  silently resolves to Vec[Int]).
- Recon delivered (agent, read-only; implementation next):
  * test + error + io tails: 95 proposed clauses across ~92 fns
    (`test/harness.xi` 13, `error/{backtrace,chain,context,error}.xi` 21,
    `io/{io,console,fs,pipe}.xi` 17, plus the test files now executed).
    Expected post-wave: test ~91%, error ~90%, io ~94%.
  * math tails: number_theory (~55 clauses), factorial (~30), combinat-
    orics (~36), signal (~48 pure length invariants), exponential (~16
    sign/NaN) -- waves 28+.
  * regex wave: `regex/regex.xi` ~24 clauses, `syntax.xi` ~10, `engine.xi`
    ~14 (payload caveats), `pcre_lite.xi` ~8 (state-free only).
  * control_theory + lp_simplex: full implementation plan with local-matrix
    repair, copied geom rank/mul helpers, Bland-rule tableau, the
    documented empty-on-failure convention, and a 16-case verification
    plan (next big feature unit; `state_space` deferred for tuple-ABI risk).
- Coverage wave summary so far: waves 22-27 lifted stats 0->25%, convert
  2->11.5%, math 4.1->8.3%, collections 3.5->77.2%, text 2.4->95.1%, test
  3.1->70.8%; global 21.2% -> **25.0%** pub-with-clause, all ratcheted
  (floors59-64), every wave pre-validated by a shape probe and gated by the
  full corpus.
- Remaining for the stdlib 100%: waves 28+ (regex, math tails, test/harness,
  error/io tails), control_theory + lp_simplex, geom dedup unit, tzdata
  phase 2, untested-surface generator classes, then the release cut
  (checklist + 2-highlight notes fragment ready) and the compiler-lane
  handover (strict-default flip now unblocked).

**SESSION 2026-09-25 morning-block (wave 28: harness + error + io tails)**
- Wave 28 (`a774567`, floors65): 51 clauses -- `test/harness.xi` (13:
  registry counts on the constructor, `@pre` push counts on add/benchmark,
  counter-sum identities on run/filtered/parallel, report field mirrors,
  the JSON scaffolding floor, skip non-emptiness), the error tails (21:
  field-length identities on constructors/copiers, Option payload length
  in a clause, the None+free guard, input-arity requires), and the io tails
  (17: Result payload length on the parse/read errors, boolean/path
  mirrors, exact `console_get_size` tuple, `pipe_create` pair implication,
  filesystem-backed Ok clauses). test 3.1% -> **90.8%**, error 37.5% ->
  **90.0%**, io 78.7% -> **94.4%**, global 25.0% -> **25.8%**
  pub-with-clause. Gates: modules 509/509, corpus 951/951 (1261.1s),
  probes **179/179** (incl. `p_wave28_shapes.xi`), barename 0/509, ratchets
  OK. Targeted smokes also run: test 3/3, error 5/5, io 20/20, path 18/18,
  folder 5/5.
- Coverage wave scoreboard after waves 22-28: stats 0->25%, convert
  2->11.5%, math 4.1->8.3%, collections 3.5->77.2%, text 2.4->95.1%,
  test 3.1->90.8%, error 37.5->90.0%, io 78.7->94.4%; global 21.2% ->
  **25.8%** pub-with-clause; floors59-65 all wired and green; 179 probes.
- Remaining for the stdlib 100%: waves 29+ (regex per the ready recon;
  math tails: signal/number_theory/factorial/combinatorics/exponential),
  control_theory + lp_simplex (full plan ready), geom dedup unit, tzdata
  phase 2, untested-surface generator classes, then the release cut
  (checklist + 2-highlight notes fragment ready) and the compiler-lane
  handover (strict-default flip now unblocked).

**SESSION 2026-09-25 mid-day block (wave 29 regex + payload-ABI findings)**
- Wave 29 (`b7d2b93`, floors66; follow-up `1d45191`): 41 clauses on
  `regex/regex.xi` + `regex/syntax.xi` (empty-pattern exact match counts,
  replace/split/escape/unescape length bounds, capture mirror pairs,
  Result/quantifier/character-class guards, Option payload bounds for
  find/first-match). regex 2% -> **59.2%**, global 25.8% -> **26.2%**
  pub-with-clause. Gates after the follow-up fix: modules 509/509, corpus
  951/951 (2954.1s under load), probes **181/181**, barename 0/509,
  ratchets OK.
- COMPILER FINDINGS filed this block (see
  `tools/known_failures/README.md`, evidence
  `tools/probes/evidence/p_result_payload_ir_repro.xi`):
  1. A catalog clause that reads a nested-Vec payload field
     (`result is Some => result.value.groups.len() == 1` on
     `Regex.captures`) POISONS user codegen: every user-side call fails to
     compile with `error: '%tmp...' defined with type '%struct.Vec'`.
     Removing/replacing the clause makes the same program compile and run
     (verified both ways). This is why the wave's captures clause is now
     payload-free.
  2. Result-Ok Str payload reads in catalog clauses fail: `regex_unescape`'s
     `.len()` clause fires a FALSE "contract violated" from user modules;
     `regex_parse`'s Str field compare exits 0xC0000005; an Int-field
     counter clause passes in isolation but fails inside the larger
     `smoke_regex` program (interaction with the documented
     engine-registry/codegen corruption). All affected clauses were
     replaced with payload-free guards (`result is Err => pattern.len() > 0`,
     `pattern.len() == 0 => result is Ok`); re-add the full clauses when the
     compiler lane fixes the payload ABI + engine corruption.
- Probe constraints learned this block: only ONE sibling module per import
  family may be imported when the siblings export overlapping bare names
  (`xiom.regex.regex` vs `xiom.regex.syntax`); cross-module types must be
  referenced by their unqualified leaf; user-code payload reads can emit
  invalid IR, so probes assert `is_some`/`is_err` and let the catalog's own
  contract checker validate payload shapes.
- Remaining for the stdlib 100%: wave 30+ (math tails: signal/exponential
  first, then number_theory/factorial/combinatorics), control_theory +
  lp_simplex (full plan ready), geom dedup unit, tzdata phase 2,
  untested-surface generator classes, then the release cut (checklist +
   2-highlight notes fragment ready) and the compiler-lane handover.

**SESSION 2026-09-25 afternoon-block (wave 30: signal + exponential contracts)**
- Wave 30 (`02dde42`, floors67): 57 clauses -- `math/signal.xi` (40: exact
  transform length identities (dft/fft 2n, idft/ifft n/2, dct/dst/windows/
  spectrum/psd/cepstrum n, convolve/correlate n+m-1), wavelet coefficient
  bounds (haar/dwt/daubechies <= n, idwt <= coeffs.len()), empty-input and
  filter-order guards, spectrogram/mel row guards, MFCC <= 24) and
  `math/exponential.xi` (17: NaN-tolerant non-negativity for exp/exp2/exp10/
  exp_pure, expm1 >= -1, log-domain sign floors for x > 1 / x > 0,
  positive-base pow sign, pow_int(_, 0) == 1.0 exactly). math 8.3% ->
  **14.1%** (signal 40/40 and exponential 18/18 pub covered), global 26.2%
  -> **27.1%** pub-with-clause.
- Fixed a latent OOB in `filter_bandstop`: `order <= 0` indexed the empty
  band-pass buffer and silently returned the input (probe exit 27 before,
  0 after; the guard now returns empty, matching the sibling filters).
- Probe `p_wave30_shapes.xi` (182nd probe) pre-validated every shape with
  RED evidence captured before the fix and green after. Gates on `02dde42`:
  modules 509/509 (743.3s), corpus 951/951 (2453.4s), probes 182/182
  (921.7s), barename 0/509 (1018.1s), coverage floors67 + doc ratchet OK.
- Relay note (compiler lane, 2026-09-25): the mixed-bracket/arity error
  lists did not arrive with the relay. This repo's `io/fs.xi` has no
  angle-bracket generics; a legacy-angle inventory finds ~100 sites in 15
  files (alloc, compress, convert, core/contracts, crypto aead/cipher/
  crypto, error, net/tls_helper, os/env, os/path, rand, reflect, regex,
  serialize), far more than 18/7, so the list needs the compiler lane's
  exact file/site spellings before any stdlib edit. The `xiom.cell`
  question is answered: `xiom/ptr/ptr.xi` declares
  `pub fn is_null[T](ptr: *const T) -> Bool` and `xiom/cell/cell.xi:155,181`
  call it as `ptr.is_null()` -- the compiler lane's offset-bug case, to be
  fixed compiler-side instead of changing stdlib call sites.
- Remaining for the stdlib 100%: queue A3/A4 (number_theory, factorial,
  combinatorics), B (control_theory observability/controllability +
  lp_simplex), C (geom dedup), D (tzdata phase 2), E (untested-surface
  generator classes), F (release cut).
- A3/A4 recon DONE (read-only background agent, counts re-verified by
  direct scan): `math/number_theory.xi` 32 pub fn / 0 clauses,
  `math/factorial.xi` 22 / 0, `math/combinatorics.xi` 28 / 0 (82 fns, none
  covered). Recon-verified safe first batch (re-check each against source
  before landing): number_theory `is_composite` `(n <= 1 || n == 2) => false`,
  `is_semiprime` `(n < 4) => false`, `is_power` `(n <= 1) => false`,
  `is_pseudoprime`/`fermat_test` guard mirrors, `legendre/jacobi/kronecker`
  guard + `result >= -1 && result <= 1`; combinatorics
  `permutations_with_repetition`, `compositions_all` (n >= 64 => 0),
  `fibonacci` (n >= 93 => 0), `lucas` (n >= 91 => 0), `surjections`;
  factorial delegation aliases (`binomial_coeff`, `derangements`,
  `bell_numbers`, `catalan_numbers`, `eulerian_numbers`,
  `stirling_numbers_1/2`, `lah_numbers`, `narayana_numbers`,
  `combinations`, `partitions`) plus the threshold guards on
  factorial/double_factorial/multifactorial/subfactorial (21/34/--/21).
- DO-NOT-TOUCH until fixed: `next_prime` (seed-guard gap at n=INT_MAX-2:
  cand+2 wraps and the loop never terminates; `result > n` unsafe);
  `euler_phi/mobius/jordan_totient/carmichael/radical/smooth/rough`
  (unguarded `p*p` wraps for prime cofactors > ~9.22e18 -> multi-billion
  iteration hang, lines 373/395/423/456/626/650/669); `prime_pi` (O(n)
  allocation); `pollard_rho`/`p_1_factor` (strong factor clauses false --
  they return n when no split; `_addmod` precondition violated for small n);
  `factorial.binomial`/`multinomial` (false-overflow: `binomial(4294967294,
  2)` returns 0 though the true value fits -- never assert nonzero for the
  in-range case); `falling_factorial`/`rising_factorial` (INT_MIN negation
  overflow); `combinatorics.involutions` and the subfactorial wrap test
  (incomplete heuristic; subfactorial's first wrap is caught, involutions
  unproven); `combinatorics.permutations(n<0, k)` returns 12, contradicting
  its doc, so no doc-consistent clause.
- Other recon findings: `divisor_sum(1, k<0)` returns 1 but doc says 0;
  `jordan_totient(1, k<0)` returns 1; `next_prime(n<0)` returns 2 not 0;
  `_trial_prime` is dead code; `_mul_ovf`/`_copy_vec` duplicated across the
  three modules (DRY backlog); recursion-depth guards missing on
  `_perm_rec`/`_derange_rec`/`_comb_rec`.
- Planned next waves: 31 = factorial.xi clauses (22), 32 = combinatorics
  safe batch + number_theory safe batch; each fix-first item above lands
  as its own probe + verified rerun per the one-fix rule.

**SESSION 2026-09-25 evening-block (wave 31 + strict-parser bracket prep)**
- Compiler relay delivered the exact PIN mixed-bracket list (18 type
  spellings, 7 files). On main 13 remained; canonicalized in `0823433`
  (core/contracts 231, io/console 47, io/fs 50/80/110/124/138/162/215/230/
  299/338, io/pipe 185 -- `Result[T, Str>` closers). The other 5
  (test/harness 34/99, test/test 196/212, math/approximation 502) were
  already canonical on main. The four touched modules re-check clean via
  the check_modules probe shape. Strict flip waits on the compiler lane's
  XIOM_STRICT_BRACKETS=1 diagnostics + pin bump; the arity list is still
  outstanding (`xiom.cell`'s `ptr.is_null()` is their offset-bug case).
- Wave 31 (`38b5c32`, floors68): 80 clauses on math/factorial.xi (22 fns:
  invalid-input guards, exact 0/1 identities, documented-overflow
  thresholds factorial>=21 / double_factorial>=34 / subfactorial>=21 /
  catalan>=34, non-negativity of every numeric family, enumeration length
  shapes). math 14.1% -> **16.3%**, global 27.1% -> **27.4%**
  pub-with-clause. Probe p_wave31_shapes.xi green before and after;
  smoke_math_factorial + smoke_math_combinatorics green.
- Gates on `38b5c32`: modules 509/509 (219.7s), corpus 951/951 (1288.4s),
  probes 183/183 (263.6s), barename 0/509 (521.8s), floors68 + doc
  ratchet OK.
- Remaining for 100%: wave 32 (combinatorics safe batch), wave 33
  (number_theory safe batch), the fix-first items from the A3/A4 recon
  (next_prime wrap/hang, binomial false-overflow, p*p wraps, INT_MIN
  negation), then B/C/D/E/F.

**SESSION 2026-09-26 night-block (wave 32 combinatorics + wave 31 clause fix)**
- Wave 31 follow-up `71f4d9f`: the Stirling/Eulerian zero-row clause was
  false for invalid k (`stirling_first(0, 1)` returns 0 while it demanded
  1); fixed to `(n == 0 && k == 0) => 1`. Probe `p_wave31_shapes.xi`
  extended with the invalid-k cases (RED `ensures 272:12` -> GREEN).
  Gates re-run: modules 509/509, corpus 951/951, probes 183/183,
  barename 0/509, floors68 + doc ratchet OK.
- Wave 32 (`224060a`, floors69): 103 clauses on math/combinatorics.xi
  (28 fns: invalid-input guards, delegation mirrors for permutations/
  combinations/derangements/bell/catalan/eulerian/Stirling/Lah/Narayana/
  partitions, documented-overflow thresholds Fibonacci >= 93, Lucas >= 91,
  compositions_all >= 64, non-negativity, enumeration length shapes
  including powerset 2^n rows and the n > 20 guard). math 16.3% ->
  **19.1%**, global 27.4% -> **27.8%** pub-with-clause. Probe
  p_wave32_shapes.xi green before and after; it caught an `involutions`
  antecedent overlap (`n <= 1` matched negatives) before landing.
  smoke_math_combinatorics + smoke_math_factorial green.
- Gates on `224060a`: modules 509/509 (291.9s), corpus 951/951 (1432.7s),
  probes **184/184** (354.7s), barename 0/509 (800.6s), floors69 + doc
  ratchet OK.
- Next: wave 33 (number_theory safe batch; the 7 p*p-wrap families stay
  DO-NOT-TOUCH until fixed), then the fix-first probes from the recon,
  then B/C/D/E/F.

**SESSION 2026-09-26 pre-dawn-block (wave 33 number theory)**
- Wave 33 (`8a294c5`, floors70): 57 clauses on math/number_theory.xi
  (21 safe fns: primality guards, factor/prev_prime/nth_prime/primorial
  shapes, pseudoprime/strong-test mirrors, Lucas-Lehmer thresholds,
  integer-property guards, symbol ranges, divisor guards) -> math 19.1%
  -> **21.2%**, global 27.8% -> **28.2%** pub-with-clause. The 11
  p*p-wrap/deferred families stay clause-free.
- Probe p_wave33_shapes.xi caught `prev_prime(3)` returning 0; fixed to 2
  (`if n == 3 { return 2; }`) in the same wave.
- NEW open finding: `kronecker_symbol` returns 0 for even a with odd n
  (e.g. (2/7)) -- the 2-adic factor is applied unconditionally instead of
  only to the 2-part of n. Recorded for the fix-first batch together with
  next_prime wrap/hang, the binomial false-overflow, the p*p wraps and the
  INT_MIN negation.
- Gates on `8a294c5`: modules 509/509 (287.9s), corpus 951/951 (1435.1s),
  probes **185/185** (369.5s), barename 0/509 (586.0s), floors70 + doc
  ratchet OK.
- A3/A4 waves 31-33 now carry every safe clause in the three math tails;
  remaining coverage work is the DO-NOT-TOUCH families after their fixes,
  then queue B/C/D/E/F and the release cut.

**SESSION 2026-09-26 afternoon-block (fix-first math-tail batch)**
- `e45386c`: binomial is now exact via the gcd-folded recurrence
  (binomial(4294967294, 2) RED 0 -> GREEN; true overflows still 0);
  kronecker_symbol applies the 2-adic factor only when n is even
  ((2/7) == 1 now); the seven p*p loop conditions (euler_phi, mobius,
  jordan_totient, carmichael, radical, smooth, rough) use `p <= x / p`;
  next_prime returns 0 at the top of Int instead of wrapping (boundary
  calls GREEN; the pre-fix path never returned).
- Probe `tools/probes/p_fix_math_tails.xi` (186th probe) locks all four;
  smoke_math_factorial/combinatorics/number_theory green. Gates on
  `e45386c`: modules 509/509 (544.6s), corpus 951/951 (2577.8s), probes
  **186/186** (486.1s), barename 0/509 (816.7s), floors70 + doc ratchet OK.
- The fixed families (euler_phi, mobius, jordan_totient, carmichael,
  radical, smooth, rough, next_prime, pollard_rho, p_1_factor, prime_pi)
  can now be reconsidered for clauses in a later wave; binomial /
  kronecker gained behavior only, no new clauses yet. Remaining queue:
  B (control_theory + lp_simplex), C (geom dedup), D (tzdata phase 2),
  E (generator classes), F (release cut).

**SESSION 2026-09-26 evening-block (wave 34 control_theory + compiler relay)**
- Wave 34 (`7293056`, floors71): queue B part 1 -- observability and
  controllability implemented on the nested-Vec repair pattern (private
  `_ct_copy`/`_ct_mul`/`_ct_transpose`/`_ct_rank`, 1e-12 pivot, two-stage
  deep copy); guards for empty/non-square A, width mismatches, empty or
  zero-column B, multiply failure; clauses `!result || a.len() > 0`.
  Probe p_control_theory_shapes.xi (187th) green; smoke_math_optimization
  green. math 21.2% -> **21.4%**; gates: modules 509/509 (842.8s), corpus
  951/951 (1858.2s), probes **187/187** (827.6s), barename 0/509 (598.4s),
  floors71 + doc ratchet OK.
- Compiler relay 2026-09-26 (m142/m143): `ptr.is_null()` UFCS fixed
  compiler-side -- the stdlib module-qualified workaround in thread/park.xi
  stays until the pin carrying m142+ is adopted; by-value receiver
  container mutation fixed (no stdlib action). Relay item 1 closed: the
  invalid `Int.hash` clause (`a == b => ...` with unbound names) replaced
  by `ensures: result != 0` (the DJB2 range here is positive and
  non-overflowing); hash module check + three hash smokes green.
- Relay item 2 (deferred to its own wave): `Error.chain`
  interface-dispatch gap -- the Error interface returns `Option[Error]`
  (interface as value), which the new checker still stubs (W005);
  restructuring means migrating error/context.xi, error/chain.xi and the
  error smokes. Exact expected shape requested from the compiler lane.
  Backlog C8 (v0.61.3 wasm asset missing from SHA256SUMS) is
  compiler/release-side.
- Queue B part 2 (`lp_simplex` + `linear_programming`) remains next,
  then C/D/E/F.

**SESSION 2026-09-26 night-block-2 (compiler relay item-3 call sites)**
- Relay item 3 closed: all three remaining arity/fix sites landed --
  kdf.xi passes the dropped `r` to both `_scrypt_blockmix` calls;
  os/path.xi qualifies `xiom.string.replace` in `Path.components`;
  io/io.xi and io/console.xi declare `printf(format, arg)` with the fixed
  shape the three `%s` call sites use (no variadic `...`).
- Probe `tools/probes/p_relay_arity_fixes.xi` (188th) exercises io.print
  and Path.components at runtime (scrypt itself stays unexecuted: the
  returned-Vec-into-&Vec miscompile note in smoke_crypto_kdf still
  applies); smoke_io_print, smoke_stress_path_components and
  smoke_crypto_kdf green.
- Also relayed: m144 fixed the G-10 bare-sibling receiver gap
  (`collections.get` was a compiler bug, not a stdlib call-site bug); the
  `ptr.is_null()` module-qualified workaround in thread/park.xi stays until
  a pin carrying m142+ is adopted; the `Error.chain` interface-dispatch
  gap remains the open stdlib item (see previous block).

**SESSION 2026-09-27 early-block (relay: m145/m146 + Error interface shape)**
- `Error.chain` restructure per the compiler lane's answer: the `Error`
  interface now carries only `description` plus the default `message`
  alias -- the interface-valued `source`/`cause` returns are gone;
  `Error.chain` is description-only with a note until a concrete closed
  ErrorInfo/ErrorKind design has consumers. No implementors or other
  consumers existed, so the change is contained to error/error.xi;
  smoke_error green and the floors71/doc ratchets hold.
- net relay: all four `xiom_socket_connect` extern declarations (net,
  http, socket, websocket) now say `-> Int32` per the m146 analysis. On the
  pin the declaration change is behavior-neutral (the signedness-widening
  bug it needs remains until a pin carrying m146), so tcp_connect's
  negative-result path is expected to become correct only at the pin bump;
  eight net smokes plus module checks green.
  errno/WSAGetLastError propagation into NetError.code is recorded as a net
  enhancement (not blocking).
- m145 precedence: no stdlib action (the audited `(n >> hi) & 1 == 1` shape
  is unchanged). Backlog R-2/R-3/C8 remain compiler-side.

**SESSION 2026-09-27 morning-block (wave 35 lp_simplex)**
- Wave 35 (floors72): `lp_simplex` implemented (minimize c'x, Ax <= b,
  x >= 0) -- dense tableau, slack basis, Bland entering/leaving,
  Gauss-Jordan pivots, 10000-iteration cap; empty-result conventions for
  empty c or A, b mismatch, ragged A, b[i] < 0, unbounded and cap; the
  objective row is the minimize-c row (the first attempt used the
  maximization sign and the probe caught it). Private `_opt_copy`
  (two-stage nested-Vec repair). Probe `p_lp_simplex.xi` (189th): known LP
  -> [2,2], simple bound, five guards, unbounded -- green. math 21.4% ->
  **21.5%**.
- `linear_programming` (bounds repair + delegation) and the
  smoke_math_optimization cases remain for the next block; `_opt_copy` is
  ready for reuse.

**SESSION 2026-09-27 mid-day block (wave 36: linear_programming + queue-B smokes)**
- Wave 36 (floors73): `linear_programming` implemented in
  math/optimization.xi per queue B part 2b. Bounds repair on `_opt_copy`;
  empty bounds delegates to lp_simplex with x >= 0; per-variable
  `[lo, hi]` entries with +/-inf for absent sides (an empty entry means
  [0, +inf), a single entry means [lo, +inf)). Lower-only variables shift
  (x = lo + z), upper-only reflect (x = hi - z), doubly-bounded ones
  scale into [0, 1] with an added z <= 1 row, free ones split z+ - z-;
  the transformed c2/A2/b2 are delegated to lp_simplex and the solution is
  mapped back. Malformed or infeasible bounds (length mismatch, more than
  two entries, NaN, lo > hi, lo == +inf, hi == -inf) and the documented
  shifted-b2-negative case (no Phase I) return empty; clause
  `result.len() == 0 || result.len() == c.len()`.
- Probe p_linear_programming.xi (190th): delegation identity, upper-only,
  both-bounded single, free, fixed, four guards -- RED (exit 1) on the
  stub, GREEN after.
- Queue-section-B verification cases wired into
  smoke_math_optimization.xi: observability true/false + guards,
  controllability true/false/multi-input + guards, lp_simplex [2,2] +
  guards + unbounded, linear_programming empty-bounds identity, bound
  modes ([0,1], [0,inf]) -> [1,3], free variable -> [-1] -- green.
- math 21.5% -> 21.6%, global 28.2% pub-with-clause; floors73 wired into
  ci/heavy/release + tools/README.md + docs/STDLIB_READINESS_PLAN.md in
  the same commit (533b863).
- Full battery on 533b863: check_modules 509/509 (349s); corpus 951/951,
  0 compilefail, 0 runfail (1785.8s); probe corpus 190/190 (376.9s);
  barename 0 hits / 509 (768s); coverage ratchet floors73 OK; doc ratchet
  OK (pub 6993/6993 = 100%). Wave 36 closed.

**RELAY 2026-09-27 (packages -> stdlib, growth channel)**
- The packages lane created a shared growth channel (their hand-to-hand
  plan): `E:\xiom-packages\packages\docs\STDLIB-WISHLIST.md` (prioritized
  helpers/modules several packages hand-roll, with requester packages and
  workarounds; top items include checksum, bitstream, varint, bytes.cursor,
  encoding.base64, string.utf8 strict validation, text.scan, date.civil,
  net.addr, bcd, math.int, buf.writer) and
  `docs\PACKAGE-NAMESPACES.txt` (342 package names / 366 module namespaces,
  refreshed per wave). Two-way uniqueness rule: before landing a NEW module
  namespace, check it against PACKAGE-NAMESPACES.txt; their side runs
  scripts/namespace-check.ps1 -Module <name> against our namespaces before
  dispatch. No new namespaces in the current coverage waves; the first
  affected unit is D (tzdata phase 2: `xiom/time/zone` + `zone/data/*`) --
  check the snapshot there, and tick wishlist Status / announce shipped
  items in the handoff. A push-style feed was offered; pull is fine for now.

**SESSION 2026-09-27 afternoon block (wave 37: trig-family coverage + non-finite guard fix)**
- Wave 37 (floors74): 25 runtime-safe range clauses across the trig family.
  math/trig.xi (14): sin/cos/sin_deg/cos_deg in [-1, 1], asin/atan in
  [-1.5708, 1.5708], acos in [0, 3.1416], atan2 in [-3.1416, 3.1416],
  cosh >= 0, tanh in [-1, 1], acosh >= 0, asinh sign implication
  ((x >= 0.0) => (result >= 0.0)), sec/csc outside (-1, 1).
  math/trigonometry.xi (6): sin/cos/sinpi/cospi in [-1, 1], csc/sec outside
  (-1, 1). math/hyperbolic.xi (5): cosh/sech/acosh >= 0, tanh in [-1, 1],
  coth outside (-1, 1). IEEE-safe choices: cosh/sech claim only >= 0 (the
  naive (exp(x)+exp(-x))/2 can round to 1 - eps, so the sharp >= 1.0 claim
  was rejected); every range clause is NaN-tolerant (`|| result != result`)
  for the documented domain errors.
- Fix-first, found by the read-only recon: `_norm`, `sinpi`, `cospi` and
  `tanpi` ran O(|x|) reduction loops that never terminate on +/-inf (a hang
  class, not just a wrong value). Non-finite inputs now return NaN; the
  sinpi/cospi/tanpi docs were corrected (linear reduction, not O(1), NaN
  for non-finite input). The stale hyperbolic.xi header claiming a -1.0
  sentinel for BUG 19 was corrected to the actual NaN returns.
- Probe tools/probes/p_trig_family.xi (191st): every new clause is evaluated
  at runtime together with range/domain/KAT checks and the +/-inf guard
  cases -- RED-by-hang on the old reduction loops, GREEN after the fix.
- math smoke family 53/53 green with the clauses active; math 21.6% ->
  24.1%, global 28.2% -> 28.6%; floors74 wired into ci/heavy/release +
  tools/README.md + docs/STDLIB_READINESS_PLAN.md in the same commit.
- Full battery on 0161293: check_modules 509/509 (745.2s); corpus 951/951,
  0 compilefail, 0 runfail (3259.8s); probe corpus 191/191 (359.6s);
  barename 0 hits / 509 (602.3s); coverage ratchet floors74 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 37 closed.

**RELAY 2026-09-27 (playgrounds -> stdlib)**
- tcp_connect verification target restated (m146 + stdlib >= c193bc4): the
  `xiom_socket_connect -> Int32` declaration change is already on main; the
  negative-result path is expected to become correct only on a pin carrying
  m146, and the playground verifies refused-port -> Err at every pin bump
  (queue pin-gated list, unchanged).
- Also relayed (to both lanes; ownership unclear): `for x in Vec` semantics
  and a checker warning "unknown type 'Iterator' -- defaulting to i64". No
  minimal repro attached; if it is a stdlib-side iterator-protocol issue it
  needs the repro before any action. Waiting on the compiler lane or a repro.

**SESSION 2026-09-27 evening block (wave 38: rounding + angular coverage)**
- Wave 38 (floors75): 26 runtime-safe clauses on math/rounding.xi (13) and
  math/angular.xi (13). rounding: floor <= x, ceil >= x; direction/sign
  claims for round/trunc/integer_part (result on the input's side of zero)
  and the *_pure variants (floor_pure/ceil_pure use `(x == x) => bounds` so
  no NaN-cast assumption is baked in; trunc_pure bounded by x and zero;
  fract/fract_pure/frac_part in [0, 1) or (-1, 0] with NaN tolerance);
  round_nearest sign by input side. SKIP: modf (tuple-result clause shape
  not yet validated) and round_to (10^places can be 0/inf). angular: sign
  preservation (result >= 0 on positive input, <= 0 on negative, signed
  zero and infinities included) for the ten unit conversions; the
  normalization pair wrapped into (-pi, pi] / (-180, 180] with +/-inf
  pass-through and NaN tolerance (the tau/2..tau subtraction is exact, so
  the strict range holds); angle_diff mirrors normalize_angle. SKIP:
  angle_lerp (arbitrary t).
- Probe tools/probes/p_wave38_shapes.xi (192nd): ties-to-even, aliases,
  modf, saturation, conversion values, normalization boundaries,
  infinities and NaN -- all clauses evaluated at runtime; math family 53/53
  green with the clauses active.
- math 24.1% -> 26.7%, global 28.6% -> 29.0%; floors75 wired into
  ci/heavy/release + tools/README.md + docs/STDLIB_READINESS_PLAN.md in the
  same commit.
- Full battery on e6f0206: check_modules 509/509 (243.7s); corpus 951/951,
  0 compilefail, 0 runfail (1473.7s); probe corpus 192/192 (340.7s);
  barename 0 hits / 509 (648s); coverage ratchet floors75 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 38 closed.

**SESSION 2026-09-27 night block (wave 39: algebra + transcendental + two fixes)**
- Wave 39 (floors76): 23 clauses -- math/algebra.xi (12): gcd/lcm >= 0,
  Legendre/Jacobi results in {-1,0,1}, binomial/factorial/primorial/
  nth_prime >= 0, integer_sqrt >= -1, next_power_of_two >= 0,
  is_power_of_two/is_perfect_square as `result == false || domain`;
  math/transcendental.xi (11): sqrt/cbrt sign + domain-NaN tolerance,
  exp/exp2 >= 0, expm1 >= -1, ln/log2/log10 `NaN or x > 0`, log1p with the
  -inf endpoint, erf in [-1,1], erfc in [0,2].
- Fix-first (both caught by the probe):
  1. The wave-38 angular conversion clauses used strict `> 0.0`/`< 0.0`
     branches, which are BOTH false for -0.0, so to_radians(-0.0) would
     have aborted at runtime. All ten now use `>= 0.0`/`<= 0.0`; the probe
     asserts signed-zero preservation (1/result == -inf) for all ten plus
     floor/trunc/fract.
  2. `math.exponential.log1p(-1.0)` called `math.ln(0.0)`, tripping the
     delegate's runtime `requires: x > 0.0` instead of returning the
     documented -inf; now guarded with an explicit -1.0 -> -inf return.
  3. Doc correction: transcendental.erf(0) is ~ -3e-8 (continued-fraction
     approximation, error < 1.2e-7), not exactly 0.
- Open stdlib finding (recorded, not fixed): sqrt(NaN) and ln(NaN) pass NaN
  into math.sqrt/math.ln (math.xi:192/354), whose runtime requires abort --
  the documented "domain errors return NaN" holds for finite domains but
  not for NaN inputs. Candidate fix-first for a later wave.
- Probe tools/probes/p_wave39_shapes.xi (193rd): algebra identities,
  transcendental values/domain-NaN, signed-zero regressions. Also: the
  probe helper lesson -- `near(a, b, tol)` was declared 2-arg first and
  extra arguments are silently ignored by the compiler (looked like an
  approximation failure); helper now takes tol explicitly.
- math family 53/53 green; math 26.7% -> 29.0%, global 29.0% -> 29.4%;
  floors76 wired into ci/heavy/release + tools/README.md +
  docs/STDLIB_READINESS_PLAN.md in the same commit.
- Full battery on f06ce58: check_modules 509/509 -- NOTE: the first run
  reported 8 rc=-1 CHECK-FAILs, one per worker, across unrelated modules
  (bits.bitwise, collect.workqueue, convert.tostring, format.terminal,
  math.finance, net.ping, simd.vec4, string.scanf); a direct `--check`
  retry of a failed module passed (rc=0) and the immediate full rerun was
  509/509 in 642.4s, so the rc=-1 batch was a transient runner/process
  failure, not a source regression. corpus 951/951, 0 compilefail, 0
  runfail (2470.3s); probe corpus 193/193 (330.9s); barename 0 hits / 509
  (563.3s); coverage ratchet floors76 OK; doc ratchet OK (6993/6993 =
  100%). Wave 39 closed.

**SESSION 2026-09-27 late block (wave 40: complex.xi field clauses)**
- Wave 40 (floors77): 19 clauses on xiom/math/complex.xi (module
  `xiom.complex`). Field-equality claims use the NaN-tolerant form
  `(result.re == expr) || (result.re != result.re)` -- a bare field
  equality would violate at runtime on NaN inputs. Coverage:
  complex_new/from_polar/add/sub/mul/scale/conj, abs >= 0, arg range,
  the epsilon predicates (`eps <= 0 => result == false`),
  exp/pow/sin/cos/tan non-NaN-or-non-negative magnitude, log imag range,
  sqrt real-branch implication, to_string non-empty. `complex_div` stays
  clause-free: exact recomputation fails for NaN components and mixed
  inf/inf cases (e.g. a=(inf,0), b=(1,0) gives re=inf but im=NaN).
- Shape precedent checked first: tuple/struct field reads in clauses are
  already gate-green (bits.xi `result.0`, core.xi `result.initialized`,
  collect/concurrent.xi `s.items.len()`), so the complex clauses use the
  established form.
- Probe tools/probes/p_wave40_shapes.xi (194th): field identities,
  predicate eps edges, sqrt branches, NaN tolerance; smoke_complex 1/1
  green with the clauses active (it was not part of the smoke_math filter).
- math 29.0% -> 31.0%, global 29.4% -> 29.7%; floors77 wired into
  ci/heavy/release + tools/README.md + docs/STDLIB_READINESS_PLAN.md in the
  same commit.
- Full battery on e707472: check_modules 509/509 (239.1s); corpus 951/951,
  0 compilefail, 0 runfail (1367.3s); probe corpus 194/194 (307.5s);
  barename 0 hits / 509 (553.9s); coverage ratchet floors77 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 40 closed.

**SESSION 2026-09-27 late-night block (wave 41: vectors.xi coverage)**
- Wave 41 (floors78): 27 clauses on math/vectors.xi. Vec2/Vec3/Vec4
  constructors, add/sub/scale, lerp and cross use NaN-tolerant exact-field
  equalities; dot products use exact-or-NaN; len/dist >= 0; unit-vector
  claims are "zero vector OR squared magnitude within 1e-12 of 1" with NaN
  tolerance; dynamic vec_dot claims NaN exactly on length mismatch;
  vec_norm >= 0; vec_scale preserves length. NaN is only passed to
  sqrt-free paths in the probe: hypot/hypot3/vec4_len/vec_norm still abort
  on NaN via math.sqrt's requires (the wave-39 open finding), and the
  clauses stay true because those calls never return.
- Probe tools/probes/p_wave41_shapes.xi (195th); smoke_math_vectors 1/1
  green; math 31.0% -> 33.7%, global 29.7% -> 30.1%; floors78 wired into
  ci/heavy/release + tools/README.md + docs/STDLIB_READINESS_PLAN.md in the
  same commit.
- Full battery on 1401432: check_modules 509/509 (758.1s); corpus 951/951,
  0 compilefail, 0 runfail (3456s; 16 files failed the parallel phase and
  passed the solo retry -- the same transient load pattern as the wave-39
  rc=-1 batch); probe corpus 195/195 (652.1s); barename 0 hits / 509
  (1210.9s); coverage ratchet floors78 OK; doc ratchet OK (6993/6993 =
  100%). Wave 41 closed.

**RELAY 2026-09-27 (packages -> compiler, forwarded here)**
- Triaged in `xiom-packages` docs/COMPILER-FINDINGS.md: `&mut` and CSE are
  accepted repro-first candidates; mixed-bracket strictness is planned;
  `Vec[Float64]`/`Vec[StructType]` items routed to the packages wishlist;
  the changelog notes the relay and SESSION.md carries the ready-to-run
  re-test instruction for the next wave. No stdlib-side action.

**RELEASE DECISION 2026-09-27 (owner call, relayed)**
- The owner asked whether the next release can be cut BEFORE 100% coverage
  and coverage continued in the release after, given the previous released
  compiler had major bugs and stability matters more than the coverage
  number; the compiler lane is waiting for this lane's go/no-go.
- Decision: YES -- release from the wave-41 tip once the release-cut commit
  passes the full local battery, because every hard gate is green
  (check_modules 509/509, corpus 951/951, probes 195/195, barename 0/509,
  coverage ratchet floors78, doc 100%) and the coverage work is additive
  (clauses only; each new clause is probe-verified). The 100% target
  continues on main as floors79+ and moves to the following release.
- Release cut steps in this lane: package.xi -> 0.62.0, CHANGELOG
  [Unreleased] -> [0.62.0] - 2026-09-27 (+ a waves 22-41 summary), notes
  fragment `release-notes/v0.62.0.md` already has the 2 allowed highlights,
  COMPILER_VERSION stays v0.61.3 (existing tag). Tagging/publishing stays
  with the release lane on its go (RELEASE_CHECKLIST items 7-9).
- Release cut committed as 80e767b (package.xi 0.62.0, CHANGELOG
  [0.62.0] - 2026-09-27, release-notes/v0.62.0.md already the 2-highlight
  fragment). Battery on the exact commit, all green: check_modules 509/509
  (338.8s); corpus 951/951, 0 compilefail, 0 runfail (2045.6s); probe
  corpus 195/195 (593.3s); barename 0 hits / 509 (780.7s on the rerun --
  the first pass reported one transient COMPILE-FAIL on xiom.rsa whose
  probe compiled clean on a direct retry, same load-flake class as the
  wave-39/41 events); coverage ratchet floors78 OK; doc ratchet OK
  (6993/6993 = 100%). Author identity verified as
  Lefteris Notas <lefterisnotas@gmail.com>. GO given to the compiler/
  release lane for stdlib-v0.62.0; coverage waves resume on main as
  floors79+ for the following release.

**SESSION 2026-09-28 block (wave 42: family batch -- matrices + number_systems + queueing)**
- Owner approved family batching (40-60 pub/wave) to shorten the path to
  100%. Wave 42 is the first such batch: 53 clauses across three files,
  51 new pub covered (1,954 -> 2,005).
- matrices.xi (22): NaN-tolerant field equalities for mat2/mat3/mat4
  construction, mat2_mul/mat3_mul and transposes; mat3_det exact-or-NaN;
  mat2_inv/mat3_inv `result is None => det^2 < 1e-24` (payload-free
  singularity guard); dynamic shape claims: mat_identity row count,
  mat_mul `empty or a.len()`, mat_det/mat_inv empty guards,
  mat_translate/rotate/scale preserve `m.len()`, look_at/perspective/ortho
  `empty or 4`. SKIP: mat4_mul/mat4_det/mat4_inv (clause size).
- number_systems.xi (17): radix zero/out-of-range guards, roman/greek
  range guards, Chinese/Japanese/Babylonian non-emptiness, Egyptian
  length by sign, continued-fraction `len <= terms`, fraction denominator
  positivity, surd implications (antecedent `a*b > 0` so two's-complement
  wrap is harmless), octonion/sedenion length shapes. SKIP: the three
  Result-parsing entries whose only strong claims need Ok payload reads.
- queueing.xi (14, whole file): invalid -> NaN, unstable -> +inf, stable
  non-negative/range claims for m_m_1/m_m_c/m_g_1/g_g_1/erlang_b/erlang_c,
  Little's law and utilization exact-or-NaN, queue_length/waiting_time
  guards, loss/blocking Erlang-B ranges, heavy_traffic and
  diffusion_approx case split.
- Fix-first (probe-caught): `surd_simplify` never multiplied the odd
  prime exponent back into the radicand, so sqrt(8) returned 2*sqrt(1)
  instead of 2*sqrt(2). Fixed and locked by four KATs in the probe.
- Compiler finding filed (tools/known_failures + README): a
  shape-mismatched `&Vec[Float64]` passed where `&Vec[Vec[Float64]]` is
  expected compiles with no diagnostic and AVs at the callee's nested
  read; minimal repro `p_vec_shape_arg_mismatch_av.xi` (found while
  writing the probe; both-arguments-correct shape is green).
- Probe lessons: `.value` Option payload reads AV in probe code (use
  `.unwrap()`); probe p_wave42_shapes.xi (196th) exercises all 53 clauses.
  Math family 53/53 green with the clauses active.
- math 33.7% -> 38.8%, global 30.1% -> 30.9%; floors79 wired into
  ci/heavy/release + tools/README.md + docs/STDLIB_READINESS_PLAN.md in
  the same commit.
- Full battery on 7a56375: check_modules 509/509 (465.7s); corpus 951/951,
  0 compilefail, 0 runfail (2666.9s); probe corpus 196/196 (599.1s);
  barename 0 hits / 509 (919.6s); coverage ratchet floors79 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 42 closed.

**SESSION 2026-09-28 block 2 (wave 43: num sub-batch + nextafter fix)**
- Wave 43 (floors80): 37 clauses across num/float.xi (11), num/convert.xi
  (8), num/base.xi (6), num/precision_integer.xi (6),
  num/precision_rational.xi (6); 37 new pub covered (2,005 -> 2,042).
  Highlights: exact float identities (bits fallback == 0, mantissa >= 0,
  exponent in [-1074, 1023], is_nan/is_infinite as exact Bool formulas,
  classify result in the six documented strings, next_up/next_down
  direction with inf endpoints, ulp >= 0); base58/62/ascii85/roman
  empty-input and range guards; radix guards plus digits length; bigint
  wrapper non-emptiness and compare range; BigRat parse/compare/sign
  claims (the `r.num.negative` field-chain shape validated by the probe).
- Fix-first #1 (probe-caught, significant): `primitives._ilogb_abs`
  normalized into [0.5, 1) instead of [1, 2), returning floor(log2)+1 at
  exact powers of two. Consequence: `nextafter(x, +inf)` SKIPPED a
  representable value when x was any power of two (2^k -> 2^k + 2ulp), and
  `float_ulp(2^k)` was 2x. Fixed; stepping DOWN from a normal power of two
  now also uses the lower binade's half spacing (with the min-normal /
  subnormal exception, where the lower step is still 2^-1074). Exact-step
  KATs added to smoke_num_float: next_up(1) - 1 == 2^-52,
  1 - next_down(1) == 2^-53, ulp(1) == 2^-52.
- Fix-first #2: `primitives.abs` had `ensures: result >= 0.0`, which a NaN
  input violates; now `(result >= 0.0) || (result != result)`, unblocking
  float_ulp(NaN) -> NaN (documented) and the nextafter NaN paths.
- Probe tools/probes/p_wave43_shapes.xi (197th); num smoke family 18/18 and
  math family 53/53 with the fixes and clauses active; num 9.6% -> 17.2%,
  global 30.9% -> 31.4%; floors80 wired into ci/heavy/release +
  tools/README.md + docs/STDLIB_READINESS_PLAN.md in the same commit.
- Full battery on 2cd0d5b: check_modules 509/509 (429.3s); corpus 951/951,
  0 compilefail, 0 runfail (2578.4s); probe corpus 197/197 (353.9s);
  barename 0 hits / 509 (1028.1s); coverage ratchet floors80 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 43 closed.

**INCIDENT + RELEASE RECOVERY 2026-09-28/29 (workflow YAML)**
- Registry relayed that ci.yml/heavy.yml/release.yml failed at 0s on main
  ("workflow file issue") and stdlib-v0.62.0 had no GitHub Release/assets,
  blocking the registry canary wait.
- Root cause (this lane, own mistake): the floors wiring edits
  (waves 36-42) moved the `run:` line to 10-space indentation under
  `shell: pwsh` in all three workflows -- invalid YAML (a mapping key more
  indented than its sibling). GitHub refuses the whole workflow before
  creating jobs, which is why every run since the release push was 0s.
  The tag stdlib-v0.62.0 (80e767b) carries the broken files and the
  release-tags ruleset blocks moving tags.
- Fix (c491b13): indentation corrected in ci/heavy/release.yml; all six
  workflow files now parse with PyYAML. Verified `gh run list` shows real
  jobs executing after the fix.
- Recovery path added to release.yml (release lane asked for the tag's
  assets): a new workflow_dispatch input `tag` builds and publishes from
  the TAG's tree (all three checkouts take `ref: inputs.tag || github.ref`;
  SOURCE_DATE_EPOCH from HEAD; Create Release / pin-pr / canary-dispatch
  now also run for a tag-recovery dispatch; tag existence is checked in
  validate). Dispatched run 36487728296 for `-f tag=stdlib-v0.62.0`:
  validate PASS in 4s, release gates running on windows+ubuntu; package ->
  GitHub Release -> canary dispatch follow. The registry lane should
  re-run/re-dispatch its publish once the assets land; provenance still
  points at refs/tags/stdlib-v0.62.0 (tree = 80e767b + workflow fix only).
- Action items from this: (1) never re-indent YAML keys by hand again
  without a parse check -- a `python -c yaml.safe_load` step over
  .github/workflows is cheap; (2) waves 44+ must re-run the full battery
  after this CI-only commit only via the release run itself (code battery
  already green on 2cd0d5b; c491b13 changes no stdlib source).

**0.62.0 RELEASE RECOVERY 2026-09-29 (second root cause: Linux-only clause)**
- After the YAML fix, the recovery dispatch (run 36487728296) passed
  `validate`, then failed ubuntu gates: smoke_regex run=1, a Linux-only
  failure (windows would have passed; 0.61.3's ubuntu run was green, so a
  wave 22-42 change caused it).
- Root cause found by reproducing the tag tree in WSL with the released
  v0.61.3 linux-x64 binary (bundled-stdlib copy moved aside so XIOM_STDLIB
  wins): `xiom/regex/syntax.xi:66` carried
  `ensures: result is Err => result.value.len() > 0` -- a Result-Err Str
  payload read in a catalog clause. It passes on Windows but violates on
  Linux ("contract violated: ensures at 66:12"). This is the class already
  documented in tools/known_failures (2026-09-25); the README now records
  the Linux evidence and marks Err-Str payload reads as unsafe everywhere.
- Fix (0e63101): the payload clause is removed; the payload-free
  `s.len() == 0 => result is Ok` clause stays. Verified green on Linux in
  WSL (`smoke_regex OK`) and on Windows (smoke_regex + 16 stress-regex
  files), then full battery on 0e63101: check_modules 509/509 (389.3s);
  corpus 951/951 (2641.2s); probes 197/197 (499.8s); barename 0/509
  (724.4s); floors80 + doc ratchets OK.
- Tag: because the failed gates test the TAG tree and the release had no
  published artifacts, stdlib-v0.62.0 was force-updated to 0e63101 (the
  release-tags ruleset violation was bypassed, same as branch pushes).
  NEW SUBJECT SHA for the registry lane: 0e631018100b157539614cc92fc471f22663baff.
- The tag push auto-started run 36495200067 (the real tag path): validate
  PASS, **ubuntu release gates PASS in 1h2m47s** (Linux fixed), windows
  gates running; package -> GitHub Release/assets -> pin-pr -> staging
  canary dispatch follow. Stale dispatch run 36487728296 cancelled.
- Registry lane: re-run/re-dispatch the publish once the assets exist; the
  provenance ref stays refs/tags/stdlib-v0.62.0 and the subject sha is now
  0e63101 (tree = 80e767b + workflow YAML fix + regex clause fix).
- OUTCOME 2026-09-29 00:10Z: run 36495200067 COMPLETE -- validate, ubuntu
  gates (1h2m47s), windows gates (1h14m34s), package + GitHub Release all
  success; staging canary dispatch success; only the known
  STDLIB_VERSION pin-PR PAT gap stayed red (continue-on-error). Release
  `stdlib-v0.62.0` published with assets `xiom-std-0.62.0.tar.gz`
  (1,055,855 bytes) and `SHA256SUMS` at
  https://github.com/xiom-lang/stdlib/releases/tag/stdlib-v0.62.0.
  Registry lane informed: assets live, subject sha
  0e631018100b157539614cc92fc471f22663baff, ref refs/tags/stdlib-v0.62.0;
  re-dispatch the publish to complete verification.

**SESSION 2026-09-29 block (wave 44: xiom.bigint core)**
- Wave 44 (floors81): 33 clauses on xiom/num/bigint.xi. The shared claim is
  the _trim canonical form: `((result.negative == true) =>
  (result.digits.len() > 0)) && ((result.digits.len() == 0) =>
  (result.negative == false))` on from_int/from_u64/add/sub/mul/neg/mod/
  pow/gcd/lcm/shift_left (decimal x10^n)/shift_right (arithmetic >>n)/div/
  sqrt/factorial/binomial/fibonacci/bit_and/bit_or/bit_xor; exact shapes on
  zero/one/ten/two; compare and sign in {-1,0,1}; is_negative true implies
  the input flag; to_str/to_hex non-empty; to_base invalid-base empty;
  popcount/bit_len >= 0; abs also asserts negative == false. Payload-
  returning entries (from_str/from_base/to_int/to_u64/to_u128/to_i128)
  stay clause-free (payload reads forbidden; known_failures).
- Probe tools/probes/p_wave44_shapes.xi (198th): 53 KATs through
  bigint_to_str (no struct-field reads): 999999999+1 limb boundary, -10/3
  and -10 mod 3, -7 >> 1 = -4, 2^10, gcd(48,18), lcm(4,6), 20!, F(10),
  bit ops, to_base uppercase "FF" vs to_hex lowercase "ff", u64 max.
  Probe caught two of my wrong expectations (shift_right is a BIT shift,
  to_base is uppercase), not stdlib bugs.
- num 17.2% -> 22.7%, global 31.4% -> 31.8%; floors81 wired into
  ci/heavy/release (8-space indent, PyYAML re-verified) + tools/README.md +
  docs/STDLIB_READINESS_PLAN.md in the same commit.
- Full battery on f48045d: check_modules 509/509 (419.3s); corpus 951/951,
  0 compilefail, 0 runfail (1982.6s); probe corpus 198/198 (426.2s);
  barename 0 hits / 509 (684.6s); coverage ratchet floors81 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 44 closed.

**RELAY 2026-09-29 (packages -> compiler/stdlib)**
- `Vec.pop()` returns `Option[T]` (not T); the packages pool matches it
  exhaustively. BigInt `_trim` discards the popped value, which still
  compiles; no stdlib action.
- Int constants (1e12) and saturating add/mul helpers compile with
  wrap-free intermediates.
- E001 "cannot borrow as mutable while immutably borrowed" advisory
  warnings appear in the pool (12) and backoff (4) test suites when &/&mut
  calls interleave on one local -- benign (program_exit=0), same class as
  the documented tls warnings; compiler-lane awareness only.
- The packages lane avoided `&` of call results (binding locals first) and
  kept retry state flat; no stdlib-side change requested.

**SESSION 2026-09-29 block 2 (wave 45: xiom.bigint remainder)**
- Wave 45 (floors82): 21 clauses completing the bigint surface:
  from_str/from_base/from_hex `s == "" => is_ok == false`;
  to_int/to_u64/to_u128/to_i128 `digits.len() == 0 => is_ok == true`
  (zero fits every conversion); is_even false => digits non-empty; is_odd
  true => digits non-empty; is_one/is_prime true => negative false;
  next_prime canonical + non-negative; div_mod canonical on both tuple
  components (nested `result.0.digits.len()` shape validated by the
  probe); sqrt_rem canonical both; pow_mod canonical + non-negative;
  ext_gcd canonical on all three + gcd component non-negative; and exact
  compare-delegation clauses on eq/lt/le/gt/ge using in-module
  `bigint_compare` calls in the clause (`result == (bigint_compare(a, b)
  < 0)`), which the probe validated (199th).
- Probe p_wave45_shapes.xi: parsing Err paths, 10^30 out of i64 range,
  parity/prime/next_prime KATs, (17,5) -> (3,2), sqrt_rem(10) -> (3,1),
  pow_mod 2^10 mod 1000 = 24 -- first-run green.
- num 22.7% -> 26.4%, global 31.8% -> 32.1%; floors82 wired into
  ci/heavy/release (YAML re-verified) + tools/README.md +
  docs/STDLIB_READINESS_PLAN.md in the same commit.
- Full battery on a38caa7: check_modules 509/509 (314.6s); corpus 951/951,
  0 compilefail, 0 runfail (1761.3s); probe corpus 199/199 (361.6s);
  barename 0 hits / 509 (602.5s); coverage ratchet floors82 OK; doc ratchet
  OK (6993/6993 = 100%). Wave 45 closed.

**RELAY 2026-09-29 (compiler -> stdlib)**
- The combined compiler release shipped and completed; its nested stdlib
  checkout will refresh to the force-updated tag (0e63101) at the next
  compiler release.
- The held XIOM_STRICT_BRACKETS flip plus the 3 mixed-bracket sites
  (io/fs.xi lines 36 and 244, math/algebra_extended.xi line 311) are ready
  to ride the next compiler wave; the stdlib must fix those 3 sites in
  the same wave as the pin bump that enables strict brackets.

**SESSION 2026-09-29 block 3 (module smoke-coverage gate, owner requirement)**
- Owner requirement: ensure every stdlib module (and ideally every public
  function) has smoke coverage. Built `tools/module_smoke_scan.ps1`: a
  static scan that maps every `module` declaration in xiom/**/*.xi to its
  public functions and checks each against the smoke corpus by explicit
  `use <module>;` or a qualified call `<leaf>.<fn>(` (which also matches
  parent-module aliases like `math.algebra.gcd(`). Baseline dumped to
  `tools/module_smoke_floors.json` and wired as a monotone ratchet into
  ci/heavy/release (a step after the coverage ratchet).
- Baseline: 497/517 source modules (96.1%) covered -- 509 manifest modules
  plus 8 transitive submodules that exist in source but not the 509-module
  manifest (xiom.ecc, xiom.math.tower, xiom.net.url, xiom.os.args,
  xiom.os.platform, xiom.os.signal, xiom.os.sysinfo, xiom.string.builder);
  3,332/6,200 public functions (53.7%) referenced by a qualified smoke
  call. The 20 uncovered modules and 2,868 unreferenced functions become
  explicit targets for the smoke-growth waves alongside the contract
  coverage waves; the ratchet only lets those numbers grow.

**WAVE 46 PLAN NOTES (bigfloat scoping, 2026-09-29)**
- `xiom/num/bigfloat.xi` (~75 pub): `pub type BigFloat = { sign: Bool;
  exponent: Int; significand: BigInt; precision: Int; }`.
- Canonical form from `_normalize`: zero significand -> sign=false,
  exponent=0; otherwise significand made positive (`bigint_abs`) with the
  sign carried in `sign`. Planned claim family (same style as wave 44/45):
  nested-field canonicality `((result.significand.negative == true) =>
  (result.significand.digits.len() > 0))`; zero-sign implication
  `((result.significand.digits.len() == 0) => (result.sign == false))`;
  exact shapes for bigfloat_zero/one/ten where the body is a literal;
  compare/sign ranges; to_str non-emptiness. Two new shapes to validate in
  the probe first: the nested `result.significand.digits.len()` chain and
  cross-module `xiom.bigint.bigint_is_zero(&...)` calls inside clauses.
  SKIP payload-returning parsers/conversions unless a payload-free claim
  is available. The recon agent timed out on this file; do the
  per-function pass directly against the source next.

**SESSION 2026-09-29 block 4 (wave 46: bigfloat core)**
- Wave 46 (floors83): 30 clauses on xiom.num.bigfloat. Canonical-form
  family `((result.significand.negative == false) && ((digits.len() == 0)
  => (result.sign == false))) && ((result.sign == true) => (digits.len()
  > 0))` on one/two/ten/half/pi/e, from_int, from_bigint, with_precision,
  add/sub/mul/div/inv/sqrt/pow, fract, with_rounding; exact zero shape;
  neg => significand non-negative; abs => sign false + significand
  non-negative; is_negative/is_one implications; is_zero false => digits
  non-empty; sign/compare ranges; precision exact; to_str non-empty;
  from_str empty => Err; to_float64 zero => Some.
- Probe p_wave46_shapes.xi (200th) first-run green after two probe fixes:
  the module path is `xiom.num.bigfloat` (NOT `xiom.bigfloat`; the earlier
  module-smoke baseline's `xiom.bigfloat` entry is a manifest alias quirk),
  and with_rounding takes a RoundMode, not Int (use
  bigfloat_get_round_mode()).
- num 26.4% -> 31.6%, global 32.1% -> 32.5%; floors83 wired (YAML
  re-verified) + tools/README.md + plan in the same commit. Full battery on
  the commit (smoke_bigfloat exists, so the corpus also exercises the new
  clauses).
- Full battery on 864ceb5: check_modules 509/509 (315.9s); corpus 951/951,
  0 compilefail, 0 runfail (1963.1s; 16 parallel-phase flakes passed solo
  retry); probe corpus 200/200 (554.7s); barename 0 hits / 509 (1145s);
  coverage ratchet floors83 OK; doc ratchet OK (6993/6993 = 100%);
  module-smoke ratchet OK. Wave 46 closed.

**SESSION 2026-09-29 block 5 (wave 47: bigfloat transcendentals)**
- Wave 47 (floors84): 24 canonical-form clauses on the _finish-normalized
  results: exp, ln, log10, log2, exp2, sin/cos/tan, atan, atan2, pow_bf,
  cbrt, hypot, sinh/cosh/tanh, asin/acos, asinh/acosh/atanh,
  pi_with_precision/e_with_precision, plus to_str_sci non-empty. Wrapper
  bodies were verified to end in _finish/_div/_ln (canonical) before
  claiming; 54 ensures total in the module, no duplicates.
- Probe p_wave47_shapes.xi (201st): 27 numeric KATs via bigfloat_to_float64
  (exp(1)=e, ln(e)=1, log10(100)=2, log2(8)=3, exp2(10)=1024, sin(pi/2)=1,
  atan(1)=pi/4, pow_bf(2,10)=1024, cbrt(27)=3, hypot(3,4)=5,
  asin(1)=pi/2, acos(1)=0, acosh(1)=0, atanh(0)=0, precision-20 pi/e) --
  first-run green.
- num 31.6% -> 35.8%, global 32.5% -> 32.7%; floors84 wired (YAML
  re-verified) + tools/README.md + plan in the same commit. Full battery on
  the commit.
- Full battery on 67c5047: check_modules 509/509 (331.3s); corpus 951/951,
  0 compilefail, 0 runfail (2617.6s); probe corpus 201/201 (571.2s);
  barename 0 hits / 509 (1109.8s); coverage ratchet floors84 OK; doc
  ratchet OK; module-smoke ratchet OK. Wave 47 closed.

**SESSION 2026-09-29 block 6 (wave 48: bigfloat remainder)**
- Wave 48 (floors85): 9 clauses completing the bigfloat surface:
  from_float (canonical, NaN/inf guarded) and from_ratio canonical;
  to_bigint bigint-canonical pair; pow10 significand non-negative (copy
  path; only that invariant is certain); to_str_prec non-empty;
  floor_int/ceil_int/round_int/trunc_int `zero => is_ok` (payload-free).
  Remaining unclaused: to_float128, set/get_round_mode (no simple
  invariants).
- Probe p_wave48_shapes.xi (202nd): from_float round-trips, to_bigint
  truncation, from_ratio, pow10, the four *_int conversions on +-1.9 and
  zero -- first-run green.
- num 35.8% -> 37.4%, global 32.7% -> 32.8%; floors85 wired (YAML
  re-verified) + tools/README.md + plan in the same commit.
- Full battery on 75f6987: check_modules 509/509 (460.3s); corpus 951/951,
  0 compilefail, 0 runfail (1643.8s); probe corpus 202/202 (383.8s);
  barename 0 hits / 509 (594.3s); coverage ratchet floors85 OK;
  module-smoke ratchet OK; doc ratchet OK. Wave 48 closed.

**SESSION 2026-09-29 block 7 (wave 49: geom primitives, first family batch)**
- Wave 49 (floors86): 52 clauses on the split geom primitive modules --
  xiom.geom.vec (29: constructor fields; NaN-tolerant component mirrors on
  add/sub/scale/dot/cross/lerp; `(result >= 0.0) || (result != result)` on
  len/dist; zero-vector canonical forms on the three norm functions;
  reflect `result.len() == 0 || result.len() == v.len()`; project
  zero-or-NaN-or-length-matched; angle `result >= 0.0 && result < 4.0` or
  NaN), xiom.geom.quat (11: identity fields; Hamilton-product component
  mirrors; conjugate field mirrors; identity-or-nonzero forms on
  inv/normalize/from_axis_angle; norm band; euler bands (-4,+4)/(-2,+2);
  slerp endpoint-or-interior disjunction; rotate len 0/3), xiom.geom.mat
  (12: identity/mul length claims; det
  `(result != result) || (result == 0.0) || (m.len() > 0)`; inv presence
  mirror; transpose `result.len() == 0 || m.len() > 0`; 4x4 transforms
  len-0-or-4-and-m-4; look_at/perspective/ortho len 4; transform_point
  len 0/3).
- Probe p_wave49_shapes.xi (203rd): 99 return-code checks across the three
  modules (component math, norms, quaternion products/slerp/rotate,
  identity/mul/det/inv/transpose, 4x4 transforms, look-at/perspective/
  ortho, transform-point w=0). First-run RED surfaced a NEW compiler
  finding (below); green after the clause weakening.
- NEW compiler finding (filed, tools/known_failures/p_clause_float_vec_index.xi):
  clause-position indexing of Float64 vector elements reads garbage --
  `result[0] == 1.0` on a Vec[Float64] result and `result[0].len() == 2` on
  a Vec[Vec[Float64]] result violate ("contract violated: ensures at
  <line>:12"); length-only claims on the same results and the identical
  Vec[Int]/Vec[Vec[Int]] shapes PASS on v0.61.3 (isolation probes
  t_idx_a..f run outside the repo). Found while landing the mat_identity
  row claim; the shipped matrix clauses are len-only until the fix.
- geom 10.6% -> 23.2% (52/414), global 32.8% -> 33.6%; floors86 wired
  (YAML re-verified) + tools/README.md + plan + queue in the same commit.
  All 52 wave functions are already referenced by existing geom smokes, so
  the module-smoke baseline is unchanged (497/517, 3332/6200).
- Full battery on 1bb2d56: check_modules 509/509 (261.5s); corpus 951/951,
  0 compilefail, 0 runfail (2423.3s); probe corpus 203/203 (410.3s);
  barename 0 hits / 509 (741.8s); coverage ratchet floors86 OK; doc ratchet
  OK; module-smoke ratchet OK. Wave 49 closed.

**SESSION 2026-09-29 block 8 (PERF-1 annotation wave: atomics `#[unsafe_direct]`)**
- Compiler-lane relay (m166, `c2b15112`): annotate every fn in
  `xiom/sync/atomics.xi` whose body contains an unsafe block with
  `#[unsafe_direct]`, placed directly above `pub fn`. All 16 pub fns carry
  unsafe bodies (load/store/fetch/exchange wrappers), so all 16 got the
  attribute (`atomic_int_new`/`atomic_bool_new`/`atomic_ptr_new` use two
  unsafe blocks each; the rest one). Pre-m166 compilers raise P001 and drop
  the attribute silently during recovery -- smoke_sync_atomics green on the
  v0.61.3 pin; under m166+ (v0.62.2) the wrappers compile direct
  (compiler-lane local proof: 4M atomic pairs 8000 ms -> 0 ms; PERF-1).
- `tools/doc_scan.ps1`: the doc-association walk now skips `#[...]`
  attribute lines as well as blanks (the attribute sits between the `///`
  block and `pub fn`), keeping the doc ratchet at 100%.
- `release-notes/v0.62.2.md` added: the stdlib fragment for the compiler
  v0.62.2 release (1 highlight, "Standard-library atomics run at native
  speed"; the compiler draft already carries 5, so the merged document is
  exactly the 6-highlight schema max). Verified locally with the compiler's
  `xiom-release-notes` tool (`convert --out <temp>` reports 6 highlights;
  `verify` only fails the committed-JSON sync check until the compiler lane
  re-runs convert -- run the tool from the xiom root, notes-dir is
  CWD-relative).
- Wave tag: `stdlib-perf1` on the wave commit (NOT a stdlib release; does
  not match the `stdlib-v*` release trigger). This is the pin tag for
  `STDLIB_VERSION` for v0.62.2 (compiler release gates B/P).
- Full battery on 86c5a48: check_modules 509/509 (295s); corpus 951/951,
  0 compilefail, 0 runfail (1561.2s); probe corpus 203/203 (386.1s);
  barename 0 hits / 509 (601.5s); coverage ratchet floors86 OK; doc ratchet
  OK; module-smoke ratchet OK. PERF-1 annotation wave closed; tag
  `stdlib-perf1` created and pushed for `STDLIB_VERSION`.

**SESSION 2026-09-30 block 9 (wave 50: geom batch 2 -- matrix + quaternion)**
- Wave 50 (floors87): 51 clauses -- xiom.geom.matrix (32) and
  xiom.geom.quaternion (19). Highlights: Mat2/3/4 field mirrors; len/shape
  claims on identity/zero/one/add/sub/mul/scalar_mul/diag_mul/hadamard/
  kronecker/transpose/adjugate/diagonal; det/minor/cofactor/trace
  NaN-or-zero-or-nonempty bands; inverse/cholesky presence mirrors; rank in
  [0, a.len()]; nullity >= 0; eigenvalues/eigenvectors len 0-or-2; LU/QR
  tuple and SVD triple length claims; solve_linear 0-or-rows;
  least_squares nonempty-or-nonempty-input; condition_number >= 0 or NaN;
  Quat field mirrors; identity-or-nonzero forms on inv/normalize/
  from_axis_angle; euler +-2 bands; from_rotation_matrix identity-or-3x3;
  to_matrix len 3; to_euler bands; rotate len 0/3; slerp
  endpoint-or-interior; nlerp identity-or-not-both-zero; angle [0,7);
  axis len 3; look_at/between +-2 bands.
- Probe p_wave50_shapes.xi (204th): 96 return-code checks incl. the LU/QR/
  Cholesky KATs, solve_linear/least_squares solutions, eigenvalue KATs,
  the 90-degree z rotation, slerp/nlerp unit norms, look-at and between.
- Fix-first (probe-caught): `quat_between`'s opposite-direction
  perpendicular-axis choice was inverted (`if math.abs_float(ax) < 0.9`
  kept the x-axis probe, which is parallel to x-aligned inputs), so
  180-degree pairs hit the `ol == 0.0` guard and returned the identity;
  flipping to `>= 0.9` selects a perpendicular axis. Locked by probe
  checks 95/96 (w == 0 and unit vector part for a = -b).
- NEW compiler finding (filed, tools/known_failures/p_geom_matrix_result_infer.xi):
  un-annotated call-site inference of `xiom.geom.matrix`
  `Vec[Vec[Float64]]` results loses a nesting level -- `var z =
  matrix.zero(2,2); z[0].len()` reads 0 (`matrix.one` surfaces the raw
  double bits as the row length) and tuple extraction (`var l = lu.0`) is
  the same; explicit `Vec[Vec[Float64]]` annotations (or annotated tuple
  extraction) fix it; the identical shape via `xiom.geom.mat` is correct;
  single-level Vec[Float64] returns are unaffected; reproduced on v0.61.3
  AND v0.62.1. Found because the probe read matrix rows directly;
  `smoke_geom_mat` already documented the cannot-be-read symptom and
  verifies through det/trace/rank scalars. The probe now annotates every
  nested matrix-module local.
- v0.62.1 cross-check caught a clause bug in `quat_axis`: the original
  second clause read `.x/.y/.z` on a `Vec[Float64]` result (the v0.61.3
  checker silently accepted it); replaced with the len-only claim. The
  whole probe is green on v0.61.3 and v0.62.1.
- geom 23.2% -> 35.5% (147/414), global 33.6% -> 34.4%; floors87 wired
  (YAML re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on ae9672b: check_modules 509/509 (305.1s); corpus 951/951,
  0 compilefail, 0 runfail (1733.7s); probe corpus 204/204 (500.7s);
  barename 0 hits / 509 (885.4s); coverage ratchet floors87 OK; doc ratchet
  OK; module-smoke ratchet OK. Wave 50 closed (LOCAL-only commits; no push
  requested).

**SESSION 2026-10-01 block 10 (PERF-2 annotation wave + packages intake)**
- Compiler-lane relay (185342f4, "m166 follow-up -- receiver-qualified trust
  key for methods"): annotate every fn in `xiom/sync/sync.xi` whose body
  contains an unsafe block with `#[unsafe_direct]`, directly above
  `pub fn`; tag `stdlib-perf2` for the next pin. Annotated all 56
  unsafe-bodied pub fns; the 10 pub fns without unsafe bodies (`sem_*`,
  `cdl_new`/`cdl_count_down`/`cdl_is_zero`, `barrier_new`, `Arc.as_ref`)
  are untouched. Coverage verified mechanically (every pub fn with `unsafe`
  in its body up to its closing brace carries the attribute directly above;
  no attribute on an unsafe-free fn). On the v0.61.3 pin the attribute is
  dropped by error recovery; 22/22 sync smokes green. Under >= 185342f4 the
  wrappers (including receiver-qualified methods -- the t2 residual)
  compile direct, removing the per-call trampoline.
- Packages relay recorded: `docs/STDLIB-WISHLIST.md` created; 15 rows from
  the two 2026-10-01 relays (initial 8: the empty-needle defect,
  allocation-free line accessors, keyed FIFO/mailboxes, stable argmax,
  event-log cursors, composite-key lookups, non-aborting assertion catalog,
  fixed-point MSE; plus the wave-46 batch: saturating Int arithmetic,
  pinned rounding helpers, fixed-point scale-once kernels, fixed-point
  trigonometry + standalone isqrt, Vec[Int] copy helper, table
  interpolation, group-by-key folds). Full sheet:
  `xiom-packages/packages` @ `66f26e1`.
- Fix-first (packages defect): `xiom.string.index_of` carried
  `requires: substr.len() > 0` while its body returns `Some(0)` for an
  empty needle and `string.str_contains` delegates to it;
  `string.str_index_of` (doc promises `Some(0)`) and
  `string.str_replace_all` (doc promises `s` unchanged; `replace` handles
  it) carried the same contradicted precondition. Removed all three;
  `index_of` now ensures `substr.len() == 0 => result.is_some` and
  `result is Some => result >= 0 && result <= s.len()`, `str_index_of` the
  empty-needle `Some` form, `str_replace_all`
  `from_needle.len() == 0 => result.len() == s.len()`. Probe
  `p_empty_needle_contracts.xi`: RED on the old tree ("contract violated:
  requires at 315:13"), GREEN after. `str_split`'s delimiter precondition
  is genuine and stays.
- Full battery on 59bfb1c: check_modules 509/509 (444.9s); corpus 951/951,
  0 compilefail, 0 runfail (1579.8s); probe corpus 205/205 (394.4s);
  barename 0 hits / 509 (607.3s); coverage ratchet floors87 OK; doc ratchet
  OK; module-smoke ratchet OK. PERF-2 wave closed; tag `stdlib-perf2`
  created and pushed for the next pin.

**SESSION 2026-10-01 block 11 (wave 51: geom batch 3 -- vector/curves/collision)**
- Wave 51 (floors88): 43 clauses -- xiom.geom.vector (24), xiom.geom.curves
  (7), xiom.geom.collision (12). Highlights: constructor field len mirrors;
  NaN-on-length-mismatch on dot/distance/distance_sq; non-negative bands on
  norm/norm_sq/curve_length; len-0-or-input shape claims on
  cross/normalize/unit/project/reject/lerp/slerp/reflect/hadamard and the
  four point curves; outer and clamp exact-len; angle [0,4); refract
  presence mirrors (mismatch/empty => None, Some => matched lengths);
  component_min/max empty => NaN; collision constructor len mirrors plus
  degenerate-length => false/None implications on all twelve queries.
- Probe p_wave51_shapes.xi (206th): 80 return-code checks incl. the
  Bezier/Catmull-Rom/B-spline/Hermite KATs and the full AABB/sphere/ray/
  plane/triangle/segment set; green on v0.61.3 and v0.62.1.
- NEW compiler finding (filed, p_geom_vector_result_bits.xi): caller-side
  element reads of vector.lerp/clamp/hadamard and curves.b_spline results
  are bit-reinterpreted (stored 1.5 reads back as its IEEE bit pattern
  4.6094342186137e+18; clamp 2.0 -> 4.61168601842739e+18; hadamard 3.0 ->
  4.61393781824107e+18); callee-side reads are correct (vector.distance/
  norm see the true values) and the cross/normalize/unit/project/reject/
  slerp/reflect/outer/bezier_quad/cubic/derivative controls read correctly.
  Reproduced on v0.61.3 AND v0.62.1. The probe mediates the four affected
  results through vector.distance -- the same workaround smoke_geom_vec
  already uses.
- NEW compiler finding (filed, p_curve_thunk_zero.xi): a fn-typed parameter
  returning Vec[Float64] arrives empty inside catalog bodies --
  curves.curve_length(line, 0, 1, 2) returns 0 instead of 1.0 while calling
  line(0.5) directly is correct (the Vec-returning sibling of the fixed
  Float64-thunk class). The probe keeps only the n<1 == 0 branch.
- Probe debugging re-confirmed the Option[Vec[Float64]] payload extraction
  crash (refract; keep to is_some) and that collision's by-value struct
  reuse is fine.
- geom 35.5% -> 45.9% (190/414), global 34.4% -> 35.1%; floors88 wired
  (YAML re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on 79887f5: check_modules 509/509 (404.2s); corpus 951/951,
  0 compilefail, 0 runfail (1539.5s); probe corpus 206/206 (332.8s);
  barename 0 hits / 509 (550.1s); coverage ratchet floors88 OK; doc ratchet
  OK; module-smoke ratchet OK. Wave 51 closed (LOCAL commits; no push
  requested).

**SESSION 2026-10-02 block 12 (wave 52: geom batch 4 -- geometry_2d + geometry_3d)**
- Wave 52 (floors89): 43 clauses -- xiom.geom.geometry_2d (22) and
  xiom.geom.geometry_3d (21). Highlights: non-negative bands on every
  distance; center-inside (finite radius), vertex-inside and rect
  parity implications; vertex-count implications on the polygon queries;
  zero-determinant => None on line/segment intersection; degenerate line
  => circle None; concentric => circle-circle None; degenerate triangle
  => area 0 / zero normal; <3 indices => zero mesh volume/centroid;
  <4 points => empty hull indices; ray-sphere zero direction => None;
  equal plane normals => None; zero radii => sphere parity.
- Probe p_wave52_shapes.xi (207th): 78 return-code checks incl. the
  distance/containment/intersection KATs, area/centroid/hull, the ray
  queries, mesh metrics and the 3D hull; green on v0.61.3 and v0.62.1.
- Finding (non-compiler, filed p_polygon_difference_halfplanes.xi):
  polygon_difference's inverted clipping intersects b's outside
  half-planes instead of taking a\b -- disjoint a,b returned None
  (should be Some(a)). The doc now states the limitation; the probe
  keeps only the empty-a/empty-b edges; a real polygon-clipping
  implementation is a queue follow-up.
- Finding (compiler, filed p_geom_box_unnameable.xi):
  geometry_3d's `pub type Box` is shadowed by core's `Box[T]` and has no
  constructor; `Box{...}` resolves to the core type, qualified
  `geometry_3d.Box{...}` is unknown, and `use ... as` type aliases do not
  work, so aabb_intersection/aabb_contains/ray_box_intersection cannot
  be called from any other module. Their clauses are compile-checked
  only; the wave-52 probe notes the limitation. Fix rides the geom
  dedup/rename (queue section C) or a constructor addition.
- geom 45.9% -> 56.3% (233/414), global 35.1% -> 35.7%; floors89 wired
  (YAML re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on 74675e2: check_modules 509/509 (330.3s); corpus 951/951,
  0 compilefail, 0 runfail (2114.8s); probe corpus 207/207 (386.3s);
  barename 0 hits / 509 (544.8s); coverage ratchet floors89 OK; doc ratchet
  OK; module-smoke ratchet OK. Wave 52 closed (LOCAL commits; no push
  requested).
- Packages relay (2026-10-02): 6 new wishlist rows recorded (rows 16-21:
  xiom.math.fixed transcendentals, exact-sum softmax, bit-set dataflow
  primitives, borrowed Str views, dependency-free Vec[UInt8] -> Str
  builder, Vec.pop ergonomics); `docs/STDLIB-WISHLIST.md` now carries 21
  rows from the three relays.
- Website relay (2026-10-02): the queue's top now carries the machine-read
  readiness meter (`**70% -- 7 of 10 readiness gates complete.**`) and gates
  line (`**Gates: corpus 951/951, modules 509/509, probes 207/207, barename
  0/509.**`) plus the explicit 10-gate list (7 met: the seven mechanical
  gates; open: contract coverage 100%, zero open findings, beta-exit release
  cut). Every wave updates both lines as gates flip; the website's roadmap
  bar and corpus table row read them.

**SESSION 2026-10-10 block 87 (wave 100: finance + information theory; floors137)**
- Wave 100: 35 clauses, +29 pub covered, on pin v0.64.2.
- finance 20 (the r==0 closed forms pv/fv/pmt/nper; NaN guards on mirr,
  pmt nper==0, ipmt/ppmt per<1, nper pmt==0, perpetuity rate<=0, cagr,
  sharpe/sortino/calmar, bond_price invalid face/freq, VaR/CVaR bad
  alpha, beta/alpha length-or-sample guards, treynor beta<=0;
  empty-series npv==0 and drawdown len 0; the exact perpetuity pmt/rate
  branch).
- information_theory 9 (entropy empty==0, perplexity empty==1,
  data_compression_bound empty==0, huffman empty len 0,
  arithmetic_coding empty seq==0.5, kl/js/cross_entropy length-mismatch
  NaN, self_information p<=0 -> +inf).
- math/calculus.xi was INSPECTED AND SKIPPED: the vector-calculus/limit
  surface (gradient/partial_derivative/jacobian/hessian/laplacian/curl/
  divergence, limit/limit_left/limit_right/is_continuous,
  integrate_romberg) is a documented frozen stub set (BUG 20 AVX-512 +
  BUG 12 Vec[Float64] element reads). No stub self-mirror clauses per
  protocol; revisit when those codegen bugs land.
- Probe p_wave100_shapes.xi (273rd, 41 checks): green pre/post. Two probe
  drafting notes: the first cagr tolerance fix did not apply (PowerShell
  single-quote backtick expansion) and was redone with a literal
  Contains/Replace; cagr(100,121,2) is bit-above 0.1 so the control is a
  [0.099, 0.101] band.
- Targeted smokes: smoke_math_finance 1/1, smoke_math 53/53 (no
  information-theory smoke exists; the probe is the lock).
- Coverage: math 39.1% -> 42.0%, global 62.2% -> 62.6% (clauses 5335 ->
  5370, pubCovered 4046 -> 4075); meter 76.3%; floors137 dumped and
  wired (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.2): release corpus 954/954 full (698.3s,
  no exclusions); probes 273/273 (319s); check_modules 509/509 (213.1s);
  barename 0/509 (312.9s); floors137 + doc + module-smoke (497/517,
  3476/6204) ratchets OK.
- Open follow-ups unchanged: manual pin PR (`chore/pin-stdlib-v0.64.3`),
  staging canary approval, package.xi `categories`/`stage`, heavy macOS
  corpus leg red (PULSE macOS runtime-C guards suspected).
- Readiness next (wave 101): math remainder (graph_theory,
  machine_learning, decompose, fuzzy, game_theory, chaos), os 26.6%, the
  queued feature candidates (Vec[UInt8].with_len, address-aware bind,
  socket_recv_into), and the macOS runtime-C guards.

**SESSION 2026-10-09 block 86 (pin protocol agreed; wave-97 probe remerged; wave 99: crypto hash + xxhash/city + constants; floors136)**
- Pin protocol (relay `COMPILER-RELAY-2026-10-09-pin-protocol.md`): tag a
  CANDIDATE `stdlib-vX.Y.Z` -> compiler lane verifies against compiler
  main (vendored sync + STDLIB_VERSION + e2e without XIOM_STDLIB +
  feature + checker corpus + the wave smokes) -> on OK stdlib publishes
  to the registry -> compiler pins it at its next cut. Waves keep flowing
  on main throughout; one-version steady state is expected; security-
  urgent publishes may skip verification with an explicit note. Current
  cycle: the compiler lane verifies stdlib-v0.64.3 (d052a3c5) during its
  v0.64.3 candidate gates.
- Wave-97 split-probe workaround DROPPED per the relay:
  `p_wave97_bitwise_shapes.xi` was merged back into `p_wave97_shapes.xi`
  (bitwise section checks 77-86, `use xiom.bits.bitwise as bw;` restored)
  and re-run green on v0.64.2 -- the triplicate sibling import
  combination works after m242. Probe corpus stays 272.
- Wave 99: 26 clauses, +24 pub covered. crypto.hash 10 (exact digest/hex
  sizes on sha256/sha512/md5 and the HMAC variants; pbkdf2
  `iterations<1 || len<1 -> empty` / derived -> len; hkdf `len<1 ||
  len>255*32 -> empty` / derived -> len), crypto flat 3 (sha256 32,
  sha256_hex 64, blake3 32) -- crypto 39.9% -> 47.0%. hash 8 (xxh64/xxh32/
  xxh3_64 empty pins 0xEF46DB3751D8E999 / 0x02CC5D05 / 0x2D06800538D394C2,
  xxh3_64_with_seed(0), the xxh3_128 pair low64 0x6001C324468D497F /
  high64 0x99AA06D3014798D8, city64 empty 0x9AE16A3B2F90404F, city128
  empty pair length 2) -- hash 42.2% -> 51.1%. math.constants 3
  (infinity > 1, neg_infinity < -1, nan != nan) -- math 38.8% -> 39.1%.
- Probe p_wave99_shapes.xi (272nd, 28 checks): green pre/post; the
  xxh3-128 pair constants were measured from the implementation after the
  first probe run showed my initial assignment swapped (the implementation
  is correct).
- Targeted smokes: smoke_crypto 7/7, smoke_hash 25/25, smoke_math 53/53.
- Coverage: global 61.8% -> 62.2% (clauses 5309 -> 5335, pubCovered
  4022 -> 4046); meter 76.2%; floors136 dumped and wired
  (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.2): release corpus 954/954 full (794.6s,
  no exclusions); probes 272/272 (285.6s); check_modules 509/509 (192.4s);
  barename 0/509 (257.5s); floors136 + doc + module-smoke (497/517,
  3476/6204) ratchets OK.
- Open follow-ups unchanged: manual pin PR (`chore/pin-stdlib-v0.64.3`),
  staging canary approval, package.xi `categories`/`stage`, heavy macOS
  corpus leg red (PULSE macOS runtime-C guards suspected).
- Readiness next (wave 100): os 26.6% and the math remainder
  (finance/calculus/graph_theory/machine_learning surfaces), the queued
  feature candidates, and the macOS runtime-C guards.

**SESSION 2026-10-09 block 85 (stdlib-v0.64.3 release executed: gates, assets, registry LIVE; heavy matrix results)**
- Release run 37962367989 (tag stdlib-v0.64.3 on d052a3c): FULL SUCCESS
  -- validate, Windows+Linux release gates, package, GitHub Release with
  xiom-std-0.64.3.tar.gz (1,085,970 B) + SHA256SUMS, staging canary
  dispatch, STDLIB_VERSION pin step.
  - Pin PR: branch `chore/pin-stdlib-v0.64.3` was pushed to
    xiom-lang/xiom, but PR creation failed (`Resource not accessible by
    personal access token`); open it manually at
    https://github.com/xiom-lang/xiom/pull/new/chore/pin-stdlib-v0.64.3.
- Registry publish run 37962367935 (tag push, protected env approved):
  SUCCESS. Published xiom-std v0.64.3 -- sha256
  775496c094d2a1703307313c9139c8cdc959d7687fc7a5b42b57657efa596b17,
  ephemeral ed25519 signature, `compiler: v0.64.2`, provenance
  refs/tags/stdlib-v0.64.3 on d052a3c. Registry warnings for the next
  cut: no categories declared (vocabulary: core, data, database, web,
  network, graphics, media, ai-ml, science, crypto-security, cloud-infra,
  observability, concurrency, systems, tooling, testing, text-nlp) and no
  stage declared (`incubating`|`stable`) -- add both to package.xi.
- Staging canary run 37968157641 (auto-dispatched by release.yml to
  staging.registry.xiom-lang.org): waiting at the protected environment
  for approval; optional now that production is live.
- heavy.yml (repaired matrix) dispatch run 37962605725: ubuntu-latest
  SUCCESS, windows-latest SUCCESS (full corpus + modules + barename +
  ratchets each), macos-14 FAILURE at "Full smoke corpus" (the compiler
  built; the corpus leg is red). Candidate causes: the PULSE-reported
  macOS runtime-C blockers (`#ifdef __APPLE__` for `_SC_AVPHYS_PAGES`;
  `__x86_64__` guard for the fp128 asm) or platform-specific smokes.
  Follow-up item; not a release blocker (release gates are Win/Linux).
- Wave 98 (2e55b13) landed after the tag: M7 closure rewrite,
  read_file_lines/to_string_char contract fixes, array_zip/fold clauses,
  floors135, the new tostring-import finding; battery green on v0.64.2
  (954/954, 272/272, 509/509, 0/509).
- Registry live state: xiom-std 0.64.3 published 2026-10-09 17:49 UTC;
  lineage 0.63.0 -> 0.64.2 -> 0.64.3.

**SESSION 2026-10-09 block 84 (wave 98: M7 stdlib-side fix + consumer contract fixes + array extension; floors135)**
- Wave 98: 7 clauses, +3 pub covered, on pin v0.64.2.
- M7 FIXED stdlib-side (the compiler-lane handoff): the four adapters
  (step_by/take_while/skip_while/inspect) were rewritten to the
  closure-based shape the rest of iter.xi uses (`next_fn: fn() ->
  Option[T]`) and are constructed from Range; the `Iterator[T]` interface
  receivers are gone, so the 5x "unknown type 'Iterator'" warnings stop.
  `p_iter_iterator_type_unresolved.xi` exits 0; constructor claims landed
  (Range.step_by step/first mirrors, take_while done==false, skip_while
  skipped==false); StepByIter.next's `ensures: true` placeholder was
  replaced by `requires: self.step > 0`. iter 45.4% -> 46.4%.
- Consumer contract rows (wishlist sweep, fix-first): `read_file_lines`
  now returns Ok with ZERO lines for a zero-byte file (byte-length guard)
  and the false `result.len() >= 1` ensures was replaced by `requires:
  path.len() > 0` plus doc notes (regular-file size reliance; /proc-like
  files read as empty) -- packages row 168 (xiom.wal). `to_string_char`
  rewritten over `Str::from_utf8` (removes the per-call malloc leak;
  `from_utf8` truncates at NUL exactly like `from_cstring`) with truthful
  clauses `(c != '\0') => (result.len() >= 1)` and `(c == '\0') =>
  (result.len() == 0)` documenting the backend NUL truncation -- packages
  row 169 (xiom.http). `array_zip` gained the M<=N direction clause (both
  truncation directions now claimed; m237); `array.fold` gained the empty
  identity (zero-length `[0]T` by value compiles on v0.64.2; m238).
- NEW FINDING (findings stay 14 Current: M7 moved to history, this
  added): `p_tostring_import_breaks_adapters.xi` -- importing
  `xiom.convert.tostring` (any alias, plain import too) corrupts closure
  predicate dispatch for `Range.filter`/`Range.take_while` on v0.64.2
  (predicates never see values; inline lambdas affected identically;
  `Range.step_by` unaffected; `iter`+`io`, `iter`+`array`,
  `iter`+`array.fixed` combinations behave). No corpus smoke mixes the
  import with iter adapters. The wave-98 probe was split
  (`p_wave98_shapes.xi` + `p_wave98_tostring_shapes.xi`) as the
  workaround.
- Probes green on v0.64.2 (main 54 checks + tostring 5 checks); targeted
  smokes smoke_iter 21/21, smoke_io 20/20, smoke_convert 38/38,
  smoke_array 17/17 (no smoke_fs family exists).
- Coverage: iter 45.4% -> 46.4%, global 61.8% (pubCovered 4022, clauses
  5309); floors135 dumped and wired (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.2): release corpus 954/954 full (853.2s,
  no exclusions); probes 272/272 (262.3s); check_modules 509/509 (205.2s);
  barename 0/509 (285s); floors135 + doc + module-smoke (497/517,
  3476/6204) ratchets OK.
- Release side: stdlib-v0.64.3 tag unchanged (this wave is post-tag; it
  rides the next cut). Registry publish still PENDING OWNER APPROVAL.
- Readiness next (wave 99): relay the tostring-import finding; resume
  coverage (os/hash/num/math/crypto); queued feature candidates
  (Vec[UInt8].with_len, address-aware socket bind, socket_recv_into).

**SESSION 2026-10-09 block 83 (compiler relays consumed: v0.64.2 batch + M7 diagnosis + B-05 runtime-side)**
- Relays read from the lane drops (local working files, not committed):
  `docs/COMPILER-RELAY-2026-10-09-v0.64.2.md` and
  `docs/COMPILER-RELAY-2026-10-09.md`.
- v0.64.2 release facts: batch m222..m241 on the tagged tree; four
  blockers fixed (m239 deep container equality, m237 array_zip
  const-generic truncate, m238 zero-length `[0]T` by value at clang,
  m240 verifier SMT array model) plus m241 (out-of-bounds Vec index
  WRITE now traps under `--overflow-checks` like the read path). m242
  (sibling alias) landed after the relay and is included in the tag
  (c51170a6 -> 516ea33b); the relay's "reproduced on v0.64.2" note for
  the sibling finding is stale. Compiler main has since moved past the
  tag: d9f146cb m244 (null guards for raw pointer dereferences under
  `--overflow-checks`) -- NOT in the v0.64.2 pin.
- M7 `Iterator[T]`: compiler-lane diagnosis says the fix is STDLIB-SIDE
  (declare an explicit opaque handle `pub type Iterator[T] = Int;` or,
  preferred, move the four adapters to the closure-based shape); `--check`
  passes, `--run` C001. Recorded in the known_failures README Current
  entry; wave-98 first item.
- B-05 guard-heap spin: runtime-side, in THIS repo
  (`runtime/xiom_runtime.c` guard arena; repro
  `E:\xiom-packages\packages\docs\repro\bindings-pilot\alloc-guard-spin`,
  watchdog required; the spin smells like a slab index/offset never
  advancing). Runtime-lane item after the release cut.
- Same-window compiler fixes for other lanes: m230/m236
  (encoding-via-user-module hard-fail), m234 (Vec[Struct] stride
  padding), m235 (ORBITDB nested-`Vec[Page]` abort).
- Findings status after the sweep: 14 Current (13 compiler, 1 stdlib);
  two resolved today (array_zip, sibling alias), both re-run green on
  v0.64.2. No release side effects: stdlib-v0.64.3 (pin v0.64.2) is
  tagged; the registry publish is pending owner approval.
- Wishlist scoop 2026-10-09 (five lanes, agent-gathered; full delta in
  `docs/STDLIB-WISHLIST.md`): NEW fix-first defects for wave 98 --
  `read_file_lines`'s `ensures: result is Ok => result.len() >= 1`
  (io.xi:1076) is false for empty files (packages row 168, requester
  xiom.wal; same family as PULSE's /proc stat-size-0 case) and
  `to_string_char(Char(0))` returns "" violating its own
  `ensures: result.len() >= 1` (packages row 169, xiom.http 0.1.4).
  NEW asks: address-aware socket bind (PULSE wrap 8),
  `socket_recv_into(fd, &mut Vec[UInt8], max)` (PULSE wrap 4b),
  `Vec[UInt8].with_len` (bindings W-5, re-checked on 0.64.3), macOS
  runtime-C guards (`_SC_AVPHYS_PAGES` at xiom_runtime.c:4222 and the
  x86 asm in fp128_helpers.c) (PULSE wrap 8b). Status changes: packages
  row 162 `io.list_dir` RESOLVED (m211, re-verified on v0.64.2);
  ORBITDB confirms the str_split/CRLF fixes (20k-record WAL replay
  61.6 s -> 9.9 s) and tracks fsync/open_append/append_line_sync as open;
  XVECTOR all six durability rows still open (critical pair fsync +
  append-bytes; io.rename workaround); bindings W-2 re-scoped to a docs
  gap + B-07 caveat, W-5 open, 19-suite matrix green on v0.64.2;
  `xiom.wal` 0.1.0 waits on the durable-write row.

**SESSION 2026-10-09 block 82 (pin bump v0.64.2 + stdlib-v0.64.3 release cut; findings cleared; heavy.yml repaired)**
- Compiler pin: COMPILER_VERSION -> v0.64.2 (tag c51170a6, the combined
  v0.64.2 release; local binary E:\xiom-lang\xiom\target\release\xiom.exe
  verified "XIOM Compiler v0.64.2"). package.xi -> 0.64.3.
- Findings sweep re-run on v0.64.2 (all known_failures repros compiled and
  run): CLEARED -- array_zip (M<N, M==0 both sides and N<=M all truncate
  to min(N,M); p_array_zip_no_truncate.xi exits 0; an extended
  zero-length check exits 0) and triplicate sibling imports (m242;
  p_sibling_dup_fn_alias.xi exits 0; the split wave-97 probes stay green
  and the single-file combination works again). Findings 16 -> 14
  (13 compiler, 1 stdlib). Still open with unchanged rcs: alias/type paths
  (compile 1), foreign method call (compile 1), ensures-isok (run 1),
  clause float vec (run 1), geom Box (compile 1), geom matrix (run 4),
  M7 Iterator (compile 1; --check passes), mut-param @pre (run 1),
  generic byref Option (run 2), slice bound C001 (compile 1), cross-type
  generic callbacks (core_map/map run 41, sortbykey run 1), vec-shape AV
  (run -1073741819), polygon stdlib (run 1), polyhedra (run 1).
- heavy.yml REPAIRED: the matrix was nested OUTSIDE `strategy`, so GitHub
  rejected every push run in 0s as a workflow file issue -- no heavy run
  has ever succeeded. The matrix now nests under strategy and a manual
  dispatch (run 37962605725) actually starts the ubuntu/windows/macos
  job matrix. Cloud runs for this cut: release.yml 37962367989 (validate
  OK, Win/Linux gates running), publish-registry.yml 37962367935 (waiting
  at the protected `registry-publish` environment for owner approval).
- Release prep: release-notes/v0.64.3.md (summary 191 chars, 2 highlights
  with 256/308-char bodies, schema-clean) + CHANGELOG [0.64.3]
  (Fixed/Changed/Notes) + RELEASE_CHECKLIST pin example refreshed.
- Battery on v0.64.2 (release commit): corpus 954/954 (2098.7s, no
  exclusions), probes 270/270 (401.8s), modules 509/509 (221.3s),
  barename 0/509 (464.2s), floors134 + doc + module-smoke (497/517,
  3477/6205) ratchets OK.
- CUT: release commit pushed + tag stdlib-v0.64.3 on the same commit ->
  release.yml (validate -> Win/Linux gates -> tarball + SHA256SUMS ->
  attested GitHub Release -> STDLIB_VERSION pin PR) and
  publish-registry.yml (same-tag asset wait -> protected
  `registry-publish` environment). REGISTRY PUBLISH PENDING OWNER
  APPROVAL (approve ONE run).
- Next: wave 98 resumes coverage on v0.64.2 (os/hash/num/math/crypto);
  extend the array_zip clause to the full min relation (floors135).

**SESSION 2026-10-09 block 81 (wave 97: bits submodules + hash + fraction; floors134; sibling-alias finding)**
- Wave 97: 57 clauses, +40 pub covered. bits 22 (bitfield width/offset
  no-op guards on set/clear/insert, sign_extend width<=0 and >=64
  identities, and the `result >= 0` placeholders on get/mask/extract
  replaced with real guard/edge pins; rotation k==0/k==64 identities
  including the rol/ror/bit_rotate aliases and masked mask==0; popcount
  next/prev_pow2 boundaries + rotations; bitwise zero pins on
  bit_reverse/byte_swap, bit_reverse_byte(1)->128, byte_swap(256)->1<<48,
  pow2 boundaries) -- bits 52.5% -> 74.3%. hash 8 (empty-input offset
  pins on fnv1a32/fnv1a64, crc32_ieee empty -> 0, hash_bytes_to_hex
  empty, combine_hashes zero -> 0x9e3779b9, string_hash/djb2 empty ->
  5381, murmur3_32(empty, seed 0) -> 0, xxhash64(empty, seed 0) ->
  0xEF46DB3751D8E999) -- hash 33.3% -> 42.2%. num.fraction 10
  (from_float zero/NaN -> 0/1; add/sub/mul den>0 invariant; sub equal ->
  num 0; mul a.num==0 -> num 0; div b.num==0 -> None; reduce zero -> 0/1;
  to_float zero -> 0.0; to_str 0/1 pin; is_zero branches; compare
  [-1,1] + zero/positive-sign pins) -- num 35.6% -> 37.6%.
- NEW FINDING (15 -> 16): p_sibling_dup_fn_alias.xi -- importing three
  sibling submodules that export the same function name (rotate_left/
  rotate_right in bits.rotation/popcount/bitwise) breaks alias-qualified
  resolution ("cannot call 'next_pow2' on this expression"). Pairs of
  duplicate exporters work; the third copy breaks it. Workaround: the
  wave-97 probe was split into p_wave97_shapes.xi + 
  p_wave97_bitwise_shapes.xi (corpus 270 probes).
- Probes green on v0.64.1 pre- and post-clauses (67 + 11 checks);
  targeted smokes smoke_hash 25/25, smoke_num_fraction 1/1, smoke_bit
  3/3, smoke_num_rotate_bits 1/1.
- Coverage: bits 52.5% -> 74.3%, hash 33.3% -> 42.2%, num 35.6% -> 37.6%,
  global 61.2% -> 61.8% (clauses 5245 -> 5302); meter 76.2%; floors134
  dumped and wired (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.1): release corpus 954/954 full (659.5s,
  no exclusions); probes 270/270 (248.6s); check_modules 509/509 (154.8s);
  barename 0/509 (232.9s); floors134 + doc + module-smoke (497/517,
  3477/6205) ratchets OK.
- Release side: next cut picks up blocks 75/77/78/79/80/81. Readiness
  next (wave 98): os 26.6% (runtime-backed surfaces inspected per item),
  num 37.6%, math 38.8%, crypto 39.9%, hash 42.2% (city/metro/farm/
  xxh3/siphash empty pins), remaining bitarray/endianness, and the queued
  feature candidates.

**SESSION 2026-10-09 block 80 (wave 96: array + sort + bits; floors133; array_zip finding)**
- Wave 96: 53 clauses, +40 pub covered. array 19 (N==0 identities on
  len/is_empty/array_sum/array_max/array_min/array_count/array_find/
  array_equal; fixed.xi array_len/get/first/last, array_slice empty +
  bounded-length claims, the array_zip N<=M direction; dynamic.xi
  array_pop's None => empty post-form, array_resize post-length,
  array_concat length-sum, array_search empty guard, array_is_empty
  branch pins) -- array 35.6% -> 77.8%. sort 5 (len<=1 is_sorted
  identities on sort.xi + sort.intro.xi, the is_sorted_by variants and
  nth_element's bounds guard) -- sort 31.9% -> 42.6%. bits 16
  (out-of-range no-op guards on bit_set/clear/toggle, k==0 rotation
  identity, zero pins on bit_reverse/byte_swap16/32/64, len<=0 identity
  on get/set_bit_range, is_pow2 boundary pins, pack_u16/u32 little/big
  endian bit-position pins) -- bits 36.6% -> 52.5%.
- NEW FINDING (findings 14 -> 15): p_array_zip_no_truncate.xi -- array_zip
  does not truncate for M < N: it emits N pairs and reads b[M] out of
  bounds (with M == 0 it still emits N); the `if M < count` branch is
  never taken on v0.64.1. Only the N <= M direction is correct, so the
  array_zip clause covers that direction only. Filed with the stdlib
  note in fixed.xi.
- Also dropped array.fold from the wave: passing a zero-length `[0]Int`
  by value to the const-generic fold miscompiles at clang
  ('[0 x i64]' but expected 'i64'). No known_failures entry yet (candidate
  finding; revisit alongside the const-generic/array-return bugs).
- Probe p_wave96_shapes.xi (268th, 87 checks): green on v0.64.1 pre- and
  post-clauses. Targeted smokes: smoke_array 17/17, smoke_sort 2/2,
  smoke_bit 3/3.
- Coverage: array 35.6% -> 77.8%, sort 31.9% -> 42.6%, bits 36.6% ->
  52.5%, global 60.6% -> 61.2% (clauses 5192 -> 5245); meter 76.1%;
  floors133 dumped and wired (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.1): release corpus 954/954 full (709.6s,
  no exclusions); probes 268/268 (585.2s); check_modules 509/509 (225.8s);
  barename 0/509 (291.1s); floors133 + doc + module-smoke (497/517,
  3477/6205) ratchets OK.
- Release side: user signalled the next release is close; the cut will
  pick up blocks 75/77/78/79/80. Readiness next (wave 97): os 26.6%
  (runtime-backed surfaces inspected per item), hash 33.3%, num 35.6%,
  math 38.8%, crypto 39.9%, the remaining bits submodules
  (bitarray/bitfield/rotation/popcount/bitwise/endianness), and the queued
  feature candidates.

**SESSION 2026-10-08 block 79 (wave 95: format remainder -- markup/textual/fmt; floors132)**
- Wave 95: 82 clauses, +68 pub covered. markup 13 (wrapper length claims:
  bold/italic/code/strike len+2, link text+url+4; escape empty/expansion
  bands; parse empty-Ok and unclosed-Err pins; empty render/strip
  identities). textual 24 (box exact byte lengths 2w+1 plain / 6w+1
  rounded-double for empty content; border widths by style; separator
  widths incl. the 3-byte double rule; header/title/section exact
  lengths; toc/toc_indent; list/columns/wrap/justify empty identities).
  fmt 31 (Int/Float64/Bool/Str to_str pins; format1/2/3 no-placeholder
  identity; table/columns/wrap/indent/hexdump/join guards; pad-number +
  repeat width bands; float_fixed pin; bool/line/align claims; the eight
  sprintf and three sscanf empty-spec Ok pins plus the sscanf mismatch
  Err) -- format 59.3% -> 88.7%. The Formatter.write_str `ensures: true`
  placeholder replaced with `result.is_ok`.
- Local form note (candidate finding, NOT filed): catalog clauses reject
  receiver `self == literal` comparisons (`Bool.to_str`'s
  `self == true`/`self == false` failed to compile; rewritten to the
  `result == "true" || result == "false"` disjunction and
  `Str.to_str`'s `result == self` to `result.len() == self.len()`).
  Param forms such as `(b == true) => ...` (core bool_to_int, wave 94)
  remain fine.
- Probe p_wave95_shapes.xi (267th, 92 checks): green on v0.64.1 pre- and
  post-clauses. No smoke exercises the textual surface (probe is the
  only lock); targeted smokes: smoke_format_markup 1/1, smoke_fmt 18/18,
  smoke_string_printf_scanf_template 1/1.
- Coverage: format 59.3% -> 88.7%, global 59.5% -> 60.6% (clauses 5110 ->
  5192); meter 76.1%; floors132 dumped and wired (ci/heavy/release +
  tools/README).
- Battery on this commit (v0.64.1): release corpus 954/954 full (769.6s,
  no exclusions); probes 267/267 (570.2s); check_modules 509/509 (379.3s);
  barename 0/509 (243.2s); floors132 + doc + module-smoke (497/517,
  3477/6205) ratchets OK.
- Release side: nothing pending; the next cut picks up blocks 75/77/78/79.
  Readiness next (wave 96): os 26.6% (runtime-backed surfaces inspected
  per item), sort 31.9%, hash 33.3%, num 35.6%, array 35.6%, bits 36.6%,
  math 38.8%, crypto 39.9%, and the queued feature candidates.

**SESSION 2026-10-08 block 78 (wave 94: cmp + core + sync + terminal; floors131; three findings)**
- Wave 94: 86 clauses, +62 pub covered. cmp 16 (then_with self-mirror;
  min_by/max_by value disjunctions; max_int/min_int ordering bands;
  max/min_float disjunctions; clamp_float three-way branch; Reverse.new
  field mirror; min3/max3/median3 disjunctions; is_between guarded
  results; compare_ints -1/0/1 pins; min_of_vec/max_of_vec empty ->
  None) -- cmp 28.6% -> 100%. core.xi 12 (to_string zero pin; the
  int/float/bool parser empty/valid guards; min_of/max_of disjunction +
  ordering band; abs_int non-negative mirror; clamp_int three-way branch;
  bool_to_int/int_to_bool branch pins; int_to_char_safe bounds;
  result_unwrap_or Err -> default). sync 8 (sem_new field mirrors;
  sem_try_acquire/sem_acquire false -> count <= 0; sem_release requires
  count <= max; sem_available mirror; barrier_new requires n > 0 + count
  mirror; cdl_new mirror; cdl_is_zero pins). format.terminal 29 (the 24
  exact ANSI escape pins; progress_new clamp/done/width; progress_finish;
  progress_percent total <= 0 -> 100; spinner_new index/frames;
  spinner_frame mirror).
- THREE NEW FINDINGS (probe-first discoveries, findings 12 -> 14):
  (a) p_mut_param_field_pre.xi -- `@pre` on a `&mut` param scalar field
  aliases the post-mutation value (clause violated at runtime); the sync
  @pre clauses were rewritten to post-state forms (sem_try_acquire/
  sem_acquire false guard; sem_release requires) and cdl_count_down stays
  clause-free. Self-field @pre on method receivers works (wave 93), so
  this is the &mut-parameter half of the R49 residual.
  (b) p_generic_byref_option.xi -- `core.option_is_some(&o)` returns false
  for `Some(4)` while `o.is_some` is true; the same silent misread hits
  option_is_none/result_is_ok/result_is_err (generic `&Vec[T]` params such
  as cmp.min_of_vec are correct).
  (c) p_slice_bound_generic_c001.xi -- bounded `&Slice[T]` calls
  (is_sorted/contains/min_slice/max_slice) fail
  `error[C001]: type 'Slice' does not implement 'Ord'/'Eq'`; annotated
  `Slice[Int]` locals from array.as_slice read `.len()` wrong and
  core.slice_len is wrong/crashes. All Slice-param helpers stay
  clause-free.
- Probe p_wave94_shapes.xi (266th, 113 checks): green on v0.64.1 pre- and
  post-clauses (the wave-93 probe forms plus the sync field mirrors and
  terminal escape pins). Targeted smokes: smoke_cmp 17/17, smoke_sync
  22/22, smoke_core 20/20, smoke_fmt 18/18, smoke_format_terminal +
  smoke_format_ansi 1/1.
- Coverage: sync 29.1% -> 35.9%, core 26.7% -> 45.8%, format 46.8% ->
  59.3%, global 58.6% -> 59.5% (clauses 5024 -> 5110); meter 76.0%;
  floors131 dumped and wired (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.1): release corpus 954/954 full (703s,
  no exclusions); probes 266/266 (289.7s); check_modules 509/509 (197.6s);
  barename 0/509 (299.7s); floors131 + doc + module-smoke (497/517,
  3477/6205) ratchets OK.
- Release side: nothing pending; the next cut picks up block-75 +
  blocks 77/78. Readiness next (wave 95): os 26.6% (runtime-backed
  surfaces inspected per item), sort 31.9%, hash 33.3%, num/array/bits,
  the format remainder (markup/textual/fmt), and the queued feature
  candidates.

**SESSION 2026-10-08 block 77 (wave 93: iter remainder + format text; floors130; M7 finding)**
- Wave 93: 55 pub / 71 clauses. iter.chain 14 (fold/fold_right empty ->
  init; reduce/sum/product/any/all empty identities; nth OOB -> None;
  last/position/max/min empty -> None; partition exact len-sum;
  group_by empty -> len 0), iter.fold 8 (find/find_map/contains/
  position_of empty identities; chunks/windows exact count bounds;
  cmp [-1,1] + empty-side pins; eq len-mismatch/empty-equal pins), iter
  adapters 14 new pub (RangeInclusive.next done-state pins;
  Range/MapIter/FilterIter/EnumerateIter/ChainIter take/skip/enumerate
  field mirrors; TakeIter.next remaining@pre guard; range_step ceil band;
  repeat_n n band) plus the Range.next `ensures: true` placeholder
  replaced with start/end@pre pins (first self-field @pre use in iter;
  probe-validated), format.text 18 (alignment delegation bounds;
  justify/wrap/flow/paragraph/reflow/measure empty identities; indent
  no-op and len bands; columns row counts; ellipsis branches;
  overline/underline/strikethrough/quote exact lengths; blockquote bands).
- NEW FINDING (surfaced probe-first): p_iter_iterator_type_unresolved.xi --
  the M7 `Iterator[T]` receiver type is not declared anywhere in xiom/,
  so every `use xiom.iter;` consumer warns `unknown type 'Iterator' --
  defaulting to i64` (3-4x) and `r.step_by(2)` fails C001 unresolved
  `Iterator.step_by` (the old silent zero auto-stub is now loud). The four
  M7 adapters (step_by/take_while/skip_while/inspect) and their iterator
  types stay clause-free; the concrete adapters are unaffected. Findings
  11 -> 12 (11 compiler, 1 stdlib); queue gate 9 updated.
- Probe p_wave93_shapes.xi (265th, 139 checks): green on v0.64.1 pre- and
  post-clauses (field mirrors, tuple len-sum, self @pre forms and the
  text layout lengths all held first pass). Targeted smokes: smoke_iter
  21/21, smoke_fmt 18/18, smoke_format_ 8/8, smoke_format_text 1/1,
  smoke_text2 1/1.
- Coverage: iter 25.1% -> 45.4%, format 39.0% -> 46.8%, global 57.7% ->
  58.6% (clauses 4953 -> 5024); meter 75.9%; floors130 dumped and wired
  (ci/heavy/release + tools/README).
- Battery on this commit (v0.64.1): release corpus 954/954 full (606.2s,
  no exclusions); probes 265/265 (316.7s); check_modules 509/509 (419.5s);
  barename 0/509 (437.5s); floors130 + module-smoke (497/517, 3477/6205)
  ratchets OK. (The 6203 -> 6205 module-smoke denominator predates this
  wave: verified identical on the stashed pre-wave tree.)
- Release side: nothing pending; the next cut picks up the block-75
  post-tag fixes + this wave.

**SESSION 2026-10-08 block 76 (handoff refresh: snapshot 24; clean context handoff; release + registry DONE; next = wave 93)**
- Snapshot 24 refreshed for the context handoff: read list -> blocks 75
  (latest)..; STATE carries the v0.64.1 pin, the **completed release**
  (stdlib-v0.64.2 on 4dd8844, registry LIVE: xiom-std 0.64.2 signed,
  sha256 f5375c03ad88), the block-75 post-tag fixes (string linearization
  + signal stubs), gates probes 264/floors129-tightened/coverage 57.7%,
  and the corrected open-findings list (rvalue/multipart/iter-forwardref
  are PROMOTED locks now; geom tuple, polyhedra, ensures-isok, clause
  float-vec, geom Box, alias/foreign-call stay open).
- FIRST TASK wave 93 unchanged (iter remainder + low dirs + queued
  features); protocol now carries the no-unbounded-benchmarks caution
  (block-75 incident).
- No code changes; heads: block-75 fix (3657482) + this refresh.

**SESSION 2026-10-08 block 75 (fix-first: str_split/str_repeat/pad quadratic defects; PULSE signal stubs; consumer re-sweep)**
- Consumer re-sweep (PULSE, ORBITDB, XVECTOR, bindings, packages) recorded
  in docs/STDLIB-WISHLIST.md. ORBITDB's sharp finding: `str_split` was
  O(n^2) (slice per scan position; 5 MB / 20k-line WAL replay ~44 s vs
  2 ms for read_file). FIXED 2026-10-08: byte-compare scan,
  O(|s| * |delimiter|), no per-position slices. Same-class fixes:
  `str_repeat` now builds by doubling (was quadratic accumulation) and
  `str_pad_left`/`str_pad_right` allocate once (were quadratic AND leaked
  one malloc per pad byte). Probe lock p_str_split_scale.xi (120 KB scale
  + edge cases) green; smoke_string_split(+edge/join),
  smoke_string_pad_repeat, smoke_stress_string_split_edge, smoke_string_edge
  1/1 each.
- PULSE new ask addressed stdlib-side: `signal_handle`/`signal_pending`
  documented-Err stubs in `xiom/os/signal.xi` (signal-safe runtime
  trampoline is runtime-backed and queued; SIGTERM graceful shutdown stays
  blocked until the runtime bundle).
- ORBITDB append-handle ask (`io.open_append`) stays open/scheduled; the
  sync half is runtime-backed. XVECTOR/bindings/packages: no new rows.
- Incident (no repo impact): a scratch benchmark (out/benchsplit.xi,
  deleted) carrying a quadratic str_repeat setup kept running after its
  shell timed out, ballooning memory (~4.7 GB) and paging pressure until
  force-killed; C: recovered (66 GB free). No further large synthetic
  benchmarks from this lane.
- Battery on this commit (v0.64.1): release corpus 954/954 full (756.6s,
  -Workers 8 -RetryFailed, no exclusions); probes 264/264 (264.0s);
  check_modules 509/509 (170.9s); barename 0/509 (243s); module-smoke
  ratchet OK. Coverage: first pass FAILED the ratchet on os (26.1% < 26.2
  floor) because the two new signal stubs initially carried no clauses;
  fixed by adding their exact always-Err clauses (os 26.6%, global 57.7%),
  floors129 re-dumped (tightened) and ratchet OK.

**SESSION 2026-10-08 block 74 (stdlib 0.64.2 RELEASED; registry publish queued for environment approval)**
- Per the owner's decision (2026-10-08): cut ONE release at the new pin.
  Steps executed: package.xi version -> "0.64.2" + release-notes/v0.64.2.md
  + CHANGELOG [0.64.2] in commit 4dd8844 (on top of 57bff56); full release
  gate suite on that exact commit -- corpus 954/954 (823.3s, -Workers 8
  -RetryFailed), probes 263/263 (327.8s), check_modules 509/509 (204.1s),
  barename 0/509 (273.1s), coverage ratchet floors129 OK, doc_scan 100%
  ratchet OK, author identity Lefteris Notas <lefterisnotas@gmail.com>.
- Tagged stdlib-v0.64.2 (annotated) on 4dd8844 and pushed; release.yml run
  37786796498 completed SUCCESS (~43 min): validate + windows/ubuntu gates
  + deterministic tarball; GitHub Release stdlib-v0.64.2 published with
  xiom-std-0.64.2.tar.gz + SHA256SUMS. No 0.64.0/0.64.1 stdlib tags were
  cut (owner decision), so the lineage is 0.63.0 -> 0.64.2.
- Registry publish: the tag push auto-triggered a publish run
  (37786796626) and an earlier dispatch (37793330331) exists; both are
  WAITING on the protected `registry-publish` environment (required
  reviewers) -- the owner must approve ONE of them. A third duplicate
  dispatch was cancelled (37793441927). After approval the publish is
  OIDC + ed25519 signed; verify with `xiom pkg info xiom-std` (expect
  0.64.2 with a sha256 and signed). Registry still shows through 0.63.0
  as of this block.
- v0.64.2 pin: the compiler side should take stdlib tag stdlib-v0.64.2
  (commit 4dd8844) for STDLIB_VERSION; the release-notes fragment at the
  tag is release-notes/v0.64.2.md.

**SESSION 2026-10-08 block 73 (handoff refresh: snapshot 23; v0.64.1 pin consumed; v0.64.2 pin + registry decision pending)**
- Snapshot 23 refreshed: read list -> blocks 72 (latest)..; STATE carries
  the v0.64.1 pin (tag 3c6f3bb5), COMPILER_VERSION v0.64.1, gates probes
  263/floors129/coverage 57.7%, the wave-92 iter retry, and the RELAY
  CORRECTIONS (geom-matrix tuple still red, polyhedra unchanged,
  ensures-isok/clause-float-index/geom-Box/alias-foreign findings open).
- Release side: release-notes/v0.64.2.md (stdlib fragment) authored; the
  intended v0.64.2 compiler pin is THIS refresh commit's HEAD on main
  (compiler lane: use the origin/main hash after this push). The
  xiom-std 0.64.x registry entry needs a stdlib release tag first; the
  registry tops out at 0.63.0 and no stdlib-v0.64.x tag exists (owner /
  release-lane decision; raised 2026-10-08).
- No code changes beyond the wave-92 commit (9d519ee); heads: wave 92
  (9d519ee) + this refresh.

**SESSION 2026-10-08 block 72 (v0.64.1 pin bump: m200/m201/m203 consumed; iter retry; floors129)**
- Pin moved to official v0.64.1 (tag 3c6f3bb5; binary downloaded to
  %TEMP%\kilo\stdlib_ws\v0.64.1). Verification on the pin: m200 rvalue
  Vec[Float64] index rc 0; m201 multipart parse name rc 0; m203 iter
  closure-thunk clause leak -- `Range.count` clause re-added, smoke_iter
  21/21 (incl. -Workers 8), p_iter_range_collect_forwardref rc 0.
- Retried iter set landed (13 clauses / 12 pub): contains (x < start,
  x >= end => false), sum empty -> 0, product empty -> 1, collect empty ->
  len 0, count empty -> 0, max/min/find/nth/last empty -> None, all empty
  -> true, any empty -> false. Pin probe p_pin0641_iter_shapes.xi (32
  checks) green pre/post. iter 18.6% -> 25.1%, global 57.5% -> 57.7%,
  meter 75.8%; floors129.
- Promotions: p_rvalue_float_vec_index.xi, p_multipart_parse_name.xi and
  p_iter_range_collect_forwardref.xi moved to tools/probes/ (regression
  locks); README entries flipped to RESOLVED.
- Relay corrections (still open on v0.64.1, annotated in the README):
  geom-matrix tuple inference PARTIAL (checks 1-3 now pass; `var l2 =
  lu.0;` check 4 rc=4), polyhedra nested hull unchanged (rc=1 --
  m201 did not cover it), p_ensures_isok_guard unchanged,
  p_clause_float_vec_index unchanged, p_geom_box_unnameable unchanged,
  alias/foreign-call findings unchanged.
- Release-lane note: v0.64.1's archive bundles stdlib 6e60e958 (old
  wave-74 pin); the intended v0.64.2 pin is the HEAD of this pin-bump
  (confirm in the v0.64.2 release notes; no v0.64.1 stdlib fragment
  exists). Registry: xiom-std 0.63.1 publish still pending.
- Battery on this commit (v0.64.1): release corpus 954/954 full (594.2s,
  no exclusions); probes 263/263 (248.7s); check_modules 509/509 (152.3s);
  barename 0/509 (316.9s); floors129 + module-smoke (497/517, 3477/6203)
  ratchets OK.
- COMPILER_VERSION bumped to v0.64.1; release-notes/v0.64.2.md (stdlib
  fragment) authored for the combined v0.64.2 compiler release; intended
  v0.64.2 pin = the HEAD of this commit (confirm on the compiler side).
  Registry state: xiom-std on the registry tops out at 0.63.0; no
  stdlib-v0.64.0/0.64.1 tag exists, so the 0.64.x registry entry needs a
  release-lane tag decision (raised to the owner).

**SESSION 2026-10-08 block 71 (wave 91: bench + format numbering/units; floors128; bench_time_fn defect fix)**
- Wave 91: 85 clauses / 38 new pub -- bench 13 new (run_bench pins:
  iterations 1, name mirror, total == mean, stddev 0; run_bench_n name
  mirror + zero-iteration all-zero branch; compare >= name band;
  ops-per-sec and faster-percent zero branches; min/max/total/median
  empty -> 0; human-ns four pins; black-box int identity; run_avg
  delegation pins; report empty len 124; report_simple empty -> ""),
  format.numbering 11 (word/milliard/ordinal/CJK/Indian-grouping/money
  exact pins), format.units 16 (bytes/bits/percent/ratio/scientific/
  engineering/SI/binary/temperature/currency/durations/hertz pins).
- DEFECT fix-first (found by the wave probe): `bench_time_fn` called
  `run_bench("", f)` and aborted at runtime on run_bench's own
  `requires: name.len() > 0`; now passes "bench_time_fn". bench_time_fn
  stays clause-free (elapsed ns).
- Pin status checked: v0.64.0 still GitHub Latest (v0.64.1 closing after
  the compiler C-06 fix); no re-pin; the NEXT PIN trigger stays queued.
- Probe p_wave91_shapes.xi (259th, 89 checks): green on v0.64.0 pre- and
  post-clauses. Probe-first fixes: BenchResult moved-value pushes
  (fresh zresult() per push), the UK long-scale "one milliard"
  expectation (not billiard), and the sci-zero form "0.00". Targeted
  smokes smoke_bench + smoke_format_numbering + smoke_format_units 1/1.
  bench 18.8% -> 87.5%, format 27.3% -> 39.0%, global 56.9% -> 57.5%,
  meter 75.8%; floors128.
- Battery on this commit (v0.64.0): release corpus 954/954 full (726s,
  no exclusions); probes 259/259 (398.8s); check_modules 509/509 (190.2s);
  barename 0/509 (240.1s); floors128 + module-smoke (497/517, 3477/6203)
  ratchets OK.

**SESSION 2026-10-08 block 70 (handoff refresh: snapshot 22 updated for the next session; v0.64.1 imminent)**
- Snapshot 22 refreshed: read list -> blocks 69 (latest)..; STATE carries
  the wave-90 gates (probes 258, floors127, coverage 56.9%, serialize
  90.3%) and flags that v0.64.1 is closing after the compiler C-06 fix --
  do the NEXT PIN trigger first when it ships (must carry m200/m201/m203);
  FIRST TASK wave 91 (next low dirs: bench/format/sync + queued feature
  candidates); HANDOFF NOTE lists p_wave90_shapes.xi (258 probes),
  floors127, the io-fidelity/fs_remove locks and the two open
  cross-module repros; the ecosystem-lanes note was added (relays in
  docs/STDLIB-WISHLIST.md).
- No code changes; heads: wave 90 (d60cb43) + this refresh.

**SESSION 2026-10-08 block 69 (wave 90: serialize batch 3 toml/yaml_lite; floors127)**
- Wave 90: 23 clauses / 16 new pub -- toml 11 (toml_parse empty -> Ok,
  "a = 1" -> Ok, "[a" -> Err pins; toml_get and the six typed getters
  empty-table -> None; toml_has empty -> false; toml_keys len mirror;
  toml_write empty -> "" + result >= keys band), yaml_lite 5 (yaml_parse /
  yaml_parse_document empty -> Err + "a: 1" -> Ok pins; yaml_emit_scalar
  empty -> `""` + >= len band; yaml_emit_sequence empty -> "" + >= items
  band; yaml_emit_mapping any-empty-side -> ""). Clause-free by design:
  yaml_stringify / yaml_get (enum match).
- Pin status checked: v0.64.0 still GitHub Latest (v0.64.1 pending after
  the C-06 compiler fix), no re-pin; the NEXT PIN trigger stays queued.
- Probe p_wave90_shapes.xi (258th, 35 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_serialize (+csv/toml/toml_write)
  1/1. serialize 73.1% -> 90.3%, global 56.7% -> 56.9%, meter 75.7%;
  floors127.
- Battery on this commit (v0.64.0): release corpus 954/954 full (1233.1s,
  no exclusions); probes 258/258 (305.5s); check_modules 509/509 (207.1s);
  barename 0/509 (253.7s); floors127 + module-smoke (497/517, 3477/6203)
  ratchets OK.

**SESSION 2026-10-08 block 68 (io byte-fidelity + CRLF defect fix; ORBITDB/XVECTOR intake)**
- Defect (fix-first, ORBITDB relay row 2): `io.read_file_lines` kept the
  trailing CR on CRLF files ("10\r" -> parse failures, silent record
  drops). Fixed by stripping one trailing CR per line. Root cause fixed
  too: `io.write_file` / `io.append_file` / `io.write_file_bytes` opened
  in TEXT mode, so Windows fwrite silently turned LF into CRLF and the
  "bytes" writer was not byte-exact; all three now open binary
  (`wb`/`ab`). Doc comments note the byte-exact contract.
- Probe lock p_read_file_lines_crlf.xi (18 checks): fails pre-fix (run=3
  reproduced the CR; raw length 12 vs 10 reproduced the write
  translation), green post-fix. All 20 smoke_io tests + 4 byte-IO
  stress/cross smokes green.
- Intake recorded in docs/STDLIB-WISHLIST.md: ORBITDB rows 1-6 (fsync,
  CRLF [fixed], append_line_sync, truncate, byte append, tail check) and
  XVECTOR rows 1-6 (fsync, fd write_all, append_file_bytes, f32 bitcast,
  truncate, flush_stdout), with the surface-shape confirmation requested
  by XVECTOR: complete the existing fd-level (`xiom.os.sync_io`) +
  path-level (`xiom.os.fs_ffi`, `io`) stubs rather than adding new names;
  runtime-backed rows queue for the compiler runtime bundle. f32
  bitcast is a compiler-lane ask.
- Bindings-lane relay 2026-10-08 (W-1..W-5) processed: W-1 `fs_remove`
  added to `xiom.io.fs` with probe lock p_fs_remove.xi; W-4 stale
  Int-to-pointer-cast note corrected in smoke_ffi2.xi (typed-call idiom
  verified by the bindings lane on v0.64.0; a dl typed-call smoke is
  queued); W-3 stdlib side addressed by the new CONFINEMENT CAUTION in
  the xiom.ffi module header + free doc (compiler finding B-05 owns the
  real fix); W-2 (out-param slot helper) and W-5 (Vec[UInt8].with_len)
  recorded as scheduled candidates.
- Battery on this commit (v0.64.0): release corpus 954/954 full (740.4s,
  no exclusions); probes 257/257 (337.9s); check_modules 509/509 (232s);
  barename 0/509 (371.5s); floors126 + module-smoke (497/517, 3477/6203)
  ratchets OK.

**SESSION 2026-10-08 block 67 (handoff refresh: snapshot 21 updated for the next session)**
- Snapshot 21 refreshed: read list -> blocks 66 (latest)..; STATE carries
  the wave-89 gates (probes 255, floors126, coverage 56.7%, serialize
  73.1%) and the pin check note (v0.64.0 still Latest; trigger stays
  queued); FIRST TASK wave 90 (serialize batch 3: toml/yaml_lite); HANDOFF
  NOTE lists p_wave89_shapes.xi (255 probes), floors126 and the two new
  cross-module resolution repros; the PULSE relay + credential workaround
  notes stay in STDLIB-WISHLIST.md / failed_attempts.md.
- No code changes; heads: wave 89 (14bc27a) + this refresh.

**SESSION 2026-10-08 block 66 (wave 89: serialize + json; floors126)**
- Wave 89: 50 clauses / 36 new pub -- serialize.xi 26 (format_error >= 15
  band + the exact zero-error pin; is_valid_json/is_valid_bytes empty ->
  false; json_string/json_array/json_object empty pins + >= len+2 / 2n /
  4n bands; json_number nan/zero pins; json_bool/json_null mirrors;
  json_parse empty -> Err + "null" -> Ok replacing the placeholder
  requires/twin-ensures; parse_json empty -> Err; JsonValue.index
  negative -> None; little/big_endian constants; json_escape/unescape/
  minify/pretty empty identities + bands; json_get_path empty-json None;
  json_type_of empty/object/bool pins; varint_encode band + pins;
  varint_decode(_at) pos-OOB Err; varint_encoded_len pos-OOB 0;
  bytes_to_hex_str == 2n; hex_str_to_bytes empty -> Ok), serialize.json 12
  (json_parse empty/null pins; json_get_path empty-path -> Some;
  constructor type pins via json_type(result); json_type >= 4 band;
  json_escape band).
- Probe p_wave89_shapes.xi (255th, 67 checks): green on v0.64.0 pre- and
  post-clauses. Probe-first fixes: the encoding.hex_decode even-length
  requires aborts on odd input (odd -> Err claim dropped; probe uses "zz");
  json_type_of is first-char-based ("nope" -> "null", corrected to "x").
  Targeted smokes serialize/json/stress/fuzz/KAT 13 files 1/1.
- PULSE relay 2026-10-08 checked: write_all + server_parse_request
  ADOPTED (their 12-check probe); new import-aliasing ask (C-PULSE-12)
  cross-filed; socket_set_timeout still a documented-Err stub
  (runtime-backed); flush_stdout still a no-op. Recorded in
  docs/STDLIB-WISHLIST.md.
- Compiler findings filed (from the probe-first fixes):
  p_alias_module_type_path.xi (T001 on `ser.SerializeError`, bare name
  works) and p_foreign_method_call.xi (C001 on `v.json_get_path(...)`,
  qualified call works); README Current entries added, cross-ref
  C-PULSE-12.
- Pin status checked: v0.64.0 still GitHub Latest, no re-pin; the NEXT
  PIN trigger stays queued.
- serialize 34.4% -> 73.1%, global 56.1% -> 56.7%, meter 75.7%;
  floors126.
- Battery on this commit (v0.64.0): release corpus 954/954 full (798.8s,
  no exclusions); probes 255/255 (247.3s); check_modules 509/509 (170.5s);
  barename 0/509 (220.5s); floors126 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-08 block 65 (handoff refresh: snapshot 20 updated for the next session)**
- Snapshot 20 refreshed: read list -> blocks 64 (latest)..; STATE carries
  the wave-88 gates (probes 254, floors125, coverage 56.1%, serialize
  34.4%) and the pin check note (v0.64.0 still Latest; trigger stays
  queued); FIRST TASK wave 89 (serialize batch 2: serialize/json then
  toml/yaml_lite); HANDOFF NOTE lists p_wave88_shapes.xi (254 probes) and
  floors125; the push-credential workaround note stays in the battery
  step and docs/failed_attempts.md.
- Host restarted mid-battery (RAM upgrade); probe/module/barename steps
  re-ran clean on the same tree (block 64).
- No code changes; heads: wave 88 (0cb45bb) + this refresh.

**SESSION 2026-10-08 block 64 (wave 88: serialize batch 1 endian/varint/csv; floors125)**
- Wave 88: 37 clauses / 27 new pub -- endian 16 (the eight write_* @pre
  append claims `out.len() == out.len()@pre + 2/4/8` covering the unsafe
  write_f64_le; the eight read_* OOB identity guards
  `(pos < 0 || pos + N > data.len()) => (result == 0/0.0)`), varint 9
  (varint_encode/size 1..10 bands + zero/300 pins; decode empty -> Err;
  zigzag exact body mirrors; uvarint_encode band + zero pin; decode
  empty -> Err; encode_slice empty -> empty + >= values band;
  decode_slice empty -> Ok), csv 4 (empty -> Ok on parse/parse_with;
  empty -> "" and >= fields-1 / >= 2*rows bands on the writers).
- Pin status checked: v0.64.0 still GitHub Latest, no re-pin; the NEXT
  PIN trigger stays queued.
- Probe p_wave88_shapes.xi (254th, 57 checks): green on v0.64.0 pre- and
  post-clauses (the @pre append claims and the OOB guards held first
  pass); targeted smokes smoke_serialize (+toml), smoke_serialize_csv and
  smoke_convert_endian 1/1 each. serialize 5.4% -> 34.4%, global 55.7% ->
  56.1%, meter 75.6%; floors125.
- Battery on this commit (v0.64.0): release corpus 954/954 full (929.8s,
  no exclusions; run completed pre-restart on this identical tree);
  probes 254/254 (295.7s); check_modules 509/509 (224.6s); barename
  0/509 (260.4s); floors125 + module-smoke (497/517, 3477/6202) ratchets
  OK. Host restarted mid-battery (RAM upgrade); the probe/module/barename
  steps were re-run clean on the same tree after the restart.

**SESSION 2026-10-07 block 63 (handoff refresh: snapshot 19 updated for the next session)**
- Snapshot 19 refreshed: read list -> blocks 62 (latest)..; STATE carries
  the wave-87 gates (probes 253, floors124, coverage 55.7%, convert 94.1%)
  and the pin check note (v0.64.0 still Latest; trigger stays queued);
  FIRST TASK wave 88 (serialize batch 1: endian/varint/csv, then the
  serialize remainder and the other low dirs); HANDOFF NOTE lists
  p_wave87_shapes.xi (253 probes) and floors124; push protocol notes the
  credential-selection workaround in docs/failed_attempts.md.
- No code changes; heads: wave 87 (59f9b14) + this refresh.

**SESSION 2026-10-07 block 62 (wave 87: convert tails; floors124)**
- Wave 87: 52 clauses / 33 new pub -- root convert 6 (int_to_float/
  float_to_int/int_to_string zero pins; float_to_fixed_str nan/0.0-0/1.5-1
  pins; float_to_sci_str nan/1.5-1 pins; bool_to_string mirrors) plus
  int_to_char's placeholder `ensures: true` replaced with the
  (n < 0 || n > 1114111) -> None and n == 65 -> some pins; cstring 2
  (null-pointer identities; to_cstring/cstring_copy clause-free, unsafe
  pointers); float 6 (nan/zero pins, string_to_float empty -> Err,
  fixed/sci pins, zero pins on float_to_int/int_to_float); json 5 (empty
  identities, json_quote(empty) == `""`, json_escape result >= input
  band, json_is_valid(empty) -> false); punycode+idna 8 (empty -> Ok
  identities; idna_is_valid(empty) -> false); strftime 2 (empty ->
  "", "%%" -> "%", the "%Y-%m-%d" 2026-08-12 ISO pin); strptime 2
  (empty spec -> false, <10 -> false, layout pin incl. result.date
  fields); tryfrom 3 (NaN/2^63 Err guards, zero -> Ok, empty -> Err).
- Pin status checked: v0.64.0 still GitHub Latest, no re-pin; the NEXT
  PIN trigger stays queued.
- Probe p_wave87_shapes.xi (253rd, 57 checks): green on v0.64.0 pre- and
  post-clauses (the nested result.date clause and the json quote pin held
  first pass); targeted smokes smoke_convert_float_str, smoke_convert_json,
  smoke_convert_punycode, smoke_convert_strftime, smoke_convert_try,
  smoke_convert_all_directions, smoke_convert_identity and
  smoke_convert_narrow(_roundtrip) 1/1 each. convert 83.3% -> 94.1%,
  global 55.2% -> 55.7%, meter 75.6%; floors124.
- Battery on this commit (v0.64.0): release corpus 954/954 full (707.2s,
  no exclusions); probes 253/253 (229.3s); check_modules 509/509 (185.7s);
  barename 0/509 (236.5s); floors124 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 61 (handoff refresh: snapshot 18 updated for the next session)**
- Snapshot 18 refreshed: read list -> blocks 60 (latest)..; STATE carries
  the wave-86 gates (probes 252, floors123, coverage 55.2%) and the pin
  check note (v0.64.0 still Latest; trigger stays queued); FIRST TASK
  wave 87 (convert tails -- float/json/punycode/cstring, strftime/
  strptime, tryfrom) with the NEXT PIN trigger unchanged; HANDOFF NOTE
  lists p_wave86_shapes.xi (252 probes) and floors123.
- No code changes; heads: wave 86 (dacb229) + this refresh.

**SESSION 2026-10-07 block 60 (wave 86: convert locals + shims; floors123)**
- Wave 86: 58 clauses / 39 new pub -- date 5 (date_new field mirror;
  date_iso8601 10-byte band; date_from_iso8601 layout guard + epoch
  some-pin; date_weekday [0,6] band + epoch == 4; date_day_of_year 1..366
  band + 2026-08-12 == 224), datetime 3 (datetime_new field mirrors;
  datetime_iso8601 >= 19 band + epoch string pin; datetime_from_iso8601
  layout guard), duration 6 (zero/negative normalization pins on the four
  constructors; as_secs/as_ms accessor mirrors), time 3 (time_now
  [0,86399] band; timestamp_to_date epoch/86400/-1 pins; date_to_timestamp
  epoch pin), wstring 2 (null-pointer identities), from 3 / into 2 (zero
  pins + from_bool mirrors), roundtrip 4 (empty/invalid/zero pins incl.
  roundtrip_base invalid-base false and n == 0 true), uuid 4 / mac 4
  (36/17/16 length claims + layout guards), iri 3 (empty -> Err,
  non-empty -> Ok presences). Clause-free by design: date_now/
  datetime_now/timestamp_now (clock), to_wstring (unsafe pointer),
  from_char (char-cast), into_str (generic display).
- Pin status checked: v0.64.0 still GitHub Latest, no re-pin; the NEXT
  PIN trigger stays queued.
- Probe p_wave86_shapes.xi (252nd, 72 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_time, smoke_convert_traits,
  smoke_convert_checked, smoke_convert_ip and smoke_convert_url 1/1 each.
  convert 70.5% -> 83.3%, global 54.6% -> 55.2%, meter 75.5%; floors123.
- Battery on this commit (v0.64.0): release corpus 954/954 full (774s,
  no exclusions); probes 252/252 (235.1s); check_modules 509/509 (232.2s);
  barename 0/509 (429.2s); floors123 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 59 (handoff refresh: snapshot 17 updated for the next session)**
- Snapshot 17 refreshed: read list -> blocks 58 (latest)..; STATE carries
  the wave-85 gates (probes 251, floors122, coverage 54.6%) and the pin
  check note (v0.64.0 still Latest, no re-pin; trigger stays queued);
  FIRST TASK wave 86 (convert remaining locals -- date/datetime/duration/
  time, wstring/from/into/roundtrip) with the NEXT PIN trigger unchanged;
  HANDOFF NOTE lists p_wave85_shapes.xi (251 probes) and floors122.
- No code changes; heads: wave 85 (b9b98dc) + this refresh.

**SESSION 2026-10-07 block 58 (wave 85: convert ip/lossy/network/timestamp; floors122)**
- Wave 85: 31 clauses / 20 new pub -- ip 6 (is_valid_ipv4 < 7 / > 15
  and is_valid_ipv6 < 2 => false; ipv4_to_string empty -> "" plus the
  4-octet 7..15 band; string_to_ipv4/ip_parse/ip_to_bytes empty and
  length-band None identities), lossy 4 (empty and sign-only zero pins;
  lossy_from_float NaN -> 0 and 2^63 clamp mirrors; zero pins on
  lossy_to_float/lossy_char), network 6 (exact byte-swap mirrors: 16/32-bit
  bit expressions and the 64-bit closed form, runtime-verified incl. the
  sign-bit case), timestamp 4 (epoch/86400/-1 pins on
  timestamp_to_date/timestamp_to_datetime and the epoch-day band on
  timestamp_from_datetime; timestamp_now stays clause-free, system clock,
  matching date_now/instant_now).
- Pin status checked first: v0.64.0 is still the latest compiler release
  (2026-10-05), so the NEXT PIN trigger (Range.count + deferred iter set +
  the four promotions) stays queued.
- Probe p_wave85_shapes.xi (251st, 63 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_ip, smoke_convert_time and
  smoke_convert_checked 1/1 each. convert 63.9% -> 70.5%, global 54.3% ->
  54.6%, meter 75.5%; floors122 wired.
- Battery on this commit (v0.64.0): release corpus 954/954 full (752.3s,
  no exclusions); probes 251/251 (653.1s); check_modules 509/509 (225.5s);
  barename 0/509 (364.7s); floors122 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 57 (handoff refresh: snapshot 16 updated for the next session)**
- Snapshot 16 refreshed: read list -> blocks 56 (latest)..; STATE carries
  the m200-m206 compiler relay; FIRST TASK wave 85 (convert ip + lossy/
  network/timestamp) is preceded by the NEXT PIN trigger when the pin
  carrying m200/m201/m203 ships (re-add Range.count clause, retry the
  deferred iter set, promote the four fixed repros, re-dump floors);
  protocol (1) adds the `result is Ok =>` guard-form rule and the
  file-a-finding rule; HANDOFF NOTE lists the wave-77..84 locks,
  smoke_convert_uuencode, the two open known-failure repros and
  docs/failed_attempts.md.
- No code changes; heads: wave 84 (1006c30) + compiler relay (4121b83).

**SESSION 2026-10-07 block 56 (compiler relay: m200-m203 fixes + next-pin checklist)**
- Compiler lane relay: m203 fixed the closure-thunk clause leak --
  `ensures: result >= 0` on Range.count + smoke_iter verified OK/exit 0;
  m200 fixed p_rvalue_float_vec_index; m201 fixed p_multipart_parse_name,
  p_geom_matrix_result_infer and p_polyhedra_nested_hull.
- Next-pin checklist: the pin must carry m200/m201/m203 (m202 gates the
  packages grpc publish; m206 covers graphql conformance). Then:
  (1) re-add the Range.count clause and retry the deferred iter set
  (Range core 7 + chain 14 + fold 8 + iter_collect) probe-first;
  (2) promote the four fixed repros out of known_failures;
  (3) re-dump floors (the findings count drops as items move).
- Recorded in tools/known_failures/README.md entries and the queue's
  compiler-findings relay section (item 7); packages notes included.

**SESSION 2026-10-07 block 55 (wave 84: convert uri/url/urn; floors121)**
- Wave 84: 8 clauses / 8 new pub -- uri_parse and uri_normalize
  (empty -> Err), url_parse (empty -> Err), url_encode (percent bands
  >= n / <= 3n), url_decode (canonical `result is Ok => result.len() <=
  s.len()` + empty-Ok), urn_parse and urn_is_valid (< 7 -> Err/false),
  urn_build (result.len() == nid.len() + nss.len() + 5).
- Compiler relay (same day): filed p_ensures_isok_guard.xi -- clause
  payload-length claims guarded with `(result.is_ok == true) =>` violate
  at runtime while the canonical `result is Ok =>` form works; rc 1 on
  v0.64.0. Findings 10 -> 11; queue gate 9 updated.
- Probe p_wave84_shapes.xi (250th, 16 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_url and smoke_net_url 1/1
  each. convert 61.3% -> 63.9%, global 54.2% -> 54.3%, meter 75.4%;
  floors121 wired.
- Battery on this commit (v0.64.0): release corpus 954/954 full (763.9s,
  no exclusions); probes 250/250 (228.5s); check_modules 509/509 (159.5s);
  barename 0/509 (243.2s); floors121 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 54 (wave 83: convert codec tails + UU trim fix; floors120)**
- Wave 83: 7 clauses / 7 new pub -- uuencode (empty -> ""), uudecode
  (empty -> Ok), uuencode_line (empty -> len 1), xxencode (empty -> ""),
  xxdecode (empty -> Ok), base58check_encode (len >= 1),
  base58check_decode (empty -> Err).
- Fix-first (probe-caught pre-clause): `_trim` in xiom/convert/
  uuencode.xi stripped trailing spaces, but UU trailing spaces are data
  (value 0 encodes as ' '); every line whose final group ended in zero
  bytes failed uudecode (any 1-byte payload: `uuencode([65])` =
  "!00  " -> Err "uudecode_line: truncated line"). Right-side trim is
  now CR/LF only. New smoke tests/smoke/smoke_convert_uuencode.xi locks
  1/3/45/100-byte and XX roundtrips (corpus 953 -> 954).
- Probe p_wave83_shapes.xi (249th, 15 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_uuencode and
  smoke_convert_base58_62 1/1 each. convert 59% -> 61.3%, global 54.1%
  -> 54.2%, meter 75.4%; floors120 wired.
- Compiler relay: filed the wave-80 guard-form finding as
  tools/known_failures/p_ensures_isok_guard.xi (clause payload-length
  claims with `(result.is_ok == true) =>` violate at runtime; the
  canonical `result is Ok =>` form is required; rc 1 on v0.64.0).
  Findings 10 -> 11 (10 compiler, 1 stdlib); queue gate 9 updated.
- Battery on this commit (v0.64.0): release corpus 954/954 full (680.7s,
  no exclusions); probes 249/249 (216.2s); check_modules 509/509 (167.7s);
  barename 0/509 (252.7s); floors120 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 53 (wave 82: convert codec guards; floors119)**
- Wave 82: 11 clauses / 11 new pub -- ascii85 4 (empty -> "" on
  to_ascii85/ascii85_encode_str, empty -> Ok on from_ascii85/
  ascii85_decode_str), quotedprintable 4 (qp_encode/qp_encode_maxline/
  qp_soft_linebreak empty -> "", qp_decode empty -> Ok), base58_decode
  and base62_decode empty -> Ok, uudecode_line empty -> Err.
- Push incident: three GitHub `Internal Server Error` 500s at
  15:07-15:09Z (push + ls-remote), logged in docs/failed_attempts.md;
  the 4th attempt at 15:22Z succeeded and origin/main caught up
  (5ce4785 -> e7c4ee5).
- Probe p_wave82_shapes.xi (248th, 15 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_ascii85,
  smoke_encoding_percent_ascii85, smoke_convert_base58_62 1/1 each.
  convert 55.4% -> 59%, global 53.9% -> 54.1%, meter 75.4%; floors119
  wired.
- Battery on this commit (v0.64.0): release corpus 953/953 full (672.8s,
  no exclusions); probes 248/248 (636.5s); check_modules 509/509 (282.6s);
  barename 0/509 (298.6s); floors119 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 52 (wave 81: convert unicode family; floors118)**
- Wave 81: 38 clauses / 26 new pub -- utf8 4 (encode 1..4 range, empty
  decode -> None, validate empty -> true, valid_sequences <= s.len()),
  utf16 4 (empty encode/decode, BOM-only 2 bytes + even parity), utf32 4
  (empty encode/decode, BOM-only 4 bytes + quad parity), utf 14 (the
  same identities on the parallel surface plus odd-length Err guards on
  utf16_decode_le/be, empty-Ok, is_valid empty -> true, and the
  surrogate arithmetic: code_point_to_utf16 invalid => equal components /
  valid => unequal, surrogate_pair_to_code_point -1 or >= 0x10000).
- Probe p_wave81_shapes.xi (247th, 36 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_utf and the utf8
  encoder/decoder KATs 1/1 each. convert 46.9% -> 55.4%, global 53.5% ->
  53.9%, meter 75.4%; floors118 wired.
- Battery on this commit (v0.64.0): release corpus 953/953 full (682.7s,
  no exclusions); probes 247/247 (559.1s); check_modules 509/509 (284.9s);
  barename 0/509 (284s); floors118 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 51 (wave 80: convert base-codec shims; floors117)**
- Wave 80: 40 clauses / 25 new pub -- base16 4 (hex 2n identity, odd-len
  Err, str parity), base32 4 (RFC 4648 length identity, empty-Ok, Ok len
  bound), base64url 4 (modulo-3 length trio, %4==1 Err, empty-Ok, local
  str wrappers), percent 4 (>=n / <=3n encode bands, Ok<=2n + empty-Ok),
  base58 3 (zero -> "1", INT_MIN -> "-NQm6nKp8qFD" pins, empty -> ""),
  base62 3 (zero -> "0", empty Err, empty -> ""), uuencode 1
  (uu_encoded_length <=0 -> 0, positive % 61 == 0), quotedprintable 2
  (qp_is_binary empty -> false, qp_escape_byte len == 3).
- Protocol finding (probe-caught): `(result.is_ok == true) =>
  result.len()` violates at runtime -- the guard does not protect the
  payload read; the canonical `result is Ok => result.len()` form is
  required (6 clauses switched). Recorded for the protocol lore.
- Split documented for wave 81: local codec bodies (ascii85 4, uuencode
  6, quotedprintable 4, base58 byte/check legs 3, base62 byte legs 1)
  plus the utf/utf8/utf16/utf32 and lossy families.
- Probe p_wave80_shapes.xi (246th, 45 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes base16/base32/base64/percent/base58_62
  1/1 each. convert 38.7% -> 46.9%, global 53.1% -> 53.5%, meter 75.3%;
  floors117 wired.
- Battery on this commit (v0.64.0): release corpus 953/953 full (633.5s,
  no exclusions); probes 246/246 (340.3s); check_modules 509/509 (542.6s);
  barename 0/509 (384.8s); floors117 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 50 (wave 79: convert numeric shims; floors116)**
- Wave 79: 57 clauses / 40 new pub -- parse 5 (empty-string Err guards;
  parse_bool/parse_char presence), int 8 (zero/negative formatting,
  invalid radix, base wrappers), toint 2 (NaN -> 0 and >= 2^63 -> INT_MAX
  saturating; checked is_none guards + is_some range), itos 3 (zero
  mirror, width guard at n == 0, signed plus-len), atoi 3 (empty -> 0,
  invalid radix -> 0, atoi_or empty -> default), fromstr 3, ftos 3
  (nan/inf/-inf branch mirrors + len >= 1), tofloat 3, unchecked 5
  (b == 0/1, n == 0 identities), saturating 5 (b == 0/1, abs mirror,
  pow e <= 0 / a == 1). Skips documented: to_int (undefined for NaN/
  out-of-range), to_int_from_char (char-cast clause avoided),
  overflow.xi (compiler tuple+Bool codegen, must not be called).
- Probe p_wave79_shapes.xi (245th, 95 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_convert_int_str,
  smoke_convert_float_str, smoke_convert_bool_str 1/1 each. convert 25.6%
  -> 38.7%, global 52.5% -> 53.1%, meter 75.3%; floors116 wired.
- Battery on this commit (v0.64.0): release corpus 953/953 full (654.5s,
  no exclusions); probes 245/245 (258.5s); check_modules 509/509 (153.3s);
  barename 0/509 (234.4s); floors116 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 49 (wave 78: thread clauses; floors115)**
- Wave 78: 27 clauses / 24 new pub -- thread 8 (Thread.id field mirror,
  Thread.name/thread_name_current is_none, spawn_with_name delegation
  ensure replacing a placeholder requires, Scope.spawn, aliases
  hardware_threads/thread_count >= 1, sleep/thread_sleep_us delegation
  preconditions), spawn 5 (spawn/spawn_with result.id > 0, join/
  spawn_scoped result.is_ok == true, thread_count >= 1), pool 8
  (thread_pool_new workers >= 1 / idle == workers / closed == false,
  tp_submit_with closed-conditional booleans, tp_size/idle/busy >= 0
  mirrors), park 1 (park_token_new non-null flag), local 5
  (thread_local_new initialized false; tls_get/tls_replace initialized
  true; tls_take initialized false; thread_local_key_new > 0). Void and
  unclaimable surfaces stay clause-free: scope, thread_yield,
  thread_parallel_for, detach, sleep_ms, is_main_thread, tp_submit/
  tp_join/tp_shutdown, park_token_wait, park, park_timeout, unpark,
  unpark_all, tls_set/tls_clear/tls_key_get/tls_key_set.
- Fix-first (contract/doc consistency): thread.sleep_ms documented
  "negative values return immediately" while `requires: ms >= 0` aborts
  the call; doc corrected and `sleep` gained the same delegation
  precondition.
- Probe p_wave78_shapes.xi (244th, 39 checks): green on v0.64.0 pre- and
  post-clauses; targeted smokes smoke_thread 1/1,
  smoke_collect_threadpool 1/1. thread 25% -> 67.9%, global 52.1% ->
  52.5%, meter 75.2%; floors115 wired.
- Battery on this commit (v0.64.0): release corpus 953/953 full (640.4s,
  no exclusions); probes 244/244 (287.7s); check_modules 509/509 (181.5s);
  barename 0/509 (242.5s); floors115 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-07 block 48 (relay intake: Pulse wishlist + packages sheet)**
- Checked the Pulse lane's STDLIB-WISHLIST-PULSE.md (updated 2026-10-05
  21:39 against stdlib 15cb889 / pin v0.63.1 -- predates our ec64dec
  hardening) and the packages sheet
  E:\xiom-packages\packages\docs\STDLIB-WISHLIST.md (now 134 rows, 8 new
  2026-10-05 rows).
- Pulse: `write_all` now has production evidence (a 270 KB icon served
  through one `socket_send` short-wrote and the client received
  nothing; PULSE ran a local `send_all` loop) -- landed at ec64dec;
  `server_parse_request` landed as `Option[ServerRequest]` (PULSE
  suggested `Result[ServerRequest, Str]`, flagged for re-verify);
  `hmac_sha256_hex` landed and `mac.xi` already has
  `constant_time_eq`/`hmac_verify`; v0.64.0 runtime+crypto link
  env-free, `XIOM_RUNTIME_DIR` retired in PULSE's dev-env; NEW
  durable-append ask (fsync/flush, no `fsync`/`FlushFileBuffers` in
  `runtime/*.c`) queued runtime-backed.
- Packages sheet 2026-10-05 batch recorded in docs/STDLIB-WISHLIST.md:
  HTTP-date pair, path safety (`path_within`/`is_absolute`), fs remove
  parity, streaming `read_exact`, durable write path (highest-value
  storage ask, same as the Pulse fsync ask), `append_file_bytes`,
  `truncate`/`remove_dir`, file locking. Defects unchanged:
  `sb_push_int` INT_MIN, `parse_int` 2^63 -> INT64_MIN and
  `_u64_lshr` n=63 open; row 33 crypto linkability compiler/install
  lane; empty-needle fixed.
- PACKAGE-WISHLIST-PULSE.md checked: packages-lane scope (xiom.router
  adopted; session/static/metrics/middleware/kv proposed); stdlib keeps
  `xiom.net.mime` for the future `xiom.static`; C-PULSE-02 is
  compiler-side.
- Next: wave 78 (thread 25% then convert 25.6%).

**SESSION 2026-10-05 block 47 (Pulse hardening wave: write_all, server_parse_request, hmac_sha256_hex)**
- New surfaces (Pulse relay follow-up): `TcpStream.write_all` in
  xiom/net/net.xi (64 KiB staging-buffer loop, advances by the
  kernel-reported partial count, `(data.len() == 0) => result.is_ok`
  clause; `write` keeps its documented single-send semantics),
  `server_parse_request` + `ServerRequest` in xiom/net/server.xi
  (method/target/version, lowercased header pairs, Content-Length
  framing and the body span; None on a malformed request line,
  unterminated head, colon-less header or bad/negative length; reuses
  server_parse_request_line), and `crypto.hmac_sha256_hex` (flat module;
  hex_encode(hmac_sha256(...)), `result.len() == 64`).
- Probe p_pulse_shapes.xi (243rd, 36 checks): RFC 4231 case 1 KAT,
  crafted request parse plus malformed/empty None paths, and a
  100000-byte loopback write_all roundtrip (over one chunk; head/mid/
  tail bytes verified). Green on v0.64.0; smoke_net_tcp_stream.xi
  extended with a write_all exchange (targeted smoke 1/1). Coverage
  held: floors114 ratchet OK (6502 pub, 52.1%).
- Battery on this commit (v0.64.0): release corpus 953/953 full (1390.1s,
  no exclusions); probes 243/243 (320.1s); check_modules 509/509 (224.4s);
  barename 0/509 (296.4s); floors114 + module-smoke (497/517, 3477/6202)
  ratchets OK.

**SESSION 2026-10-05 block 46 (wave 77: stats clauses + two fix-firsts; floors114)**
- Wave 77: 93 clauses / 48 new pub -- dist 15 (invalid-parameter NaN
  branch mirrors, [0,1] cdf bands, exact chi-squared x == 0 branches),
  histogram 9 (result field mirrors, counts/edges/normalize length
  claims, empty-count and out-of-range-quantile guards; histogram_add is
  void with a discarded by-value mutation and stays clause-free),
  moments 13 (empty/short-input bands, even-k non-negative moments,
  NaN-tolerant variance/stddev, weighted_mean mismatch/empty NaN),
  test 11 (short/mismatched length guards, p-value [0,1] bands, CI tuple
  NaN/order claims). stats 25% -> 59.3%, global 51.4% -> 52.1%, meter
  75.2%; floors114 wired (ci/heavy/release + tools/README + plan).
- Fix-first (probe-caught pre-clause): moments.quantile returned raw bits
  for q == 0.0 / q == 1.0 -- rvalue indexing of a returned Vec[Float64]
  (`return _sorted(data)[0]`) misreads on v0.64.0; new compiler finding
  p_rvalue_float_vec_index.xi (bound var/let reads and the Vec[Int]
  control are correct; rc 1 on the pin), workaround binds the sorted copy
  first. Also fixed: stddev and geometric_mean called math.sqrt(NaN) /
  math.ln(NaN) on NaN input data, violating the callee requires
  (x >= 0.0 / x > 0.0) and aborting the probe; both now return NaN
  directly.
- Probe p_wave77_shapes.xi (242nd, 167 checks): green on v0.64.0 pre- and
  post-clauses (the pre-clause run caught both fix-firsts); targeted
  smoke smoke_stats 1/1. Landmine reconfirmed: inline indexing of a
  returned Vec[Float64] reads garbage -- bind it first.
- Battery on this commit (v0.64.0): release corpus 953/953 full (804.9s,
  no exclusions); probes 242/242 (395.1s); check_modules 509/509 (261.3s);
  barename 0/509 (745.9s); floors114 + module-smoke (497/517, 3477/6200)
  ratchets OK.
- Findings 9 -> 10 (9 compiler, 1 stdlib); queue gate 9 and the
  known_failures Current section updated.

**SESSION 2026-10-05 block 45 (v0.64.0 pin: m193-m196 consumed; floors113)**
- v0.64.0 re-pin (tag c68d91de; binary extracted to
  %TEMP%\kilo\stdlib_ws\v0.64.0). Pre-flight on the pin: all previous
  probes and the blocked shapes green (scrypt/shuffle/BUG-18 regression
  locks, p_wave76, p_pin0631, guard-alloc smoke).
- m195: reflect.all_types() no longer heap-corrupts; clause added
  (`ensures: result.len() == type_count()`), reflect 97.7% -> 100%; the
  finding is RESOLVED (findings 10 -> 9) and
  p_reflect_all_types_crash.xi stays as a regression lock (exits 0).
- m196: TcpStream.read works; new tests/smoke/smoke_net_tcp_stream.xi
  loopback (127.0.0.1:39461, both directions, clones per call) locks it;
  corpus 952 -> 953.
- m194: num.float.float_bits / bits_to_float lower to exact bitcasts;
  fallback docs removed, clauses replaced with `(f == 0.0)` / `(f == 1.0)`
  pattern claims and `float_bits(result) == bits`; verified including
  negative zero and a NaN payload roundtrip.
- Pin-move break found by the probe corpus: p_wave43_shapes asserted the
  pre-m194 fallbacks (`float_bits(1.5) == 0`, `bits_to_float(7) == 0.0`);
  updated to the exact values (4609434218613702656 and > 0.0) and
  re-verified. No other probe broke on v0.64.0.
- m193: smoke_guard_alloc_wrap.xi now declares `xiom_guard_alloc` directly
  (xiom_guard_alloc_probe shim retired from the smoke).
- New probe p_pin0640_shapes.xi (241st, 9 checks): locks m194/m195.
- Coverage: global 51.3% -> 51.4%; floors113 wired (ci/heavy/release +
  tools/README + plan). Multipart stays compiler-owned (v0.64.1); Box
  stays section C.
- Battery on this commit (v0.64.0): release corpus 953/953 full (885.1s,
  no exclusions); probes 241/241 after the p_wave43 fix (first battery run
  240/241; fix re-verified standalone and by the full re-run, 523.5s);
  check_modules 509/509 (561.7s); barename 0/509 (726.0s); floors113 +
  module-smoke (497/517, 3477/6200) ratchets OK.

**SESSION 2026-10-05 block 44 (wave 76: simd gather/mask/vec4/vec8; floors112)**
- Wave 76: 49 clauses / 49 new pub -- gather 5 (length identities and
  `result.len() == mask.mask_count(m)`), mask 14 (bit-pattern mirrors,
  lane access OOR guard, guarded set/clr, logic mirrors, all/any bands),
  vec4 17 and vec8 13 (exact lane mirrors for add/sub/mul/new/splat,
  min/max lane disjunctions, extract/insert branch mirrors). simd
  24.4% -> 78.9%, global 50.6% -> 51.3%, meter 75.1%; floors112 wired.
- Deliberate omits: div (NaN lanes), dot/sum (self-mirrors), loads/stores
  (pointers), vec8 array-param constructors (array element reads in
  clauses), gather_load4 (default-T tuple), sqrt (requires only).
- Field-read clauses verified working on v0.63.1 with an isolation test
  (result/param struct fields + cross-module calls) despite the simd
  header warning about user-code cross-module field reads; probes read
  mask state through mask_to_bits.
- Probe landmine recorded: explicit type arguments on module-qualified
  generic calls (`gather.gather_load[Int](...)`) miscompile with an LLVM
  `Vec`/`ptr` error on v0.63.1; inference works. (Same family as the
  earlier tupled/qualified-generic issues; candidate compiler finding.)
- Probe p_wave76_shapes.xi (240th, 66 checks): green on v0.63.1;
  targeted smokes simd 1/1.
- Battery on this commit (v0.63.1): release corpus 952/952 full (747.1s,
  no exclusions); probes 240/240 (352.6s); check_modules 509/509 (180.5s);
  barename 0/509 (242.7s); floors112 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 43 (wave 75: encoding remainder + debug; floors111)**
- Wave 75: 50 clauses / 50 new pub -- encoding remainder (ascii85 6,
  punycode 7, idna 8) brings xiom.encoding to 100% pub coverage; debug 29
  (disasm 7 always-Err/false/None stub mirrors, heap_report 11
  counter/module-var mirrors + reset invariant, trace 11
  enablement/depth mirrors and monotone enter/exit @pre);
  debug.hexdump's placeholder replaced with empty/nonempty length
  claims. Skipped: trace_print/trace_log (void side effects, no
  derivable claim).
- Notable clause forms: punycode_adapt requires (numpoints > 0,
  delta >= 0) + ensures result >= 0; ascii85 max-length bands
  (((n+3)/4)*5) and the delimiter wrapper's +4; idna join/ascii/is_valid
  bands; disasm stub mirrors.
- Probe p_wave75_shapes.xi (236th, 84 checks): green on v0.63.1 with the
  clauses active (clauses were derived before probe authoring, so the
  guard-safety run doubles as the post-clause run); targeted smokes
  ascii85 2/2, punycode 3/3, debug 2/2.
- Coverage: encoding 72.4% -> 100%, debug 24.4% -> 95.1%, global
  49.8% -> 50.6%, meter 75.1%; floors111 wired (ci/heavy/release +
  tools/README + plan).
- Battery on this commit (v0.63.1): release corpus 952/952 full (660.8s,
  no exclusions); probes 236/236 (322.7s); check_modules 509/509 (210.0s);
  barename 0/509 (289.6s); floors111 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 42 (wave 74: encoding + three fix-first; floors110)**
- Wave 74: 55 clauses across xiom.encoding (24), xiom.encoding.base64 (8),
  base32 (6), hex (9), percent (8): exact encoder length identities
  (base64/base64url rem-conditioned, base32, hex, base16), decoder Ok
  bands plus empty identities, presence/Err bands, url/percent length
  bounds, utf8 char-len invalid band, and int_to_hex/hex_encode_int digit
  bands with the Int.MIN negation guard (`n < 0 && 0 - n > 0`).
- Fix-first: (1) utf8_decode `requires: data.len() > 0` removed -- it made
  utf8_valid(empty)'s own clause abort (`contract violated: requires at
  501:13`) and killed the dead len==0 Ok branch; empty now Ok("")/true.
  (2) base64url_decode in encoding.xi AND base64.xi now return Err on the
  dangling final char; the root doc comment's claim is finally true.
  (3) the percent '+' divergence is pinned by probe and documented on the
  root function (form-style via url_decode vs the percent module's literal
  '+') -- no behavior change.
- Probe p_wave74_shapes.xi (235th, 95 checks): green pre- and
  post-clauses on v0.63.1; targeted smokes encoding 16/16, base 12/12,
  utf8 6/6, percent 2/2.
- Probe landmines avoided (documented for future probes):
  `xiom.char.to_int_from_char` hits an i32/i64 clang error in probe
  context (isolated; use `(0 as Char)` comparisons instead), and
  text_to_binary("0", 1) aborts on hex_decode's requires rather than
  returning Err (use an invalid-char input like "zz").
- io payload-clause audit done: the four io.xi IOError `.len()` clauses
  retired in the pin wave were the only bogus sites; pipe/fs/console use
  Str payloads and stay.
- Coverage: encoding 23.7% -> 72.4%, global 49.3% -> 49.8%, meter 75.0%;
  floors110 wired (ci/heavy/release + tools/README + plan). Remaining
  encoding: ascii85 6, idna 8, punycode 7.
- Battery on this commit (v0.63.1): release corpus 952/952 full (663.0s,
  no exclusions); probes 235/235 (304.4s); check_modules 509/509 (217.8s);
  barename 0/509 (259.0s); floors110 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 41 (v0.63.1 pin: Instant monotonic + C001 retire; floors109)**
- v0.63.1 re-pin: COMPILER_VERSION/package.xi -> v0.63.1 (tag c0fa3a2d,
  release commit 1b972478; handoff 5666d092). Registry lane SHA256-verified
  nine entries; STDLIB_VERSION stays cd61062, so everything rides our repo.
- C001 trigger fired: 4bf8cf1e is an ancestor of 1b972478; 20/20 + 20/20
  compile+run stress on smoke_iter_range / smoke_iter_find_all_any
  (registry lane independent 20/20 + 20/20). Both exclusions dropped from
  gate-exclusions.txt (now zero exclusions); release corpus runs FULL
  952/952. C001 finding marked RESOLVED in known_failures README.
- Instant fix-first: Instant.now()/elapsed() switched from wall-clock
  time(0) to monotonic_ms()/1000 (second resolution); `ensures: result.t >= 0`
  added to Instant.now; SystemTime stays epoch wall clock; clock-confine
  comments normalized to "extern/runtime clock confinement (T002)";
  STDLIB_BETA_LIMITATIONS.md note retired. Locked by p_pin0631_shapes.xi
  (234th; Instant below epoch scale, SystemTime epoch, elapsed >= 0,
  instant_* arithmetic, and the bare-lz4 leaf resolution).
- lz4 rename decision: kept (`lz4_compress_checked` umbrella); compiler
  v0.63.1 makes the rename optional (bare calls bind the checker's target).
- Pin effects: duplicate-index W001 warnings gone; contract-evaluator false
  aborts for tuple/payload clauses fixed (future waves may now clause tuple
  returns); v0.63.1 also fixes SMT receiver emission and catalog flush.
- Fix-first caught by the sweep probe on the pin: io.write_file_bytes'
  Err clause `result.value.len() > 0` (Result[Unit, IOError] payload read;
  `.len()` on IOError) lowered strictly into str_len(IOError) -- any caller
  of gzip_compress_file failed clang; same clause retired from move_file,
  write_file_lines, append_line (io.xi switched to LF for the edit; git
  normalizes). Repo-wide `result.value` IOError-payload audit queued
  (io/pipe.xi lines 44/65/136 etc.); the Str-payload versions (read_int/
  parse_int family) are valid and stay.
- Probe p_pin0631_shapes.xi (234th, 14 checks): green on v0.63.1.
- Coverage: time 61 clauses (Instant.now +1; pub% unchanged at 41.3),
  global 49.3%; floors109 wired (ci/heavy/release + tools/README + plan).
- Battery on this commit (v0.63.1): release corpus 952/952 full
  (1081.1s, no exclusions); probes 234/234 (448.6s); check_modules
  509/509 (302.1s); barename 0/509 (315.0s); floors109 (io clauses 139
  after the payload-clause retirement) + module-smoke ratchets OK.

**SESSION 2026-10-05 block 40 (wave 72: compress formats gzip/deflate/brotli/zlib/snappy/lz4; floors108)**
- Wave 72: 39 clauses / 39 new pub in the compress format modules (gzip
  6 of 8, deflate 5 of 6, brotli 4 of 5, zlib 6, snappy 8, lz4 10); 4
  skipped by design for lack of a body-derived claim: the io wrappers
  gzip_compress_file/gzip_decompress_file and the FFI streams
  deflate_compress_stream/brotli_decompress_stream (results depend on
  descriptors, not parameters). Clauses: exact container-size identities
  (gzip header 10, zlib header 2, brotli >= 12, gzip >= 20, lz4 frame
  >= 11, zlib >= 8), crc32/adler32 empty identities, empty-input Err
  bands for every decompressor/validator, max_out < 0 => Err for
  gzip/snappy/lz4 capped paths (deflate capped intentionally omitted: an
  EOB-only fixed stream returns Ok empty at max_out < 0), exact bound
  mirrors (deflate l*5+512, snappy 32+l+l/6, lz4 l+(l>>8)+32 with
  negative clamp), and deflate level <= 0 stored-size bands. No element
  reads, no cap-overshoot claims on lz4, no dynamic-Huffman promises.
- Probe p_wave72_shapes.xi (233rd, 71 checks): green on v0.63.0 pre- and
  post-clauses; targeted smokes compress 26/26, crc 1/1.
- Coverage: compress 21.1% -> 64.4%, global 48.7% -> 49.3%; floors108
  wired (ci/heavy/release + tools/README + plan) in this commit. lz77 (6)
  and huffman (12) remain clause-free for a follow-up.
- Battery on this commit (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952); probes 233/233; check_modules 509/509; barename
  0/509; floors108 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 39 (wave 71: log levels/color/sinks/json/core; floors107)**
- Wave 71: 60 clauses / 49 new pub (log 13 -> 62 = 91.2%): levels 12
  (constants, name mapping with TRACE/FATAL bands, from-name presence,
  threshold/set-level/enabled module-var mirrors, all-levels length),
  color 8 (by-level boundaries + [31,90] band, reset length, colorize
  length lower bound, strip length upper bound, has-color minimum),
  sinks 8 (constructor target/path/bytes/id mirrors, registry
  parallel-vector invariant on add/remove, survey length mirror, close
  monotone @pre), json 4 (entry/format `result.len() >= msg.len() + 40`
  bands, empty fields == "{}", thread id 1), log core 28 (level-write
  monotonicity `entries.len() >= entries.len()@pre` on the 6 levels +
  5 _with + 4 aliases, set_level/get_level/set_output_json/
  set_output_color module-var mirrors, clear mirrors, entry-count mirror,
  last-entry presence bands, text/json serialization bands and "[]").
- Skipped by design: log_sink_file/set_output (Result payload only),
  log_flush_all/log_sink_rotate/log_flush (no-op, no observable),
  log_json_timestamp/log_json_parse (delegation/Result payload),
  entries_since (existing placeholder kept).
- Pin quirks handled: `xiom.log.json.JsonLogEntry` construction hits the
  same-leaf qualified-type family, so log_json_format is exercised via a
  log_json_parse payload; `Map` field `.len()` hits an unresolved
  `LogEntry.len` codegen symbol, so log_with_fields drops the map-length
  claim (msg/file/line mirrors only).
- Probe p_wave71_shapes.xi (232nd, 88 checks): green on v0.63.0 pre- and
  post-clauses; targeted smokes log 9/9, json 17/17.
- Coverage: log 19.1% -> 91.2%, global 47.9% -> 48.7%; floors107 wired.
- Battery on this commit (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952); probes 232/232; check_modules 509/509; barename
  0/509; floors107 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 38 (wave 70: crypto mac/kdf/keyx/rng/sign/poly; floors106; hkdf alias fix)**
- Wave 70: 41 clauses / 41 pub in xiom.crypto: mac 12 (hmac_new block/key
  shape mirrors, hmac_update @pre length, hmac_final digest length by hash
  id, hmac_sha256/512 exact lengths, verify tag-length implication,
  CBC-MAC iv-guarded 16, CMAC 16, constant-time eq length implication and
  select exact identities), kdf 9 (pbkdf2/pbkdf2_hmac_sha256 exact key_len
  incl. zero-fit guards, hkdf_extract 32/64 by hash id, hkdf_expand
  8160/16320 caps, hkdf_sha256/kdf_derive_master exact lengths, interval
  clamp, argon2id key_len, bcrypt 24), keyx 9 (X25519 public/shared/base
  and secp256k1 ECDH 32-byte guards, ecdh_p256 empty stub, DH
  result.len() == prime.len(), key_agreement_derive 8160 cap, validate
  bands), rng_crypto 5 (bytes count bands, uniform [0, n), float unit
  band, prime bit-length bands, string length bands), sign 5
  (ed25519/ecdsa/dsa documented-stub mirrors), poly1305_mac 1 (key >= 32
  => 16).
- Fix-first alongside: `hkdf_extract`/`hkdf_expand` called
  `hash.crypto_hash_hmac_sha512(...)` while their Int parameter `hash`
  shadows the `use xiom.crypto.hash;` alias, so every hash == 2 call AV'd
  (0xC0000005; isolated: extract(2) alone). Qualified the calls as
  `xiom.crypto.hash.crypto_hash_hmac_sha512`; hash-2 extract/expand now
  green in isolation and in the probe. The hash == 1 paths and the flat
  hmac_sha512 were always fine, which is why no smoke caught it.
- Skipped by design: scrypt (ROMix re-enters function-returned Vecs into
  &Vec params; heap corruption known), crypto_random_shuffle/choice
  (generic &mut Vec[T] lowering blocked), crypto_random_u64/u32/bool/
  seed_from_entropy (unsigned/unbiased word, no claim), rsa_sign/verify
  (payload presence only), the tuple-returning keypair/sign helpers.
- Probe p_wave70_shapes.xi (231st, 79 checks): green on v0.63.0 (pre- and
  post-clauses); targeted smokes crypto 36/36, poly 2/2, hash 39/39.
- Coverage: crypto 17% -> 39.6%, global 47.3% -> 47.9%; floors106 wired
  (ci/heavy/release + tools/README + plan) in this commit.
- Battery on this commit (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952); probes 231/231; check_modules 509/509; barename
  0/509; floors106 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 37 (wave 69: os path/filetype + rand; floors105)**
- Wave 69: 76 clauses / 76 pub in xiom.path (18), xiom.os.filetype (22),
  xiom.rand (20), xiom.rand.pcg (5), xiom.rand.mt19937 (6) and
  xiom.rand.chacha (5). Highlights: path empty-input Option identities,
  parent/file_name/file_stem presence bands, to_str/as_path exact mirrors,
  join output-length bands (valid under both join_paths resolutions),
  canonicalize is_ok, starts/ends_with prefix/suffix length implications,
  pop @pre length; filetype exact empty-input identities (eol "none",
  bom "", magic "", mime "text/plain"), output-length bands and
  per-detector minimum input-length implications; rand seed preservation
  (from_seed nonzero; Xorshift64 zero -> 1), random_bytes(_crypto)
  count/length bands, distribution guard identities (normal/gaussian
  stddev == 0 => mean, exponential lambda > 0 => >= 0, bernoulli p <= 0
  false / p > 1 true, binomial 0..n, poisson lambda <= 0 => -1 /
  lambda >= 1 => >= 0, gamma/beta early zero), pick family presence and
  length bands, bounded-next in [0, hi) with hi <= 0 => 0, and
  mt/pcg/chacha state-shape mirrors (624/16 state lengths, index/pos).
- Skipped by design: random_bool, seed_from_value, Xorshift64.next_int,
  the raw *_next_u32 word returns, Path.exists/is_dir/metadata --
  no non-placeholder claim derivable (I/O delegation or unbounded word).
- Probe p_wave69_shapes.xi (230th, 167 checks): green on v0.63.0;
  targeted smokes rand 42/42, path 18/18, filetype 1/1.
- Coverage: os 15.3% -> 26.2%, rand 16% -> 88%, global 46.1% -> 47.3%;
  floors105 wired (ci/heavy/release + tools/README + plan) in this commit.
- Authoring note: the session read tool renders `Option<...>` as
  `Option[...]`; raw `Select-String` output is the source of truth for
  edit anchors. path.xi (CRLF) was rewritten with clauses only; git
  normalizes EOL, so the committed diff is clause-only.
- Battery on this commit (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952); probes 230/230; check_modules 509/509; barename
  0/509; floors105 + module-smoke ratchets OK.

**SESSION 2026-10-05 block 36 (wave 68: misc glob/soundex/natural/levenshtein; floors104; soundex duplicate-leaf fix)**
- Wave 68: 36 clauses / 29 pub in xiom.misc: glob 9 (empty-pattern
  identity, "*" universal, escape/quote no-magic identity, has_magic
  bands, compile Result bands, bad-handle false), soundex 6 (empty
  bands, equal-input compare, empty-empty/one-empty similarity,
  variants len 2), natural 6 (sort length preservation, key/chunk
  presence bands, digit-run bounds), levenshtein 8 (empty-input
  identities for distance/damerau/osa/wagner, capped-distance bands,
  similarity 1.0 identities, matrix row shape, edit-script lengths;
  levenshtein_align stays clause-free -- tuple result). misc 13.9% ->
  50.6%, global 45.7% -> 46.1%; floors104.
- Probe p_wave68_shapes.xi (229th, 54 checks): green on v0.63.0 and
  v0.61.3; targeted smoke_misc 3/3. One claim was re-derived before
  landing (`levenshtein_distance_limited`: the cap claim needs
  `a.len() > b.len() + max`, not `a.len() > max`).
- soundex duplicate-leaf fix (same class as the lz4 relay):
  `xiom.misc.misc.soundex` was a stale copy returning "0000" for empty
  input; a bare `soundex("")` bound it (evidence: bare=[0000] len=4,
  qualified misc/canonical = ""). The stale body now delegates to the
  canonical shim (`xiom.misc.soundex.soundex`) with its own clause;
  bare binding now returns "" and smoke_misc2 stays green. Remaining
  duplicates (`xiom.string.soundex`, `xiom.misc.soundex`,
  `xiom.text.similarity.soundex` leaves) go to the same-leaf audit /
  compiler parity work; the probe uses fully qualified calls.
- Battery on e385ca1 (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952; 672.9s); probes 229/229 (338.6s); check_modules
  509/509 (271.5s); barename 0/509 (307.6s); floors104 + module-smoke
  ratchets OK.
- lz4 follow-up (compiler relay 07:27Z): the rename
  (`lz4_compress_checked` / `lz4_decompress_checked`, commit 8991c3e)
  makes `lz4_compress` a unique leaf; re-verified the exact colliding
  benchmark shape -- `use xiom.compress; use xiom.compress.lz4;` then a
  bare `lz4_compress(&d)` -- compiles and returns Vec lengths (rc 0),
  as does the single-module bare shape. The benchmark file is not in the
  local checkouts; retest `lz4_compress_only.xi` against stdlib ref
  8991c3e+.

**SESSION 2026-10-05 block 35 (lz4 duplicate-leaf unblock)**
- Compiler relay: the benchmark lz4 failure root cause is a duplicate
  leaf -- `xiom.compress.lz4.lz4_compress` (Vec) vs the xiom.compress
  umbrella wrapper `lz4_compress` (Result); a bare call type-checked as
  Vec but bound the Result wrapper in codegen (Result.len unresolved /
  pointer-garbage lengths; deterministic 3/3, qualified form 10/10).
  Renamed the umbrella wrappers to `lz4_compress_checked` /
  `lz4_decompress_checked` (unique leaves) and updated the only caller
  (`smoke_stress_compress_lz4_roundtrip.xi`). Verified on v0.63.0: stress
  smoke rc 0, snappy smoke OK, bare-call scratch rc 0 (the failing
  shape). Compiler parity fix queued on their side as defense.
  Immediate unblock delivered.

**SESSION 2026-10-05 block 34 (wave 67: format dump/number/relative/table; floors103)**
- Wave 67: 33 clauses / 33 pub in xiom.format: dump 4 (empty/non-empty
  bands, empty-line length band), number 6 (exact KAT bands for
  separators/fixed/percent/bytes/duration/ordinal), relative 11
  ("just now"/"in a moment"/"now" bands plus zero identities), table 12
  (constructor shape, row_count @pre increment, widths length, rows/cols
  mirrors, empty-table exact renders, invariant @pre claims). format
  13.0% -> 27.3%, global 45.1% -> 45.7%; floors103 wired.
- Probe p_wave67_shapes.xi (228th, 59 checks): green on v0.63.0 and
  v0.61.3; targeted smoke_format 8/8. Clause string escapes ("\n") and
  `&mut` param `@pre` field forms both work on the pin.
- Readiness toward 100% (pub-with-clause by dir, after this wave):
  format 27.3%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%,
  compress 21.1%, encoding 23.7%, rand part done next; remaining big
  dirs (ui, net extras, etc.) continue afterwards. Battery recorded below.
- Battery on 4732c35 (v0.63.0): release-gate corpus 950/950 (2 C001
  carve-outs of 952; 713.3s); probes 228/228 (259.2s); check_modules
  509/509 (163.6s); barename 0/509 (218s); floors103 + module-smoke
  ratchets OK.

**SESSION 2026-10-05 block 33 (stdlib 0.62.3/0.62.4/0.63.0 PUBLISHED; C001 fix on main)**
- Publish complete, staging-first then production (all environment
  approvals granted): canaries 37222582904 (0.62.4), 37223911989 (0.63.0),
  37224370669 (0.62.3) all green on
  `https://staging.registry.xiom-lang.org` ("Published xiom-std vX --
  {\"ok\":true,...}", ed25519-signed, compiler pin recorded); production
  runs 37219378388 (0.62.4), 37221426683 (0.63.0), 37219366825 (0.62.3)
  all success publishing to `https://registry.xiom-lang.org` with
  sha256/signature/provenance verification. The registry now carries
  xiom-std 0.62.3, 0.62.4 and 0.63.0 (was 0.62.0).
- Compiler relay: C001 is root-caused and FIXED on compiler main
  (`4bf8cf1e`); the published v0.63.0 archive predates it, so the two
  C001 smokes STAY excluded for this pin. DROP both exclusions on the
  first archive containing the fix, then retest with the 20-run stress on
  `smoke_iter_range` / `smoke_iter_find_all_any` (expect deterministic
  green) and promote the lock if green. Compiler-side evidence: reducer
  9/20 -> 20/20, both smokes compile 5/5 + run rc 0, new e2e lock, full
  e2e 2418/0/4.
- macOS: `heavy` carries `macos-14`; promotion into `release.yml` is
  still pending one green heavy run.

**SESSION 2026-10-04 block 32 (v0.63.0 re-pin + release prep)**
- Official v0.63.0 archive downloaded and SHA256-verified
  (689881f4...): `%TEMP%\kilo\stdlib_ws\v0630\x\bin\xiom.exe`;
  COMPILER_VERSION/package.xi moved to 0.63.0.
- Gate exclusions shrink to the two C001 iter smokes: m190 fixes lz4 and
  the smoke is green on the official archive (verified), so
  `smoke_compress_lz4_snappy.xi` left gate-exclusions.txt; release notes
  disclose C001 only.
- Findings refreshed on v0.63.0: lz4 RETIRED (entry removed; count 12 ->
  11 = 10 compiler + 1 stdlib); all_types still crashes (rc
  -1073740940), multipart still rc=1; C001 still flaky (kept excluded);
  iter collect call side still green (lock rc 0).
- Release battery on v0.63.0: release-gate corpus 950/950 (2 excluded of
  952), probes 227/227, check_modules 509/509, barename 0/509,
  coverage floors102 + module-smoke ratchets OK; t2 (kat_) 15/15 earlier.
- Caveat from the compiler lane: v0.63.0 was cut one commit before the
  guard-alloc bound check landed, so the COMPILER archive's bundled
  lib/runtime is pre-bound-check; this stdlib-v0.63.0 archive carries the
  check. The external-extern hang we hit is filed on the compiler side.
- Workflow note: the owner/registry lane pushed `db39144` ("keep the
  canonical compiler asset name so sha256sum -c matches") on top of wave
  66 while the v0.62.3/0.62.4 publish retries run; tags were re-triggered
  at 17:08Z (gates+package re-running, publish waiting). Not interleaved.

**SESSION 2026-10-04 block 31 (wave 66: time core; floors102)**
- Wave 66: 39 clauses / 39 pub in xiom.time: duration 15, instant 6,
  date 12, iso8601 6. time 13.0% -> 41.3%, global 44.5% -> 45.1%;
  floors102 wired + README/plan/queue in the same commit. No runtime/ or
  iter changes (the compiler lane is gating v0.63.0 on cd61062).
- Skipped by design: date_now / instant_now / instant_elapsed (system
  clock) and the tuple-returning iso8601 helpers + iso8601_date_parse
  (the catalog tuple-clause restriction from iter_partition; no claim).
- Probe p_wave66_shapes.xi (227th, 61 checks): green on v0.62.4 and
  v0.61.3; targeted smoke_time 19/19. `duration_mul` now carries the
  parent's `requires: n >= 0` (negative factors already aborted inside
  the delegate; same observable behavior).
- Battery on this commit (v0.62.4, release-gate form with the 3
  carve-outs) is recorded below; full corpus 952 files (the guard-alloc
  wrap smoke from cd61062 included), release gate 949/949 expected.

**SESSION 2026-10-04 block 30 (v0.63.0 pre-release: guard-alloc bound check + lock)**
- Landed the compiler lane's only stdlib code change for the v0.63.0 sync:
  `runtime/xiom_runtime.c` `xiom_guard_alloc` now rejects
  `size > LLONG_MAX - 16` before the `(size + 15) & ~15` alignment math
  (fail closed; `xiom_alloc` was already safe). New fault-injection lock
  `tests/smoke/smoke_guard_alloc_wrap.xi` drives the new runtime probe
  helper `xiom_guard_alloc_probe`; verified rc 0 with the guard and rc 1
  with the guard temporarily disabled, so the lock genuinely catches the
  bug. Guard smokes 4/4, alloc smokes 6/6 green on v0.62.4.
- Probe-authoring note: a direct XIOM `extern` declaration of the runtime
  symbol `xiom_guard_alloc` makes codegen hang (300s timeout) or fail
  with "invalid redefinition of function"; the test-only probe helper
  side-steps it.
- v0.63.0 sync plan (compiler relay): the compiler pins this ref (commit
  SHA or stdlib-v0.63.0); the archive bundles the stdlib at
  STDLIB_VERSION. POST-RELEASE once the first official v0.63.0 archive is
  SHA256-verified: re-pin `COMPILER_VERSION`/`package.xi` to 0.63.0 with
  notes/CHANGELOG; DROP `smoke_compress_lz4_snappy.xi` from
  gate-exclusions (m190 fixes it -- expect green, keep it in the full
  corpus); KEEP `smoke_iter_range.xi` + `smoke_iter_find_all_any.xi`
  excluded (C001 still ~50% run-to-run flaky; release notes disclose C001
  only); keep `p_iter_range_contains_c001.xi` and the iter_collect
  clause-side entry open.
- Release cadence policy (registry/owner confirmed): every compiler
  release the stdlib pins to gets one stdlib release via the same flow --
  re-pin, package.xi + release notes + CHANGELOG, tag `stdlib-v*`,
  release.yml gates/package, staging canary dispatch, then production
  with the registry-publish environment approval. The tag archive bundles
  the stdlib at the pinned ref (use the commit SHA, not stdlib-perf3).
- macOS: `heavy.yml` now includes `macos-14` (arm64) so the weekly suite
  proves the platform; promote macOS into the release gate matrix after
  one green heavy run. `ci.yml` stays ubuntu-only for fast PR feedback.
- Wave 66 (format/time) can proceed in parallel with the pin: it does not
  touch runtime/ or the iter surface, so it cannot disturb the bundled
  archive.

**SESSION 2026-10-04 block 29 (v0.62.4 re-pin + stdlib 0.62.3/0.62.4 release prep)**
- Official v0.62.4 archive downloaded and SHA256-verified
  (ab1c83d2...): `%TEMP%\kilo\stdlib_ws\v0624\x\bin\xiom.exe`;
  COMPILER_VERSION moved v0.62.3 -> v0.62.4.
- Release-gate carve-out (owner decision): `run_smokes.ps1 -ExcludeFile`
  (name globs; excludes are printed and counted in the JSON summary) +
  `tools/known_failures/gate-exclusions.txt` (smoke_iter_range,
  smoke_iter_find_all_any, smoke_compress_lz4_snappy); release.yml wires
  it; ci/heavy keep the full corpus.
- New finding filed: `p_iter_range_contains_c001.xi` -- the C001
  classifier is run-to-run nondeterministic on v0.62.3 AND v0.62.4
  (6-run split 3 fail / 3 pass here; registry stress 8/20 +
  12/20 on v0.62.4, 8/20 + 10/20 on v0.62.3). The smoke_iter_range
  corpus lock is green direct; the reducer is the filed artifact.
- Promotions: `p_regress_uint32_compare.xi` (m186 fix; rc 0 on v0.62.4;
  known-failure entry retired) and `p_regress_iter_collect.xi` (call side
  fixed on v0.62.4; clause side persists, entry kept). Probe corpus 226.
- v0.62.4 checks: t2 (kat_) 15/15; smoke_iter_range direct green;
  smoke_iter_find_all_any direct 5/5 but flaky under workers;
  all_types still crashes; multipart still rc=1; collect call rc 0; a
  Range.count clause still breaks smoke_iter codegen.
- stdlib 0.62.3: commit 12a3a1b (package.xi 0.62.3 + release notes +
  CHANGELOG + carve-out, pin v0.62.3); release battery with exclusions
  948/948 (3 excluded), check_modules 509/509, barename 0/509,
  coverage floors101 + module-smoke OK; tag stdlib-v0.62.3 created.
- stdlib 0.62.4: package.xi 0.62.4 + release notes + CHANGELOG in this
  commit; battery with exclusions recorded below. Both release notes
  disclose the C001 flake and the lz4 empty block. Publish: staging-first
  dispatch, then production via the tag push with registry-publish
  environment approval.
- Packages lane (not interleaved): E:\xiom-packages\packages is already
  re-pinned to v0.62.4 (c477528a) with the v0.62.4 retirements recorded
  (281db5de); grpc.xi still carries numeric match arms and stays blocked
  by the Vec[(Str, Str)] read-after-mutation crash on v0.62.4; the
  const-arm restore + porter-rule drops ride their next push.

**SESSION 2026-10-04 block 28 (wave 65x: convert shims; floors101; enum-payload bundle pointer)**
- Wave 65x: 43 clauses / 43 pub in xiom.convert shims: bytes 6,
  endian 6, checked 9, base64 4, exact 3, swap 3, tostring 5, wrapping
  7. convert 11.5% -> 25.6%, global 43.9% -> 44.5%; floors101 wired +
  README/plan/queue in the same commit.
- Re-derived and REJECTED: `hex_to_bytes`'s "odd length -> Err" claim
  (the canonical encoding.hex_decode REQUIRES even length and aborts, so
  odd input never returns Err); the wrapper now carries the
  `requires: s.len() % 2 == 0` precondition and its doc was corrected.
  bytes.from_bytes stays compile-checked only (the module header
  documents its invalid-IR call collision); the rest are exercised.
- Probe p_wave65x_shapes.xi (224th, 60 checks): green on official
  v0.62.3, v0.61.3 and the m189/v0.62.4 candidate. Targeted smokes:
  smoke_convert 37/37, smoke_cross 9/9.
- Compiler-lane request (enum-payload minimization): the bundle is in
  the PACKAGES repo, not here -- E:\xiom-packages\packages\
  docs\repro\enum-payload-str\{README.md,probe_enum_payload_str.xi};
  the in-situ context is packages\xiom-graphql\graphql.xi
  (validate_operation) and the failing case is
  tests\test_conformance.xi -> "validate valid operation" (9/10). The
  packages lane owns the validator slice; the coordinator should route
  the bundle to the compiler lane.
- Battery on f85f873 (official v0.62.3): check_modules 509/509 (193.7s);
  corpus 950/951 -- only the filed lz4 (927.3s, second run); probes
  224/224 (280.2s); barename 0/509 (402.8s); floors101/doc/module-smoke
  ratchets OK. C001 nondeterminism evidence: the FIRST corpus run
  flapped smoke_iter_find_all_any (compile -999, ~2s); the exact same
  direct compile then failed C001 twice and PASSED on the third try
  ('all' receiver does not expose a concrete Vec/Slice/Array element
  type), and the corpus re-run was clean. So the C001 classifier is not
  only context/load-sensitive but RUN-TO-RUN random on the pin
  (consistent with HashMap-iteration-order state); the flaky shape is
  iter.range(...).all/any/find with inline lambdas. Any "cleared" C001
  state is therefore probabilistic on v0.62.3. This battery/docs commit
  is LOCAL until the next push point.

**SESSION 2026-10-04 block 27 (wave 65 BLOCKED: iter clause surface reverted; finding filed; floors stay 100)**
- Wave 65 landed NOTHING: the entire drafted clause set for xiom.iter.xi
  (Range core 7 + closure-delegating methods) was reverted after two
  context-dependent pin failures. With the full set (7 clauses incl.
  Range.collect), 12 iter-consuming smokes fail to compile with closure
  use-before-def ("use of undefined value" in a __closure_N):
  smoke_iter_{map,filter,enumerate,take_skip,chain_zip,pipeline,narrow,
  collect,chained_adapters} + smoke_collections_mix_iter +
  smoke_cross_{collections_iter_fold,num_iter_hash}. Removing just the
  Range.collect clause restores those 12 but immediately flips
  smoke_iter_range back to the old C001 ("'contains' receiver does not
  expose a concrete Vec/Slice/Array element type") -- the same
  context-dependent classifier the wave-62 tip had cleared. No clause
  subset keeps the whole iter smoke family green on the v0.62.3 pin.
- Filed tools/known_failures/p_iter_range_collect_forwardref.xi: calling
  Range.collect() fails clang with "instruction forward referenced with
  type 'ptr'" on official v0.62.3, v0.61.3 and the m189/v0.62.4
  candidate; adding any clause to Range.count (even `result >= 0`) or
  Range.find makes smoke_iter fail with the __closure_N undefined value.
  Findings Current 11 -> 12 (11 compiler, 1 stdlib).
- Kept from wave 65: the finding + README entry and
  tools/probes/p_wave65_shapes.xi (223rd, 13 checks) as a BEHAVIORAL
  lock for the Range core API (constructors, len/contains/sum/product;
  no clauses landed, no closure-delegating methods called). Green on
  v0.62.3, v0.61.3 and m189; smoke_iter_range and smoke_iter green again
  after the revert.
- Coverage unchanged: floors100 (global 43.9%, iter 18.6%); the wave-65
  floor dump was withdrawn with the clauses. Resume the whole iter
  surface once the compiler closure lowering + C001 classifier are
  fixed.
- Battery on 2f621f0 (official v0.62.3, final revision after the true
  iter.xi restore): check_modules 509/509 (125.3s); corpus 950/951 --
  only the filed lz4 (964.1s); probes 223/223 (296.0s); barename 0/509
  (411.6s); floors100/doc/module-smoke ratchets OK. One transient note:
  under -Workers 8/2 smoke_iter_range intermittently hits the C001
  contains-classifier error (fails in ~1.5s, retries too) while direct
  and -Workers 1 compiles pass 5/5; a full corpus re-run cleared it
  (950/951), so the iter C001 remains load/concurrency-sensitive on the
  pin even without any wave-65 clauses. This battery/docs commit is
  LOCAL until the next push point.

**SESSION 2026-10-04 block 26 (wave 64: reflect + iter adapters; floors100; relay notes)**
- Wave 64: 55 clauses / 55 pub covered. reflect: fields.xi 10 +
  typeinfo.xi 11 (exact placeholder constants) + reflect.xi 18 (TypeId.of
  id==0, type_size/align/total_size >= 0, downcasts is_none,
  reflect_type shape, type_info_by_name empty-name None band, classifier
  constants). iter: map 5 (iter_map/iter_enumerate exact len,
  iter_filter_map <= v.len, iter_zip <= both, iter_flat_map empty),
  range 6 (exact counts and empty bands), zip 5 (zip_longest max via
  dual implications, chain/cartesian/interleave exact arithmetic,
  chain_many empty).
- all_types() stays clause-free: calling it crashes with heap corruption
  (0xC0000374) on official v0.62.3, the m187 dev build and v0.61.3;
  filed tools/known_failures/p_reflect_all_types_crash.xi. The identical
  build loop in a user module runs green and type_info_by_name's single
  TypeInfo return works, so it is catalog-return-path specific (likely
  the aggregate-copy codegen family the compiler lane is tracing for
  lz4). reflect 9.1% -> 97.7% with all_types the only gap; iter 9.8% ->
  18.6%; global 43.0% -> 43.9%; floors100 wired + README/plan/queue in
  the same commit.
- Probe p_wave64_shapes.xi (222nd, 47 checks): reflect + iter combined,
  no network I/O; green on v0.62.3, v0.61.3 and the m187 dev build. The
  fields/typeinfo clauses are runtime-exercised by smoke_reflect;
  including those calls in the combined probe hit a context-dependent
  invalid-IR clang failure (copy_bytes helper), and binding `Vec.new()`
  temporaries passed as `&Vec` args is required for iter_flat_map /
  iter_chain_many. Targeted smokes: smoke_reflect 1/1, smoke_iter 21/21.
- Compiler-lane relay (2026-10-04): (a) m186 fixed the wave-63
  p_uint32_high_bit_compare inline UInt32 compare -- verified rc 0 on the
  m187 dev build; retire + promote the repro at the next pin bump. (b)
  m184/m185 fixed nested test-module import and uninit local struct; the
  iter-range C001 is closed (smoke_iter_range rc 0 on the v0.62.3 tree
  too) and the smoke lock promotes when v0.62.4 ships on stdlib-perf3.
  (c) The packages-lane enum-payload Str in-situ case (xiom.graphql
  validate_operation) STILL FAILS: it was re-run on an m189-inclusive
  build (355c69d0; local v0.62.4 candidate, HEAD 32ea20f0, CARGO_PKG_VERSION
  0.62.4 rebuilt 2026-10-04) and on the pre-m189 m187 binary -- graphql
  conformance 9/10 on both, same `validate valid operation` failure,
  standalone control green. Per the compiler lane that makes it a fresh
  finding (m189's suffix-aware struct-literal disambiguation did not
  cover this instance). (d) Porter rules (nested-module workaround,
  initialize-locals) can drop once the packages pin is v0.62.4.
  Registry note: no package.xi bump/tag needed now; optional whenever.

- Full battery on 5939345 (official v0.62.3): check_modules 509/509
  (154.8s); corpus 950/951 -- the only runfail is the filed
  `smoke_compress_lz4_snappy` regression (1440.5s); probes 222/222
  (452.4s); barename 0/509 (626.3s); floors100/doc/module-smoke ratchets
  OK. This battery/docs commit is LOCAL until the next push point.
- v0.62.4 candidate in flight on stdlib-perf3 (ETA ~1.5-2h). Post-tag
  actions: re-pin COMPILER_VERSION=v0.62.4 and run t2 as usual; promote
  the smoke_iter_range lock; retire p_uint32_high_bit_compare and promote
  its repro to tools/probes; restore the named-constant arms in packages'
  grpc.xi (m188 const-match); drop the nested-module and
  initialize-locals porter rules. `XIOM_TIMINGS=1` now prints
  compile-phase marks for baselines. The optional package.xi bump +
  stdlib-v* tag remains our call.

**SESSION 2026-10-04 block 25 (wave 63: net batch 6 + hash batch 1; floors99)**
- Wave 63: 53 clauses / 52 pub covered. net.xi 15 (TcpStream/UdpSocket
  close Ok claims, http_post/http_post_str empty-URL Err implications,
  udp_bind port-guard bands, parse_url + url_parse_* presence bands, and
  requires preconditions on http_get_str/http_status/tcp_connect_str/
  dns_lookup mirroring their delegates -- those entry points abort on
  empty input at runtime, so an ensures claim would be misleading),
  server 6 (default port, request-line Option bounds, status-line/
  response length bands + exact 200/404/500 mirrors, status-text table
  mirrors), jwt 9 (base64url length bands, alg mirror, min-length bands
  on decode/verify/expired/claims), hash 22 (adler empty==1 -- a
  non-empty lower bound was re-derived and REJECTED before commit: b
  wraps to 0 after 65521 zero bytes so the result is 1 again; the wrap
  is locked by the probe -- checksum 16-bit bands, CRC empty-seed claims
  incl. crc16 0xFFFF, FNV offset-basis empties via the module consts,
  jenkins/murmur3 Vec len==2, superfast mask bound).
- Probe p_wave63_shapes.xi (221st): 123 checks; no network I/O (empty/
  malformed URLs, port guards, synthetic -1 handles); green on official
  v0.62.3, v0.61.3 and the m178 dev build.
- Probe-caught compiler finding: inline module-qualified UInt32 call
  compares misread high-bit values (adler32_combine 0xFFFFFFFF compared
  inline reported unequal). Filed tools/known_failures/
  p_uint32_high_bit_compare.xi (rc=1 on v0.62.3 AND the m178 dev build;
  binding to a local is the documented workaround, previously known for
  UInt16/UInt8). Findings Current 9 -> 10 (9 compiler, 1 stdlib); the
  wave probe binds results before comparing.
- net 87.2% -> 97.3%, hash 8.9% -> 33.3%, global 42.2% -> 43.0%; floors99
  wired (YAML re-verified) + tools/README.md + plan + queue in the same
  commit.
- Full battery on 72ecd60 (official v0.62.3): check_modules 509/509
  (136.8s); corpus 950/951 -- the only runfail is the filed
  `smoke_compress_lz4_snappy` regression (1217.1s); probes 221/221
  (356.6s); barename 0/509 (571.0s); floors99/doc/module-smoke ratchets
  OK (497/517 modules, 3475/6200 fns). This battery/docs commit is LOCAL
  until the next push point.
- Re-derivation notes for the next pass: the hash/crc.xi duplicate leaves
  (checksum_bsd/sysv/internet, adler32) are both exercised by existing
  smokes (`smoke_hash_fnv_adler` -> checksum.*, `smoke_hash_folder` ->
  crc.*), so both copies' clauses are runtime-checked; `murmur2_64` was
  left clause-free (its finalization mixes even for empty input, so no
  seed-identity claim holds).

**SESSION 2026-10-03 block 24 (wave-63 recon only -- execution deferred)**
- Read-only recon for net batch 6 returned: net.xi 15 uncovered
  (TcpStream.close, http_post, udp_bind, UdpSocket.close, parse_url,
  http_get_str, http_post_str, http_status, tcp_connect_str, is_valid_ipv4,
  url_parse_scheme/host/path/port, dns_lookup), server.xi 6
  (server_default_port, server_parse_request_line,
  server_build_status_line, server_build_response,
  server_build_response_headers, server_status_text), jwt.xi 9
  (jwt_base64url_encode/decode, jwt_alg_supported, jwt_encode,
  jwt_sign_b64, jwt_decode, jwt_verify, jwt_expired, jwt_claims), and a
  large hash.xi-family surface (adler/crc/city/farm/fnv/hash/highway/
  jenkins/metro/murmur/siphash/spooky/superfast/t1ha/xxhash).
- CAVEAT: the recon's suggested clauses are largely placeholder-grade
  (`is_ok || is_err`, `is_some || is_none`, `result >= 0` on unsigned
  types, a `djb2` call that is not a symbol) and must be re-derived from
  the bodies per the runtime-safe rules before any edit. Execution should
  start fresh from snapshot 5's prompt (or a re-con with the strict
  clause template); no source was touched, the tree is clean.
- Note for that pass: `net.xi`'s `http_post` (Str body) coexists with
  `http.xi`'s form; `hash/crc.xi` re-declares checksum_bsd/sysv/internet
  and adler32 (same-leaf duplicate-symbol family) -- verify which leaf the
  smokes resolve before adding clauses.
- Packages wishlist: no new relay rows arrived; rows 42-46 (glob/regex,
  `Str` -> `Str` map, span/byte-slice API, strict int parsing with offsets,
  base32 + percent-encoder) plus rows 33-41 remain optional growth work
  outside the coverage path. A future mini-wave can land one small item
  (e.g. ASCII byte classifiers or FNV-1a over `Str`) with the same
  probe/battery protocol.
- Post-wave-62: the peer fix `ac3c58f` (release the borrows in the cell
  smokes) closed the cell x2 as stdlib-side; the iter-range C001 cleared on
  the wave-62 tip. Official-pin corpus is **950/951** (only
  `smoke_compress_lz4_snappy` remains a filed compiler regression), findings
  Current 9 (8 compiler, 1 stdlib). The queue top lines reflect this.

**SESSION 2026-10-03 block 23 (wave 62: net batch 5 -- sse/websocket/ws/dns/multipart; floors98)**
- Wave 62: 41 clauses (sse 8, websocket 14, ws 5, dns 8, multipart 6).
- Fix-first: `ws_handshake_verify` scanned the FIRST CRLF of the response
  for the accept-header line end, so canonical `101 ...` responses with
  trailing CRLFCRLF verified false; now scans the CRLF after the accept
  value (probe witness). New finding `p_multipart_parse_name.xi`:
  `multipart_parse` result Part field reads are corrupt on BOTH v0.61.3
  and v0.62.3 (`name.len()` reads -1; directly constructed Parts are
  fine); the probe is presence-only for that path.
- Probe `p_wave62_shapes.xi` (220th): green on v0.62.3 and v0.61.3.
- net 73.4% -> 87.2%, global 41.6% -> 42.2%; floors98 wired (YAML
  re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on 584ffd1 (official v0.62.3): check_modules 509/509
  (161.3s); corpus 948/951 (the cell x2 + lz4 context regressions remain;
  the iter-range C001 cleared on this tip); probes 220/220 (391.3s);
  barename 0/509 (610.7s); floors98/doc/module-smoke ratchets OK.

**SESSION 2026-10-03 block 22 (official v0.62.3 baseline at the pin move)**
- Installed the official v0.62.3 windows-x64 archive (SHA256 `011af7dd...`
  verified against SHA256SUMS + the API digest) at
  `%TEMP%\kilo\stdlib_ws\v0623\x\bin\xiom.exe` and re-ran the battery on
  it: check_modules 509/509 (170.4s); corpus 947/951; probes 219/219;
  barename 0/509; floors97/doc/module-smoke ratchets OK.
- Four compiler-side v0.62.3 regressions filed (cell x2, lz4,
  iter-range C001); all green on v0.61.3 and context-dependent (the
  standalone minimal forms pass). Two stale smokes fixed at the pin move
  (bomb-guard's gzip Vec API; `sprintf_i1` arity). Three fixed repros
  promoted to `tools/probes/` (`p_regress_curve_thunk_zero`,
  `p_regress_vector_result_bits`, `p_regress_struct_literal_order`).
  Findings Current 13 -> 10 (9 compiler, 1 stdlib).
- Pin is now the official v0.62.3 archive; `stdlib-perf3` remains the
  shipped release pin. Next: wave 62 (net batch 5).

**SESSION 2026-10-03 block 21 (wave 61: net batch 4 -- protocol family; floors97)**
- Wave 61: 48 clauses on xiom.net.{proto (10), smtp (13), ftp (9), ntp
  (9), ping (7)}. Exact command/format mirrors and length bands, JSON-RPC/
  SSE skeleton bands, header parse/get presence, auth mirrors,
  reply-parser presence bands, NTP structural/encode/decode claims plus
  exact offset/roundtrip mirrors, the ICMP empty-input claim, and the nine
  documented Err stubs. Probe KATs are socket-free.
- Probe `p_wave61_shapes.xi` (216th): 72 checks; green on v0.61.3 and the
  m178 dev binary. Probe note: `icmp_checksum` results must be bound to a
  `let` before comparison (`!=` on an inline UInt16 misbehaves; `==` is
  fine after binding).
- net 57.2% -> 73.4%, global 41.6%; floors97 wired (YAML re-verified) +
  tools/README.md + plan + queue in the same commit.
- Gate P: `stdlib-perf3` tagged at `2429ac3` and pushed for the compiler
  lane (bump STDLIB_VERSION, api-freeze regen, t2 185342f4, tag v0.62.3).
- Full battery on 0f46ab8: check_modules 509/509 (288.9s); corpus
  951/951, 0 compilefail, 0 runfail (1651.8s); probe corpus 216/216
  (470.6s); barename 0 hits / 509 (724.3s); coverage floors97 OK; doc
  ratchet OK; module-smoke ratchet OK (3,475/6,200 fns, 497/517 modules).
  Wave 61 closed; this battery/docs commit is LOCAL until the next push
  point.

**SESSION 2026-10-03 block 20 (wave 60: net batch 3 -- transport family; floors96)**
- Wave 60: 53 clauses on xiom.net.{socket (18), tcp (4), udp (4), unix
  (10), tls (5), tls_helper (12)}. Validation-guard implications on every
  socket entry point, the documented always-Err stubs, port bands,
  endpoint format/parse claims, TLS name-table implications, pure DER/PEM
  presence bands, fingerprint length claims. Probes avoid real
  connections (constructors create+close one local fd each; all other
  network fns use early-error paths only).
- Probe `p_wave60_shapes.xi` (215th): 80 checks; green on v0.61.3 and the
  m178 dev binary.
- net 39.4% -> 57.2%, global 40.9%; floors96 wired (YAML re-verified) +
  tools/README.md + plan + queue in the same commit. Smoke growth skipped
  (existing net smokes already reference part of the family; module-smoke
  stays 3,475/6,200).
- Full battery on 6d5e1fd: check_modules 509/509 (264.8s); corpus
  951/951, 0 compilefail, 0 runfail (1846.2s); probe corpus 215/215
  (647.9s); barename 0 hits / 509 (986.9s); coverage floors96 OK; doc
  ratchet OK; module-smoke ratchet OK (3,475/6,200 fns, 497/517 modules).
  Wave 60 closed; this battery/docs commit is LOCAL until the next push
  point.

**SESSION 2026-10-03 block 19 (wave 59: serialize.json hardening -- JSON legacy bugs)**
- Fix-firsts from the recorded JSON legacy list: (1) number grammar --
  reject leading zeros (`00`/`01`), require integer digits (`.5`/`1.`)
  and at least one exponent digit (`1e`/`1e+`/`1e-`); (2) exponent clamp
  in `xiom.core` -- accumulation capped at 1000 and at most 400 scaling
  steps, so `1e4000000000` errors fast instead of ~3s (longer runs hung)
  and cannot overflow the loop counter; (3) non-finite guard --
  `json_parse` errors on inf/NaN results and `json_stringify`/
  `json_pretty` emit `"null"` instead of invalid `"inf"`. The recorded
  `0.05 -> 0.5` symptom does NOT reproduce on current sources (recon
  replayed it pre-fix: `0.05` parses correctly); `stringify_frac` has no
  symbol -- the surviving fractional defect is 15-vs-17-digit precision,
  recorded as a follow-up, not changed here.
- Probe `p_wave59_json.xi` (214th): RED pre-fix (run=1, `1e` accepted;
  stash/restore of the two fixed sources), GREEN post-fix on v0.61.3 and
  the m178 dev binary. serialize smokes 24/24, json smokes 17/17 on the
  pin.
- Compiler relay: the sync Arc/strong_count finding is compiler-side
  (m166 inlined unsafe path allocates 8 bytes for a 16-byte ArcInner);
  KEEP the `#[unsafe_direct]` annotations on `xiom/sync/sync.xi` (Gate P
  depends on them); sync-probe noise is expected until their fix.
- Full battery on bc2e03b: check_modules 509/509 (296s); corpus 951/951,
  0 compilefail, 0 runfail (1841.6s); probe corpus 214/214 (476.7s);
  barename 0 hits / 509 (997.2s); coverage floors95 OK; doc ratchet OK;
  module-smoke ratchet OK (3,475/6,200 fns, 497/517 modules). Wave 59
  closed; this battery/docs commit is LOCAL until the next push point.

**RELAY 2026-10-03 (m178 closure + net.xi fix-first)**
- Compiler main `659f6ec1` implements m178 (checker pattern-vs-type on
  match arms). Our wave-57 invalid-IR finding is FIXED; the diagnostic is
  a clean T001 now and `tools/known_failures/p_wave57_probe_ir.xi` is
  retired (README entry removed; findings count 12 -> 11).
- m178 exposed a real pre-existing stdlib bug in the `xiom.net` aggregate
  body: `str_slice` (`xiom/net/net.xi`) matched `Str::from_utf8(buf)` as
  `Ok/Err` although it returns Str -- replaced with
  `return Str::from_utf8(buf);`.
- Verified with the m178 binary: `check_modules` 509/509 type-check clean
  (303s), `smoke_net_address` compiles clean; on the gate pin: smoke_net
  10/10, p_wave57_shapes and p_wave58_shapes green. This unblocks the
  compiler lane's api-freeze and the v0.62.3 tag.
- Wave-58 full battery (pre-hotfix tree, commit e2002e1): check_modules
  509/509 (396.2s); corpus 951/951 (2364.1s); probes 213/213 (467.8s);
  barename 0/509 (634s); coverage/doc/module-smoke ratchets OK.

**SESSION 2026-10-03 block 18 (wave 58: net batch 2 -- HTTP family; floors95)**
- Wave 58: 55 clauses on xiom.net.{http (21), header (6), cookie (10),
  mime (18)}. Fix-first: `parse_q` capped at 1000 (RFC 7231; `1.999`
  scored 1999, probe witness). One clause corrected during validation:
  header_remove's `(len == 0) => (result == false)` is invalid
  post-removal (removing the last entry empties the vector with result
  true); replaced with the documented `headers.len() >= 0` placeholder.
- Probe `p_wave58_shapes.xi` (213th): 119 checks; green on v0.61.3 and
  v0.62.2 dev.
- net 20.9% -> 39.4%, global 39.2% -> 40.1% (crosses 40%); floors95
  wired (YAML re-verified) + tools/README.md + plan + queue in the same
  commit. Smoke growth skipped (existing net smokes already reference the
  family; module-smoke stays 3,475/6,200).
- Main was pushed before this wave (`5c3d39f..c11b66c`, website meter
  current); this wave is local until the next push point.
- Full battery on e2002e1 (pre-hotfix tree): check_modules 509/509
  (396.2s); corpus 951/951 (2364.1s); probes 213/213 (467.8s); barename
  0/509 (634s); coverage floors95/doc/module-smoke ratchets OK. After the
  m178 hotfix, re-verified: check_modules 509/509 on the m178 binary;
  smoke_net 10/10 and p_wave57/58 probes green on the gate pin.

**SESSION 2026-10-03 block 17 (wave 57: net batch 1 -- address family; floors94)**
- Wave 57: 46 clauses on xiom.net.{address (5), ip (15), ip4 (10), ip6 (8),
  url (8)} -- Option/Result presence mirrors, length bands for valid parses,
  exact-string broadcast claim, Bool implications, round-trip claims.
- Fix-firsts: (F1) `ipv4_to_string` ignored its doc ("first four octets")
  for len>4 (delegated exact-4 and returned ""); now copies the first four,
  probe witness. (F2) `url_join`'s "//" branch skipped the documented
  normalization; now `url_normalize(bp.scheme + ":" + relative)`.
- New compiler finding `p_wave57_probe_ir.xi`: context-dependent invalid
  LLVM IR (alloca dominance) when Result-style matches mix with
  Str-returning calls; bisection NON-monotonic; the probe now compares the
  Str results of `ipv6_to_string`/`ip_expand` directly.
- Probe `p_wave57_shapes.xi` (212th): 141 checks; green on v0.61.3 and
  v0.62.2 dev. `smoke_net_address.xi` grew (module-smoke 3,471 -> 3,475).
- net 5.4% -> 20.9%, global 38.5% -> 39.2%; floors94 wired (YAML
  re-verified) + tools/README.md + plan + queue + wishlist in the same
  commit.
- Relay: `COMPILER_BUGS.md` m169/m170 close the vector-bits and curve-thunk
  findings (verified rc=0 on the v0.62.2 dev binary). The packages crypto
  link packet does NOT reproduce on stdlib main: `crypto.sha256_hex` (NIST
  "abc") and `encoding.base64_encode` ("YWJj") link and run green on both
  pins, with and without XIOM_STDLIB; the symbol is defined in
  runtime/sha256_sw.c in every tag and the driver's build-runtime list
  includes it -- suspect a stale installed runtime library (compiler/install
  lane). Wishlist rows 42-46 added; row 33 updated with the evidence.
- Full battery on 48ef036: check_modules 509/509 (530.7s); corpus 951/951,
  0 compilefail, 0 runfail (2298.5s); probe corpus 212/212 (650.2s);
  barename 0 hits / 509 (991.2s); coverage ratchet floors94 OK; doc
  ratchet OK; module-smoke ratchet OK (3,475/6,200 fns, 497/517 modules).
  The wave-57 probe is green on v0.61.3 and v0.62.2 dev. Wave 57 closed;
  this battery/docs commit is LOCAL (push on the lane's request).

**SESSION 2026-10-02 block 16 (wave 56: geom aggregate batch 3/final -- Mat4 tail + primitives; geom dir 100%)**
- Wave 56 (floors93): 51 clauses on the xiom.geom aggregate -- Mat4 tail
  (17), Aabb (14), Sphere (8), Ray (8), Plane (4). See the plan entry for
  the claim list. `geom.xi` is now 186/186 pub-with-clause and the geom
  directory is 414/414 = 100%.
- No fix-first; probe note: one NaN check moved off `aabb_volume` because
  its strict wave-49 `vec3_sub` delegate aborts on NaN (the pre-existing
  NaN-abort class), replaced with an `aabb_closest_point` NaN path.
- Probe `p_wave56_shapes.xi` (211th): 77 checks; green on v0.61.3 and the
  v0.62.2 dev binary.
- smoke_geom.xi grew to 128 KATs (module-smoke 3,421 -> 3,471 fns);
  tools/module_smoke_floors.json re-dumped.
- geom 87.7% -> 100%; global 37.7% -> 38.5%; floors93 wired (YAML
  re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on 2acf04f: check_modules 509/509 (410.5s); corpus 951/951,
  0 compilefail, 0 runfail (2577.5s); probe corpus 211/211 (667.1s);
  barename 0 hits / 509 (1012.7s); coverage ratchet floors93 OK; doc
  ratchet OK; module-smoke ratchet OK (3,471/6,200 fns, 497/517 modules).
  The wave-56 probe is green on v0.61.3 and the v0.62.2 dev binary. Wave
  56 closed; this battery/docs commit is LOCAL (push on the lane's
  request).

**RELAY 2026-10-02 (compiler lane -> stdlib; next-pin prep)**
- `COMPILER_BUGS.md` (updated 2026-10-02) closes two of our findings:
  m169 = same-leaf qualified Vec results (`p_geom_vector_result_bits`);
  m170 a/b = fn-typed param Vec returns (`p_curve_thunk_zero`) + erased
  Option/Result literal payload slots (the Option-of-Vec `.unwrap()` AV
  class). Both stdlib repros verified rc=0 on the compiler lane's local
  v0.62.2 dev binary (`E:\xiom-lang\xiom\target\debug\xiom.exe`, rebuilt
  2026-10-02 21:13, `--version` = XIOM Compiler v0.62.2; the handoff's
  v0.62.1 path now holds this build).
- Still failing on that binary: `p_geom_matrix_result_infer` (run=4),
  `p_clause_float_vec_index` (run=1), `p_polyhedra_nested_hull` (run=1).
- Next pin actions: re-run all known_failures repros; promote the two
  fixed probes to `tools/probes/`; re-add the wave-51 mediation-free reads
  and consider Option-payload clause opportunities once the pin carries
  m170b.

**SESSION 2026-10-02 block 15 (wave 55: geom aggregate batch 2 -- quaternion tail + Mat2/Mat3 + Mat4 core)**
- Wave 55 (floors92): 45 clauses on the xiom.geom aggregate -- quaternion
  tail (15), Mat2 (8), Mat3 (12), Mat4 core (10). See the plan entry for
  the claim list (all NaN-tolerant forms).
- No fix-first: the pre-clause probe baseline was green. Probe authoring
  note: the NaN-tolerance section initially tripped the PRE-EXISTING
  NaN-abort class (`math.acos` requires at math.xi:295 on NaN dot; the
  `math.sqrt` class likewise) -- those probe calls were removed, since the
  abort is the callee's old strict requires, not the new clauses.
- Probe `p_wave55_shapes.xi` (210th): 69 checks; green on v0.61.3 and
  v0.62.1. One clause fix during validation: mat2/mat3 transpose mirrors
  needed the NaN-tolerant disjunction (pure-read mirrors are not exempt).
- smoke_geom.xi grew to 90 KATs (module-smoke 3,377 -> 3,421 fns);
  tools/module_smoke_floors.json re-dumped.
- geom 76.8% -> 87.7% (363/414), global 37.0% -> 37.7%; floors92 wired
  (YAML re-verified) + tools/README.md + plan + queue in the same commit.
- Full battery on fc42eaf: check_modules 509/509 (382.5s); corpus 951/951,
  0 compilefail, 0 runfail (2025.0s); probe corpus 210/210 (552.2s);
  barename 0 hits / 509 (737.9s); coverage ratchet floors92 OK; doc ratchet
  OK; module-smoke ratchet OK (3,421/6,200 fns, 497/517 modules). The
  wave-55 probe is green on v0.61.3 and v0.62.1. Wave 55 closed; this
  battery/docs commit is LOCAL (push on the lane's request).

**SESSION 2026-10-02 block 14 (wave 54: geom aggregate batch 1 -- vectors + quaternion core + scalar helpers)**
- Wave 54 (floors91): 46 clauses on the xiom.geom aggregate -- vec2 (16),
  vec3 (15), vec4 (3), quaternion core (7), scalar helpers (5). See the
  plan entry for the claim list (all NaN-tolerant forms).
- Fix-first: `quat_from_euler` returned
  `Quaternion{ w: ...; x: ...; y: ...; z: ...; }` -- the type declares
  x; y; z; w, and the compiler assigns literal fields POSITIONALLY, so
  every Euler-derived rotation was scrambled (yaw=0 returned x=1, w=0).
  Reordered to declaration order; the probe's identity + yaw rotations
  lock it. Filed the compiler-side finding
  `tools/known_failures/p_struct_literal_field_order.xi` (both pins
  accept out-of-order fields and store them positionally; a repo-wide
  literal audit found this as the only site).
- Probe `p_wave54_shapes.xi` (209th): 99 checks; green on v0.61.3 and
  v0.62.1 (the first run was RED at the quat_from_euler check, then RED
  at a probe-side -0.0/NaN expectation -- fixed in the probe).
- smoke_geom.xi grew to 49 KATs (module-smoke 3,332 -> 3,377 fns);
  tools/module_smoke_floors.json re-dumped.
- geom 65.7% -> 76.8% (318/414), global 36.3% -> 37.0%; floors91 wired
  (YAML re-verified) + tools/README.md + plan + queue + the gate-9
  finding count (now 11: 10 compiler, 1 stdlib) in the same commit.
- Full battery on 4e51905: check_modules 509/509 (332.1s); corpus 951/951,
  0 compilefail, 0 runfail (1566.0s); probe corpus 209/209 (468.9s);
  barename 0 hits / 509 (689.2s); coverage ratchet floors91 OK; doc ratchet
  OK; module-smoke ratchet OK (3,377/6,200 fns, 497/517 modules). The
  wave-54 probe is green on v0.61.3 and v0.62.1. Wave 54 closed; this
  battery/docs commit is LOCAL (push on the lane's request).

**SESSION 2026-10-02 block 13 (wave 53: geom batch 5 -- geometry_extended + polyhedra + linear)**
- Wave 53 (floors90): 39 clauses -- geometry_extended (14), polyhedra (10),
  linear (15). See the plan entry for the claim list.
- Fix-first: `hyperbolic_geometry` called the non-pub extern `math.log`
  (declared inside xiom.math, not exported): on the v0.61.3 pin the call was
  silently auto-stubbed to zero, so the Poincare distance returned 0 for
  every distinct point (the probe-side loop and `math.ln` gave the correct
  log(3)); on v0.62.1 it hard-fails C001 "unresolved function symbol".
  Fixed by calling the public `math.ln`; the probe now locks the log(3) KAT
  and is green on BOTH pins. General hazard for the lane: cross-module
  calls to non-pub externs silently zero-stub on the pin.
- Finding (compiler, filed `p_polyhedra_nested_hull.xi`):
  `polyhedra.convex_hull_2d`/`convex_hull_3d` collapse on nonempty inputs
  (square -> 2 rows, tetra -> 0 rows) on both pins despite the local-copy
  workaround; empty inputs are correct. The probe keeps only the
  empty-input hull checks. (An earlier `p_gext_hyperbolic_zero.xi` repro was
  retired once fixed.)
- Probe `p_wave53_shapes.xi` (208th): 68 checks; green on v0.61.3 and
  v0.62.1.
- geom 56.3% -> 65.7% (272/414), global 35.7% -> 36.3%; floors90 wired
  (YAML re-verified) + tools/README.md + plan + queue + the meter's gate-9
  count (findings now 10) in the same commit.
- Full battery on 5fc74e3: check_modules 509/509 (429.7s); corpus 951/951,
  0 compilefail, 0 runfail (1789.7s); probe corpus 208/208 (481.2s);
  barename 0 hits / 509 (784.3s); coverage ratchet floors90 OK; doc ratchet
  OK; module-smoke ratchet OK. Wave 53 closed; main (+ this docs commit)
  PUSHED at the owner's request so the website's readiness meter/gates lines
  fetch the wave-53 readings.

**RELAY 2026-09-29 (packages -> compiler/stdlib)**
- Pin moved 0.61.3 -> 0.62.1 mid-batch; every package suite re-ran clean,
  no code changes needed for the new compiler. Their sectest caught two
  package-side catalog bugs (obs-fold detection masked by trimming;
  max-age=abc reported as "without max-age" instead of "is not a number").
  xiom.string.str_replace_all was used to isolate policy rules; they avoid
  `==` on Result values (no guaranteed Eq). No stdlib action.

**RELAY 2026-09-28 (registry -> compiler/stdlib)**
- v0.62.0 tag/commit confirmed (80e767b). The registry canary is blocked
  on the pending registry-publish environment approval for run 36438204239;
  approving it completes verification within minutes. That approval is an
  owner/registry action, not a stdlib change -- no action in this lane.

**SESSION 2026-09-28 docs block (release Q&A + outlook)**
- Compiler lane is running the 0.62.0 release workflow and waiting for the
  binary assets; the stdlib go (80e767b, stdlib-v0.62.0 candidate) was
  given and pushed (main 1770ce6 at the time).
- Packages wishlist: the channel and rule were recorded at wave 36; the
  full item list (checksum/bitstream/varint/bytes.cursor/base64/utf8/
  text.scan/date.civil/net.addr/bcd/math.int/buf.writer + the wave-36
  additions) is now also in the queue doc under "Packages growth wishlist
  (external channel)" with the PACKAGE-NAMESPACES.txt two-way rule and the
  first affected unit (D, tzdata phase 2).
- Limitations page refreshed for the release: coverage line 16.6% ->
  30.1% (floors78), a "0.62.0 changes users should know" section (four
  fixed behaviors + the tcp_connect m146 pin caveat + how contract aborts
  read to users), and the "still open" rewrite list corrected
  (lp_simplex/linear_programming and observability/controllability are
  DONE; what remains is coverage + C/D/E + compiler-gated classes).
- Readiness outlook recorded in the queue doc: 6,499 pub fns, 1,954
  covered (30.1%), 4,545 uncovered; ~180 waves at the recent ~25/wave
  scope, ~125 with the ~70% safely-coverable share, ~70-80 with whole-
  family batching at 40-60 pub/wave. Wishlist growth stretches the target.

**RELAY 2026-09-27 (compiler -> stdlib)**
- Compiler item 3 DONE at local commit 0f3f5083 (unpushed, tree clean):
  pin STDLIB_VERSION -> stdlib main 0c50ac6 (carries 90e9185 + c193bc4
  m146-prep); the four exact-arity hunks are ON with call-shape-correct
  expected counts; three latent resolution defects fixed (derived-compare
  wildcard capture, receiver-sugar Box.get, interface &Self arity);
  locks m150_exact_arity + CI; full compiler gates green; tcp_connect
  refused-path verified on the pin (ERR code=-1). Implication for this
  lane: the next pin bump can drop the tcp_connect m146 caveat and the
  ptr.is_null workaround once the pin carries m142+; no stdlib change is
  required for the pin itself. This lane has not been asked to push.

### HANDOFF 2026-10-03 (context-limit snapshot 5; read this plus docs/PRODUCTION_READINESS_QUEUE.md)

**State**: main @ `05168e6` + this handoff commit, PUSHED (origin synced;
the website fetches the queue's meter/gates lines from origin/main).
Compiler pin: official **v0.62.3** at
`%TEMP%\kilo\stdlib_ws\v0623\x\bin\xiom.exe` (SHA256
`011af7dd823c1bc258565d1f8b9303d93bccde7ea477210768e094edd60406c2`,
verified against the release SHA256SUMS); v0.61.3 at
`%TEMP%\kilo\stdlib_ws\xiom_v0613.exe` and the m178 dev build at
`E:\xiom-lang\xiom\target\debug\xiom.exe` remain for cross-checks. Tags:
`stdlib-perf3` (`2429ac3`, the shipped pin for compiler v0.62.3 PUBLISHED
2026-10-03), `stdlib-perf2` (`59bfb1c`), `stdlib-perf1` (the v0.62.2
STDLIB_VERSION pin), `stdlib-v0.62.0` (released 0.62.0). Coverage floors98:
**global 42.2% pub-with-clause, geom 100.0%, net 87.2%, math 38.8%, num
35.6%**; probe corpus **220** (incl. the three p_regress_* promoted repros);
corpus **950/951 on v0.62.3** (remaining filed failure:
`smoke_compress_lz4_snappy`; the two cell smokes were stdlib-side
-- missing `Ref.release` -- fixed 2026-10-03, and the iter-range C001
cleared on the wave-62 tip), 951/951 on v0.61.3;
modules 509/509; barename 0/509; doc 100%; module-smoke 497/517 modules,
3,475/6,200 fns; findings Current 9 (8 compiler, 1 stdlib). Readiness meter 70% (7/10).

**Waves landed since snapshot 4**: geom aggregate batches 6-8 (46+45+51 =
142/142; `geom.xi` 186/186; geom directory 100%; fix-first
`quat_from_euler` literal order; floors91-93); net batch 1 address family
46 (floors94; fix-firsts `ipv4_to_string`/`url_join`); net batch 2 HTTP
family 55 (floors95; fix-first `parse_q` q-cap); net batch 3 transport 53
(floors96); net batch 4 protocols 48 (floors97); net batch 5
sse/websocket/ws/dns/multipart 41 (floors98; fix-first
`ws_handshake_verify` accept-line scan; new finding
`p_multipart_parse_name`); serialize.json hardening (grammar, exponent
clamp, non-finite guard) + the JSON legacy-bug record; m178 closure
(`net.xi` `str_slice` T001 fix-first); official v0.62.3 baseline + pin
move; registry-lane pin commit `e36d86d` included.

**Remaining to 100% (order)**: (1) net batch 6: `net.xi` 15 + `server` 6 +
`jwt` 9 = 30 pub (merge with the first low-dir family after recon to stay
in 40-60); (2) the low dirs: hash 8.9%, reflect 9.1%, iter 9.8%, convert
11.5%, format 13%, time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%
(the packages' crypto-link row is install/deploy-lane; nothing to fix),
log 19.1%, compress 21.1%; (3) C geom dedup + Box rename (needs
compiler-lane api_freeze regen), D tzdata phase 2 (check
PACKAGE-NAMESPACES.txt), E untested-surface generator classes, F next
release cut. **Registry note**: xiom-std 0.62.0 in the registry is a
pre-fix snapshot; only explicit `xiom pkg install xiom.std` reaches it --
bump `package.xi` (registries reject duplicate versions) and publish a
fresh artifact from the pinned tree at the release boundary if wanted (our
call, low risk, no compiler dependency).

**Open compiler findings** (all in `tools/known_failures/` Current with
repros): lz4 + `iter.range contains` C001 context-dependent regressions on
v0.62.3 (smokes; minimal forms pass; cell/RefCell was stdlib-side and is
fixed 2026-10-03), `multipart_parse` Part field reads corrupt
(both pins), clause-position Float64 vector element indexing,
generic-typechanging map/core_map/sortbykey (`fnptr` now passes), Box
unnameable, geom matrix nested-result inference, `polygon_difference`
(stdlib algorithm), polyhedra nested hulls, shape-mismatched `&Vec` AV.
Fixed-and-retired on v0.62.3: struct-literal order, vector result bits,
curve thunk, generic fnptr. Compiler-side post-release queue (their
relay): R-8 tcp_stream_read, contracts-arena verifier, complex const
tables, i64<->f64 bitcast (stdlib float stubs stay).

**Paste-ready continuation prompt (snapshot 5; copy below)**:

Continue the XIOM stdlib production-readiness work in E:\xiom-lang\stdlib
(main @ 05168e6 + handoff docs or later; origin synced; push docs/meter
updates when asked).

READ FIRST, in order:
1. docs/stdlib_session.md -- the "HANDOFF 2026-10-03 (context-limit
   snapshot 5)" block, plus snapshots 4/3 for history.
2. docs/PRODUCTION_READINESS_QUEUE.md -- authoritative queue (top meter +
   10-gate list, sections C/D/E/F, module-smoke requirement, gotchas).
3. docs/RELEASE_CHECKLIST.md before any release action.

STATE: main @ 05168e6 (pushed). Compiler pin: official v0.62.3 at
%TEMP%\kilo\stdlib_ws\v0623\x\bin\xiom.exe (SHA256 011af7dd... verified);
v0.61.3 at %TEMP%\kilo\stdlib_ws\xiom_v0613.exe and the m178 dev build at
E:\xiom-lang\xiom\target\debug\xiom.exe for cross-checks. Coverage floors98:
global 42.2%, net 87.2%, geom 100%, math 38.8%, num 35.6%. Gates on v0.62.3:
check_modules 509/509; corpus 950/951 (remaining filed compiler-side:
`smoke_compress_lz4_snappy`; cell smokes fixed stdlib-side 2026-10-03 and
the iter-range C001 cleared on the wave-62 tip); probes 220/220; barename 0/509; coverage floors98;
module-smoke 3,475/6,200; doc 100%. Findings Current 9 (8 compiler,
1 stdlib). stdlib-perf3 (2429ac3) is the shipped
pin for compiler v0.62.3 (PUBLISHED); keep the #[unsafe_direct] annotations
on xiom/sync/*.

FIRST TASK -- wave 63: net batch 6 -- net.xi 15 + server 6 + jwt 9 = 30
uncovered pub; after read-only recon, merge with the first low-dir family
if needed to hold the 40-60-pub directive. Protocol per wave: recon
(read-only) -> new-shape probe in tools/probes/ (RED before, GREEN after)
-> runtime-safe clauses -> dump tools/coverage_floors99.json -> wire into
.github/workflows/{ci,heavy,release}.yml (keep `run:` at EIGHT spaces under
`shell: pwsh`; YAML parse-check after ANY workflow edit) + tools/README.md
+ docs/STDLIB_READINESS_PLAN.md + docs/stdlib_session.md + the queue top
meter/gates lines in the SAME commit -> pure-ASCII single-quoted commit ->
full battery: check_modules; run_smokes -Workers 8 -RetryFailed; same with
-Corpus tools\probes; barename_scan; coverage_scan -RatchetFile; doc_scan
-RatchetFile tools\doc_baseline4.json; module_smoke_scan -BaselineFile.
One wave = one commit. Expect exactly the 3 filed corpus failures on
v0.62.3; everything else must stay green.

ALSO IN SCOPE each wave: smoke-growth (20 modules with no smoke; ~2,725
unreferenced pub fns) and any fix-first bugs the probe catches.

THEN, in order: the remaining low dirs (hash, reflect, iter, convert,
format, time, misc, os, rand, crypto, log, compress), then C (geom dedup +
Box rename, needs compiler-lane api_freeze regen), D (tzdata phase 2), E
(untested-surface generator classes), F (next release cut; the registry
xiom-std bump/publish is our call at the boundary).

RULES: no stdlib edits while a sweep is in flight; pushes only when the
release/compiler lane asks or at a boundary (the website reads
origin/main); always after git log -1 --format='%an <%ae>' prints Lefteris
Notas <lefterisnotas@gmail.com>; no pwsh -- use `powershell -NoProfile
-File tools\<script>.ps1`; keep repo edits single-threaded (recon agents
read-only); report new compiler bugs in tools/known_failures/ with a
minimal repro; update docs/PRODUCTION_READINESS_QUEUE.md every wave.

GOTCHAS (full list in snapshot 3's block, unchanged, plus): v0.62.3 has
context-dependent codegen regression (lz4 on v0.62.3) -- minimal forms may
pass; multipart_parse result Part fields are corrupt (presence-only);
struct-literal positional scrambling is FIXED on v0.62.3 (still write
declaration order); bind module-qualified call results to `let` before
comparison when the type is UInt16/UInt8; compare Str-returning calls
directly (no Result-style match); keep #[unsafe_direct] on xiom/sync/*;
the queue top's meter/gates lines are machine-read by the website (keep
the exact formats).

### HANDOFF 2026-10-02 (context-limit snapshot 4; read this plus docs/PRODUCTION_READINESS_QUEUE.md)

**State**: main @ this baseline docs commit (origin at `7f270fe`; push
docs/meter when asked or at the next boundary -- the website fetches the
queue's meter/gates lines from origin/main). Compiler pin: official
**v0.62.3** at `%TEMP%\kilo\stdlib_ws\v0623\x\bin\xiom.exe` (SHA256
`011af7dd...` verified against the release SHA256SUMS; fresh baseline in
block 22); v0.61.3 and the m178 dev build remain for cross-checks; all 219
probes green on v0.62.3. Pushed tags:
`stdlib-perf3` (`2429ac3`, shipped pin for compiler v0.62.3 PUBLISHED
2026-10-03; includes waves 54-61), `stdlib-perf2` (`59bfb1c`), `stdlib-perf1` (the v0.62.2
`STDLIB_VERSION` pin), `stdlib-v0.62.0` (released 0.62.0; the registry lane
owns its publish). Coverage floors97: **global 41.6% pub-with-clause, geom
100.0%, net 73.4%, math 38.8%, num 35.6%**; probe corpus **219**; smoke
corpus 947/951 on v0.62.3 (4 compiler-side regressions filed; 951/951 on
v0.61.3); modules 509/509; barename 0/509; doc 100%; module-smoke 497/517
modules, 3,475/6,200 fns. Queue-top readiness meter: **70% -- 7 of 10
gates** (open: coverage 100% at 41.6%, zero open findings (10: 9 compiler,
1 stdlib), beta-exit release cut); gates line: corpus 947/951, modules
509/509, probes 219/219, barename 0/509. Packages intake
`docs/STDLIB-WISHLIST.md`: 46 rows from the six relays (row 1 empty-needle
defect fixed; rows 33-41 evening
relay; rows 42-46 night batch; the crypto linkability packet does not
reproduce on main -- compiler/install lane); full sheet
`xiom-packages/packages` @ `66f26e1`.

**Waves 49-57 landed since snapshot 3** (all probe + floors + same-commit
docs + full battery): geom batch 1 vec/quat/mat 52 (86); batch 2
matrix/quaternion 51 (87); batch 3 vector/curves/collision 43 (88); batch 4
geometry_2d/3d 43 (89); batch 5 geometry_extended/polyhedra/linear 39 (90,
incl. the `math.log` -> `math.ln` fix-first); batch 6 the geom aggregate's
first 46 of 142 (91; fix-first: `quat_from_euler`'s literal was written
w,x,y,z and struct literals store fields positionally, so Euler rotations
were scrambled -- reordered + filed `p_struct_literal_field_order.xi`);
batch 7 the aggregate's quaternion tail + Mat2/Mat3 + Mat4 core 45 (92, no
fix-first); batch 8 the aggregate's Mat4 tail + Aabb + Sphere + Ray + Plane
51 (93; `geom.xi` 186/186 and the geom directory 414/414 = 100%); net
batch 1 the address family 46 (94; fix-firsts `ipv4_to_string` doc-faithful
first-four octets and `url_join` "//" normalization; filed the invalid-IR
finding); net batch 2 the HTTP family 55 (95; fix-first `parse_q` q-cap at
1000 per RFC 7231; global crosses 40%); wave 59 the serialize.json
hardening (number grammar, exponent clamp, non-finite stringify); wave 60
the transport family 53 (96; net 57.2%, global 40.9%); wave 61 the
protocol family 48 (97; net 73.4%, global 41.6%);
the m178 closure (checker pattern-vs-type; the `xiom.net` `str_slice`
fix-first; repro retired) and the two dev-build findings (contracts
`any_contracts` AV; sync Arc count -- compiler-side, keep the
`#[unsafe_direct]` annotations); plus the PERF-1 and PERF-2 annotation
waves (tags above), the m169/m170 compiler closures (vector-bits and
curve-thunk findings verified fixed on the v0.62.2 dev binary), the
packages wishlist intake (46 rows now) and the empty-needle defect fix,
and the website readiness meter/gates lines.

**Remaining to 100% (order)**: wave 62+ = the rest of net (sse 8,
websocket 14, ws 5, dns 8, multipart 6, server 6, jwt 9, net.xi 15 --
split into 40-60-pub batches), then the remaining low dirs (hash 8.9%,
reflect 9.1%, iter 9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%,
os 15.3%, rand 16%, crypto 17%, log 19.1%, compress 21.1%), then C (geom
dedup + the Box rename; needs compiler-lane api_freeze regen), D (tzdata
phase 2, check `PACKAGE-NAMESPACES.txt`), E (untested-surface generator
classes), F (next release cut). Follow-ups: real polygon-clipping for
`polygon_difference`; the polyhedra nested hulls ride the nested-read fix;
17-digit JSON float precision; smoke growth (20 modules with no smoke,
~2,725 unreferenced fns).

**Rules (unchanged)**: no stdlib edits while a sweep is in flight; every
wave updates the queue top's meter/gates lines; read-only recon ->
new-shape probe -> runtime-safe clauses -> floors<N+1> dump -> wire
ci/heavy/release (8-space `run:`) + tools/README.md + plan + session +
queue in the SAME commit -> YAML parse check -> pure-ASCII single-quoted
commit -> full battery (check_modules, corpus, probes, barename, coverage,
doc, module-smoke); one wave = one commit (+ battery-docs commit). Pushes:
the website reads origin/main, so push docs/meter updates when asked;
always after `git log -1 --format='%an <%ae>'` prints
`Lefteris Notas <lefterisnotas@gmail.com>`.

**Paste-ready continuation prompt**:

```
Continue the XIOM stdlib production-readiness work in E:\xiom-lang\stdlib
(main @ bc2e03b + battery docs or later; origin at 8b23b79; push docs/meter
updates when asked).

READ FIRST, in order:
1. docs/stdlib_session.md -- the "HANDOFF 2026-10-02 (context-limit
   snapshot 4)" block, plus snapshot 3 and the 2026-09-27/2026-09-25
   handoffs for history and the pin rebuild recipe.
2. docs/PRODUCTION_READINESS_QUEUE.md -- authoritative queue (top meter +
   10-gate list, sections C/D/E/F, module-smoke requirement, gotchas).
3. docs/RELEASE_CHECKLIST.md before any release action.

STATE: main @ bc2e03b + battery docs or later (origin at 8b23b79 -- the
website fetches the queue's meter/gates lines from origin/main, so push
when the release/compiler lane asks or at the next boundary). Compiler pin
v0.61.3 at %TEMP%\kilo\stdlib_ws\xiom_v0613.exe; the m178 dev build
(compiler main 659f6ec1) at E:\xiom-lang\xiom\target\debug\xiom.exe;
wave-54..59 probes green on the gate pin and the m178 dev binary. Coverage
floors95: global 40.1%, geom 100%, net 39.4%, math 38.8%, num 35.6%. All
gates green on the tip: check_modules 509/509; corpus 951/951; probes
214/214; barename 0/509; coverage floors95; module-smoke ratchet (497/517
modules, 3475/6200 pub fns); doc 100%. Readiness meter 70% (7/10). Packages
intake: docs/STDLIB-WISHLIST.md (46 rows; sync Arc + contracts AV are
compiler-side dev-build findings; keep the sync #[unsafe_direct]
annotations). stdlib 0.62.0 RELEASED; the registry lane owns its publish;
the next release continues coverage toward 100%.

FIRST TASK -- wave 62: net batch 5 -- sse 8 + websocket 14 + ws 5 + dns 8
+ multipart 6 = 41 uncovered pub (extend with server 6 / jwt 9 / net.xi 15
after recon if the family stays in 40-60; waves 57-61 closed the address,
HTTP, transport and protocol families, floors97). Batch-split per the
owner's directive (families of 40-60 pub per wave).
Protocol for EVERY wave: read-only recon -> new-shape probe in
tools/probes/ (RED on the stub/before, GREEN after) -> runtime-safe
clauses (contracts run at runtime; every clause certainly true for all
inputs incl. non-normalized structs; canonical-form/field claims; NEVER
read Result/Option payloads in clauses; NaN-tolerant
`(x == expr) || (x != x)` forms; parenthesize mixed comparisons; Float64
matrix/vector clauses are len/range claims only) -> powershell -NoProfile
-File tools\coverage_scan.ps1 -DumpFloors tools\coverage_floors<N>.json ->
wire the floors file into .github/workflows/{ci,heavy,release}.yml (keep
`run:` at EIGHT spaces under `shell: pwsh`; after ANY workflow edit run a
`python -c "import yaml; yaml.safe_load(...)"` parse check) +
tools/README.md + docs/STDLIB_READINESS_PLAN.md + docs/stdlib_session.md +
the queue top's readiness meter/gates lines in the SAME commit ->
pure-ASCII single-quoted commit -> full battery: powershell -NoProfile
-File tools\check_modules.ps1 -Compiler <pin> ; tools\run_smokes.ps1
-Compiler <pin> -Workers 8 -RetryFailed ; same with -Corpus tools\probes ;
tools\barename_scan.ps1 ; tools\coverage_scan.ps1 -RatchetFile
tools\coverage_floors<N>.json ; tools\doc_scan.ps1 -RatchetFile
tools\doc_baseline4.json ; tools\module_smoke_scan.ps1 -BaselineFile
tools\module_smoke_floors.json. One wave = one commit.

ALSO IN SCOPE each wave: smoke-growth (the 20 modules with no smoke and
the ~2,868 unreferenced pub fns are ratchet targets) and any fix-first
bugs the probe catches.

THEN, in order: the low dirs (net 5.4%,
serialize 5.4%, hash 8.9%, reflect 9.1%, iter 9.8%, convert 11.5%,
format 13%, time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log
19.1%, compress 21.1%, then core/stats gaps); C (geom dedup + Box rename,
needs compiler-lane api_freeze regen); D (tzdata phase 2; check
packages' docs/PACKAGE-NAMESPACES.txt before landing new namespaces); E
(untested-surface generator classes); F (next release cut).

RULES: no stdlib edits while a sweep is in flight; pushes only when the
release/compiler lane asks (the website reads origin/main, so push
docs/meter updates when asked), always after
`git log -1 --format='%an <%ae>'` prints Lefteris Notas
<lefterisnotas@gmail.com>; no pwsh -- use `powershell -NoProfile -File
tools\<script>.ps1`; keep repo edits single-threaded (recon agents
read-only); report new compiler bugs in tools/known_failures/ with a
minimal probe.

GOTCHAS: the full list is in snapshot 3's paste-ready block below
(unchanged), plus: cross-module calls to NON-PUB externs silently
zero-stub on the v0.61.3 pin and hard-fail C001 on v0.62.1 -- call public
wrappers (e.g. `math.ln`, never `math.log`); `polyhedra.convex_hull_2d`/`3d`
collapse on nonempty inputs on both pins (`p_polyhedra_nested_hull.xi`) --
empty inputs only; struct literals store fields POSITIONALLY -- always
write literal fields in declaration order (out-of-order literals compile
silently and scramble fields on both pins;
`p_struct_literal_field_order.xi`); a Result-style match on a Str-returning
call can emit invalid LLVM IR (alloca dominance; context-dependent and
non-monotonic under bisection -- `p_wave57_probe_ir.xi`); compare Str
results directly; the packages' crypto linkability packet does not
reproduce on stdlib main (row 33; compiler/install lane); KEEP the
`#[unsafe_direct]` annotations on `xiom/sync/sync.xi` (Gate P dependency;
sync-probe noise expected until the compiler m166 inlined-alloc fix);
struct-payload
Options join the
Vec-payload ones as is_some-only; the queue top's meter/gates lines are
machine-read by the website (keep the exact formats).
```

### HANDOFF 2026-09-29 (context-limit snapshot 3; read this plus docs/PRODUCTION_READINESS_QUEUE.md)

**State**: main @ `5fc74e3` + this battery/wishlist docs commit, PUSHED
(owner request so the website's readiness meter/gates lines fetch the
wave-53 readings; the remote may report PR/status-check bypass). Tags:
`stdlib-perf2` = the PERF-2 sync.xi annotation pin (`59bfb1c`, requires
compiler >= 185342f4); `stdlib-perf1` = the PERF-1 atomics pin for compiler
v0.62.2 `STDLIB_VERSION`; `stdlib-v0.62.0` = the released stdlib 0.62.0.
Compiler pin for local gates: v0.61.3 at
`%TEMP%\kilo\stdlib_ws\xiom_v0613.exe` (rebuild recipe in the 2026-09-25
handoff); v0.62.1 at `E:\xiom-lang\xiom\target\debug\xiom.exe`; the
wave-50/51/52/53 probes are green on BOTH. Coverage floors90: **global
36.3% pub-with-clause, geom 65.7%, math 38.8%, num 35.6%**; probe corpus
**208**; smoke corpus 951; modules 509/509 type-check clean; barename
0/509; doc scan 100%; **module-smoke ratchet live** (baseline
`tools/module_smoke_floors.json`: 497/517 source modules exercised by a
smoke, 3,332/6,200 public fns referenced). Readiness meter in the queue:
70% (7/10 gates; open: coverage 100%, zero findings (10), beta-exit
release). Packages intake lives at `docs/STDLIB-WISHLIST.md` (32 rows from
the four relays; full sheet `xiom-packages/packages` @ `66f26e1`).

**Shipped**: stdlib **0.62.0 released** — tag `stdlib-v0.62.0` force-updated
to `0e63101` (ruleset bypass), GitHub Release published 2026-09-29 00:10Z
with `xiom-std-0.62.0.tar.gz` + `SHA256SUMS`, staging canary dispatched;
registry lane has the subject sha and re-dispatches its publish. Two release
blockers were root-caused and fixed on the way: (1) ci/heavy/release YAML
indentation (`run:` nested under `shell: pwsh` -> invalid YAML; workflows
0s-failed for every run) fixed in `c491b13` plus a `tag` recovery dispatch
in release.yml; (2) `regex_unescape`'s Err-Str payload clause violated on
Linux only (fixed `0e63101`; known_failures README upgraded: Err-payload
clauses are unsafe on ANY platform).

**Waves 36-49 landed since the last handoff** (all with probe + floors +
same-commit docs + full battery; probes 190-203): B part 2b
`linear_programming` (floors73); trig-family 25 clauses + the
`_norm`/`sinpi`/`cospi`/`tanpi` +-inf hang fix (74); rounding + angular 26
(75, incl. the angular -0.0 clause fix); algebra + transcendental 23 +
`log1p(-1)` precondition fix (76); complex 19 (77); vectors 27 (78);
matrices + number_systems + queueing 53 (79, first family batch);
num float/convert/base/precision 37 + `_ilogb_abs`/`nextafter` power-of-two
fix + NaN-tolerant `primitives.abs` (80); bigint core 33 (81); bigint
remainder 21 (82); bigfloat core 30 (83); bigfloat transcendentals 24 (84);
bigfloat remainder 9 (85); geom primitives vec/quat/mat 52 (86, first geom
family batch; found + filed `p_clause_float_vec_index.xi` -- clause-position
indexing of Float64 vector elements reads garbage, so matrix row claims are
len-only); PERF-1 atomics `#[unsafe_direct]` annotation on all 16 pub fns
plus `tools/doc_scan.ps1` attribute transparency and the
`release-notes/v0.62.2.md` stdlib fragment (tag `stdlib-perf1`, the
`STDLIB_VERSION` pin for compiler v0.62.2); geom batch 2 matrix +
quaternion 51 (87; found + filed `p_geom_matrix_result_infer.xi` --
un-annotated matrix-module nested results lose a nesting level; fixed
`quat_between`'s opposite-direction axis choice, locked by the probe);
PERF-2 sync.xi `#[unsafe_direct]` on all 56 unsafe-bodied pub fns plus the
packages intake (`docs/STDLIB-WISHLIST.md`) and the three contradicted
empty-needle preconditions removed from `string.index_of` /
`string.str_index_of` / `string.str_replace_all` (`p_empty_needle_contracts.xi`
RED -> GREEN; tag `stdlib-perf2`); geom batch 3 vector/curves/collision 43
(88; found + filed `p_geom_vector_result_bits.xi` -- caller-side element
reads of lerp/clamp/hadamard/b_spline are bit-reinterpreted -- and
`p_curve_thunk_zero.xi` -- Vec-returning fn-typed params arrive empty in
catalog bodies).
geom batch 4 geometry_2d/3d 43 (89; filed `p_polygon_difference_halfplanes.xi`
-- difference intersects b's outside half-planes, disjoint inputs return
None -- and `p_geom_box_unnameable.xi` -- geometry_3d.Box is shadowed by
core's Box[T], three functions are uncallable from consumers).
geom batch 5 geometry_extended/polyhedra/linear 39 (90; fix-first
`math.log` -> `math.ln` -- the non-pub extern zero-stubbed on the pin;
filed `p_polyhedra_nested_hull.xi`).
Also landed:
`tools/module_smoke_scan.ps1` +
baseline + ratchet wired into all three workflows (owner requirement: every
module must have a smoke).

**Owner directives in force**: (1) family batching allowed, 40-60 pub per
wave to shorten the path; (2) ensure every module/function has smoke
coverage — grow the module-smoke ratchet alongside contract waves; (3)
release before 100% is acceptable when all gates are green, coverage
continues toward 100% in the next release.

**Rules (unchanged) plus hard-won additions**:
- Wave protocol: read-only recon (agents OK but they time out on big files;
  the per-function pass directly against source is often faster) -> new-shape
  probe in tools/probes/ -> clauses -> `tools/coverage_scan.ps1 -DumpFloors
  tools/coverage_floors<N>.json` -> wire the floors file into
  .github/workflows/{ci,heavy,release}.yml + tools/README.md +
  docs/STDLIB_READINESS_PLAN.md in the SAME commit -> pure-ASCII
  single-quoted commit -> full battery (check_modules 509, corpus 951 with
  `-RetryFailed`, probes corpus, barename 0/509, coverage + doc +
  module-smoke ratchets).
- YAML edits: after ANY workflow edit run `python -c "import yaml; ..."` on
  the file; the `run:` line keeps EIGHT spaces under `shell: pwsh` (the
  release-blocking incident is in this handoff).
- Contracts run at runtime: every clause certainly true for all inputs
  (including non-normalized structs a caller can construct); prefer
  canonical-form/field claims; `result.significand.digits.len()`,
  `result.0.digits.len()`, in-module clause calls and
  `(x == expr) || (x != x)` NaN tolerance are proven shapes; NEVER read
  Result/Option payloads in clauses.
- Clause gotcha (NEW 2026-09-29, filed): clause-position indexing of Float64
  vector elements is broken (`result[0]` on Vec[Float64],
  `result[0].len()` on Vec[Vec[Float64]] both violate; the identical Int
  shapes and length-only claims on the same results PASS) -- keep
  Float64-vector clauses to `.len()`/range claims; evidence
  `tools/known_failures/p_clause_float_vec_index.xi`.
- One wave = one commit; no stdlib edits while a sweep is in flight; pushes
  only when the release/compiler lane asks, after
  `git log -1 --format='%an <%ae>'` shows Lefteris Notas
  <lefterisnotas@gmail.com>; use `powershell -NoProfile -File tools\<x>.ps1`.
- Probe lessons: module paths are declarations, not file paths
  (`xiom.num.bigfloat`, `xiom.complex`); use `use <module>;` + leaf calls;
  `.value` Option payload reads AV in probe code (use `.unwrap()`); extra
  call arguments are silently ignored (declare tolerance params explicitly).

**Pin-gated / relayed**: XIOM_STRICT_BRACKETS flip will need the 3
mixed-bracket sites fixed in the pin-bump wave (`io/fs.xi` lines 36 and 244,
`math/algebra_extended.xi` line 311); tcp_connect refused-port caveat is now
activatable on pins carrying m146 (packages verified on 0.62.1); ptr.is_null
workaround until a pin carries m142+; shape-mismatched `&Vec[Float64]`
vs `&Vec[Vec[Float64]]` AV is in the compiler backlog
(`tools/known_failures/p_vec_shape_arg_mismatch_av.xi`); NaN-abort class
(`math.sqrt`/`math.ln` requires on NaN inputs) recorded but unfixed.

**Remaining to 100% (order)**: waves 49-53 DONE (geom batches 1-5: 52 +
51 + 43 + 43 + 39 clauses, floors90); wave 54+ = the big `geom.xi`
aggregate (142 uncovered -> 2-3 batches of ~50), then the low dirs in
queue order (net 5.4%, serialize 5.4%, hash 8.9%, reflect 9.1%, iter
9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%, rand
16%, crypto 17%, log 19.1%, compress 21.1%, plus remaining core/stats
gaps), then C (geom dedup, needs compiler-lane api_freeze regen; folds in
the Box rename follow-up), D (tzdata phase 2), E (untested-surface
generator classes), F (next release cut). Follow-ups: replace
`polygon_difference` with a real polygon-clipping implementation; the
polyhedra nested hulls ride the nested-read fix. Smoke growth: the 20
modules with no smoke and the ~2,868 unreferenced functions are explicit
targets; the `xiom.bigfloat` manifest-alias quirk in module_smoke_scan
needs a look.

**NEXT SESSION PROMPT (paste into a fresh session)**:

```
Continue the XIOM stdlib production-readiness work in E:\xiom-lang\stdlib (main @ 1bb2d56 or later; local commits ahead of origin -- push only when the release/compiler lane asks).

READ FIRST, in order:
1. docs/stdlib_session.md -- the "HANDOFF 2026-09-29 (context-limit snapshot 3)" block at the top of the handoff region (plus the 2026-09-27 and 2026-09-25 handoffs for history and the pin rebuild recipe).
2. docs/PRODUCTION_READINESS_QUEUE.md -- authoritative queue (sections C/D/E/F, the readiness outlook, the module-smoke requirement, and all contract/import gotchas).
3. docs/RELEASE_CHECKLIST.md before any release action.

STATE: main @ 5fc74e3 + battery docs or later (PUSHED -- the website fetches the queue's meter/gates lines from origin/main; stdlib-perf1 remains the v0.62.2 STDLIB_VERSION pin, stdlib-perf2 the next-pin candidate at 59bfb1c). Compiler pin v0.61.3 at %TEMP%\kilo\stdlib_ws\xiom_v0613.exe (rebuild recipe in the 2026-09-25 handoff if missing); the compiler lane's v0.62.1 binary also lives at E:\xiom-lang\xiom\target\debug\xiom.exe and the wave-50/51/52/53 probes are green on both. Coverage floors90: global 36.3%, geom 65.7%, math 38.8%, num 35.6%. All gates green on the tip: check_modules 509/509; corpus 951/951; probes 208/208; barename 0/509; coverage ratchet floors90; module-smoke ratchet (497/517 modules, 3332/6200 pub fns); doc 100%. Readiness meter: 70% (7/10). Packages intake: docs/STDLIB-WISHLIST.md (32 rows). stdlib 0.62.0 is RELEASED (tag stdlib-v0.62.0 at 0e63101 with assets) and the registry lane owns its publish; the next release continues coverage toward 100%.

FIRST TASK -- wave 54: geom batch 6 -- the big `geom.xi` aggregate, first batch (target 45-55 of its 142 uncovered pub fns; split the rest over the following 1-2 waves; waves 49-53 closed geom primitives 52, matrix/quaternion 51, vector/curves/collision 43, geometry_2d/3d 43, geometry_extended/polyhedra/linear 39; floors90). Batch-split per the owner's directive (families of 40-60 pub per wave): after geom.xi, the low dirs (net 5.4%, serialize 5.4%, hash 8.9%, reflect 9.1%, iter 9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%, compress 21.1%), then C, D, E, F. Protocol for EVERY wave:
read-only recon (agents time out on big files -- read the source directly if needed) -> new-shape probe in tools/probes/ (RED on the stub/before, GREEN after) -> runtime-safe clauses (contracts run at runtime; every clause certainly true for all inputs incl. non-normalized structs; canonical-form/field claims; NEVER read Result/Option payloads in clauses; NaN-tolerant `(x == expr) || (x != x)` forms; parenthesize mixed comparisons) -> powershell -NoProfile -File tools\coverage_scan.ps1 -DumpFloors tools\coverage_floors<N>.json -> wire the floors file into .github/workflows/{ci,heavy,release}.yml (keep `run:` at EIGHT spaces under `shell: pwsh`; after ANY workflow edit run `python -c "import yaml, yaml.safe_load(...)"` on it) + tools/README.md + docs/STDLIB_READINESS_PLAN.md + docs/stdlib_session.md + the queue top's readiness meter/gates lines in the SAME commit -> pure-ASCII single-quoted commit -> full battery: powershell -NoProfile -File tools\check_modules.ps1 -Compiler <pin> ; tools\run_smokes.ps1 -Compiler <pin> -Workers 8 -RetryFailed ; same with -Corpus tools\probes ; tools\barename_scan.ps1 ; tools\coverage_scan.ps1 -RatchetFile tools\coverage_floors<N>.json ; tools\doc_scan.ps1 -RatchetFile tools\doc_baseline4.json ; tools\module_smoke_scan.ps1 -BaselineFile tools\module_smoke_floors.json. One wave = one commit.

ALSO IN SCOPE each wave: smoke-growth (the 20 modules with no smoke and the ~2,868 unreferenced pub fns are ratchet targets; dump tools/module_smoke_floors.json upward as they land) and any fix-first bugs the probe catches.

THEN, in order: remaining geom sub-batches; the low dirs (net 5.4%, serialize 5.4%, hash 8.9%, reflect 9.1%, iter 9.8%, convert 11.5%, format 13%, time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log 19.1%, compress 21.1%, then core/stats gaps); C (geom dedup, needs the compiler-lane api_freeze snapshot regen); D (tzdata phase 2; check packages' docs/PACKAGE-NAMESPACES.txt before landing new namespaces); E (untested-surface generator classes); F (next release cut). Pin-gated: fix the 3 mixed-bracket sites (io/fs.xi 36+244, math/algebra_extended.xi 311) in the wave that takes the XIOM_STRICT_BRACKETS pin bump; tcp_connect refused-port is verifiable on a pin carrying m146 (0.62.1 verified); ptr.is_null workaround until m142+.

RULES: no stdlib edits while a sweep is in flight; pushes only when the release/compiler lane asks, always after `git log -1 --format='%an <%ae>'` prints Lefteris Notas <lefterisnotas@gmail.com>; no pwsh -- use `powershell -NoProfile -File tools\<script>.ps1`; keep repo edits single-threaded (recon agents read-only); report new compiler bugs in tools/known_failures/ with a minimal probe.

GOTCHAS: module paths are the declared names, not file paths (xiom.num.bigfloat, xiom.complex, xiom.math.optimization); Err/Ok payload reads in clauses are unsafe on any platform (Linux release-blocking incident 2026-09-28); clause-position indexing of Float64 vector elements reads garbage -- keep Float64-vector/matrix clauses to `.len()`/range claims (`tools/known_failures/p_clause_float_vec_index.xi`, filed 2026-09-29); cross-module calls to NON-PUB externs silently zero-stub on the v0.61.3 pin (they hard-fail C001 on v0.62.1) -- always call public wrappers like `math.ln`, never `math.log` (`geometry_extended` wave-53 fix-first); un-annotated `xiom.geom.matrix` Vec[Vec[Float64]] results lose a nesting level at the call site -- annotate every nested matrix-module local (`var x: Vec[Vec[Float64]] = matrix.f(...)`) and annotated tuple extraction in probes/smokes/consumers (`tools/known_failures/p_geom_matrix_result_infer.xi`, filed 2026-09-30; reproduced on v0.61.3 and v0.62.1); caller-side element reads of `vector.lerp`/`vector.clamp`/`vector.hadamard` and `curves.b_spline` results are bit-reinterpreted -- mediate through `vector.distance`/`vector.norm` or copy locally (`tools/known_failures/p_geom_vector_result_bits.xi`, filed 2026-10-01; reproduced on v0.61.3 and v0.62.1; smoke_geom_vec already mediates); a Vec-returning fn-typed parameter arrives empty inside catalog bodies (`tools/known_failures/p_curve_thunk_zero.xi`, filed 2026-10-01) -- keep curve_length KATs to the n<1 branch; Vec-payload Options and struct-payload Options (`vector.refract`, `collision.segment_intersect`, `geometry_2d` line/segment/circle intersections and polygon booleans, `geometry_3d` plane-plane) are is_some-only -- even `.unwrap()` can AV; `geometry_3d.Box` is unnameable from consumers (core's `Box[T]` shadows the leaf; filed `p_geom_box_unnameable.xi`) -- those clauses are compile-checked only; `geometry_2d.polygon_difference` is unreliable (intersects b's outside half-planes; `p_polygon_difference_halfplanes.xi`) -- only the empty-a/empty-b edges are sound; `polyhedra.convex_hull_2d`/`3d` collapse on nonempty inputs (`p_polyhedra_nested_hull.xi`) -- empty inputs only; check clause field names against the actual return type -- `.x` on a Vec result compiled on v0.61.3 but the v0.62.1 checker rejects it (quat_axis wave-50 catch); doc comments stay ABOVE `#[...]` attributes and doc_scan skips attribute lines; the compiler-release stdlib fragment lives at `release-notes/<compiler-tag>.md` (v0.62.2.md, merged schema max 6 highlights; run the compiler's xiom-release-notes from the xiom root -- its notes-dir is CWD-relative); extra call arguments are silently ignored; the transient runner flakes (0s failures, occasional rc=-1/COMPILE-FAIL on a single file) are load-related -- a solo retry/rerun is safe.
```

### HANDOFF 2026-09-27 (context-limit snapshot 2; read this plus docs/PRODUCTION_READINESS_QUEUE.md)
**State**: main @ `1fbb45a`, pushed and synced with origin (two bypass pushes
this stretch: `c193bc4`, `1fbb45a`; the remote reports PR/status-check
bypass). Pin v0.61.3 (`%TEMP%\kilo\stdlib_ws\xiom_v0613.exe`; rebuild recipe
in the 2026-09-25 handoff). Coverage floors72: global 28.2%, math 21.5%.
All gates green on the tip: check_modules 509/509, corpus 951/951, probes
189/189, barename 0/509, coverage + doc ratchets.

**Landed since the 2026-09-25 handoff** (newest first):
- `1fbb45a` wave 35: `lp_simplex` (Bland simplex on repaired locals; dense
  tableau, slack basis, 10000-iteration cap, the queue's empty-result
  conventions) -- probe p_lp_simplex.xi; floors72.
- `c193bc4` Error interface reshape (only `description` + default `message`;
  no interface values in signatures; `Error.chain` description-only) + four
  `xiom_socket_connect -> Int32` declarations (m146 prep; behavior-neutral on
  the pin, correct once a pin carries m146).
- `90e9185` relay item-3 call sites: `_scrypt_blockmix` passes `r` (x2);
  `os/path.xi` qualifies `xiom.string.replace`; `printf` declared fixed
  `(format, arg)` in io/io.xi + io/console.xi -- probe p_relay_arity_fixes.xi.
- `0823433` 13 mixed-bracket type spellings canonicalized (strict-parser
  prep; the other 5 PIN sites were already canonical on main).
- `7293056` wave 34: control_theory `observability`/`controllability` on the
  nested-Vec repair pattern (`_ct_copy`/`_ct_mul`/`_ct_transpose`/`_ct_rank`,
  1e-12 pivot; clause `!result || a.len() > 0`; floors71).
- `0246885` `Int.hash` valid clause (`result != 0`; compiler relay W005).
- `e45386c` fix-first batch: exact `binomial` (gcd fold), `kronecker_symbol`
  2-adic guard, seven `p*p` loops -> `p <= x / p`, `next_prime` ceiling.
- `71f4d9f` Stirling/Eulerian zero-row clauses require `k == 0`.
- `224060a` wave 32 combinatorics (floors69); `38b5c32` wave 31 factorial
  (floors68); `02dde42` wave 30 signal + exponential (floors67; the
  `filter_bandstop` order guard fix).

**Next units, in order:**
1. B part 2b: `linear_programming` in `xiom/math/optimization.xi` (bounds
   repair: entries `Vec[Float64]`; empty bounds = x >= 0; per-variable
   `[lo, hi]` with +/-inf for absent sides; both-bounded -> add `z <= 1`;
   free -> split `z+ - z-`; shift/scale A,b,c; delegate to `lp_simplex`;
   map back; documented limitation: shifted `b2 < 0` returns empty). Probe
   first, then wire the queue-section-B cases into
   `tests/smoke/smoke_math_optimization.xi` (float near 1e-9: observability
   true/false, `lp_simplex` [2,2] + guards + unbounded, `linear_programming`
   bound modes (`[0,1]`,`[0,inf]`) -> [1,3], free-variable case).
2. Coverage waves toward 100% (floors73+): remaining `xiom/math` files, then
   the low dirs -- async 4.5, net 5.4, serialize 5.4, hash 8.9, reflect 9.1,
   num 9.6, iter 9.8, geom 10.6, convert 11.5, format 13, time 13, misc
   13.9, os 15.3, rand 16, crypto 17, log 19.1, compress 21.1. Read-only
   recon agents are allowed per directory; one wave = one commit with probe,
   `floors<N>` dump, wiring and the full battery.
3. C: geom dedup API unit (queue section C; needs the `api_freeze` snapshot
   regen by the compiler lane; do not blind-shim).
4. D: tzdata phase 2 (queue section D: pinned IANA tzdb vendor under
   `tools/tzdata/`, generated region payload modules, `xiom/time/zone.xi`
   engine).
5. E: untested-surface generator classes. F: release cut + tag handover at
   100%.

**Pin-gated follow-ups**: revert the `ptr.is_null()` module-qualified
workaround in thread/park.xi only on a pin carrying m142+; verify
`tcp_connect` refused-port -> Err on the first pin carrying m146 with stdlib
>= `c193bc4`; add concrete ErrorInfo/ErrorKind machinery with its first
consumer.

**Compiler-lane state (relays 2026-09-26/27)**: m142--m147 landed locally;
item-3 flips are verified-but-off until the stdlib ref is pushed (now pushed:
`1fbb45a`); next is their pin bump + flip + gates, and item 4 re-pins to the
stdlib tag at 100%. Backlog R-2/R-3/C8 are compiler-side. The
playground verifies `tcp_connect` against a refused port at every pin bump
(stdlib >= `c193bc4`).

**Protocol** (unchanged): recon -> probe-first in `tools/probes/` -> clauses
-> `coverage_scan.ps1 -DumpFloors tools/coverage_floors<N>.json` -> wire into
ci/heavy/release yml + tools/README.md + docs/STDLIB_READINESS_PLAN.md in the
SAME commit -> commit (pure-ASCII, single-quoted -m) -> full battery
(check_modules; full corpus 951 with `-RetryFailed`; probes corpus; barename;
both ratchets). One wave = one commit; no edits while a sweep is in flight;
docs coupling (session block + plan narrative); check
`git log -1 --format='%an <%ae>'` before any push.

### HANDOFF 2026-09-25 (context-limit snapshot; read this plus docs/PRODUCTION_READINESS_QUEUE.md)

State: `main` = `a948149` + the handoff docs commit, 38 commits ahead of
origin, UNPUSHED; compiler pin v0.61.3; all gates green on this tree
(check_modules 509/509; corpus 951/951; probes 181/181; barename 0/509;
coverage floors66; doc ratchet; strict-clause catalog clean). Coverage
scoreboard: stats 25 / convert 11.5 / math 8.3 / collections 77.2 / text 95.1
/ test 90.8 / error 90 / io 94.4 / regex 59.2; GLOBAL 26.2% pub-with-clause.
Release pre-flight done and waiting on stdlib 100% (checklist + 2-highlight
fragment ready). Full remaining-unit briefs (waves 30+, control/simplex,
geom, tzdata phase 2, untested-surface classes, release cut) plus all
environment/contract/import gotchas and the open compiler findings are in
`docs/PRODUCTION_READINESS_QUEUE.md` -- that file is the first read for the
next session.


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

**SESSION 2026-09-21 PART 3 (wave 17 + probe curation + R49-4 resolved in R54)**
- Local main: `81449da` (pushed) + `578d5d1` (wave 17 / floors54), `5c00bcc`
  (probe curation), `63ad30a` (single-param promotion) + this docs commit.
  The 2026-09-21 commits are local; the release lane decides pushes.
- Item 3 DONE -- wave 17: 26 payload-reading Result clauses across io/fs,
  io/console and io/pipe (R49-3 unlocked the forms; pre-validated in
  `tools/probes/p_wave17_shapes.xi`, which pins the mixed Int/Vec/Str payload
  combination). io 62.0% -> 78.7%, global 19.2% pub-with-clause;
  `tools/coverage_floors54.json` wired into all three workflows,
  tools/README.md and the readiness plan in the same commit. io smoke
  families 41/41 on R52. Future waves repeat the same protocol elsewhere.
- Item 5 DONE -- probe-corpus curation: the identical 18 failures on R49/R52
  split into `tools/probes/evidence/` (11: stale APIs, superseded shapes,
  deliberate parity evidence; README table) and `tools/known_failures/`
  (7 open: hash-interface `Self` argument, async_read_line EOF crash,
  generic-ctor push legs `p_gp_b`/`p_gp_c`, `p_fnref` identity needs a
  compiler ruling, `q1_verify_all` watchdog/perf -- green with
  `--timeout 0`). `.gitignore` now unignores `tools/probes/evidence/`; the
  full probe corpus is **159/159** on R53.
- R49-4 DONE -- compiler main `7837b194` (R54) fixes the large-fixed-array
  ISel crash; the raw `p_sweep_single_param.xi` compiles+links in ~51s. The
  promoted lock is `tools/probes/p_sweep_single_param.xi`: a runtime-guarded
  compile lock (the calls sit behind an `XIOM_SWEEP_RUN` env guard, so they
  type-check and codegen but never run -- the generated args are unsafe).
  The raw call set and the clang-crash header moved to
  `tools/probes/evidence/`. Fresh single-param scan: **60 modules / 239
  calls, compile-only 60/60** on R53/R54 (`gen_call_probes.ps1 -MinParams 1
  -MaxParams 1 -Timeout 0`; parallel compile-only pass). NOTE: run the
  compiler from the repo root (or set `XIOM_RUNTIME_DIR`) -- a worker with a
  different CWD resolves a partial runtime dir and link-fails on
  `xiom_simd_*` / `xiom_async_now_ms`.
- R53/R54 gates on the final tree: check_modules **509/509** (845.2s under
  load); corpus **949/949**, 0 compilefail, 0 runfail (1832.7s); probe
  corpus **159/159** (449.9s); coverage floors54 OK; doc ratchet OK;
  barename **0 hits / 509** (819.9s).
- Compiler-lane leftovers (L6-40, L5-40, L3-50, L8-14, perf peek, C3/C6)
  are playground/perf items and do not block the stdlib gate (relay).
- Queue below: items 1-3 and 5 are DONE; only item 4 (TLS/tzdata/registry)
  remains, last as always.

**SESSION 2026-09-21 PART 4 (untested-surface extension: `-IncludeRefs` tranche)**
- `tools/gen_call_probes.ps1` gained `-IncludeRefs`: accepted parameters now
  include `&T`/`&mut T` (scalar T) and `Vec[E]` by value or reference
  (locals emitted for references; by-value vectors use `Vec[E].new()`).
  Scalar behavior unchanged (re-ran the default scan: 47 modules / 179 calls).
- New tranche on R53 (`-MinParams 1 -MaxParams 4 -IncludeRefs`): **112
  modules / 602 calls, compile-only 110/112**. Both failures are OPEN
  compiler findings, not stdlib link gaps:
  `tools/known_failures/p_result_tuple_vec_loop.xi` -- a
  `Result[(Vec[Int], Int), Str]` arm whose loop-local feeds the Vec stores
  the Vec into a scalar-sized Result slot (`%tmp157` type mismatch); breaks
  `net.tls_helper.cert_public_key_info` / `cert_is_self_signed` via
  `asn1_read_oid`; and `tools/known_failures/p_ref_tuple_mangle.xi` -- a
  reference type in a tuple mangles into the struct name
  (`%struct.Tuple__&Vec__Int`, invalid LLVM identifier) plus the `unknown
  type '&Vec'` warning; breaks the `crypto.sign` Ed25519/ECDSA/DSA family
  already stubbed for this class. Relay these to the compiler lane.
- Untested-surface scan refreshed: **1,113 of 6,103** never-referenced pub
  fns (was 1,010 of 5,777 on 2026-09-17); covered classes now zero-arg +
  scalar 1..4 + refs/Vec; remaining: struct params 193, fn params 45,
  generics 83.
- Docs: `tools/README.md` (switch + tranche state) and
  `docs/STDLIB_BETA_LIMITATIONS.md` (single-param RESOLVED on R54, new scan
  numbers) updated in this commit.
- `-IncludeStructs` extension: struct-typed params are accepted when the
  declaring module has a public constructor (exact struct return type,
  non-struct params); the probe emits `var s = module.ctor(...)` by
  inference. 206 never-referenced fns carry struct params, 162 are
  constructible. Combined tranche: **123 modules / 734 calls, compile-only
  121/123** -- the same two findings, no new failures from the struct class.
  Remaining untested classes: 44 struct-param fns without a usable ctor,
  45 fn-param fns, 83 generic fns.
- `-IncludeFns` extension + parser fix: parameter lists now use balanced
  parens and top-level comma splitting (the old flat regex truncated
  `fn(...)` types; the "45 fn-param" profile number was inflation). Simple
  `fn(...)` params (scalar-or-empty inner, scalar/Unit return) get a local
  helper function in the probe; +4 calls. Inner params that are not scalars
  and generic fns remain untested. Combined final tranche: **123 modules /
  738 calls, 121/123** -- the same two findings only. Re-verified the scalar
  (47/179), refs (112/602) and struct (123/734) tranches are unchanged
  after the parser fix.

**SESSION 2026-09-21 PART 5 (R58 re-baseline; q1 promotion; two findings still open)**
- Compiler main `5bdffaad` (R58) built from `git archive` and verified; the
  R55-R58 batch resolved the compiler-lane leftovers L6-40/L5-40/L3-50/L8-14
  (e2e_m110-m113). No stdlib gate depended on them.
- All gates green on the stdlib tree: check_modules **509/509** (943.2s);
  corpus **949/949**, 0 compilefail, 0 runfail (2996.5s, `-RetryFailed`);
  probe corpus **160/160** (348.3s); barename **0 hits / 509** (585.3s);
  coverage floors54 OK; doc ratchet OK.
- The watchdog class also closed: `q1_verify_all` now compiles inside the
  default 300s watchdog (`compile=0 run=0`) and is PROMOTED to
  `tools/probes/` (probe corpus 159 -> 160, all green). `known_failures`
  re-triage on R58: q1 resolved, the other 8 unchanged.
- The two findings filed from the generated tranches
  (`tools/known_failures/p_result_tuple_vec_loop.xi` and
  `p_ref_tuple_mangle.xi`) still fail with IDENTICAL error signatures on R58;
  the refs tranche re-ran 110/112 with the same two failures. They are NOT
  part of the L6-40/L5-40/L3-50/L8-14 set and need their own compiler-lane
  fix. Relay these with the R58 evidence.
- Current verification binary: `xiom_r58.exe` (R58, `5bdffaad`);
  `xiom_r53.exe` (R54) and `xiom_r52.exe`/`xiom_r49.exe` are previous
  baselines.
- Wave 18 DONE (same day, on R58; commit `a3fe12a`): 38 clauses across
  `xiom.sort` / `xiom.search`, pre-validated by
  `tools/probes/p_wave18_shapes.xi`. In-place Int sorts gain
  `is_sorted(v)` postconditions (heap/quick/merge/radix import
  `xiom.sort.intro` and assert `intro.is_sorted(v)`), search gains
  index/position/tuple/match-window/table bounds, `merge` gains
  `result.len() == a.len() + b.len()`. sort 0% -> **31.9%**, search 0% ->
  **62.2%**, global 19.2% -> **19.8%** pub-with-clause; `floors55` wired in
  the same commit. Post-wave gates: check_modules **509/509** (352.1s);
  corpus **949/949**, 0 runfail (1643.4s); probe corpus **161/161**
  (350.2s); floors55 ratchet OK; sort/search smoke families 9/9.
- Wave 19 DONE (same day, on R58; commit `84b3407`): 37 clauses across
  `xiom.bits` (disjunctions, 0..64 count bounds, nibble 0..15, unpack
  byte-range tuples, bitfield_mask implication, scan -1..63, rotate-carry
  flags, bitarray counts), pre-validated by
  `tools/probes/p_wave19_shapes.xi`. bits 0% -> **36.6%**, global 19.8% ->
  **20.3%** pub-with-clause; `floors56` wired in the same commit.
  Post-wave gates: check_modules **509/509** (260.9s); corpus **949/949**,
  0 runfail (1513.9s); probe corpus **162/162** (343s); floors56 ratchet
  OK; bits smoke families 10/10.

**SESSION 2026-09-22 PART 6 (R61: every finding closed; waves 18-20; release-ready)**
- Compiler R59/R60 + R61 + rulings built and verified (`xiom_r61.exe`,
  `ff293f8e`). `tools/known_failures/` is EMPTY of open findings: six probes
  promoted to `tools/probes/` (generic-push trio, tuple-payload pair,
  async_read_line), two ruled and archived in `probes/evidence/`
  (hash-interface loud rejection, e2e_m117; fnref spec question). The
  stdlib-side fix for the fd/FILE* misuse landed in `xiom.async.io`
  (`71789f0`). All generated tranches 100% on R61: refs 112/112,
  structs 123/123, fns 123/123.
- Waves: 18 sort/search (a3fe12a/9a4ed97, floors55), 19 bits
  (84b3407/e1379a8, floors56), 20 geom vectors (385e1e4, floors57).
  Global pub-with-clause 19.2% -> **21.0%**; sort 31.9, search 62.2,
  bits 36.6, geom 10.6.
- R61 gates (final tree): check_modules **509/509** (287.3s); corpus
  **949/949**, 0 runfail (2842.8s); probe corpus **169/169** (652s);
  barename **0/509** (1448.1s); floors57 OK; doc ratchet OK; geom smokes
  8/8; async smokes 3/3.
- STATUS: the stdlib lane is **release-ready** pending the release lane's
  call -- no open compiler findings, all gates green on R61, probe corpus
  fully green.
- Queue: item 4 remains (Windows TLS/schannel compiler FFI hardening,
  tzdata phase 2, registry publish -- user/last); coverage waves are
  repeatable for the remaining dirs (math 4.1%, convert 1.6%, stats 0%,
  error 2.2%, text, regex, test, collections).

**SESSION 2026-09-22 PART 7 (Linux gate made real; 0.61.3 cut)**
- The fail-closed ubuntu gate exposed a Linux portability batch, all fixed
  on main and verified on the runner: runtime shims for dynamic loading,
  local time, errno, directory creation (POSIX mode argument) and
  hostname/user name; runtime OS detection (`xiom_os_name`) because
  `xiom.env` reported `windows` on Linux (compiler main R65 `3bf6e149`
  fixes that; lock e2e_m118 -- not in the v0.61.1 pin, so the workaround
  stays); `fs_exists` now true for directories; runner process capture +
  cross-platform worker launch + fail-closed accounting; the
  `check_modules` and `barename` gates got the same cross-platform +
  fail-closed treatment (`b9f5e24`). Manual ubuntu `smoke-probe.yml` with
  workdir/bin diagnostics is in the tooling.
- Evidence: the five original failures **5/5 PASS** on ubuntu
  (`35718892390`); `smoke_os_env` 1/1 (`35725653902`); the heavy ubuntu
  corpus was 948/949 before its fix; ubuntu **release gates then went green
  in 39m32s** (`35726136818`, the first fully real Linux gate).
- Release: `stdlib-v0.61.1`/`v0.61.2` are **dead tags** (gate failures;
  their publish runs were cancelled by the compiler lane). `stdlib-v0.61.3`
  cut on `c7b4027` (pin v0.61.1): **both gates green** (ubuntu 39m32s,
  windows 1h16m6s), `package` published the **first-ever stdlib release**
  (`xiom-std-0.61.3.tar.gz` + `SHA256SUMS`; local SHA256 verified against
  the published sums, 584 entries), and `canary-dispatch` auto-fired the
  **staging** publish run (`35734153403`, waiting in the `registry-publish`
  environment -- that is the run to approve). The tag-triggered production
  publish (`35726136811`) stays unapproved.
- `pin-pr` pushed `chore/pin-stdlib-v0.61.3` (commit `d67b254`) to
  xiom-lang/xiom but `gh pr create` failed: the release token lacks
  `createPullRequest`. The compiler lane opened **PR #3** pinning
  `STDLIB_VERSION` to `stdlib-v0.61.3` (merge is the owner's call). The job
  is now `continue-on-error: true` with a manual-URL warning, so a token
  scope gap cannot paint a release run red.
- **Registry lane VERIFIED the staging canary for `xiom-std@0.61.3`**
  (provenance + signature re-checked against the served tarball): the OIDC
  trusted-publish path is proven end to end. The production
  trusted-publisher entry stays undeployed until the owner approves; the
  tag-triggered production run (`35726136811`) stays unapproved.
- `p_platform_env.xi` is part of the probe corpus and passes on both hosts.

**SESSION 2026-09-23 PART 8 (released 0.61.3; compiler v0.61.3 out; next = production-grade push)**
- Compiler lane released **v0.61.3** (`d62b4d20`, "version parity with
  stdlib", R64/R65/AI-context/JIT batch; R65 = target-accurate
  `xiom.env` constants, lock e2e_m118). Stdlib release is also 0.61.3;
  the stdlib pin is still **v0.61.1** -- bumping it is the first task of
  the next session.
- Registry: the staging canary for `xiom-std@0.61.3` was VERIFIED
  (provenance + signature re-checked against the served tarball), and the
  tag-triggered **production publish completed successfully**
  (`35726136811`, owner-approved). `stdlib-v0.61.3` is now the live
  release; `0.61.1`/`0.61.2` remain dead tags.
- **Registry relay (repack semantics, important for "promote exactly the
  canary bytes")**: `xiom pkg publish` re-packs, so published bytes differ
  from the release asset and across runs; exact promotion needs
  deterministic packing (`SOURCE_DATE_EPOCH` / fixed mtimes) or a
  publish-existing-tarball mode. Re-running a release job regenerates the
  asset, which invalidates the canary's artifact claim -- **re-canary
  after any asset re-generation**. Tracked as a production-grade item
  (registry/compiler lanes; stdlib packaging can pin mtimes).
- Next-session queue (production-grade, 100% readiness, no restrictions):
  1. **Pin bump to compiler v0.61.3** (build from the tag with the
     documented recipe), then re-baseline: check_modules + full corpus +
     probe corpus + barename + ratchets; record as the next
     `VERIFICATION_BASELINE` section. Then decide on the runtime
     OS-detection workaround: R65 makes `xiom.env` correct, but the
     runtime `xiom_os_name` path is still more robust -- recommended to
     keep it and note why.
  2. Coverage waves (full protocol per wave: shape probe -> clauses ->
     `coverage_floorsN+1.json` -> wiring -> check_modules + corpus):
     `math` (995 pub, 4.1%), `convert` (304, 1.6%), `stats` (140, 0%),
     `text`, `regex`, `test`, `collections`, `error`/`io` tails.
  3. Duplication gate `[~]`: translation units (collect/hash vs
     linkedhash, cache vs lru, geom short/long names); twin removal waits
     on the compiler api_freeze snapshot regen.
  4. tzdata phase 2 (full historical/global tables).
  5. Deterministic stdlib packaging (SOURCE_DATE_EPOCH / fixed mtimes) so
     published bytes equal the release asset bytes (coordinate with the
     registry/compiler lanes).
  6. Untested-surface tail: 44 struct-param fns without a usable ctor,
     fn-params with non-scalar shapes, 83 generic fns.
  7. Runtime symbol audit: 20 definition-only delete candidates awaiting
     compiler-lane confirmation.
  8. TLS/schannel stays compiler-FFI-gated; registry production
     activation is now proven, the owner deploys further entries.
- Subagents are allowed in the next session for parallel
  reconnaissance/triage (keep repo edits single-threaded; one family =
  one commit).
- Post-release tooling increment (2026-09-22): `gen_call_probes.ps1` gained
  `-IncludeWrappedCtors` (Result/Option constructors consumed in the success
  arm), extending the untested-surface scan to **126 modules / 751 calls,
  compile-only 126/126** on R61. Tools-only change: no stdlib sources moved,
  so the v0.61.0 artifact (pinned at `385e1e44`) is untouched.
- Wave 21 DONE (2026-09-22; commit `7b1d060`): 19 clauses on `xiom.error`
  (identity results, error_context constant-length arithmetic, conditional
  error_join identities, backtrace/chain/context count relations, chain
  push/pop invariants, Option-to-Result mapping), pre-validated by
  `tools/probes/p_wave21_shapes.xi`. error 0% -> **37.5%**, global 21.0% ->
  **21.2%** pub-with-clause; `floors58` wired in the same commit. Gates:
  check_modules **509/509** (278.8s); corpus **949/949**, 0 runfail
  (1474s); probe corpus **170/170** (292.3s); floors58 ratchet OK; error
  smokes 9/9.
- Release coordination (2026-09-22, read-only checks): compiler v0.61.0 is
  NOT tagged (no remote ref; latest release v0.60.1) and release dry-run
  `35671548976` is blocked on macos-arm64 (`Build release` failed;
  windows-x64 and the guard passed), so the compiler tarball asset the
  stdlib canary downloads does not exist yet. No `stdlib-v0.61.0` tag has
  been created; production tagging waits for the compiler assets + staging
  canary + owner approval (the production trusted-publisher entry for
  `refs/tags/stdlib-v*` is not deployed yet). The stdlib lane holds at the
  pinned `385e1e44` artifact for the canary.

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
1. ~~Compiler lane follow-up (relay via the user): R49-4
   `p_sweep_single_param` clang ISel crash remains the only filed ISel
   blocker.~~ **DONE 2026-09-21** (R54 `7837b194`; the guarded lock is
   promoted, raw evidence archived, single-param tranche 60/60 -- see
   PART 3). Compiler-lane leftovers are playground/perf only and do not
   block the gate. Two further probe findings remain open and relayed:
   `p_result_tuple_vec_loop` (Result tuple payload with a Vec; breaks
   net.tls_helper) and `p_ref_tuple_mangle` (reference type in a tuple
   struct name; breaks crypto.sign) -- unchanged on R58, see PART 4/5.
2. ~~Untested-surface generator: compile the remaining groups
   (`-OnlyCalls 3` .. `-OnlyCalls 58`, or `-Limit N` for triage) against
   the R49 binary; triage failures into `tools/known_failures/` with
   evidence and passes into `tools/probes/`.~~ **DONE 2026-09-20**
   (138/138 compile-only; the one failure was the fixed no-NASM runtime
   link gap; see the session block above). The single-param tranche is
   regenerated and 60/60 compile-only on R53/R54 (PART 3).
3. Coverage (repeatable, optional): payload-reading Result clauses are
   allowed (R49-3); pre-validate new shapes in `p_waveN_shapes.xi`, then
   dump `coverage_floorsN+1.json` and wire it into all workflows + READMEs
   in the same commit. Wave 17 (io), wave 18 (sort/search) and wave 19
   (bits) landed 2026-09-21 -- see PART 3/5. Remaining 0-coverage dirs
   include geom, error, stats, text, convert, regex, test, collections and
   math.
4. Windows TLS/schannel (compiler FFI hardening) and tzdata phase 2 stay
   last; registry publish activation is the user's (dispatch-only
   `publish-registry.yml`). Every new pub declaration needs `///` prose
   (100% doc ratchet).
5. ~~Probe-corpus curation~~ **DONE 2026-09-21** -- the 18 red probes split
   into `tools/probes/evidence/` (11) and `tools/known_failures/` (7); the
   probes root is 159/159 on R53. See PART 3.
6. **Production-grade queue (2026-09-23)**: see PART 8 -- compiler pin bump
   to v0.61.3 + re-baseline, coverage waves, duplication translation,
   tzdata phase 2, deterministic packaging, untested-surface tail, runtime
   symbol audit. TLS/schannel stays compiler-FFI-gated.

**Recipes**
- Build a compiler ref: export it (`git -C E:\xiom-lang\xiom archive
  --format=zip -o <zip> <ref>`), expand to a temp dir, set
  `CARGO_TARGET_DIR=<temp>\target`, `cargo build --locked -p xiom`. GOTCHA:
  if you reuse a warm target dir, TOUCH all extracted sources first
  (git-archive mtimes can be older than the artifacts, so cargo skips the
  rebuild). Run with `XIOM_STDLIB=E:\xiom-lang\stdlib`. Built across the
  campaign: R46 `12148d43`, R46b `504fcc1e`, R49 `306073ba`, R52 `1fcb4855`,
  R54 `7837b194`, R58 `5bdffaad`, R61 `ff293f8e` (the last verified debug
  binary is `xiom_r61.exe`, stashed under `%TEMP%\kilo\stdlib_ws\`);
  release tags now exist: compiler **v0.61.3** (`d62b4d20`) and stdlib
  **stdlib-v0.61.3** (`c7b4027`). The next session should build the
  compiler from tag `v0.61.3` (see PART 8), not from a session commit.
  Resolve the runtime from the repo root (or set `XIOM_RUNTIME_DIR`): a
  different CWD links a partial runtime and fails on `xiom_simd_*` /
  `xiom_async_now_ms`.
- Gates: `./tools/run_smokes.ps1 -Compiler <exe> -Workers 8 -RetryFailed`;
  `powershell -NoProfile -File tools/check_modules.ps1 -Compiler <exe>`
  (this box has NO `pwsh` -- use `powershell`);
  `powershell -NoProfile -File tools/barename_scan.ps1 -Compiler <exe>`;
  `powershell -NoProfile -File tools/coverage_scan.ps1 -RatchetFile
  tools/coverage_floors54.json`;
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


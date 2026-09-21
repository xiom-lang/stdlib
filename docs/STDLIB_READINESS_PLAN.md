<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# XIOM Stdlib Readiness Plan (production-grade bar)

**Created:** 2026-08-24 - **Branch:** `feat/architect` - **Baseline HEAD:** `81ed009a` (round-15)
**Scope:** `stdlib/**` (package `xiom/*`, `runtime/` C+asm) plus smoke realignment in
`examples/stdlib_smoke/`. The PARALLEL COMPILER SESSION owns `crates/**`; see
`docs/COMPILER_READINESS_PLAN.md`. Neither session edits the other's tree.
**Sources:** `docs/xiom-stdlib-audit-v0.58.md`, `docs/stdlib_session.md`,
`docs/REPORT_TO_STDLIB_SESSION.md`.

---

## 0. Position (why this plan)

The audit's verdict stands: breadth A-, assurance F. Three broken foundations,
in urgency order:

1. **No test culture** -- 8 `test_*` fns / 3 asserts in 150k LOC; zero KATs for
   crypto/encodings/parsers.
2. **Compiler-forced duplication** -- same-name delegation crash forces
   copy-paste modules; copies already diverged (base64 4-vs-8 pub fns).
3. **Allocation-per-op core types** -- every string predicate mallocs; no views/
   builder/arena; Option/Result payload-always layout.

(2) is a compiler fix -- we prep, they land. (1) and most of (3)'s first steps
are OURS and unblocked TODAY.

## 1. Ownership & coordination contract

| Item | Owner | Status |
|---|---|---|
| `stdlib/**`, `runtime/**`, smoke realignment | STDLIB (this plan) | active |
| Same-name delegation crash (repro: `convert/base58`) | COMPILER | flagged, needs priority bump |
| geom nested `&Vec[Vec[Float64]]` param reads | COMPILER | round-16 queue |
| CRT-layout AV family / json heap layer / stack-cookie fns / clang variants | COMPILER | stage 4 |
| array_zip T001 tuple typing | COMPILER | stage 2 |
| LET-array representation joint decision (M33 let->Vec vs &[N]T) | JOINT | doc pending from compiler |
| api_freeze harness path sync (item B) | COMPILER | blocks honest manifest checks |

Rule (from REPORT_TO_STDLIB_SESSION.md): never work around an open compiler
bug in stdlib code; document the blocker instead, fix when their round lands.

## 2. Phase T -- Trust (this campaign; highest ROI)

Audit Phase 0 adapted to what is executable now:

### T1. Ground truth sweep
Full 907-smoke sweep on the isolated round-15 binary (worktree build at HEAD;
the compiler session holds uncommitted crates/ changes, so a shared binary is
unusable for attribution). Triage deltas vs the known-fail clusters in
`stdlib_session.md` section 1. Every NEW failure gets probe -> log -> verify
before any edit; stdlib-side fixes committed, compiler-side logged to
`REPORT_TO_COMPILER_SESSION.md`.

### T2. Known-answer test corpus (kills audit #1)
New smokes prefixed `kat_` in `examples/stdlib_smoke/`, one module family per
file, official vectors ONLY (no self-invented expectations):

| File | Vectors |
|---|---|
| kat_encoding_base16_32_64 | RFC 4648 test vectors incl. padding/url-alphabet |
| kat_convert_base64url | RFC 4648 S5 + unpadded forms (diverged-copy lock) |
| kat_encoding_punycode | RFC 3492 S7 sample vectors |
| kat_convert_utf8_decoder | Kuhn stress set subset (BMP, surrogates-reject, overlong-reject, boundary bytes) |
| kat_crypto_sha2 | NIST CAVP short/msg digests SHA-256/512 + empty-string vectors |
| kat_crypto_hmac | RFC 4231 HMAC-SHA-256 cases 1-7 |
| kat_crypto_chacha20poly1305 | RFC 8439 S2.3.2 keystream + S2.8.2 AEAD vector (where paths compile) |
| kat_serialize_json | JSONTestSuite y_/n_ minimal subset (parse accept/reject) |
| kat_net_parsers | url/ip/percent edge tables from RFC 3986/4291 examples |
| kat_num_bigint_bigfloat | known decimal expansions + round-trip identities |

Blocked-but-written rule: if a KAT's path hits a compiler cluster (pbkdf2/
argon2 stack cookies, json heap layer), commit it anyway marked BLOCKED in the
header with the bug name; it flips green automatically when their fix lands.
Crypto first -- an untested AES is indistinguishable from a broken AES.

### T3. Lock in verified wins as permanent smokes (handoff item 5)
- `smoke_iter_zip_predicates` (probe_iter_terminals shapes)
- `smoke_sync_arc_battery` (deref-assign constructor pattern)
- string byte-copy locks: multibyte passthrough lower/upper, str_slice via
  byte_at, byte_at OOB -> 0

### T4. Ownership convention (audit Phase 0 item 3)
`docs/STR_OWNERSHIP.md`: who frees what across `Str.from_cstring`, malloc'd
buffers crossing extern boundaries; then audit all ~93 extern "C" sites against
it. ASAN pass deferred until compiler stage-5 infra exists.

## 3. Phase E -- Core ergonomics (stdlib-side, unblocked)

1. **StringBuilder** (`string/builder.xi`): amortized doubling, push_str/
   push_byte/int_to_string reuse; migrate hot encode/parse internals.
2. **Deallocated predicates**: rewrite starts_with/ends_with/index_of family as
   index-range comparisons (no slice-malloc). Blessed `(Str, start, end)` idiom
   until the language has borrowed views; keep API compatible.
3. **Route bulk copies through runtime memops**: bind the already-exported
   `xiom_asm_memcpy/memmove/memset`; concat/copy fast-path above a length
   threshold. Bound via `xiom.mem`/`xiom.ffi.c`; the `XIOM_NO_ASM` C
   fallbacks in `runtime/xiom_runtime.c` now carry external linkage
   (2026-09-20) so no-NASM compiler builds link those externs; locked by
   `tools/probes/p_asm_fallback_link.xi`. The length-threshold fast-path
   for concat/copy remains open.
4. **Container tuning docs**: load/growth/shrink factors, iteration-order
   guarantees; make keyed siphash the default Map hasher (hash-DoS).
5. **CSPRNG binding** (audit security top item): inspect `rng_crypto.xi`
   seeding; runtime exports no OS entropy symbol -> add `xiom_os_entropy` to
   `runtime/` (BCryptGenRandom on Win, getrandom on Unix), reseed policy doc.

Order matters: 1-3 change no APIs, so they can land between compiler rounds
without churn.

## 4. Phase O -- Organization (prep now, execute after delegation fix)

- Dedup inventory: canonical module per twin pair (base64, base32, ascii85,
  percent, punycode, json, endian x3, glob, soundex, levenshtein, ip, url,
  duration, date, fs x3, terminal x3, platform x2, geom twins) with migration
  shim design. Executing renames BEFORE the same-name-delegation crash is fixed
  would hit the identical crash -- do not reorder.
- `package.xi` identity fix ("xiom-bench"/"xiom-std" nonsense) after driver
  registry format settles (compiler stage 5 supply chain).
- Deprecation ladder for MD5/DES/SHA-1: move under `crypto/legacy/` with loud
  headers; never defaults. Pure-doc + header change, safe NOW.
- Namespace cleanup (collect vs collections, escaped crypto names, memory
  quartet) -- mechanical, gated on delegation fix + shims.

## 5. Phase C -- Capability completion (priority order)

1. CSPRNG (see E5 -- pulled forward into this campaign if time allows).
2. TLS decision doc: recommend FFI-bind system schannel first (toolchain is
   Windows-first); until landed, https/jwt/ws modules carry honest
   "plaintext unless you bring your own TLS" security footnotes.
3. CSV DONE 2026-09-12 (`xiom.serialize.csv`: RFC 4180 reader/writer,
   quoted/doubled-quote/embedded-newline handling, CRLF writer,
   smoke_serialize_csv with round-trip vectors). TOML + argv-parsing
   still owed (toolchain eats its own `xiom.toml`).
4. tzdata: phase 1 delegate to OS timezone APIs via FFI; embed IANA snapshot later.
5. Bind-or-delete the ~175 orphaned runtime symbols (atomics ordering, ctx
   swap, ct_compare into MAC compare, disk/sysinfo).
6. Async stress suite (10k fibers, cancellation storms, channel saturation).

## 6. Phase S -- Scale discipline

Property tests for collections (BST balance, heap shape, hashmap distribution);
fuzz targets for url/ip/header/cookie/mime/json/utf parsers (pairs with
compiler stage-5 fuzz infra); decompression-bomb guards (max output ratio/
size caps) on gzip/lz4/json decoders; coverage ratchet from whatever number
T1/T2 yields.

## 7. Sequencing rules

- Sweeps run on ISOLATED binaries built from committed HEAD in a temp worktree;
  never the shared target/debug (compiler session rebuilds it live).
- No stdlib edits while a sweep is in flight; author new files in staging.
- One fix = one probe = one verified rerun; batch commits per family.
- Contract clauses ride along on every touched function (target >=60% pub-fn
  coverage in collections/string/io eventually; verifier hardening makes them
  meaningful).
- Update `stdlib_session.md` at session end; report cross-boundary items to
  `REPORT_TO_COMPILER_SESSION.md`.

## 8. Definition of production-ready (gate)

- [x] Zero known-cluster regressions -- DEFINITIVE all-green 2026-09-12:
      r33 sweep on committed compiler HEAD b8e2fa43 = 935 files,
      935 PASS / 0 RUNFAIL / 0 COMPILEFAIL (includes smoke_serialize_csv).
      History: r20 903/937; r29 916/935; r32 927/934 with three compiler
      WIP regressions (R11/R12/R13) which b8e2fa43 superseded and closed.
      Freeze re-verification 2026-09-17 on compiler tag v0.60.0:
      947/947 PASS, 509/509 module check, 0 bare-name hits, ratchet OK
      (docs/VERIFICATION_BASELINE.md).
- [x] KAT corpus committed and passing for encodings/UTF-8/hashes/MACs/AEAD/
      parsers -- 15 files, ALL un-gated as of 2026-09-10 (kdf + json last)
- [x] CSPRNG bound to OS entropy with documented reseed policy -- flip
      landed 7148b615; OS-seeded LCG only as documented no-OS fallback
- [x] StringBuilder + alloc-free predicates shipped (DONE); runtime memops
      bound in xiom.mem (DONE); STRING fast-path RE-LANDED 2026-09-12:
      str_concat + sb_to_str route through xiom_memcpy_dispatch with the
      R16 Int-cast workaround for the dest offset (the old Str-cast
      chained-concat failure was the `buf + len_a` argument miscompile,
      not the casts). Verified by p_fastpath_live + the string subset;
      full r34 corpus sweep runs as the definitive gate.
- [x] Legacy ciphers quarantined: banners + physical move DONE 2026-09-12
      (des/md5/sha under crypto/legacy/; module names frozen for the api
      freeze, manifest paths synced; p_legacy_modules + 41-file crypto
      battery green); TLS story documented (TLS_DECISION.md); schannel
      binding not started
- [~] Duplication consolidated -- 2026-09-12 waves: endian trio unit
      landed; namespace waves (collect dirs, memory quartet); ascii85
      audited (= already layered: convert canonical, encoding wrappers, no
      action). UPDATE 2026-09-15/16 (R15/R20/R22 fixed): convert.base16/
      base32/base64/base64url/percent are delegating shims over
      xiom.encoding (r44/r45 green + corpus gate clean); convert.base58
      delegates to_base58 to num.convert with the INT_MIN pin;
      convert.punycode audited as NOT A TWIN (ACE-label vs RFC raw-payload
      conventions) and locked by smoke_convert_punycode. UPDATE 2026-09-16
      (round 62): the ip family is DELEGATED -- convert.ip validators/
      parser, net.dns ip helpers, net.ip v6 legs (+ local v6 parser
      removed) and net.net's v4 validator all delegate to net.ip4/net.ip6
      (p_ip_parity/p_ip_parity2/p_dns_parity/p_netip_parity zero
      mismatches; R28-safe named-local binding). os.term shimmed onto
      os.terminal + format.terminal. Platform audited 2026-09-17 and found
      NOT a duplicate pair: xiom.platform (ergonomic os_name/is_bsd/
      newline/path_sep surface, declared in core/platform.xi) and
      xiom.os.platform (platform_* surface + hostname/user) have disjoint
      names and both have consumers; core/platform already delegates to
      xiom.os/env. net.address and io.console-vs-os.terminal also audited
      as NOT duplicates. Remaining consolidation units (translation, no
      blind shims): collect/hash vs collect/linkedhash, collect/cache vs
      collect/lru, geom short/long names; twin removal waits on the
      compiler api_freeze snapshot regen.
- [x] Coverage number published + ratcheted in CI-equivalent sweep script --
      DELIVERED 2026-09-12: global 1092 clauses / 8634 fns = 12.6%
      (pub-with-clause 720/6469 = 11.1%); key modules io 38.9%,
      string 17.1%, collect 18.9% (target >=60% in later waves). Wave 1
      added 40 clauses on touched io/string/IntMap/StringMap fns; wave 2
      added 83 clauses across 56 collect containers (size/len/count >= 0,
      is_empty == (len == 0), clear -> size 0), lifting collect
      2.0% -> 18.9%. Wave 3 (2026-09-14): 22 clauses (str_slice bounds,
      empty-needle predicates, is_empty equalities, rindex/title/swap
      length locks, 9 cache/ring capacities) -> string 22.4%, collect
      20.8%, global 13.6% clauses / 12.3% pub-with-clause. Wave 4
      (2026-09-15): 61 clauses (distance-family non-negativity,
      unicode counts/grapheme stepping, char radix guards + len_utf8
      bounds, rotate length-preservation, collect heights/pool/graph/
      unionfind/tinylfu/radix, io line/args length clauses) -> string
      30.2%, collect 23.4%, io 45.4%, global 14.2% clauses / 13.2%
      pub-with-clause. Wave 5 (2026-09-16): 46 clauses, mostly REAL range
      specs (char predicate family `result == <range expression>`, compare/
      collate sign bounds, collate_key length preservation, bloom FPR) ->
      string 39.5%, collect 23.6%, io 45.4%, global 14.7% clauses / 13.8%
      pub-with-clause. Wave 6 part 1 (2026-09-16): 16 clauses (iter
      count/length equalities + bounds, sync channel/barrier counts) ->
      iter 9.8%, sync 29.1%, global 14.9% clauses / 14.0%
      pub-with-clause. Wave 6 part 2 (2026-09-16): 31 clauses (25 ANSI
      ESC-prefix specs + net ftp/port/cookie/address real specs) ->
      net 5.4%, format 13.0%, global 15.2% clauses / 14.5%
      pub-with-clause. Wave 6 part 3 (2026-09-16): 7 clauses (natural-order
      sign bounds, unicode wrapper specs) -> global 15.3% clauses / 14.6%
      pub-with-clause. Wave 7 (2026-09-17): 25 clauses on collect
      (constructors, Option.is_some == query relations, post-remove
      absence, order/iter length equalities) -> collect 23.6% -> 29.7%,
      global 15.7% clauses / 15.0% pub-with-clause. Wave 8 (2026-09-17):
      26 clauses (unicode display/width bounds, fixed script/category
      code lengths, numeric Option value bounds, boundary length bounds;
      collect pop/remove @pre size relations) -> collect 30.8%,
      string 40.5% -> 44.6%, global 16.1% clauses / 15.4%
      pub-with-clause. Wave 9 (2026-09-17): 22 clauses (combinatorics
      shuffle/interleave/reverse length equalities, chunk/window/unique/
      frequency count bounds, most-frequent Some-implies-nonempty,
      permutation count bounds; io parent_path + BufReader/BufWriter
      constructors + read_file helper Ok-length) -> string 44.6% ->
      48.5%, io 45.4% -> 50.9%, global 16.3% clauses / 15.7%
      pub-with-clause. Wave 10 (2026-09-17): 18 clauses (rbtree full
      surface: constructor size, insert/remove @pre size + membership,
      get/is_some==contains, min/max Some-iff-nonempty, walk lengths;
      cache LRU/LFU/ARC constructor field, get/is_some==contains,
      put-membership) -> collect 30.8% -> 34.4%, global 16.6% clauses /
      16.0% pub-with-clause. Wave 11 (2026-09-18): concurrent constructors
      -> collect 34.9%, global 16.6% clauses / 16.1% pub-with-clause;
      floors48. Wave 12 (2026-09-18): 60 clauses (graph traversal/
      union-find relations, spatial size @pre + query count bounds,
      persistent length relations, LFU/ARC membership, CMS/TinyLFU
      estimate bounds) -> collect 34.9% -> 44.8%, global 17.3% clauses /
      16.8% pub-with-clause. Wave 13 (2026-09-18): 21 clauses (string
      case/normalize empty-input implications; io buffer Result-Ok and
      constructor field specs; fs is_file/is_dir imply exists) -> string
      48.5% -> 50.7%, io 50.9% -> 62.0% (the first key module across the
      60% gate), global 17.6% clauses / 17.1% pub-with-clause. Wave 14
      (2026-09-18): 38 clauses (btree/btreeplus/bloom/fenwick/cuckoo/avl/dag
      size + membership relations; no call-`@pre` clauses -- see the
      compiler bug) -> collect 44.8% -> 53.2%, global 18.3% clauses /
      17.7% pub-with-clause. Wave 15 (2026-09-19): 38 clauses (string
      builder/align/pad/join/replace/search/escape/wrap no-op + empty
      relations) -> string 50.7% -> 60.0% (second key module across the
      60% gate), global 18.7% clauses / 18.3% pub-with-clause. Wave 16
      (2026-09-19): 35 clauses (bitmap/deque/bheap/blockingqueue/hash/
      concurrent/fheap size + membership relations) -> collect 53.2% ->
      60.7% (all three key modules now above the gate), global 18.9%
      clauses / 18.9% pub-with-clause. Wave 17 (2026-09-21): 23 clauses
      (payload-reading Result forms unblocked by R49-3: io/fs Err messages
      non-empty, fs_read_range bounded/zero-length Vec payloads,
      fs_write_range written <= data.len(), io/console + io/pipe Err
      payloads, always-Ok reads, simulated tty false) -> io 62.0% -> 78.7%,
      global 19.2% pub-with-clause; pre-validated by
      tools/probes/p_wave17_shapes.xi. Ratchet:
      tools/coverage_scan.ps1 -RatchetFile tools/coverage_floors54.json
      (repo tooling as of the split; positive + negative runs verified;
      earlier floors kept at
      coverage_floors32/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/50/51/52/53.json).
      Floors are per top-level stdlib/xiom directory and must be refreshed
      when a module is ADDED (new uncovered pub fns dilute the percentage
      -- TOML dropped serialize 6.1% -> 5.4%, tz dropped time 13% ->
      12.4%; global is 12.0% after both modules).

## 9. Status audit -- 2026-09-10 (rounds 15-29, sweep29 in flight)

### 9.1 What is genuinely done (verified, not aspirational)

- **Trust (T)**: 935-file smoke corpus + 15 KAT files (RFC 4648/4231/5869/
  8439/1952, NIST SHS, JSONTestSuite subset, Kuhn UTF-8); ownership
  convention (STR_OWNERSHIP.md) with full extern-site audit; probe-first
  verification protocol; compressed/gzip proven interoperable with python.
- **Ergonomics (E1,E2,E4,E5)**: StringBuilder; alloc-free search predicates;
  container tuning doc; CSPRNG (OS-entropy flip + lock smoke);
  decompression-bomb caps through lz77/huffman/deflate/gzip/zlib/lz4/snappy.
- **Compiler-forced debt cleared**: T007 whole-body-unsafe sweep (128 fns),
  io.rename/exit collision shims, io.sleep Windows fix, 20+ smoke/API
  keyword-defect repairs (env.var, MimeType.type, module_theory/module,
  pub/fn locals), stdio FILE* accessors, R5/R6/KDF/CRT/json flips verified.
- **Organization (O)**: dedup execution started; legacy banners; TLS doc.

### 9.2 Remaining work, ordered

**A. Unblocked now (highest ROI first)**
1. sweep29 triage + publish baseline. Fix smoke_stress_io_bufreader
   harness block: add io.open/io.close (FILE* wrappers; BufReader has NO
   file-open API today) and make the smoke file-based; note for all sweep
   harnesses: redirect stdin.
2. ~~Seeded-siphash DEFAULT hasher switch (E4; hash-DoS)~~ DELIVERED
   2026-09-12 (b6df21b7): StringMap defaults to per-process OS-entropy
   seeded SipHash-2-4 (zero-copy Str core, vectors re-verified); degraded
   fallback documented. Iteration order now varies run-to-run by design
   (STDLIB_CONTAINER_TUNING.md updated). Follow-up: generic HashMap[K,V]
   seed rollout.
3. ~~Legacy physical move to crypto/legacy/ + deprecation ladder~~ DONE
   2026-09-12: des/md5/sha moved to crypto/legacy/ with physical-location
   headers; module names frozen (api_freeze), manifest synced; probe +
   41-file crypto battery green.
4. ~~Namespace cleanup wave 1: collections/.xi files declare module
   xiom.collect.* (62 files) while xiom.collections also exists~~ DONE
   2026-09-12: 61 xiom.collect.* files moved to stdlib/xiom/collect/
   (rc-move pattern); xiom.collections aggregate stays at
   collections/collections.xi; manifest + naming docs synced; 100/100
   container smokes green. Memory quartet still queued.
5. ~~Contract-coverage wave 1 (io/string/collections touched fns) + publish
   the coverage number + add a ratchet mode~~ DONE 2026-09-12 (see gate #7).
6. Dedup continuation: ~~endian three-way~~ DONE 2026-09-12
   (convert/endian -> delegating shim over serialize.endian + bits;
   twin-vs-vectors pinned by smoke_convert_endian). UPDATE 2026-09-15
   (R20 fixed): convert.base16/base32/base64/base64url + percent ->
   delegating shims over xiom.encoding.hex/base32/base64/percent (r44
   940/940 + corpus gate clean with them; percent's component/decode
   legs delegate while its unique full-URL percent_encode stays local).
   Remaining: punycode (API translation to encoding.punycode/idna) and
   base58 (num.convert INT_MIN divergence) -- need a translation pass,
   probes p_pct_probe/p_b32_alias document the R22 shapes (now closed).
   Still queued: ip4+ip6 (needs an API translation pass --
   Result/Vec[UInt8] vs Option/Vec[UInt16], not a blind shim),
   console/os.terminal/os.term, core.platform/os.platform -- each lands
   with a parity smoke.

**B. Capability (C)**
7. Runtime symbol audit: 441 xiom_* defs vs 247 stdlib externs => ~194
   unbound symbols; bind-or-delete.
8. ~~CSV + TOML modules (toolchain eats its own xiom.toml)~~ CSV DONE
   2026-09-12 (xiom.serialize.csv + smoke_serialize_csv); TOML owed.
9. tzdata phase 1 via OS timezone FFI (only chrono_timezone_offset today).
10. Async stress suite (10k fibers, cancellation storms, saturation);
    async infra currently has a single smoke.
11. TLS schannel binding (project; decision doc done).

**C. Compiler-gated**
12. ~~R7 (generic container mono truncates large V)~~ FIXED 2026-09-11
    (882ee321): json nested + large_json + Map[K,bigV] verified green.
13. ~~R8 (char_at contract codegen)~~ FIXED 2026-09-11 (20aa3d07):
    char_at in-range ensures RESTORED and verified; R8 follow-up
    (method `.trim()` on Str params) + R10 (Vec[Option[struct]]
    element AV) also FIXED and verified on r32 (029bdb77).
12b. ~~R9 (full-path calls without import)~~ latent only: stdlib shims
    all import their targets and the shipping corpus is clean; the
    compiler lane is on it (tests/regression/m70_full_path_shim_delegation.xi
    in flight). R11/R12/R13 (r31/r32 WIP regressions) CLOSED by
    b8e2fa43; r33 all-green.
14. ~~memops string fast-path re-land (Str-cast chained concat)~~ DONE
    2026-09-12: the real failure was R16 (`ptr + int` as a memcpy dest
    argument miscompiles); re-landed with the Int-cast workaround in
    str_concat + sb_to_str. Completes gate #4's performance item.
15. Stage-5 coupling: fuzz targets, api_freeze manifest path sync,
    package.xi identity.

**D. Scale discipline (S)**
16. Property tests for collections (BST balance, heap shape, hash
    distribution). STARTED 2026-09-15: smoke_prop_collect_avl (512-key
    deterministic LCG Fisher-Yates permutation: membership + AVL height
    bound across random-order inserts/removals, min/max, empty-out),
    smoke_prop_collect_heap (pairing-heap extract_min non-decreasing +
    exact size tracking), smoke_prop_collect_lhmap (LhMap overwrite/remove
    size + value consistency + strictly ascending keys_in_order).
    EXTENDED 2026-09-16: smoke_prop_collect_bloom (no false negatives over
    500 LCG keys, rate in [0,1] non-decreasing, clear empties),
    smoke_prop_collect_persistent (PVec/PMap structural persistence),
    smoke_prop_collect_rbtree (inorder exactness/ordering under 512-key
    shuffle + removals), smoke_prop_collect_hashchurn (1000-key model vs
    LhMap through 2000 mixed ops). Corpus 937 -> 946; r46 sweep 946/946 +
    ratchet OK. Property-smoke queue CLOSED (avl/heap/lhmap/bloom/
    persistent/rbtree/hashchurn).
17. Parser fuzz ladder (url/ip/header/cookie/mime/json/utf) once stage-5
    fuzz infra lands.
18. Coverage ratchet in CI-equivalent script; async/CLI-of-everything.

### 9.3 Honest Rust-parity gaps (beyond the original plan)

- CSV and TOML (v1 reader) landed 2026-09-12; still missing: timezone
  database/zoneinfo and TLS -- the remaining "not a complete systems
  stdlib yet" items.
- Async runtime is minimal (executor/timer/channel); saturation +
  cancellation VALIDATED 2026-09-16: smoke_async_stress.xi (2000-task
  executor storm with side-effect verification, 2000 channel FIFO pairs,
  1000 broadcast ordering, 200-timer wheel fire/cancel storm) and
  smoke_async_cancel.xi (executor_shutdown drops 1000 pending tasks;
  wheel cancel-all/selective/unknown-id; channel close drain + Err/false
  semantics). Compiler finding R23 (executor stored-fn shape-dependence)
  is FIXED (2e06a3e7) and re-verified on r46. No preemptive cancellation
  API exists (cooperative model) -- documented in
  docs/STDLIB_BETA_LIMITATIONS.md.
- Runtime symbol audit DONE 2026-09-16 (docs/RUNTIME_SYMBOL_AUDIT.md):
  322 unique xiom_* runtime definitions vs 138 stdlib extern names; 192
  unbound = 83 codegen-referenced (keep), 83 runtime-internal (keep), 20
  definition-only delete candidates (mostly the hot-reload family +
  API-completeness stubs). Nothing is worth BINDING: the unbound remainder
  is compiler runtime ABI or dead code. Compiler lane to confirm dynamic
  use and delete/annotate the 20.
- Contract coverage 14.2% globally / 13.2% pub-with-clause (wave 4,
  2026-09-15); key modules io 45.4%, string 30.2%, collect 23.4%
  (target >=60%; waves 5+ owed).
- Namespace/identity debt: collect vs collections, memory quartet,
  package.xi identity, geom/twin module names.
- No fuzz infrastructure (stage-5 dependent); collection property smokes
  landed 2026-09-15/16 (avl balance/membership, pairing-heap ordering,
  LhMap overwrite/remove invariants, bloom no-false-negatives/rate/clear,
  PVec+PMap structural persistence); the coverage number IS published +
  ratcheted (gate #7) as of 2026-09-12.
- Item A catalog findings: stdlib burn-down DONE 2026-09-12 (237 -> 2
  findings, 17 -> 1 parse errors; the remainder are the compiler-side
  D4 iter:413 / D5 path:261 / D1 time `<=>` items) -- full details in
  docs/ITEM_A_STDLIB_FINDINGS.md; r36 sweep 935/935, ratchet OK.
- Console is Windows-first (console_clear "cls"); os.terminal exists but
  the split is not consolidated.

Strengths relative to the Rust-parity bar: breadth (40 module families),
KAT-locked crypto/compression with real RFC interop, 935-file executable
smoke corpus, OS-entropy CSPRNG, working threads/sync/atomics, SIMD/geom/
stats/math towers, and a documented verification protocol.

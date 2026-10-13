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
      collect/lru, geom short/long names. UNBLOCKED 2026-09-24: the
      compiler lane regenerated the api_freeze snapshot (m125 --
      rename-only AsyncExecutor.*/NetHttpResponse, 1:1 verified) and
      INDEPENDENTLY VERIFIED IT ON THE PIN (freeze suite 2/2 + stdlib-exec
      85/85 on stdlib-v0.61.3), so the twin removal may proceed with the
      checklists in docs/STDLIB_DEDUP_INVENTORY.md.
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
      clauses / 18.9% pub-with-clause. Wave 17 (2026-09-21): 26 clauses
      (payload-reading Result forms unblocked by R49-3: io/fs Err messages
      non-empty, fs_read_range bounded/zero-length Vec payloads,
      fs_write_range written <= data.len(), io/console + io/pipe Err
      payloads, always-Ok reads, simulated tty false) -> io 62.0% -> 78.7%,
      global 19.2% pub-with-clause; pre-validated by
      tools/probes/p_wave17_shapes.xi. Wave 18 (2026-09-21): 38 clauses on
      sort + search (in-place Int sorts gain `is_sorted(v)` postconditions,
      incl. cross-module `intro.is_sorted` in heap/quick/merge/radix; search
      index bounds for binary/interpolation/linear/fibonacci, position
      bounds for lower/upper_bound, tuple bounds for search_range, merge
      length sum, KMP/Boyer match-window and table length bounds) -> sort 0%
      -> 31.9%, search 0% -> 62.2%, global 19.2% -> 19.8% pub-with-clause;
      pre-validated by tools/probes/p_wave18_shapes.xi. Wave 19 (2026-09-21):
      37 clauses on bits (bit_get/parity disjunctions, popcount/clz/ctz/
      bit_width/leading-ones/trailing-ones 0..64 bounds, nibble 0..15,
      unpack byte-range tuples, bitfield_mask implication, scan -1..63,
      rotate-carry flags, bitarray counts) -> bits 0% -> 36.6%, global 19.8%
      -> 20.3% pub-with-clause; pre-validated by
      tools/probes/p_wave19_shapes.xi. Wave 20 (2026-09-21): 44 clauses on
      geom vectors (component-wise add/sub/mul/div and scalar variants
      mirrored exactly for Vec2/Vec3/Vec4, dot/cross identities,
      length/distance/squared non-negativity, lerp mirrors, neg/abs,
      min/max component bounds) -> geom 0% -> 10.6%, global 20.3% -> 21.0%
      pub-with-clause; pre-validated by tools/probes/p_wave20_shapes.xi.
       Wave 21 (2026-09-22): 19 clauses on error (identity results, constant
       length arithmetic for error_context, conditional error_join
       identities, backtrace/chain/context count and length relations,
       chain push/pop invariants, Option-to-Result mapping) -> error 0% ->
       37.5%, global 21.0% -> 21.2% pub-with-clause; pre-validated by
       tools/probes/p_wave21_shapes.xi. Wave 22 (2026-09-23): 45 clauses on
       stats/stats.xi + stats/probability.xi (empty/short-input identities,
       non-negative float bounds incl. the NaN-tolerant disjunction,
       two-Vec length-mismatch guards, exact histogram bin counts,
       probability-domain guarded intervals, CDF boundary equalities) ->
       stats 0% -> 25%, global 21.2% -> 21.8% pub-with-clause; pre-validated
       by tools/probes/p_wave22_shapes.xi. Wave 23 (2026-09-23): 30 clauses
       on convert/escape.xi + convert/validate.xi (escape lower bounds,
       unescape upper bounds, exact quote-wrapper arithmetic, Bool
       short-circuit guards, disjunctive length guards, empty-input Str
       guards) -> convert 2% -> 11.5%, global 21.8% -> 22.3%
       pub-with-clause; pre-validated by tools/probes/p_wave23_shapes.xi.
       Wave 24 (2026-09-23): 42 clauses on math/modular.xi +
       math/arithmetic.xi + math/logic.xi + math/set_theory.xi (uniform
       modular ranges with no-modulus guards, square-root ranges with the
       small-prime guard, tuple-field non-negativity, two-parameter Vec
       length arithmetic, cardinality bounds, exact Boolean mirrors,
       guarded power-of-two results, sign-matching remainders, power-set
       guard) -> math 4.1% -> 8.3%, global 22.3% -> 22.9% pub-with-clause;
       pre-validated by tools/probes/p_wave24_shapes.xi. Wave 25
       (2026-09-24): 59 clauses on collections/collections.xi (&mut length
       preservation through @pre, post-state map reset, empty/short-input
       identities incl. a Str guard, Option presence mirrors, aggregate and
       Set/Map bounds, exact sliding-window counts, parity/arithmetic on
       result lengths, Boolean mirrors) -> collections 3.5% -> 77.2%,
       global 22.9% -> 23.6% pub-with-clause; pre-validated by
       tools/probes/p_wave25_shapes.xi. Wave 26 (2026-09-25): 57 clauses on
       text/transliterate.xi + text/similarity.xi + text/diff.xi (byte-ratio
       transliteration bounds, custom-table pass-through, DP integer bounds,
       exact n-gram counts, exact 4-byte soundex normalization, similarity
       ranges, Option mirrors, diff op bounds, unified-diff header floor,
       precondition-guarded clause indexing) -> text 2.4% -> 95.1%, global
       23.6% -> 24.3% pub-with-clause; pre-validated by
       tools/probes/p_wave26_shapes.xi. Wave 27 (2026-09-25): 46 clauses on
       test/test.xi + test/assert.xi (exact Boolean mirrors on the
       TestResult field, panic-mirror ensures on the assert module, count
       bounds on result vectors, Str length floors on formatted output,
       benchmark passthrough, empty/length mirrors) -> test 3.1% -> 70.8%,
       global 24.3% -> 25.0% pub-with-clause; pre-validated by
       tools/probes/p_wave27_shapes.xi. Wave 28 (2026-09-25): 51 clauses on
       test/harness.xi (13: registry counts, @pre push counts, counter-sum
       identities, report field mirrors, JSON scaffolding floor), the error
       tails (21: field-length identities on constructors/copiers, Option
       payload length, input guards), and the io tails (17: Result payload
       length, boolean/path mirrors, tuple element values and pair
       implication, filesystem-backed Ok clauses) -> test 3.1% -> 90.8%,
       error 37.5% -> 90.0%, io 78.7% -> 94.4%, global 25.0% -> 25.8%
       pub-with-clause; pre-validated by tools/probes/p_wave28_shapes.xi.
       Wave 29 (2026-09-25): 41 clauses on regex/regex.xi + regex/syntax.xi
       (empty-pattern exact match counts, length upper bounds on
       replace/split/escape/unescape, capture mirror pairs, Result/
       quantifier/character-class guards, Option payload bounds for
       find/first-match) -> regex 2% -> 59.2%, global 25.8% -> 26.2%
       pub-with-clause; pre-validated by tools/probes/p_wave29_shapes.xi +
       tools/probes/p_wave29_syntax_shapes.xi. Compiler findings filed
       (Result-Ok Str payload reads in catalog clauses; nested-Vec payload
       clause poisoning user codegen -- tools/known_failures/README.md,
       evidence probe p_result_payload_ir_repro.xi; affected clauses
       replaced by payload-free guards).
       Wave 30 (2026-09-25): 57 clauses on math/signal.xi (40: exact
       transform/filter/window output lengths, wavelet coefficient bounds,
       empty-input and filter-order guards, spectrogram/mel row guards,
       MFCC cap) and math/exponential.xi (17: NaN-tolerant non-negativity
       for exp/exp2/exp10/exp_pure, expm1 >= -1, log-domain sign floors
       for x > 1 / x > 0, positive-base pow sign, pow_int(_, 0) == 1.0)
       -> math 8.3% -> 14.1% (signal 40/40 and exponential 18/18 pub
       covered), global 26.2% -> 27.1% pub-with-clause; pre-validated by
       tools/probes/p_wave30_shapes.xi. Also fixed filter_bandstop reading
       the empty band-pass buffer for order <= 0 (probe exit 27 before,
       0 after).
       Wave 31 (2026-09-25): 80 clauses on math/factorial.xi (22 fns:
       invalid-input guards (negative n/k -> 0; n <= 0 for Narayana/Lah),
       exact 0/1 identities (factorial(0/1), binomial(n,0/n), Stirling/
       Eulerian/Narayana/Lah mirrors, subfactorial(0)=1 and (1)=0),
       documented-overflow thresholds (factorial >= 21, double_factorial
       >= 34, subfactorial >= 21, catalan >= 34), non-negativity of every
       numeric family, enumeration length shapes (integer_partitions,
       bell_triangle)) -> math 14.1% -> 16.3%, global 27.1% -> 27.4%
       pub-with-clause; pre-validated by tools/probes/p_wave31_shapes.xi.
       Wave 32 (2026-09-26): 103 clauses on math/combinatorics.xi (28 fns:
       invalid-input guards, delegation mirrors for permutations/
       combinations/derangements/bell/catalan/eulerian/Stirling/Lah/
       Narayana/partitions, Fibonacci 93 / Lucas 91 / compositions_all 64
       overflow thresholds, non-negativity, enumeration length shapes incl.
       powerset 2^n rows and the n > 20 guard) -> math 16.3% -> 19.1%,
       global 27.4% -> 27.8% pub-with-clause; pre-validated by
       tools/probes/p_wave32_shapes.xi (the probe caught an involutions
       n <= 1 overlap before landing). Wave 31 follow-up `71f4d9f`: the
       zero-row Stirling/Eulerian clauses now require k == 0 (probe RED at
       ensures 272:12 -> GREEN), full gates re-run green.
       Wave 33 (2026-09-26): 57 clauses on math/number_theory.xi (21 safe
       fns; the 11 p*p-wrap/deferred families stay clause-free): primality
       guards, factor/prev_prime/nth_prime/primorial shapes, pseudoprime
       and strong-test mirrors, Lucas-Lehmer thresholds, integer-property
       guards, symbol ranges ([-1, 1]) with the n == 0/1 mirrors, divisor
       guards and non-negativity -> math 19.1% -> 21.2%, global 27.8% ->
       28.2% pub-with-clause; pre-validated by
       tools/probes/p_wave33_shapes.xi (the probe caught prev_prime(3)
       returning 0, fixed to 2). Open finding recorded: kronecker_symbol
       returns 0 for even a with odd n (e.g. 2/7) -- algorithm bug, left
       for the fix-first batch.
       Wave 34 (2026-09-26): queue B part 1 -- `observability` and
       `controllability` implemented in math/control_theory.xi on the
       nested-Vec repair pattern (private `_ct_copy`/`_ct_mul`/
       `_ct_transpose`/`_ct_rank`, pivot threshold 1e-12, two-stage deep
       copy); clauses `!result || a.len() > 0`; guards for empty/non-square
       A, width mismatches, empty C/B, zero-column B and multiply failure.
       Verification cases in tools/probes/p_control_theory_shapes.xi
       (rank-2/rank-1, multi-input, six guard cases) -> math 21.2% ->
       21.4%, global 28.2% pub-with-clause. Next: queue B part 2
       (`lp_simplex` + `linear_programming`).
       Wave 35 (2026-09-27): queue B part 2a -- `lp_simplex` implemented in
       math/optimization.xi (minimize c'x, Ax <= b, x >= 0): dense tableau
       (m+1) x (n+m+1), slack basis, Bland entering + leaving, Gauss-Jordan
       pivots, 10000-iteration cap; returns empty for empty c or A, b-length
       mismatch, ragged A, b[i] < 0, unbounded, cap exhaustion; else the
       argmin of length n. Verification in tools/probes/p_lp_simplex.xi
       (known LP -> [2,2], simple bound, five guards, unbounded) -> math
       21.4% -> 21.5%. Next: `linear_programming` + the smoke cases.
       Wave 36 (2026-09-27): queue B part 2b -- `linear_programming`
       implemented in math/optimization.xi on top of lp_simplex: repaired
       c/A/b/bounds, empty bounds delegates with x >= 0, per-variable
       [lo, hi] entries with +/-inf for absent sides, lower-only shift
       (x = lo + z), upper-only reflect (x = hi - z), both-bounded scale
       into [0,1] with an added z <= 1 row, free split z+ - z-; shifted b2
       (no Phase I) plus malformed or infeasible bounds return empty;
       clause result.len() == 0 || result.len() == c.len().
       Pre-validated by tools/probes/p_linear_programming.xi (identity,
       three bound modes, free, fixed, four guards) and the queue-section-B
       cases wired into smoke_math_optimization.xi (observability/
       controllability true/false, lp_simplex [2,2] + guards + unbounded,
       bound modes -> [1,3]) -> math 21.5% -> 21.6%. Next: coverage waves.
       Wave 37 (2026-09-27): coverage wave 1 -- 25 range clauses across the
       trig family (math/trig.xi, math/trigonometry.xi, math/hyperbolic.xi):
       sin/cos/sin_deg/cos_deg/sinpi/cospi in [-1, 1], asin/atan in
       [-1.5708, 1.5708], acos in [0, 3.1416], atan2 in [-3.1416, 3.1416],
       cosh/sech/acosh >= 0 (IEEE-safe, no sharp 1.0 claim), tanh in [-1, 1],
       sec/csc/coth outside (-1, 1), asinh sign implication -- all
       NaN-tolerant for the documented domain errors. Fix-first (recon):
       `_norm`/`sinpi`/`cospi`/`tanpi` returned from O(|x|) reduction loops
       that never terminate on +/-inf; non-finite inputs now return NaN and
       the docs note the linear reduction. Probe tools/probes/p_trig_family.xi
       (191st) exercises every clause at runtime plus the guards; math
       21.6% -> 24.1%, global 28.2% -> 28.6%. Next: remaining math files.
       Wave 38 (2026-09-27): coverage wave 2 -- 26 clauses on
       math/rounding.xi (13) and math/angular.xi (13). rounding: floor <= x,
       ceil >= x, sign/direction claims for round/trunc/integer_part and the
       *_pure variants (floor_pure/ceil_pure use (x == x) => bounds so no
       NaN-cast assumption is needed; trunc_pure bounds by x and 0;
       fract/fract_pure/frac_part in [0,1) or (-1,0] with NaN tolerance),
       round_nearest sign by input side; modf and round_to stay clause-free
       (tuple-result shape / 10^places inf-zero factor). angular: sign
       preservation for the ten unit conversions (safe under underflow to
       signed zero and infinities), normalize_angle in (-pi, pi] and
       normalize_angle_deg in (-180, 180] with +/-inf pass-through and NaN
       tolerance (the tau/2..tau subtraction is exact, so the range is
       strict), angle_diff mirrors normalize_angle; angle_lerp stays
       clause-free (arbitrary t). Pre-validated by
       tools/probes/p_wave38_shapes.xi (192nd) with ties-to-even, aliases,
       normalization boundaries, infinities and NaN; math 24.1% -> 26.7%,
       global 28.6% -> 29.0%. Next: remaining math files.
       Wave 39 (2026-09-27): coverage wave 3 -- 23 clauses on
       math/algebra.xi (12: gcd/lcm non-negativity, Legendre/Jacobi in
       {-1,0,1}, binomial/factorial/primorial/nth_prime non-negativity,
       integer_sqrt >= -1, next_power_of_two >= 0, the
       is_power_of_two/is_perfect_square true-implies-domain mirrors) and
       math/transcendental.xi (11: sqrt/cbrt sign + domain NaN, exp/exp2
       >= 0, expm1 >= -1, ln/log2/log10 NaN-or-positive-domain, log1p
       domain with the -inf endpoint, erf in [-1,1], erfc in [0,2]).
       Fix-first from the probe: the wave-38 angular conversion clauses
       used strict > / < and failed for -0.0 -- now >= / <= with signed
       zero preserved; exponential.log1p(-1.0) tripped the delegate
       math.ln requires (x > 0.0) instead of returning the documented
       -inf -- now guarded; the erf(0) doc was corrected (approximation
       error ~1e-7, not exact). Open stdlib finding recorded: sqrt(NaN)
       and ln(NaN) reach the math.sqrt/math.ln requires and abort instead
       of returning NaN. Probe tools/probes/p_wave39_shapes.xi (193rd);
       math 26.7% -> 29.0%,        global 29.0% -> 29.4%. Next: remaining math
       files.
       Wave 40 (2026-09-27): coverage wave 4 -- 19 clauses on
       xiom/math/complex.xi (module xiom.complex): NaN-tolerant exact-field
       equalities for complex_new/from_polar/add/sub/mul/scale/conj (the
       `(result.re == expr) || (result.re != result.re)` form, since a
       bare equality would violate on NaN inputs), abs >= 0, arg in
       [-3.1416, 3.1416], the epsilon predicates false for eps <= 0, exp/
       pow/sin/cos/tan non-NaN-or-non-negative magnitude, log imaginary
       part in [-3.1416, 3.1416], sqrt real-branch implication, to_string
       non-empty; complex_div stays clause-free (inf/inf and NaN component
       mixed cases make any exact claim unsafe). Struct-field and tuple/
       field reads in clauses follow the bits.xi/core.xi precedent.
       Pre-validated by tools/probes/p_wave40_shapes.xi (194th);        smoke_
       complex green; math 29.0% -> 31.0%, global 29.4% -> 29.7%. Next:
       remaining math files.
       Wave 41 (2026-09-27): coverage wave 5 -- 27 clauses on
       math/vectors.xi: NaN-tolerant exact-field equalities for the
       Vec2/Vec3/Vec4 constructors, add/sub/scale, lerp and cross (the
       `(result.x == expr) || (result.x != result.x)` form), dot products,
       len/dist >= 0, unit-vector claims (zero vector OR squared magnitude
       within 1e-12 of 1, NaN-tolerant for the sqrt-free paths), dynamic
       vec_dot NaN-on-length-mismatch, vec_norm >= 0, vec_scale length
       preservation. NOTE: hypot/hypot3/vec4_len/vec_norm abort on NaN
       inputs because they reach math.sqrt's requires (same open finding
       as wave 39); the clauses stay true because those calls never
       return. Probe tools/probes/p_wave41_shapes.xi (195th); smoke_
       math_vectors green;        math 31.0% -> 33.7%, global 29.7% -> 30.1%.
       Next: matrices.xi fixed-size + shape-only claims, then remaining
       math files.
       Wave 42 (2026-09-28): coverage wave 6 -- first family-batched wave,
       53 clauses across matrices + number_systems + queueing. matrices.xi
       (22): NaN-tolerant field equalities for mat2/mat3/mat4
       construction/mul(2/3)/transpose, mat3_det, the `result is None =>
       det^2 < 1e-24` singularity guards for mat2_inv/mat3_inv, and
       shape-only claims for the dynamic entries (mat_identity row count,
       mat_mul `empty or a.len()`, mat_det/mat_inv empty guards,
       mat_translate/rotate/scale preserve m.len(), projection helpers
       `empty or 4`); mat4_mul/det/inv stay clause-free (clause size).
       number_systems.xi (17): radix zero/out-of-range guards, roman/greek
       range guards, Chinese/Japanese/Babylonian non-emptiness, Egyptian
       length by sign, continued-fraction length <= terms, fraction
       denominator positivity, surd implications (with the a*b > 0
       overflow-agnostic antecedent), octonion/sedenion length shapes.
       queueing.xi (14, full file): invalid -> NaN, unstable -> +inf,
       stable -> non-negative/range claims for m_m_1/m_m_c/m_g_1/g_g_1/
       erlang_b/erlang_c, Little's law exact, utilization exact,
       queue_length/waiting_time guards, loss/blocking Erlang-B ranges,
       heavy_traffic and diffusion_approx case split.
       Fix-first (probe-caught): `surd_simplify` dropped odd prime
       exponents (sqrt(8) -> 2*sqrt(1)); it now multiplies the leftover
       prime back (sqrt(8) -> 2*sqrt(2), sqrt(2) -> 1*sqrt(2),
       sqrt(18) -> 3*sqrt(2), sqrt(12) -> 2*sqrt(3) locked in the probe).
       Compiler finding filed: a shape-mismatched `&Vec[Float64]` argument
       where `&Vec[Vec[Float64]]` is expected compiles silently and AVs
       (`tools/known_failures/p_vec_shape_arg_mismatch_av.xi`), found while
       writing the probe. Probe tools/probes/p_wave42_shapes.xi (196th);
       math family 53/53;        math 33.7% -> 38.8%, global 30.1% -> 30.9%.
       Next: num (489 pub, 442 uncovered) then geom.
       Wave 43 (2026-09-28): coverage wave 7 -- num sub-batch (float +
       convert + base + precision_integer + precision_rational), 37 clauses:
       float bit fallbacks (bits == 0), mantissa >= 0, exponent in
       [-1074, 1023], subnormal/nan/infinite exact identities and
       classification set, next_up/next_down direction with the +inf/-inf
       endpoints, ulp >= 0; base58/62 zero and empty-input guards, ascii85
       empty guards, roman range Some/None, radix zero/invalid-base guards
       and digits length, Result is_ok guards; bigint wrapper non-emptiness
       and compare range; BigRat empty-parse, compare range, sign-preserving
       to_float via the `num.negative` field chain, to_str non-emptiness,
       neg/abs sign fields. Fix-first (probe-caught): `_ilogb_abs` returned
       floor(log2)+1 at exact powers of two, so `nextafter` skipped a
       representable value stepping UP from any power of two (and
       float_ulp doubled there); fixed, and the downward step now crosses
       into the lower binade with half spacing (min-normal/subnormal
       boundary kept); exact-step KATs added to smoke_num_float
       (1+2^-52 up, 1-2^-53 down, ulp(1) = 2^-52). Also `primitives.abs`
       clause made NaN-tolerant so float_ulp(NaN) propagates NaN as
       documented. Probe tools/probes/p_wave43_shapes.xi (197th); num 18/18
       and math 53/53 smoke families; num 9.6% -> 17.2%, global 30.9% ->
       31.4%. Next: bigint (55 pub) then bigfloat (75) then num.xi leaves.
       Wave 44 (2026-09-29): coverage wave 8 -- xiom.bigint core (33
       clauses): canonical-representation claims for from_int/from_u64,
       zero/one/ten/two (exact shapes), add/sub/mul/neg/abs/mod, pow/gcd/
       lcm, shift_left (decimal) / shift_right (arithmetic bit shift), div,
       sqrt, factorial/binomial/fibonacci, bit_and/or/xor, plus compare and
       sign ranges, is_negative, to_str/to_hex non-emptiness, to_base
       invalid-base emptiness, popcount/bit_len >= 0. The shared claim is
       `((result.negative == true) => (result.digits.len() > 0)) &&
       ((result.digits.len() == 0) => (result.negative == false))` -- the
       _trim canonical form (zero has no digits and negative false; a
       negative value always has digits). Payload-returning entries
       (from_str/from_base/to_int/to_u64/to_*) stay clause-free until the
       payload ABI allows reads. Probe tools/probes/p_wave44_shapes.xi
       (198th): 53 KATs through bigint_to_str (limb boundary 999999999+1,
       sign/zero canonical calls, -10/3, -10 mod 3, -7 >> 1, 2^10, gcd/lcm,
       factorial 20, fibonacci 10, bit ops, base alphabets: to_base
       uppercase vs to_hex lowercase). num 17.2% -> 22.7%, global 31.4% ->
       31.8%. Next: bigint remainder (base parsing/to_int families) then
       bigfloat.
       Wave 45 (2026-09-29): coverage wave 9 -- xiom.bigint remainder (21
       clauses): empty/invalid parse guards on from_str/from_base/from_hex,
       zero-fits-every-conversion on to_int/to_u64/to_u128/to_i128,
       parity/one/prime predicates (`is_even == false => digits non-empty`,
       `is_odd == true => digits non-empty`, `is_one == true => negative
       false`, `is_prime == true => negative false`), next_prime canonical
       and non-negative, canonical tuple claims on div_mod (both
       components) and sqrt_rem (both), canonical plus non-negative on
       pow_mod, non-negative gcd component on ext_gcd, and exact
       compare-delegation claims on eq/lt/le/gt/ge
       (`result == (bigint_compare(a, b) < 0)` etc.). Probe
       tools/probes/p_wave45_shapes.xi (199th): parsing Err paths, zero
       conversions, 10^30 out of i64, parity/prime/next_prime KATs,
       (17,5) -> (3,2), sqrt_rem(10) -> (3,1), pow_mod 2^10 mod 1000 = 24.
       num 22.7% -> 26.4%, global 31.8% -> 32.1%. Next: bigfloat.
       Wave 46 (2026-09-29): coverage wave 10 -- xiom.num.bigfloat core
       (30 clauses). The canonical-form claim family for normalized
       results: `((result.significand.negative == false) && ((digits.len()
       == 0) => (result.sign == false))) && ((result.sign == true) =>
       (digits.len() > 0))` -- 1/x, sqrt, pow, add/mul/div, fract,
       with_rounding, the constants (one/two/ten/half/pi/e), from_int/
       from_bigint/with_precision; exact zero shape (sign false, empty
       significand, exponent 0); conditional non-negative-significand on
       neg (copy_bf abs's) and unconditional on abs with sign false;
       is_negative/is_one implications, is_zero false-implies-digits,
       sign/compare ranges, precision exact, to_str non-empty, from_str
       empty -> Err, to_float64 zero -> Some. Probe
       tools/probes/p_wave46_shapes.xi (200th): constant and arithmetic
       KATs through bigfloat_to_str (1+2=3, 1/2=0.5, sqrt(4)=2, 2^10,
       fract(1.25)=0.25, with_rounding(pi,5)=3.1416). Probe fix:
       `xiom.num.bigfloat` is the module path (a smoke exists; the
       module-smoke scan's `xiom.bigfloat` manifest entry is an alias, to
       revisit in the smoke-growth wave). num 26.4% -> 31.6%, global 32.1%
       -> 32.5%. Next: bigfloat transcendentals, then geom.
       Wave 47 (2026-09-29): coverage wave 11 -- bigfloat transcendentals
       (24 clauses): the same canonical-form family on the _finish-
       normalized results of exp/ln/log10/log2/exp2, sin/cos/tan, atan/
       atan2, pow_bf, cbrt, hypot, sinh/cosh/tanh, asin/acos, asinh/acosh/
       atanh, pi_with_precision/e_with_precision; to_str_sci non-empty.
       Probe tools/probes/p_wave47_shapes.xi (201st): 27 KATs via
       bigfloat_to_float64 (e, ln(e), log10(100), log2(8), exp2(10), sin(pi/2),
       atan(1)=pi/4, cbrt(27), hypot(3,4), asin(1)=pi/2, acos(1)=0,
       acosh(1)=0, atanh(0)=0, precision-20 pi/e). num 31.6% -> 35.8%,
       global 32.5% -> 32.7%. Next: bigfloat remainder (from_ratio/pow10/
       *_int/to_bigint) then geom.
       Wave 48 (2026-09-29): coverage wave 12 -- bigfloat remainder
       (9 clauses): canonical-form on from_float (NaN/inf guarded) and
       from_ratio; to_bigint bigint-canonical pair; pow10 significand
       non-negative (copy path, so only that invariant is certain);
       to_str_prec non-empty; zero-fits-is_ok on floor_int/ceil_int/
       round_int/trunc_int. Probe tools/probes/p_wave48_shapes.xi (202nd):
       from_float round-trips (0.5/-3.25/0), to_str_prec non-empty,
       to_bigint truncation (1.5 -> 1, -1.5 -> -1), from_ratio (1/4, -3/4),
       pow10 (2e3, 1e-2), and the four *_int conversions on +-1.9 and zero.
       num 35.8% -> 37.4%, global 32.7% -> 32.8%. Next: geom.
       Wave 49 (2026-09-29): coverage wave 13 -- geom primitives, first
       family batch (52 clauses). xiom.geom.vec (29): constructor fields;
       NaN-tolerant component mirrors on add/sub/scale/dot/cross/lerp;
       non-negative bands on len/dist; zero-vector canonical forms on the
       three norm functions; reflect len-0-or-input; project
       zero-or-NaN-or-length-matched; angle [0,4) or NaN. xiom.geom.quat
       (11): identity fields; Hamilton-product mirrors; conjugate;
       identity-or-nonzero forms on inv/normalize/axis-angle; norm band;
       euler bands; slerp endpoint-or-interior; rotate len 0/3.
       xiom.geom.mat (12): identity/mul length claims; det
       NaN-or-zero-or-nonempty; inv presence mirror; transpose
       len-0-or-nonempty; 4x4 transforms len-0-or-4-and-m-4;
       look_at/perspective/ortho len 4; transform_point len 0/3.
       Fix-first: NEW compiler finding p_clause_float_vec_index.xi --
       clause-position indexing of Float64 vector elements reads garbage
       (Vec[Float64] element and Vec[Vec[Float64]] row reads violate; Int
       and length-only controls pass), so the matrix row-length claims are
       len-only until the compiler-lane fix. Probe
       tools/probes/p_wave49_shapes.xi (203rd): 99 return-code checks
       across the three modules. geom 10.6% -> 23.2%, global 32.8% ->
       33.6%. Next: geom batch 2 (matrix/vector/quaternion long-name
       domain), then curves/collision/geometry/polyhedra/linear.
       Wave 50 (2026-09-30): coverage wave 14 -- geom batch 2, the typed
       matrix + quaternion domain (51 clauses). xiom.geom.matrix (32):
       Mat2/3/4 constructor field mirrors; identity/zero/one/add/sub/mul/
       diag_mul/hadamard row-count claims; scalar_mul exact-len;
       transpose/adjugate/kronecker/diagonal shape claims; det/minor/
       cofactor/trace NaN-or-zero-or-nonempty bands; inverse/cholesky
       presence mirrors; rank bounds (0 <= result <= a.len()); nullity
       non-negative; eigenvalues/eigenvectors len 0-or-2; lu/qr tuple
       len claims; svd triple 0-or-2; solve_linear len 0-or-rows;
       least_squares nonempty-or-nonempty-input; condition_number
       non-negative-or-NaN. xiom.geom.quaternion (19): constructor/
       identity fields; Hamilton-product mirrors; conjugate; inv/
       normalize/axis-angle identity-or-nonzero forms; euler component
       bands +-2; from_rotation_matrix identity-or-3x3; to_matrix len 3;
       to_euler range bands; rotate len 0/3; slerp endpoint-or-interior;
       nlerp identity-or-not-both-zero; angle [0,7) or NaN; axis len 3;
       look_at/between component bands +-2.
       Fix-first: quat_between opposite-direction perpendicular-axis
       choice was inverted (|ax| < 0.9 picked an axis parallel to a for
       x-aligned inputs), so 180-degree pairs returned the identity; the
       probe locks the fix (w == 0, unit vector part). NEW compiler
       finding p_geom_matrix_result_infer.xi: un-annotated call-site
       inference of xiom.geom.matrix Vec[Vec[Float64]] results loses a
       nesting level (row reads return 0/raw bits; explicit
       `var x: Vec[Vec[Float64]] = ...` and annotated tuple extraction
       fix it; the same shape via xiom.geom.mat is fine; single-level
       Vec[Float64] unaffected; reproduced on v0.61.3 AND v0.62.1). The
       probe annotates every nested matrix-module local. Also caught:
       quat_axis's original second clause read `.x` on a Vec[Float64]
       result (pin tolerated it; the v0.62.1 checker rejected it) --
       replaced with the len-only claim.
       Probe tools/probes/p_wave50_shapes.xi (204th): 96 return-code
       checks incl. LU/QR/Cholesky KATs, solve_linear/least_squares
       solutions, eigenvalue KATs, the 90-degree z rotation, slerp/nlerp
       unit norms, look-at and between; green on v0.61.3 and v0.62.1.
       geom 23.2% -> 35.5%, global 33.6% -> 34.4%. Next: geom batch 3
       (vector.xi 24 + curves/collision 19), then geometry_2d/3d/extended,
       polyhedra,        linear, then the geom.xi aggregate (142 uncovered).
       Wave 51 (2026-10-01): coverage wave 15 -- geom batch 3
       (vector/curves/collision, 43 clauses). xiom.geom.vector (24):
       v2/3/4 constructor fields; cross2 mirror; NaN-on-length-mismatch
       on dot/distance/distance_sq; non-negative bands on norm/norm_sq;
       len-0-or-input on cross/normalize/unit/project/reject/lerp/slerp/
       reflect/hadamard; outer and clamp exact-len; angle [0,4);
       refract presence mirrors (mismatch/empty => None, Some => matched
       lengths); component_min/max empty => NaN. xiom.geom.curves (7):
       len-0-or-input on the four point curves; bezier_derivative
       len-0-or->=2-points; b_spline len-0-or->=4-points; curve_length
       non-negative-or-NaN. xiom.geom.collision (12): constructor len
       mirrors; degenerate-length => false/None implications on every
       query (aabb/sphere/ray/triangle/segment).
       Findings (both filed with repros): p_geom_vector_result_bits.xi --
       caller-side element reads of vector.lerp/clamp/hadamard and
       curves.b_spline results are bit-reinterpreted (stored 1.5 reads as
       0x3FF8000000000000 as a double); callee-side reads and the
       cross/normalize/unit/project/reject/slerp/reflect/outer/
       bezier_quad/cubic/derivative controls are correct; reproduced on
       v0.61.3 AND v0.62.1; the probe mediates the four through
       vector.distance (smoke_geom_vec already did) -- and
       p_curve_thunk_zero.xi -- a fn-typed parameter returning
       Vec[Float64] arrives empty inside catalog bodies (curve_length
       returns 0 instead of 1.0); the probe keeps only the n<1 branch.
       Probe tools/probes/p_wave51_shapes.xi (206th): 80 return-code
       checks incl. Bezier/Catmull-Rom/B-spline/Hermite KATs and the
       full collision query set; green on v0.61.3 and v0.62.1. geom
       35.5% -> 45.9%, global 34.4% -> 35.1%. Next: geom batch 4
       (geometry_2d 22 + geometry_3d 21 = 43), then geometry_extended 14
       + polyhedra 10 + linear 15, then the geom.xi aggregate (142
       uncovered).
       Wave 52 (2026-10-02): coverage wave 16 -- geom batch 4
       (geometry_2d 22 + geometry_3d 21 = 43 clauses). geometry_2d:
       non-negative distance bands; center-inside/vertex-inside/rect
       parity implications; empty/1-vertex polygon => false; zero-det
       line/segment => None; degenerate line => circle None; concentric
       => circle-circle None; degenerate triangle => area 0; <3-vertex
       polygon => area 0; empty polygon => zero centroid; empty input
       => empty hull; <3-vertex => not convex; empty subject => None on
       intersection/difference; both-empty => None union; non-negative
       circumference. geometry_3d: non-negative distance bands; zero
       normal => plane distance 0; zero direction => ray-sphere None;
       equal normals => plane-plane None; zero radii => sphere parity;
       AABB outside-edge => false; degenerate segment => endpoint
       return; degenerate triangle => zero normal; <3 indices => zero
       volume/centroid; <4 points => empty hull indices.
       Fix-first/findings: the Box-taking trio
       (aabb_intersection/aabb_contains/ray_box_intersection) is
       clause-only -- geometry_3d.Box is unnameable from consumers
       (core's Box[T] shadows the leaf, no constructor; filed
       p_geom_box_unnameable.xi), so those clauses are compile-checked
       only. polygon_difference's inverted clipping intersects b's
       outside half-planes instead of taking a\b (disjoint a,b returned
       None); filed p_polygon_difference_halfplanes.xi, the doc now
       states the limitation, and the probe keeps only the empty-a/
       empty-b edges; a real polygon-clipping implementation is a queue
       follow-up.
       Probe tools/probes/p_wave52_shapes.xi (207th): 78 return-code
       checks; green on v0.61.3 and v0.62.1. geom 45.9% -> 56.3%, global
       35.1% -> 35.7%. Next: geom batch 5 (geometry_extended 14 +
       polyhedra 10 + linear 15 = 39), then the geom.xi aggregate (142
       uncovered).
       Wave 53 (2026-10-02): coverage wave 17 -- geom batch 5
       (geometry_extended 14 + polyhedra 10 + linear 15 = 39 clauses).
       Shapes/degenerate implications: voronoi cell count; delaunay >= 3
       points; bezier/b_spline/nurbs zero-on-inconsistent-input; mesh
       subdivision/mesh_processing length guards; projective length;
       hyperbolic/elliptic/non_euclidean mismatch => NaN plus non-negative
       bands; incidence empty => true; computational geometry 0-or-1;
       polyhedra vertex/face counts (8/12/12/20/4/6/20) and empty hulls 0;
       linear len/shape claims plus empty-matrix predicate forms.
       Fix-first: hyperbolic_geometry called the non-pub extern
       `math.log` -- a silent zero stub on v0.61.3 (the function returned
       0) and a hard C001 on v0.62.1; switched to the public `math.ln`,
       locked by the probe's log(3) KAT. New finding:
       p_polyhedra_nested_hull.xi (convex_hull_2d/3d collapse on nonempty
       inputs on both pins; empty inputs are correct).
       Probe tools/probes/p_wave53_shapes.xi (208th): 68 checks, green on
       v0.61.3 and v0.62.1. geom 56.3% -> 65.7%, global 35.7% -> 36.3%.
       Next: the geom.xi aggregate (142 uncovered -> 2-3 waves), then the
       low dirs.
       Wave 54 (2026-10-02): coverage wave 18 -- geom aggregate batch 1
       (46 of the xiom.geom aggregate's 142 uncovered pub fns: vec2 16,
       vec3 15, vec4 3, quaternion core 7, scalar helpers 5).
       Shapes: constructor component mirrors; zero-or-nonzero canonical
       forms for normalize/project/orthogonal; reflect degenerate-normal
       implication; refract None-or-nonnegative-k presence mirror; angle
       bands; clamped-parameter guard for vec3_lerp; rotate mirrors;
       predicate soundness implications; clamp-length mirror-or-overflow;
       Hamilton product and quaternion mirrors; Euler -2..2 bands; scalar
       angle mirrors (all NaN-tolerant).
       Fix-first: quat_from_euler's literal was written w,x,y,z
       (declaration order x,y,z,w) -- the compiler assigns literal fields
       positionally, so every Euler-derived rotation was scrambled;
       reordered to declaration order. New finding:
       p_struct_literal_field_order.xi (both pins accept out-of-order
       literal fields and store them positionally; a checker error or
       name-keyed semantics is expected).
       Probe tools/probes/p_wave54_shapes.xi (209th): 99 checks, green on
       v0.61.3 and v0.62.1. smoke_geom.xi grew to 49 KATs (module-smoke
       3,332 -> 3,377 fns). geom 65.7% -> 76.8%, global 36.3% -> 37.0%.
       Next: geom batch 7 (quaternion tail 15 + Mat2 8 + Mat3 12 + Mat4
       core 10 = 45), then Mat4 tail + Aabb + Sphere + Ray + Plane (51).
       Wave 55 (2026-10-02): coverage wave 19 -- geom aggregate batch 2
       (45 pub: quaternion tail 15, Mat2 8, Mat3 12, Mat4 core 10).
       Shapes: quaternion component mirrors through the in-module
       normalizer, Hamilton/dot/length mirrors, identity-or-nonzero
       inverse/nlerp forms, slerp endpoint-or-interior, matrix literal
       shapes and field mirrors, determinant mirrors, inverse presence
       mirrors (abs-det threshold), rotation trig mirrors, perspective
       reciprocal mirrors, look_at bottom-row literals, transform_vec3
       divide-with-w-zero disjunction, and NaN-tolerant transposes.
       No fix-first; the probe baseline was green. Probe
       tools/probes/p_wave55_shapes.xi (210th): 69 checks, green on
       v0.61.3 and v0.62.1. smoke_geom.xi grew to 90 KATs (module-smoke
       3,377 -> 3,421 fns). geom 76.8% -> 87.7% (363/414), global 37.0%
       -> 37.7%. Next: geom batch 8 (Mat4 tail 17 + Aabb 14 + Sphere 8 +
       Ray 8 + Plane 4 = 51, the last aggregate batch), then the low
       dirs.
       Wave 56 (2026-10-02): coverage wave 20 -- geom aggregate batch 3/final
       (51 pub: Mat4 tail 17 + Aabb 14 + Sphere 8 + Ray 8 + Plane 4).
       Shapes: 16-field NaN-tolerant transposes, full determinant mirrors,
       inverse presence (abs-det threshold), vec4/point/direction mirrors
       with w-divide disjunction, delegate and rotation mirrors,
       affine-shape literals, orthographic reciprocals, approx/identity
       implications; Aabb/Sphere constructor mirrors, clamped closest
       point, min/max expand/union mirrors, overlap/containment
       implications, surface/volume mirrors, Option presence mirrors;
       ray slab/quadratic/plane presence mirrors, origin/dir/at mirrors,
       distance bands; plane mirrors and signed/absolute distance bands.
       No fix-first; the pre-clause probe baseline was green (one NaN
       check moved off `aabb_volume`, whose strict wave-49 `vec3_sub`
       delegate aborts on NaN -- the pre-existing NaN-abort class).
       geom.xi is now 186/186 pub-with-clause; the whole geom directory
       is 414/414 = 100%. Probe tools/probes/p_wave56_shapes.xi (211th):
       77 checks, green on v0.61.3 and the v0.62.2 dev binary.
       smoke_geom.xi grew to 128 KATs (module-smoke 3,421 -> 3,471 fns).
       global 37.7% -> 38.5%. Next: the low dirs (net 5.4%, serialize
       5.4%, hash 8.9%, reflect 9.1%, iter 9.8%, convert 11.5%, format
       13%, time 13%, misc 13.9%, os 15.3%, rand 16%, crypto 17%, log
       19.1%, compress 21.1%), then C, D, E, F.
       Wave 57 (2026-10-02/03): coverage wave 21 -- net batch 1, address
       family (46 pub: address 5, ip 15, ip4 10, ip6 8, url 8).
       Shapes: Option/Result presence mirrors, length bands for valid
       parses, exact-string broadcast claim, Bool-result implications,
       empty/nonempty round-trip claims. Fix-firsts: ipv4_to_string now
       uses the first four octets per its doc (was "" for len>4);
       url_join's "//" branch now normalizes per its doc. New finding:
       p_wave57_probe_ir.xi (context-dependent alloca-dominance invalid
       IR when Result-style matches mix with Str-returning calls;
       non-monotonic under bisection; the probe now compares Str results
       directly). Probe tools/probes/p_wave57_shapes.xi (212th): 141
       checks, green on v0.61.3 and v0.62.2 dev. smoke_net_address.xi
       grew (module-smoke 3,471 -> 3,475 fns). net 5.4% -> 20.9%,
       global 38.5% -> 39.2%. Next: net batches 2+ (http/header/cookie/
       mime ~55; transport ~53; protocols), then the remaining low dirs.
       Wave 58 (2026-10-03): coverage wave 22 -- net batch 2, HTTP family
       (55 pub: http 21, header 6, cookie 10, mime 18).
       Shapes: exact status/request-line mirrors, parse length bands,
       status/header/body presence mirrors, encode/decode bands and
       empty-input claims, network entry points through their empty-URL
       early error, mutation-helper post-length placeholders, cookie
       matcher/expiry canonical forms, MIME table spot claims, charset
       bands, etag length/matching claims, accept/link presence bands.
       Fix-first: `parse_q` now caps q at 1000 (RFC 7231); `1.999`
       previously scored 1999 (probe witness). Probe
       tools/probes/p_wave58_shapes.xi (213th): 119 checks, green on
       v0.61.3 and v0.62.2 dev. net 20.9% -> 39.4%, global 39.2% ->
       40.1%. Next: net batches 3+ (transport socket/tcp/udp/unix/tls/
       tls_helper ~53; protocols proto/smtp/ftp/ntp/ping/sse/websocket/
       ws), then the remaining low dirs (serialize 5.4% first).
       Wave 60 (2026-10-03): coverage wave 23 -- net batch 3, transport
       family (53 pub: socket 18, tcp 4, udp 4, unix 10, tls 5,
       tls_helper 12). Shapes: validation-guard implications on every
       socket entry point, documented always-Err stubs, port bands,
       endpoint format/parse claims, TLS name-table implications, pure
       DER/PEM presence bands, fingerprint length claims. Probes avoid
       real connections (constructors create+close one local fd; all
       other network fns use early-error paths only). Probe
       tools/probes/p_wave60_shapes.xi (215th): 80 checks, green on
       v0.61.3 and the m178 dev binary. net 39.4% -> 57.2%, global 40.9%.
       Next: net protocols (proto/smtp/ftp/ntp/ping/sse/websocket/ws),
       then the remaining low dirs (hash 8.9%, reflect 9.1%, iter 9.8%,
       ...).
       Wave 61 (2026-10-03): coverage wave 24 -- net batch 4, protocol
       family (48 pub: proto 10, smtp 13, ftp 9, ntp 9, ping 7). Shapes:
       exact command/format mirrors and length bands, JSON-RPC/SSE
       skeleton bands, header parse/get presence, auth header mirrors,
       reply-parser presence bands, NTP structural/encode/decode claims
       and exact offset/roundtrip mirrors, ICMP checksum empty claim, the
       nine documented Err stubs. Probe tools/probes/p_wave61_shapes.xi
       (216th): 72 checks, green on v0.61.3 and the m178 dev binary.
       net 57.2% -> 73.4%, global 41.6%. Next: net batch 5 (sse 8 +
       websocket 14 + ws 5 + dns 8 + multipart 6 + server 6 + jwt 9 +
       net.xi 15), then the remaining low dirs (hash 8.9%, reflect 9.1%,
       iter 9.8%, ...).
       Wave 62 (2026-10-03): coverage wave 25 -- net batch 5 (41 pub: sse
       8, websocket 14, ws 5, dns 8, multipart 6). Shapes: SSE
       parse/accessor and stub claims, WebSocket handshake exact-length
       split, accept-key length, frame encode/decode bands, URL parse
       bands, open-state implications, TLS-free ws twin claims, DNS
       presence/length bands, multipart constructor mirrors and builder
       bands. Fix-first: ws_handshake_verify's accept-header line scan
       searched from the response start (first CRLF), so canonical
       `101 ...\r\n...Accept: key\r\n\r\n` responses verified false; now
       scans the CRLF after the accept value. New finding:
       p_multipart_parse_name.xi (multipart_parse result field reads are
       corrupt on BOTH the v0.61.3 pin and official v0.62.3; presence-only
       in the probe). Probe tools/probes/p_wave62_shapes.xi (220th):
       green on v0.62.3 and v0.61.3. net 73.4% -> 87.2%, global 41.6% ->
       42.2%. Next: net batch 6 (net.xi 15, server 6, jwt 9), then the
       remaining low dirs.
       Wave 63 (2026-10-04): coverage wave 26 -- net batch 6 (net.xi 15,
       server 6, jwt 9) merged with hash batch 1 (22 pub: adler 3,
       checksum 4, crc 8, fnv 4, jenkins 1, murmur 1, superfast 1) = 53
       clauses / 52 pub. Shapes: handle-close Ok claims, empty-URL Err
       bands, udp_bind port-guard implications, parse_url/url_parse_*
       presence bands, alias preconditions (http_get_str/http_status/
       tcp_connect_str/dns_lookup), server status-line/response length
       bands plus exact 200/404/500 mirrors, request-line Option bounds,
       jwt base64url length bands and decode/verify/expired/claims
       min-length bands, adler empty-input claim (the 65521-byte b-wrap
       result is locked by the probe; a non-empty lower bound was
       re-derived and rejected pre-commit), checksum 16-bit
       bands, CRC empty-seed claims, FNV offset-basis empties,
       jenkins/murmur Vec length claims, superfast mask bound. New
       finding: p_uint32_high_bit_compare.xi (inline module-qualified
       UInt32 call compares misread high-bit values on official v0.62.3
       and the m178 dev build; binding to a local is the documented
       workaround extended from UInt16/UInt8). Probe
       tools/probes/p_wave63_shapes.xi (221st, 123 checks): no network
       I/O; green on v0.62.3 and v0.61.3. net 87.2% -> 97.3%, hash
       8.9% -> 33.3%, global 42.2% -> 43.0%. Next: the remaining low
       dirs (reflect 9.1%, iter 9.8%, convert 11.5%, format 13%, ...).
       Wave 64 (2026-10-04): coverage wave 27 -- reflect (40 pub: fields
       10, typeinfo 11, reflect 18) + iter build adapters (map 5,
       range 6, zip 5) = 55 clauses / 55 pub. Shapes: exact placeholder
       constants (fields/typeinfo), RTTI presence bands plus the
       single-TypeInfo return claim, reflect_type's nested-struct shape
       claim, empty/out-of-range length bands, exact length arithmetic
       (iter_map/enumerate/chain/cartesian/interleave and range/
       range_step/range_inclusive/range_count), zip-longest max via
       dual implications. New finding: p_reflect_all_types_crash.xi --
       `reflect.all_types()` heap-corrupts (0xC0000374) on official
       v0.62.3 and the m187 dev build; the same build loop replicates
       green in a user module and type_info_by_name's single-TypeInfo
       return works, so it is catalog-return-path specific (all_types is
       the only reflect pub fn left clause-free). Probe
       tools/probes/p_wave64_shapes.xi (222nd, 47 checks): reflect +
       iter combined, no network I/O; the fields/typeinfo clauses ride
       smoke_reflect at runtime instead (the combined probe including
       those calls hit a context-dependent invalid-IR clang failure;
       binding `Vec.new()` temporaries passed as `&Vec` call arguments
       avoids it). reflect 9.1% -> 97.7%, iter 9.8% -> 18.6%, global
       43.0% -> 43.9%.
       Wave 65 (2026-10-04): BLOCKED -- no clauses landed. The drafted
       xiom.iter clause sets (Range core 7 + chain 14 + fold 8 + the
       remaining Range methods) were all reverted after two
       context-dependent pin failures: with the 7-clause Range core set
       (incl. Range.collect), 12 iter-consuming smokes fail with closure
       use-before-def ("use of undefined value" in a __closure_N);
       removing the collect clause restores them but flips
       smoke_iter_range back to the old C001 contains-classifier error
       (the wave-62 context-dependence returns). Filed
       tools/known_failures/p_iter_range_collect_forwardref.xi (calling
       Range.collect fails clang "instruction forward referenced with
       type 'ptr'" on v0.62.3, v0.61.3 and the m189/v0.62.4 candidate;
       any clause on Range.count/find breaks smoke_iter). Kept as a
       behavioral Range-core API lock: tools/probes/p_wave65_shapes.xi
       (223rd, 13 checks; no clauses landed, no closure-delegating
       methods called; green on v0.62.3, v0.61.3 and m189). Coverage
       stays floors100 (global 43.9%, iter 18.6%); the wave-65 floor
       dump was withdrawn. Resume the whole iter surface once the
       compiler closure lowering and C001 classifier are fixed.
       Wave 65x (2026-10-04): coverage wave 29 on the convert shims while
       iter waits -- 43 clauses / 43 pub: convert.bytes (to_bytes len 8,
       from_bytes empty/oversize band, hex empty band -- the odd-length
       claim was re-derived and rejected: the canonical decoder REQUIRES
       even length and aborts, so the wrapper now carries that
       precondition -- concat/reverse exact lengths), endian (8-byte
       bands, empty/oversize zero bands, swap zero, host order), checked
       (checked-add/sub/mul identity bands, div-by-zero None, INT_MIN
       neg/abs None, pow exponent bands, shift range bands), base64 shims
       (empty input bands), exact (div-by-zero Err, zero-divisor None,
       ratio zero None), swap (zero), tostring (zero/decimal, bool
       exact strings, char non-empty, radix validity bands), wrapping
       (identity zero/one bands). convert 11.5% -> 25.6%, global 43.9%
       -> 44.5%; floors101. Probe tools/probes/p_wave65x_shapes.xi
       (224th, 60 checks): green on v0.62.3, v0.61.3 and m189;
       bytes.from_bytes stays compile-checked only (calling it is the
       documented invalid-IR collision). Targeted smokes: convert 37/37,
       cross 9/9.
       Release 0.62.3/0.62.4 (2026-10-04): pin moved to the SHA256-verified
       official v0.62.4 archive; release-gate carve-out
       (run_smokes.ps1 -ExcludeFile + tools/known_failures/
       gate-exclusions.txt) wired into release.yml while ci/heavy keep the
       full corpus; p_regress_uint32_compare/p_regress_iter_collect
       promoted (probe corpus 226); p_iter_range_contains_c001 filed (C001
       run-to-run nondeterministic on both pins). stdlib 0.62.3 tagged at
       12a3a1b after a 948/948 exclusion battery; stdlib 0.62.4 release
       prep in the v0.62.4 commit.
       Wave 66 (2026-10-04): coverage wave 30 -- time core, 39 clauses /
       39 pub: duration 15 (exact constructor fields and unit bands,
       normalized-nanos bands for add/sub/mul, zero-divisor zero claim,
       exact as_secs/as_millis/as_micros/as_nanos mirrors, ordered
       compare, zero predicate), instant 6 (duration_since/add/sub field
       mirrors, compare, to/from millis), date 12 (constructor, epoch
       bands for from/to_timestamp + weekday, month bands for
       days_in_month/leap/day_of_year, n==0 identities for add/sub days,
       equal-date diff/compare), iso8601 6 (padded length bands,
       parse min-length bands, exact epoch timestamp). time 13.0% ->
       41.3%, global 44.5% -> 45.1%; floors102. Probe
       tools/probes/p_wave66_shapes.xi (227th, 61 checks): green on
       v0.62.4 and v0.61.3; targeted smoke_time 19/19. Clarify: this wave
       was executed under the user's "continue on 2" while the compiler
       lane gates v0.63.0;        runtime/ and the iter surface untouched.
       Wave 67 (2026-10-05): coverage wave 31 -- format core, 33 clauses /
       33 pub: dump 4 (empty/non-empty bands + empty-line length), number
       6 (exact KAT bands for separators/fixed/percent/bytes/duration/
       ordinal), relative 11 (sub-30s phrases + zero identities), table 12
       (constructor shape, @pre row increment, widths/rows/cols mirrors,
       empty-table renders, mutation invariants). format 13.0% -> 27.3%,
       global 45.1% -> 45.7%; floors103. Probe p_wave67_shapes.xi (228th,
       59 checks) green on v0.63.0 and v0.61.3; smoke_format 8/8. Next:
       wave 68 on misc 13.9% / os 15.3% / rand 16%.
       Wave 68 (2026-10-05): coverage wave 32 -- misc core, 36 clauses /
       29 pub: glob 9, soundex 6, natural 6, levenshtein 8 (empty-input
       identities, presence and length bands, Result/Option bands).
       misc 13.9% -> 50.6%, global 45.7% -> 46.1%; floors104. Duplicate-
       leaf fix alongside: the stale `xiom.misc.misc.soundex` "0000" copy
       now delegates to the canonical shim. Probe p_wave68_shapes.xi
       (229th, 54 checks) green on v0.63.0 and v0.61.3; smoke_misc 3/3.
       Next: wave 69 on os 15.3% / rand 16% / crypto 17%.
        Wave 69 (2026-10-05): coverage wave 33 -- os path/filetype + rand,
        76 clauses / 76 pub: path 18 (empty-input Option identities,
        presence bands on parent/file_name/file_stem, to_str/as_path
        mirrors, join output-length bands, canonicalize is_ok,
        prefix/suffix length implications, pop @pre length), filetype 22
        (empty-input identities for eol/bom/binary/text/encoding/magic/
        mime, output length bands, minimum-length implications on every
        detector), rand 20 + pcg 5 + mt19937 6 + chacha 5 (exact state/
        keystream shape mirrors, seed preservation, count/length bands,
        bounded-next ranges, zero/negative early-return identities).
        os 15.3% -> 26.2%, rand 16% -> 88%, global 46.1% -> 47.3%;
        floors105. Probe p_wave69_shapes.xi (230th, 167 checks) green on
        v0.63.0; targeted smokes rand 42/42, path 18/18, filetype 1/1.
        Next: crypto 17% / log 19.1% / compress 21.1%.
        Wave 70 (2026-10-05): coverage wave 34 -- crypto core, 41 clauses /
        41 pub: mac 12 (        HMAC block/key shape mirrors, @pre update length,
        digest-length by hash id, tag-length verify implication, CBC-MAC
        iv-guarded 16, CMAC 16, constant-time eq/select), kdf 9 (PBKDF2/
        HKDF exact lengths, 8160/16320 caps, interval
        clamp, argon2id/bcrypt lengths), keyx 9 (X25519 + secp256k1 ECDH
        32-byte guards, ecdh_p256 empty stub, DH prime-length mirrors,
        agreement derive cap and validate bands), rng_crypto 5 (count/
        range/prime-bits/string bands), sign 5 (documented stub mirrors),
        poly1305_mac 1. Fix-first: `hkdf_extract`/`hkdf_expand`'s Int
        parameter `hash` shadowed the module alias, so hash == 2 AV'd;
        calls fully qualified (`xiom.crypto.hash.…`) and verified.
        crypto 17% -> 39.6%, global 47.3% -> 47.9%; floors106. Probe
        p_wave70_shapes.xi (231st, 79 checks) green on v0.63.0;
        targeted smokes crypto 36/36, poly 2/2, hash 39/39.
        Next: log 19.1% / compress 21.1% / encoding 23.7%.
        Wave 71 (2026-10-05): coverage wave 35 -- log core, 60 clauses /
        49 new pub: levels 12 (constants, name mapping, from-name
        presence, threshold/enabled module-var mirrors), color 8
        (by-level boundaries, reset/colorize/strip/has-color bands),
        sinks 8 (constructor field mirrors, registry parallel-vector
        invariants, close monotone @pre), json 4 (entry/format length
        bands, empty fields "{}", thread id 1), log 28 (level-write
        monotonicity across levels/_with/aliases, level and mode
        module-var mirrors, entry-count mirror, last-entry presence,
        text/json serialization bands). log 19.1% -> 91.2%, global
        47.9% -> 48.7%; floors107. Probe p_wave71_shapes.xi (232nd,
        88 checks) green on v0.63.0; targeted smokes log 9/9, json 17/17.
        Next: compress 21.1% / encoding 23.7% / debug 24.4%.
        Wave 72 (2026-10-05): coverage wave 36 -- compress formats,
        39 clauses / 39 new pub (gzip 6, deflate 5, brotli 4, zlib 6,
        snappy 8, lz4 10; the two io wrappers and two FFI streams skipped
        for lack of a parameter-derivable claim). Exact container-size
        identities, checksum empty identities, empty-input Err bands,
        max_out < 0 => Err on gzip/snappy/lz4 capped (deflate capped
        omitted: EOB-only Ok empty), exact bound mirrors; no element
        reads, no lz4 cap-overshoot claims. compress 21.1% -> 64.4%,
        global 48.7% -> 49.3%; floors108. Probe p_wave72_shapes.xi
        (233rd, 71 checks) green on v0.63.0; targeted smokes compress
        26/26, crc 1/1. Next: encoding 23.7% (fix-first: utf8_valid
        empty abort, base64url dangling char, percent '+' divergence) /
        debug 24.4% / simd 24.4%.
        Pin v0.63.1 (2026-10-05): re-pinned COMPILER_VERSION/package.xi
        to v0.63.1 (tag c0fa3a2d, release commit 1b972478; registry lane
        SHA256-verified nine entries; STDLIB_VERSION stayed cd61062).
        C001 carve-outs retired (4bf8cf1e is an ancestor of the release;
        20/20 + 20/20 stress on both iter smokes) -- release corpus now
        FULL 952/952 with zero exclusions; C001 finding marked RESOLVED.
        Instant.now()/elapsed() switched to the runtime monotonic clock
        (monotonic_ms()/1000 second resolution) with an
        `ensures: result.t >= 0` lock; SystemTime stays wall clock; the
        v0.63.0 limitation note retired. lz4 rename kept as an optional
        no-op (compiler binds bare duplicate-leaf calls correctly now).
        Probe p_pin0631_shapes.xi (234th, 14 checks) green on v0.63.1;
        floors109 wired (time 61 clauses, global 49.3%). Iter clause
        retry NOT unblocked by the pin: clause-side closure lowering
        re-verified failing on v0.63.1 (Range.count clause -> smoke_iter
        clang `use of undefined value`), queued with the compiler closure
        work; tuple-component clauses do now evaluate.
        Wave 74 (2026-10-05): coverage wave 37 -- encoding + three
        fix-first, 55 clauses / 37 new pub (encoding.xi 24, base64 8,
        base32 6, hex 9, percent 8). Fix-first: utf8_decode requires
        removed (utf8_valid(empty) no longer aborts), both
        base64url_decode copies reject the dangling final char, percent
        '+' divergence pinned and documented. encoding 23.7% -> 72.4%,
        global 49.3% -> 49.8%, meter 75.0%; floors110. Probe
        p_wave74_shapes.xi (235th, 95 checks) green on v0.63.1; targeted
        smokes encoding 16/16, base 12/12, utf8 6/6, percent 2/2. io
        payload-clause audit closed (io.xi four were the only bogus
        sites). Next: encoding remainder (ascii85/idna/punycode) / debug
        24.4% / tuple-component clause expansion.
        Wave 75 (2026-10-05): coverage wave 38 -- encoding remainder +
        debug, 50 clauses / 50 new pub (ascii85 6, punycode 7, idna 8,
        disasm 7, heap_report 11, trace 11; hexdump placeholder
        replaced). encoding 72.4% -> 100%, debug 24.4% -> 95.1%, global
        49.8% -> 50.6%, meter 75.1%; floors111. Probe p_wave75_shapes.xi
        (236th, 84 checks) green on v0.63.1; targeted smokes ascii85 2/2,
        punycode 3/3, debug 2/2.
        Wave 76 (2026-10-05): coverage wave 39 -- simd, 49 clauses / 49
        new pub (gather 5, mask 14, vec4 17, vec8 13). Exact lane mirrors
        (field-read clauses verified on the pin), min/max lane
        disjunctions, mask bit mirrors, gather length identities; omits
        div/dot/sum/loads/vec8 array constructors by design. simd 24.4%
        -> 78.9%, global 50.6% -> 51.3%, meter 75.1%; floors112. Probe
        p_wave76_shapes.xi (240th, 66 checks) green on v0.63.1; targeted
        smokes simd 1/1. Landmine recorded: explicit type args on
        module-qualified generic calls miscompile on v0.63.1. Next:
        stats 25% / thread 25% / convert 25.6%.
        Pin v0.64.0 (2026-10-05): re-pinned COMPILER_VERSION/package.xi to
        v0.64.0 (tag c68d91de, pin 6e60e958). Consumed m193-m196: m195
        resolves reflect.all_types (clause added, reflect 100%, finding
        RESOLVED, findings 10 -> 9); m196 restores TcpStream.read (new
        tests/smoke/smoke_net_tcp_stream.xi loopback, corpus 953); m194
        makes num.float.float_bits/bits_to_float exact (roundtrip clauses,
        negative-zero and NaN-payload verified); m193 retires the
        guard-alloc probe shim. Probe p_pin0640_shapes.xi (241st, 9
        checks) green. global 51.3% -> 51.4%; floors113; meter 75.1%.
        multipart stays compiler-owned (v0.64.1); Box stays section C.
        Next: stats 25% / thread 25% / convert 25.6%.
        Wave 77 (2026-10-05): coverage wave 40 -- stats, 93 clauses / 48
        new pub (dist 15, histogram 9 -- histogram_add is void with a
        discarded by-value mutation, moments 13, test 11). Fix-first:
        moments.quantile q == 0.0 / q == 1.0 returned raw bits (rvalue
        indexing of a returned Vec[Float64]; new compiler finding
        p_rvalue_float_vec_index.xi, bound copies used instead);
        stddev/geometric_mean NaN guards before math.sqrt/math.ln
        requires. stats 25% -> 59.3%, global 51.4% -> 52.1%, meter 75.2%;
        floors114. Probe p_wave77_shapes.xi (242nd, 167 checks) green on
        v0.64.0 pre/post; targeted smoke smoke_stats 1/1. Findings
        9 -> 10 (9 compiler, 1 stdlib). Next: thread 25% / convert 25.6%.
        Pulse hardening (2026-10-05): TcpStream.write_all (64 KiB chunked,
        partial-send aware, empty-Ok lock), server_parse_request +
        ServerRequest (headers, Content-Length, body span) and
        crypto.hmac_sha256_hex (RFC 4231 KAT); probe p_pulse_shapes.xi
        (243rd, 36 checks) + smoke_net_tcp_stream write_all exchange;
        floors114 ratchet held. Runtime-backed Pulse items (socket
        options, real flush_stdout) stay queued for the runtime bundle /
        XIOM_RUNTIME_DIR.
        Wave 78 (2026-10-07): coverage wave 41 -- thread, 27 clauses / 24
        new pub (thread 8, spawn 5, pool 8, park 1, local 5; void and
        unclaimable surfaces skipped). thread 25% -> 67.9%, global 52.1%
        -> 52.5%, meter 75.2%; floors115. Fix-first (doc/contract):
        thread.sleep_ms documented negative sleeps as immediate while
        `requires: ms >= 0` aborts; doc corrected and sleep gained the
        delegation precondition. Probe p_wave78_shapes.xi (244th, 39
        checks) green on v0.64.0 pre/post; targeted smokes smoke_thread
        1/1, smoke_collect_threadpool 1/1. Next: convert 25.6% (multiple
        waves), then the remaining low dirs.
        Wave 79 (2026-10-07): coverage wave 42 -- convert numeric shims,
        57 clauses / 40 new pub (parse 5, int 8, toint 2, itos 3, atoi 3,
        fromstr 3, ftos 3, tofloat 3, unchecked 5, saturating 5). convert
        25.6% -> 38.7%, global 52.5% -> 53.1%, meter 75.3%; floors116.
        Probe p_wave79_shapes.xi (245th, 95 checks) green on v0.64.0
        pre/post; targeted smokes convert int/float/bool str 1/1. Skips:
        to_int (undefined NaN/range), to_int_from_char, overflow.xi
        (compiler tuple+Bool). Next: convert remainder -- base-codec shims
        (43 pub), then utf16/utf32/utf/lossy families.
        Wave 80 (2026-10-07): coverage wave 43 -- convert base-codec
        shims, 40 clauses / 25 new pub (base16 4, base32 4, base64url 4,
        percent 4, base58 3, base62 3, uuencode 1, quotedprintable 2).
        convert 38.7% -> 46.9%, global 53.1% -> 53.5%, meter 75.3%;
        floors117. Protocol finding: `(result.is_ok == true) =>
        result.len()` does not guard payload reads; the canonical
        `result is Ok => result.len()` form is required. Probe
        p_wave80_shapes.xi (246th, 45 checks) green on v0.64.0 pre/post;
        targeted codec smokes 1/1. Split: local codec bodies + utf family
        arrive in wave 81.
        Wave 81 (2026-10-07): coverage wave 44 -- convert unicode family,
        38 clauses / 26 new pub (utf8 4, utf16 4, utf32 4, utf 14).
        convert 46.9% -> 55.4%, global 53.5% -> 53.9%, meter 75.4%;
        floors118. Probe p_wave81_shapes.xi (247th, 36 checks) green on
        v0.64.0 pre/post; targeted utf smokes + utf8 KATs 1/1. Next:
        convert local codec bodies (ascii85/uuencode/quotedprintable/
        base58/base62 legs) + uri/url/urn/ip families.
        Wave 82 (2026-10-07): coverage wave 45 -- convert codec guards,
        11 clauses / 11 new pub (ascii85 4, quotedprintable 4,
        base58_decode, base62_decode, uudecode_line). convert 55.4% ->
        59%, global 53.9% -> 54.1%, meter 75.4%; floors119. Push incident
        (GitHub 500s) logged and resolved in docs/failed_attempts.md.
        Probe p_wave82_shapes.xi (248th, 15 checks) green on v0.64.0
        pre/post; targeted codec smokes 1/1. Next: uuencode 5 +
        base58check 2 + uri/url/urn/ip families.
        Wave 83 (2026-10-07): coverage wave 46 -- convert codec tails,
        7 clauses / 7 new pub (uuencode, uudecode, uuencode_line,
        xxencode, xxdecode, base58check_encode, base58check_decode).
        Fix-first (probe-caught): `_trim` stripped trailing spaces but UU
        trailing spaces are data (value 0 = ' '), breaking uudecode for
        every line ending in zero bytes (any 1-byte payload); right-side
        trim now CR/LF only, locked by the new
        tests/smoke/smoke_convert_uuencode.xi (corpus 953 -> 954).
        convert 59% -> 61.3%, global 54.1% -> 54.2%, meter 75.4%;
        floors120. Probe p_wave83_shapes.xi (249th, 15 checks) green on
        v0.64.0 pre/post. Next: uri/url/urn/ip + lossy/network/timestamp.
        Wave 84 (2026-10-07): coverage wave 47 -- convert uri/url/urn
        families, 8 clauses / 8 new pub (uri_parse, uri_normalize,
        url_parse, url_encode, url_decode, urn_parse, urn_is_valid,
        urn_build). convert 61.3% -> 63.9%, global 54.2% -> 54.3%, meter
        75.4%; floors121. Compiler relay: p_ensures_isok_guard.xi filed
        (findings 11). Probe p_wave84_shapes.xi (250th, 16 checks) green
        on v0.64.0 pre/post; targeted url smokes 1/1. Next: ip + lossy/
        network/timestamp.
        Wave 85 (2026-10-07): coverage wave 48 -- convert ip/lossy/
        network/timestamp families, 31 clauses / 20 new pub (ip 6:
        validator length guards + empty-input None identities;
        lossy 4: empty/sign-only zero pins + NaN/2^63 clamp mirrors;
        network 6: exact byte-swap mirrors incl. the 64-bit closed form;
        timestamp 4: epoch/86400/-1 pins on to_date/to_datetime and the
        epoch-day band on from_datetime; timestamp_now stays clause-free,
        system clock). convert 63.9% -> 70.5%, global 54.3% -> 54.6%,
        meter 75.5%; floors122. Probe p_wave85_shapes.xi (251st, 63
        checks) green on v0.64.0 pre/post; targeted smokes
        smoke_convert_ip, smoke_convert_time, smoke_convert_checked 1/1
        each. Next: convert remaining locals (date/datetime/duration/
        time, wstring/from/into/roundtrip) then the low dirs.
        Wave 86 (2026-10-07): coverage wave 49 -- convert locals + shims,
        58 clauses / 39 new pub (date 5: field mirror, ISO length band +
        <10 None/pin, weekday [0,6] band + epoch pin, day-of-year band +
        2026-08-12 pin; datetime 3: field mirrors, ISO >= 19 band +
        epoch string pin, layout guard; duration 6: zero/negative
        normalization pins + accessor mirrors (secs; secs*1000 +
        nanos/1e6); time 3: time_of_day [0,86399] band + timestamp pins;
        wstring 2: null-pointer identities; from 3 / into 2: zero pins +
        bool mirrors; roundtrip 4: empty/invalid/zero pins; uuid 4 /
        mac 4: length + layout guards and 36/17/16 length claims;
        iri 3: empty-Err / nonempty-Ok presences). Clause-free by design:
        date_now/datetime_now/timestamp_now (system clock), to_wstring
        (unsafe pointer), from_char (char-cast), into_str (generic
        display). convert 70.5% -> 83.3%, global 54.6% -> 55.2%, meter
        75.5%; floors123. Probe p_wave86_shapes.xi (252nd, 72 checks)
        green on v0.64.0 pre/post; targeted smokes smoke_convert_time,
        smoke_convert_traits, smoke_convert_checked, smoke_convert_ip,
        smoke_convert_url 1/1 each. Next: convert tails (float/json/
        punycode/cstring, strftime/strptime, tryfrom/tostring/bytes/
        validate) then the low dirs.
        Wave 87 (2026-10-07): coverage wave 50 -- convert tails, 52
        clauses / 33 new pub. Root convert 6 (int_to_float/float_to_int/
        int_to_string zero pins, fixed/sci string pins + nan branch,
        bool mirrors; int_to_char's placeholder `ensures: true` replaced
        with the range-OOR None / 65 some pins), cstring 2 (null-pointer
        identities), float 6 (nan/zero pins, empty-Err parse guard),
        json 5 (empty identities, quote pin, escape >= input band),
        punycode/idna 8 (empty-Ok identities + idna_is_valid => false),
        strftime 2 (empty/percent/ISO pins), strptime 2 (empty/short
        guards + layout pin incl. result.date fields), tryfrom 3
        (NaN/2^63 Err guards, empty-Err, zero-Ok). convert 83.3% ->
        94.1%, global 55.2% -> 55.7%, meter 75.6%; floors124. Probe
        p_wave87_shapes.xi (253rd, 57 checks) green on v0.64.0 pre/post;
        targeted smokes convert float/json/punycode/strftime/try +
        all_directions/identity/narrow 1/1 each. Next: the low dirs
        (async 4.5%, serialize 5.4%, iter 18.6% -- clause-side blocked --
        bench 18.8%, os 26.2%, core 26.7%, format 27.3%) or the convert
        leftovers (overflow stays compiler-blocked; toint/char-cast and
        pointer/generic surfaces stay clause-free).
        Wave 88 (2026-10-08): coverage wave 51 -- serialize batch 1,
        37 clauses / 27 new pub. endian 16 (the eight write_* @pre
        append claims out.len() == out.len()@pre + 2/4/8, including
        write_f64_le's unsafe block; the eight read_* OOB-identity guards
        pos < 0 || pos + N > data.len() => result == 0 / 0.0), varint 9
        (encode/size len-int-value bands 1..10 + zero/300 pins;
        decode empty -> Err; the zigzag exact body mirrors;
        uvarint encode band + zero pin; decode empty -> Err;
        encode_slice empty -> empty + result >= values band;
        decode_slice empty -> Ok), csv 4 (empty -> Ok / "" on
        parse/parse_with/write_row/write; write_row >= fields-1 and
        write >= 2 * rows length bands). serialize 5.4% -> 34.4%,
        global 55.7% -> 56.1%, meter 75.6%; floors125. Probe
        p_wave88_shapes.xi (254th, 57 checks) green on v0.64.0 pre/post
        (@pre claims verified incl. the double-append case); targeted
        smokes smoke_serialize(+toml), smoke_serialize_csv,
        smoke_convert_endian 1/1 each. Next: serialize remainder
        (serialize 31, json 15, toml 11, yaml_lite 7) then the other low
        dirs (async 4.5% -- runtime-backed, iter clause-side blocked,
        bench 18.8%, os 26.2%, core 26.7%, format 27.3%).
        Wave 89 (2026-10-08): coverage wave 52 -- serialize + json
        modules, 50 clauses / 36 new pub. serialize.xi 26 (format_error
        >= 15 band + the zero-error exact pin; is_valid_json/bytes empty
        -> false; json_string/object/array empty pins + >= len+2 /
        >= 4n / >= 2n bands; json_number nan/zero pins; json_bool/null
        mirrors; json_parse empty -> Err + null -> Ok, replacing the
        `requires: data.len() >= 0` and `ensures: true` placeholders;
        parse_json empty -> Err; JsonValue.index negative -> None;
        little/big_endian constants; json_escape/unescape/minify/pretty
        empty identities + bands; json_get_path empty-json None;
        json_type_of empty/object/bool pins; varint_encode band + pins,
        varint_decode(_at) pos-OOB -> Err, varint_encoded_len pos-OOB ->
        0; bytes_to_hex_str == 2n + empty; hex_str_to_bytes empty -> Ok),
        serialize.json 12 (json_parse empty/null pins; json_get_path
        empty-path -> Some; json_set/array_push/object_new/array_new/
        number/string/bool/null type pins via json_type(result); json_type
        >= 4 band; json_escape band). Found and filed two compiler
        findings (repros p_alias_module_type_path + p_foreign_method_call;
        cross-ref C-PULSE-12) and recorded the PULSE 2026-10-08 delta.
        serialize 34.4% -> 73.1%, global 56.1% -> 56.7%, meter 75.7%;
        floors126. Probe p_wave89_shapes.xi (255th, 67 checks) green on
        v0.64.0 pre/post (one probe-input fix from the encoding.hex_decode
        even-length requires; one behavior fix on json_type_of's
        first-char rule); targeted smokes serialize/json/stress/fuzz/KAT
        13 files 1/1. Next: serialize batch 3 (toml 11, yaml_lite 7) and
        then the other low dirs (async 4.5% -- runtime-backed, iter
        clause-side blocked, bench 18.8%, os 26.2%, core 26.7%).
        Wave 90 (2026-10-08): coverage wave 53 -- serialize batch 3,
        23 clauses / 16 new pub. toml 11 (toml_parse empty -> Ok and
        "a = 1" -> Ok / "[a" -> Err pins; the getter family's
        empty-table -> None identities incl. the six typed getters;
        toml_has empty -> false; toml_keys len mirror; toml_write
        empty -> "" + >= keys band), yaml_lite 5 (yaml_parse /
        yaml_parse_document empty -> Err + "a: 1" -> Ok pins;
        yaml_emit_scalar empty -> `""` + >= len band; yaml_emit_sequence
        empty -> "" + >= items band; yaml_emit_mapping empty-side ->
        ""). Clause-free by design: yaml_stringify / yaml_get (enum
        match, no clause-expressible claim) and the same for the
        toml/yaml writer variant dispatch internals. serialize 73.1% ->
        90.3%, global 56.7% -> 56.9%, meter 75.7%; floors127. Probe
        p_wave90_shapes.xi (258th, 35 checks) green on v0.64.0 pre/post;
        targeted smokes smoke_serialize (+csv/toml/toml_write) 1/1.
        Next: the remaining low dirs (async 4.5% -- runtime-backed, iter
        clause-side blocked, bench 18.8%, os 26.2%, core 26.7%, format
        27.3%) with serialize leftovers (fill/emit internals) reviewed
        for future passes; also queued: ORBITDB append_line_sync pure
        half, bindings W-2 out-param slots, W-5 Vec[UInt8].with_len.
        Wave 91 (2026-10-08): coverage wave 54 -- bench + format (numbering/
        units), 85 clauses / 38 new pub. bench 13 new (run_bench field
        pins: iterations 1, name mirror, total == mean, stddev 0;
        run_bench_n name mirror + zero-iteration all-zero branch; compare
        >= name band; ops-per-sec/faster-percent zero branches; min/max/
        total/median empty -> 0; human-ns four unit pins; black-box int
        identity; run_avg delegation pins; report empty len 124;
        report_simple empty -> "") plus a DEFECT FIX: bench_time_fn called
        run_bench("", f), violating run_bench's `requires: name.len() > 0`
        at runtime -- now passes "bench_time_fn" (found by the wave probe;
        bench_time_fn stays clause-free). format.numbering 11 (word/
        milliard/ordinal/CJK/Indian/money exact pins), format.units 16
        (bytes/bits/percent/ratio/scientific/engineering/SI/binary/
        temperature/currency/durations/hertz exact pins). bench 18.8% ->
        87.5% (black_box generic + bench_time_fn remain), format 27.3% ->
        39.0%, global 56.9% -> 57.5%, meter 75.8%; floors128. Probe
        p_wave91_shapes.xi (259th, 89 checks) green on v0.64.0 pre/post
        (probe-first fixes: moved-value pushes, the long-scale milliard
        expectation, 0.00 sci-zero); targeted smokes smoke_bench +
        smoke_format_numbering + smoke_format_units 1/1. Next: the
        remaining low dirs (async 4.5% -- runtime-backed, iter 18.6% --
        clause-side blocked, os 26.2%, core 26.7%, sync 29.1%, sort
        31.9%, format remainder) and the queued feature candidates
        (ORBITDB append_line_sync pure half, bindings W-2/W-5).
        Wave 92 (2026-10-08): v0.64.1 PIN BUMP -- consumed m200/m201/m203.
        Verified on the official pin (tag 3c6f3bb5): rvalue float-vec
        index rc 0, multipart parse name rc 0, iter closure-thunk clause
        leak fixed (Range.count + smoke_iter 21/21 incl. -Workers 8, the
        forwardref repro rc 0). Landed the retried iter set (13 clauses /
        12 pub: contains x2, sum, product, collect, count-empty, max, min,
        find, all, any, nth, last) with the pin probe
        p_pin0641_iter_shapes.xi (32 checks) green pre/post; promoted the
        three resolved repros to tools/probes/ (regression locks).
        Relay corrections recorded on the pin: geom-matrix tuple
        inference PARTIAL (tuple-element check still red), polyhedra
        nested hull UNCHANGED, ensures-isok guard / clause float-vec
        index / geom Box unnameable / alias+foreign-call findings all
        still open. COMPILER_VERSION = v0.64.1; release-notes/v0.64.2.md
        (stdlib fragment) authored ahead of the next combined compiler
        release. iter 18.6% -> 25.1%, global 57.5% -> 57.7%, meter 75.8%;
        floors129. Battery on v0.64.1: corpus 954/954 (594.2s), probes
        263/263 (248.7s), modules 509/509, barename 0/509, ratchets OK.
        Next: resume coverage on the unblocked iter remainder (chain 14 +
        fold 8) and the low dirs.
        Wave 101 (2026-10-10): coverage wave 55 -- graph_theory +
        machine_learning (121 clauses, +63 pub; graph_theory 0% -> 100%,
        machine_learning 0% -> 96.9%, math 42.0% -> 48.3%, global 62.6%
        -> 63.6%, meter 76.4%; floors138). Two fix-firsts: floyd_warshall
        emitted 2n rows (n dead zero rows before the n distance rows;
        dropped) and metric_auc built its tuple scores with inline
        vector element reads (corrupted on v0.64.2; new compiler finding
        p_tuple_elem_vec_read.xi, bind-first workaround). Probe
        p_wave101_shapes.xi (274th, 145 checks) green pre/post. Battery
        on the official v0.64.2 archive: corpus 954/954 (661.4s), probes
        274/274 (258.7s), modules 509/509 (173.4s), barename 0/509
        (239.6s), floors138 + doc + module-smoke ratchets OK. NOTE:
        waves 93-100 are recorded in docs/stdlib_session.md blocks 77-88
        and docs/PRODUCTION_READINESS_QUEUE.md; the shared local compiler
        build path drifted past the pin (compiler main da7798da m252;
        use the official archive binary -- see block 89).
        Wave 102 (2026-10-10): json_parse depth cap FIXED (finding #16,
        XVECTOR relay; `_JSON_MAX_DEPTH = 128`; repro promoted to
        tools/probes/p_json_parse_depth_cap.xi; findings 16 -> 15) +
        the math remainder (decompose 15/15, fuzzy 12/14, game_theory
        6/13, chaos 13/13; 97 clauses, +46 pub) + wishlist W-5
        `Vec[UInt8].with_len(n)` (fn Vec.with_len[T]; collections
        smokes 21/21). math 48.3% -> 53.0%, global 63.6% -> 64.3%,
        meter 76.4%; floors139. Probe p_wave102_shapes.xi (275th, 118
        checks) green pre/post; compiler relay
        docs/STDLIB-RELAY-2026-10-10.md dropped (two findings +
        B-11/B-10/B-05/XVC-C-13/macOS blockers). Battery on the
        official v0.64.2 archive: corpus 954/954 (831.6s), probes
        276/276 (298.3s), modules 509/509 (265.5s), barename 0/509
        (265.3s), floors139 + doc + module-smoke ratchets OK. Next:
        os 26.6%, then the runtime-backed wishlist asks.
        Wave 103 (2026-10-10): sleep fix-first + os batch 1 -- 46
        clauses, +42 pub. pulse-6 FIXED (time.sleep_ms/sleep(Duration)
        now use the runtime ms sleep; the old integer division made
        sub-second sleeps no-ops) + pulse-5 re-triaged to the payload
        index (new finding, REL-20261010-1609-stdlib) + the new path
        println crash finding (REL-20261010-1615-stdlib). Coverage: fs
        9/10, file 12/12, dir 8/11, platform 7/10, err 3/11, args 3/6;
        os 26.6% -> 38.0%, global 64.3% -> 65.0%, meter 76.5%;
        floors140. Probe p_wave103_shapes.xi (277th, 57 checks) green
        pre/post. Battery on the official v0.64.2 archive: corpus
        954/954 (790.2s), probes 277/277 (265.6s), modules 509/509
        (200.2s), barename 0/509 (295.9s), ratchets OK. The remaining
        os gap is largely stub-gated; wave 104 takes the claimable
        remainder + the relay queue.
        Wave 104 (2026-10-10): Instant millisecond resolution +
        buffered-stdin normalization -- two relay fixes (benchmark-2:
        Instant.t is ms, elapsed/duration_since/add/sub/sleep_until and
        the instant.xi wrappers switched, the wave-66 lock remerged;
        benchmark-3: buf_reader_new(0)/buf_writer_new(1) resolve
        stdin/stdout through the runtime, piped stdin reads GOT:hello).
        Probe p_wave104_shapes.xi (278th, 13 checks) green; targeted
        smokes io2/time/stress_io/bench/test/log green. Coverage flat
        (fix wave); floors141. Battery on the official v0.64.2 archive:
        corpus 954/954 (975.5s), probes 278/278 (323.2s), modules
        509/509 (255.7s), barename 0/509 (460.9s), ratchets OK. Next:
        os batch 2 + the website-10 crypto triage + runtime asks.
        Wave 105 (2026-10-10): FIX-FIRST signal_raise/os.raise_signal
        link defect (the `raise_sig` extern existed in no runtime; the
        probe's first reference exposed the never-linkable surface) --
        both now call libc raise, with a documented-Err Windows guard
        (ucrt raise fail-fasts on unsupported numbers). os batch 2:
        env/sysinfo/term/proc/signal full covers + dir/fs/args/process/
        flat-os tails -- 64 clauses, +64 pub. Coverage: env 28/28,
        sysinfo 12/12, term 11/11 pub (is_tty/width stay the delegated
        stubs), proc 5/5, signal 8/8, dir 11/11, args 6/6, process
        11/11, fs 10/10; os 38.0% -> 55.4%, global 65.0% -> 65.9%
        (pubCovered 4226 -> 4290, clauses 5634 -> 5698); meter 76.6%;
        floors142. Probe p_wave105_shapes.xi (279th, 91 checks) RED
        pre-fix (undefined raise_sig) / GREEN post-fix and post-clauses.
        Battery on the official v0.64.2 archive: corpus 954/954 full
        (1002.7s; 5 transient clang -1 crashes cleared by -RetryFailed,
        failed_attempts entry), probes 279/279 (304.7s), modules 509/509
        (184.4s), barename 0/509 (263.1s), floors142 + doc + module-smoke
        (497/517, 3476/6204) ratchets OK.
        Next: the website-10 no-NASM crypto triage + runtime asks.
        Relay website-10 (2026-10-10, security): the no-asm runtime AES
        stubs wrote nothing and the compares returned 0 (= equal). The
        stdlib path uses the NASM-independent xiom_aesni_* intrinsics and
        crypto.mac.constant_time_eq is pure XIOM (no stdlib public API
        wrong today); the runtime dispatch primitives were the hole, and
        the pin's driver actually builds WITH -DXIOM_NO_ASM here (cached
        runtime object carries the fallbacks), so it was operative. Fixed
        with portable FIPS-197 AES-128 + branch-free XOR compares in the
        no-asm block; KAT-verified standalone and end-to-end through the
        driver; post-edit smokes kat_ 15/15, crypto 7/7, stress_crypto
        24/24, mem 6/6, ffi 2/2. New open runtime finding: aarch64
        xiom_aesni_encrypt_block is ONE round and xiom_aesni_decrypt_block
        an empty stub while xiom_crypto_aesni_available() returns 1 --
        wrong AES-128 ciphertext on Apple ARM (macos-14 leg candidate);
        fix needs an ARM runner.
        Wave 106 (2026-10-11): FIX-FIRST private-symbol collision in the
        hash modules (probe-first catch). With xiom.hash.farm and
        xiom.hash.metro co-imported, metro's module-private _K0/_K1/_K2
        resolved to farm's values: metrohash64(empty, 0) returned
        15427970114922222902 instead of 1424585646250073642 (exact
        numeric match; farm wins in both import orders). Filed
        REL-20261011-1052-stdlib (high): module-level privates must be
        per-module mangled (same mechanism covers same-named private
        fns; a full-stdlib scan found no other live divergent const).
        Stdlib-side: metro's consts renamed _METRO_K0..K3 (city/farm
        agree). Second finding filed REL-20261011-1053-stdlib (medium):
        zero-arg `.hash()` on scalars lowers to a compiler builtin
        identity that shadows Int.hash/Bool.hash (methods unreachable;
        explicit receiver does not type-check; hash_value(0) == 0).
        Hash coverage wave: 41 clauses, +39 pub covered (hash.xi 11,
        farm 9, highway 4, metro 5, murmur 2, spooky 4, t1ha 6); hash
        51.1% -> 94.4%; global 65.9% -> 66.5% (pubCovered 4290 -> 4329,
        clauses 5698 -> 5739); meter 76.7%; floors143. Probe
        p_wave106_shapes.xi (280th, 50 checks) RED on the collision /
        GREEN after the rename, pre and post clauses. Battery on the
        official v0.64.2 archive: corpus 954/954 full (788.5s), probes
        280/280 (301.6s), modules 509/509 (221.5s), barename 0/509
        (259.3s), floors143 + doc + module-smoke (497/517, 3476/6204)
        ratchets OK. Bus round: pulse-3 (server_parse_request) and
        pulse-4 (write_all) moved acked -> fixed as already-delivered at
        ec64dec (the doorbell's "wave-106 candidates" framing
        superseded). Next: crypto/misc/sync coverage; runtime asks when
        the compiler runtime bundle moves.
        Wave 107 (2026-10-11): FIX-FIRST RSA short-key OOB read in
        crypto.xi (_rsa_parse_key indexed key[0..8] unconditionally, so
        any key shorter than 8 bytes read out of bounds and made the RSA
        guards nondeterministic -- caught by the wave probe's contract
        run: the empty-key rsa_sign clause failed on garbage memory).
        Bounds-guarded the read (short keys zero-pad). Crypto batch 1:
        chacha (4), aead (10), curves (9), legacy des (4), rng (2), sign
        (6), rsa (6) -- 41 clauses, +41 pub. crypto 47.0% -> 69.4%;
        global 66.5% -> 67.2% (pubCovered 4329 -> 4370, clauses 5739 ->
        5790); meter 76.7%; floors144. Probe p_wave107_shapes.xi (281st,
        55 checks) green pre/post after the fix-first. Battery on the
        official v0.64.2 archive: corpus 954/954 full (698.4s), probes
        281/281 (299.4s), modules 509/509 (203.3s), barename 0/509
        (216.6s), floors144 + doc + module-smoke (497/517, 3476/6204)
        ratchets OK. Bus: acked the pulse keep-alive/deadlines design
        note (three interface points adopted for the queued socket-
        timeout wave). Next: crypto batch 2 (cipher + crypto.xi tail +
        ecc); misc/sync coverage.
        Wave 108 (2026-10-11): FIX-FIRST crypto defects (3). cipher.xi's
        _gf_mul11/_gf_mul13 were SWAPPED -- every cipher.xi decrypt path
        (aes_block_decrypt / ECB / CBC) computed wrong plaintext while
        encrypt stayed FIPS-correct; NO smoke covered the decrypt (the
        wave probe caught it by comparing the block roundtrip against the
        FIPS-verified runtime AES). argon2 could pass iterations <= 0 into
        pbkdf2 (whose requires trap) -- now guarded to the family's
        validate-and-return-empty convention. The educational ecc
        ed25519_sign/verify indexed 32 bytes blindly (OOB reads for short
        keys/signatures) -- bounds-guarded with zero-fill. Existing open
        note: the toy's keygen->sign->verify roundtrip is false by
        construction (sign binds sha256(sk); verify binds the passed
        key); no smoke covers it. Crypto batch 2 coverage: 49 fns, +46 pub
        (cipher 22, crypto tail 15, ecc 12); crypto 69.4% -> 94.5%; global
        67.2% -> 67.9% (pubCovered 4370 -> 4416, clauses 5790 -> 5875);
        meter 76.8%; floors145. Probe p_wave108_shapes.xi (282nd, 60
        checks) RED on the AES decrypt + argon2 trap / GREEN post-fix and
        post-clauses. Battery on the official v0.64.2 archive: corpus
        954/954 full (607.9s), probes 282/282 (246.5s), modules 509/509
        (156.2s), barename 0/509 (234.4s), floors145 + doc + module-smoke
        (497/517, 3476/6204) ratchets OK. Next: misc/sync coverage.
        Wave 109 (2026-10-11): misc dir 98.7%. 38 fns, +38 pub (misc.xi 25:
        glob/natural/palindrome, distances/similarities, roman, case
        converters, ordinal/pluralize/anagram, unit conversions,
        human_size; semver.xi 13: parse/valid/compare/matches/satisfies/
        inc/to_string/prerelease/build/caret/tilde/gt/lt). misc 50.6% ->
        98.7%; global 67.9% -> 68.5% (pubCovered 4416 -> 4454, clauses
        5875 -> 5923); meter 76.9%; floors146. Relay round: compiler
        resolver/isolation batch coordination -- forward lock already in
        p_wave106_shapes.xi, NEW reversed-order lock on main
        (p_witness_1052_rev.xi, commit 67d66c9) and the witness branch
        witness/1052-metro-rename-reverted (1566c26, rename reverted +
        both order locks; RED today by contract abort -- farm's constants
        win -- must run rc 0 post-fix). We revert the rename on main once
        isolation is verified and keep both probes as e2e locks. Battery:
        corpus 954/954 full (757.8s), probes 284/284 (377.8s), modules
        509/509 (196s), barename 0/509 (244.6s), floors146 + doc +
        module-smoke ratchets OK. Next: sync coverage (sync.xi tail +
        atomics/mutex/rwlock); async later.
        Wave 110 (2026-10-11): sync dir 94.9%. 70 fns, +70 pub (sync.xi 27:
        RwLock new/read/write/try_read/try_write + guard drops, Condvar
        new/wait, Once.new, Barrier.wait + standalone barrier_wait,
        AtomicBool/AtomicInt constructors + op guards, cdl_wait_spin, the 8
        standalone atomic_* helpers; atomics.xi 16 constructor/op guards;
        mutex.xi 6; rwlock.xi 9; barrier.xi 4; channel.xi 5 (capacity clamp,
        closed mirrors, send-Err/recv-None closed guards); condvar.xi 3).
        sync 35.9% -> 94.9%; global 68.5% -> 69.5% (pubCovered 4454 ->
        4523, clauses 5923 -> 6029 -- the 4524/6031 figures first recorded
        here counted cdl_count_down's since-reverted @pre clauses); meter
        77.0%; floors147. NEW finding
        while writing the probe: the v0.56 I3 builtin Mutex deadlock-
        detection names shadow the stdlib generic xiom.sync.Mutex[T] in
        user code (sync.Mutex.new(42) is T001; the zero-arg form binds the
        builtin and returns Int), so the parent Mutex.new/lock surface
        stays clause-free; repro p_sync_mutex_builtin_shadow.xi, bus item
        REL-20261011-1456-stdlib (findings 17 Current: 16 compiler +
        1 stdlib). Probe p_wave110_shapes.xi (285th, 49 checks) green on
        the pin pre/post; cap note: xiom.sync + xiom.sync.atomics cannot
        share one compilation (64 unsafe-direct-block codegen cap), so the
        atomics submodule shape is locked by smoke_sync_atomics.xi +
        smoke_sync_arc_battery.xi in the same battery. Battery: corpus
        954/954 full (945.5s), probes 285/285 (359.5s), modules 509/509
        (269.6s), barename 0/509 (276.7s), floors147 + doc + module-smoke
        (497/517, 3476/6204) ratchets OK. Next: the xvector json_parse
        quadratic fix (byte-based lexer fast path) as the top candidate
        item, then async; 1052 post-fix actions when the compiler
        resolver/isolation batch lands.
        Wave 111 (2026-10-11): xvector json quadratic fixed
        (REL-20261011-1453; consumer-blocking for the next candidate).
        The parser scans one cached (base, n) byte view -- json_parse takes
        s.c_str() + s.len() once and every helper reads raw bytes (no
        runtime strnlen per access); string values are rebuilt through a
        byte buffer; the number path builds the literal bytes directly.
        Same-family fixes: slice.str_bytes and string.str_slice copy
        through cached (base, len) raw reads. FIX-FIRST find while
        rewriting: the old \u escape branch fell through to a shared
        *pos increment and swallowed the byte after the 4 hex digits
        ("a\u0042c" parsed as "aB") -- now exact (probe checks 1-4).
        Evidence: xvector's pinned probes exit 0 on the fixed stdlib
        (repro_json_quad: 20000 numbers 498 ms vs ~18 s, linear
        61/123/220/498; repro_strbytes: 400 KB 366 ms vs ~3.7 s, linear
        44/93/182/366); local pre-fix numbers 10k 1972 ms / 20k 7600 ms
        (ratio 3.85) -> post 165/382 (ratio 2.31). Probe
        p_json_parse_scale.xi (286th, 49 checks) red pre-fix at check 1,
        green post (correctness + sub-quadratic ratio + ms budgets).
        NEW checker finding filed while landing the rewrite:
        REL-20261011-1626-stdlib -- a bare trailing match expression
        after a local Vec.push reports T001 "found ()"; workaround
        `return match ...;` (repro p_trailing_match_after_push.xi;
        findings 18 Current: 17 compiler + 1 stdlib). Battery: corpus
        954/954 full (795.3s), probes 286/286 (291.6s), modules 509/509
        (187.5s), barename 0/509 (264.6s), floors147 + doc + module-smoke
        ratchets OK (no floors bump; pub coverage unchanged at 69.5%).
        Relay round: 1453-xvector acked -> fixed; 1513-engine flake
        acked for tracking; 1442-compiler already fixed at ad9169e.
        Next: the cut mechanics (package.xi categories + stage, pin
        decision with the compiler lane) and the v0.64.3 release-check
        verdicts.
        Wave 112 (2026-10-11): the core Option/Result standalone queries
        and the Slice-param helper set, unblocked by the compiler v0.64.3
        generic by-reference fix (REL-20261010-1548-stdlib-5 verified on
        the official archive): 16 fns, +24 clauses -- is_sorted/all/none/
        contains length claims, slice_len/slice_is_empty/slice_to_vec
        mirrors, slice_first/slice_get/min_slice/max_slice Some-None
        branch guards, sum_slice empty claim, and the four queries with
        canonical parameter is-guards (o is Some/None, r is Ok/Err -- the
        guarded form is the one that works; the result.is_ok implication
        form stays the open finding 1548-stdlib-7). core 45.8% -> 58.0%;
        global 69.5% -> 69.8% (pubCovered 4523 -> 4539, clauses 6032 ->
        6056); meter 77.0%; floors148. Probe p_wave112_shapes.xi (287th)
        green pre/post on the pin; no empty-slice literal is constructible
        on v0.64.3 (Str.as_bytes does not resolve; M33 [0]/[] arrays lose
        the const N), so the zero-length clause branches stay
        compile-validated. Battery on the v0.64.3 pin: corpus 954/954
        (673.6s), probes 287/287 (222.1s), modules 509/509 (201.9s),
        barename 0/509 (296.8s), floors148 + doc + module-smoke ratchets
        OK. Next: the cut mechanics on the compiler's go (pin protocol
        1731-compiler-2), the wave-106 revert at the v0.64.4 archive, and
        the async/num/math/time/iter dirs.
        Wave 113 (2026-10-11): str_chars / str_code_points linear --
        the last strnlen-family conversions in slice.xi. Both loops now
        read through a cached (base, len) view: `_char_at_runtime` is a
        byte-exact replica of the runtime xiom_char_at decoder (leading
        byte on malformed/truncated sequences, stray continuation as-is)
        for str_chars, and `_char_at_masked` preserves the previous
        `_char_at_decoded` masking decode (no continuation validation)
        for str_code_points, with out-of-range bytes reading as 0 exactly
        like byte_at/the NUL terminator. Probe p_wave113_shapes.xi (288th)
        locks the values incl. the malformed quirks (lone 0xC3 -> char
        195 / code point 192) and the bounded linearity; local 400 KB:
        str_chars 2472 -> 389 ms, str_code_points 4221 -> 370 ms (linear,
        gate 500 ms). No pub-coverage change (floors148 stays). Battery
        on v0.64.3: corpus 954/954 (1377.6s), probes 288/288 (221.2s),
        modules 509/509 (250.3s), barename 0/509 (596.6s), floors148 +
        doc + module-smoke ratchets OK. Family closed for the release
        (json parser + str_bytes/str_slice in wave 111; chars/code points
        here); async remains the next coverage dir.
        Wave 114 (2026-10-12): battery pin bumped to the official v0.64.4
        release archive (corpus 954/954, probes 289/289, modules 509/509,
        barename 0/509; tuple lock promoted; COMPILER_VERSION -> v0.64.4),
        then async coverage part 1: 29 pub fns gained clauses across
        channel (10: capacity/closed mapping, send/recv outcome guards,
        broadcast seen/len relations), executor (4: new empties, tasks
        mirror, drain/shutdown empties), timer (7: armed/ready literals,
        next guards, wheel literal fields + parallel-array invariant) and
        io (8: Future.ready == true). Payload-free guards only, no @pre on
        &mut fields. async 4.5% -> 47.8%; global 69.8% -> 70.2%
        (pubCovered 4539 -> 4568, clauses 6056 -> 6102); probe
        p_wave114_shapes.xi (290th) green pre/post on the pin (values
        bound before comparing); smoke_async trio green; floors149 wired
        (ci/heavy/release + tools/README + plan). Parent xiom.async
        surface (AsyncExecutor/Channel methods) reserved for part 2.
        Wave 115 (2026-10-12): the durability + byte-level IO first drop
        (REL-20261012-1945-orbitdb / -1945-xvector-2 / -1946-pulse /
        REL-20261010-1550-packages fsync family): runtime/xiom_runtime.c
        gained the platform-branched shims xiom_fsync_fd /
        xiom_fdatasync_fd / xiom_sync_file / xiom_fflush_stdout /
        xiom_fsync_dir, the fd opens xiom_open_append / xiom_open_read,
        the fixed-offset byte IO xiom_read_at (zero-fills past EOF) /
        xiom_write_at (creates + gap-fills), xiom_append_bytes and
        xiom_truncate_path. Stdlib: fs_ffi.fsync/fdatasync real; sync_io
        read_exact (4 KiB staging, Err on early EOF), write_all
        (partial-count loop), sync_fd, fsync_dir (POSIX dir fsync;
        documented Windows no-op-with-success), open_append/open_read/
        close_fd; io gains flush_stdout (real fflush), fsync(FILE*
        handle), read_at (size-clamped), write_at, append_file_bytes,
        truncate_file. Consumer lock: fixtures verify byte-exact
        roundtrips; fs_ffi takes RAW fds while io.fsync takes FILE*
        handles (probe-locked distinction -- a FILE* passed to the fd API
        truncates and fast-fails). Probe p_wave115_shapes.xi (291st) red
        pre / green post; smoke_os_sync + smoke_os_ffi rewritten to the
        new semantics (old stub asserts retired), smoke_os* 8/8 +
        smoke_io* 20/20 green. Coverage: pubFns 6505 -> 6513, pubCovered
        4568 -> 4580; global 70.2% -> 70.3%; floors150 wired
        (ci/heavy/release + tools/README + plan). Runtime caveat:
        consumers see the new symbols at the next compiler pin that
        re-vendors stdlib/runtime (XIOM_RUNTIME_DIR on v0.64.4 until
        then). Still open in the bundle: fcntl locking (P4), mmap (P5),
        append_line_sync + tail check, fd ftruncate, remove_dir,
        read_until_eof/read_line_buffered/copy_fd*.
        Wave 116 (2026-10-12): polygon_difference disjoint-case fix --
        the difference now routes through polygon_intersection first and
        returns Some(a) exactly for disjoint inputs (both orders);
        empty-a (None), empty-b (Some(a)) and a-inside-b (None) stay
        exact; overlapping/containment inputs keep the documented
        conservative approximation (union-of-outside-clips pieces
        overlap and disjoint-piece concatenation breaks even-odd fill,
        so the full Weiler-Atherton-style clipper with holes/slits stays
        a queue follow-up). Probe p_wave116_shapes.xi (292nd) red pre /
        green post; the repro p_polygon_difference_halfplanes.xi rc 0 and
        PROMOTED to tools/probes (293rd); known_failures Current drops to
        15, all compiler (the stdlib ledger carries no open repro for the
        first time). Battery on v0.64.4-rel: corpus 954/954, probes
        293/293, modules 509/509, barename 0/509,         floors150 + doc +
        module-smoke ratchets OK.
        Wave 117 (2026-10-12): durability P5 pairs -- io.append_line_sync
        (torn-tail repair, then line + newline appended and fsynced on
        the append handle before returning), io.file_last_byte (O(1) via
        file_size + read_at) and io.ends_with_newline, io.remove_dir
        (rmdir/_rmdir), sync_io.truncate_fd (ftruncate/_chsize_s);
        runtime gains xiom_remove_dir + xiom_ftruncate_fd (Windows needed
        <direct.h> for _rmdir). Serves orbitdb-7/-8, packages-5 (with the
        wave-115 truncate_file) and the fd half of xvector-5. Probe
        p_wave117_shapes.xi (294th) red pre / green post (line bytes,
        torn-tail repair bytes, last-byte Some/None incl. empty+missing,
        newline true/false, remove_dir + dir_exists, truncate_fd shrink);
        smoke_io* 20/20 + smoke_os* 8/8; coverage pubFns 6513 -> 6518 /
        pubCovered 4580 -> 4585, global 70.3% (clauses 6128), floors151
        wired; battery on v0.64.4-rel: corpus 954/954, probes 294/294,
        modules 509/509, barename 0/509, ratchets OK.
        Wave 118 (2026-10-13): P4 advisory locking -- runtime
        xiom_flock_fd (POSIX fcntl F_SETLKW/F_SETLK whole-file; Windows
        LockFileEx full range, LOCKFILE_FAIL_IMMEDIATELY for the try) +
        xiom_funlock_fd; sync_io file_lock/file_unlock/file_try_lock real
        (stubs retired). Windows LockFileEx blocking on a range already
        held by the same handle hangs -- lock sequences are try ->
        unlock -> blocking lock -> unlock (never re-lock a held range);
        run_smokes.ps1 has no per-file timeout, so hung files must be
        guarded at the caller. Probe p_wave118_shapes.xi (295th) red pre
        / green post; smoke_os_sync remerged to the real semantics,
        smoke_os* 8/8; coverage pubCovered 4585 -> 4588 (clauses 6131,
        global 70.4%), floors152 wired; battery on v0.64.4-rel: corpus
        954/954, probes 295/295, modules 509/509, barename 0/509,
        ratchets OK. DEFERRED: the f32 bitcast pair (xvector-6) is
        compiler-blocked (the f64 pair is a compiler-intrinsic lowering;
        Float32 narrowing rides the compiler's next batch).
        Wave 119 (2026-10-13): socket options + deadline receive -- runtime
        xiom_socket_set_timeout (SO_RCVTIMEO; POSIX timeval, Windows ms),
        xiom_socket_set_nonblocking (O_NONBLOCK / FIONBIO),
        xiom_socket_reuse_addr, xiom_socket_shutdown; the Windows bind now
        sets SO_REUSEADDR (POSIX parity; the REL-20261011-0317 root cause);
        socket.xi set_timeout / set_nonblocking / reuse_addr / shutdown /
        recv_timeout real (early-error returns preserved -- old locks probe
        them and a requires form aborts). ROOT-CAUSE FIX: xiom_socket_recv
        / recvfrom returned C int but were declared Int (i64), so -1
        (EWOULDBLOCK/timeout) read as 4294967295 and the wrapper tried a
        ~34 GB Vec allocation -> ACCESS VIOLATION; both are Int32 + casts
        now, which unblocks nonblocking and timeout recv. Probe
        p_wave119_shapes.xi (296th) red pre / green post (loopback pair:
        nonblocking Err fast, 250 ms timeout Err, recv_timeout Err,
        shutdown Ok + peer EOF); p_wave60_shapes remerged to the real
        semantics; smoke_net* 11/11. Coverage: pubFns 6519, pubCovered
        4589 (clauses 6136, 70.4%), floors153 wired; battery on
        v0.64.4-rel: corpus 954/954, probes 296/296, modules 509/509,
        barename 0/509, ratchets OK.
        Wave 120 (2026-10-13): the mmap family real
        (REL-20261012-1945-xvector-2 P5) -- runtime xiom_mmap_file /
        xiom_mmap_anon / xiom_munmap / xiom_msync / xiom_madvise /
        xiom_mprotect / xiom_mlock / xiom_munlock / xiom_mem_write plus
        xiom_open_rw (POSIX mmap with MAP_ANON on Apple, msync/madvise/
        mprotect/mlock; Windows CreateFileMapping/MapViewOfFile/
        FlushViewOfFile/VirtualProtect/VirtualLock; msync flags
        transported as 1 = async / else sync because the MS_* constants
        differ on macOS); xiom/os/mmap.xi 12 stubs -> 11 real (anonymous
        + file + writeable mappings, unmap/sync/advise/protect/lock/
        unlock, pure-XIOM copy via cached offsets, memcpy write);
        mmap_resize stays a documented Err (mremap is Linux-only);
        fs_ffi mmap/munmap/msync/madvise/mlock/munlock real (path
        roundtrip, fd owned until munmap; the Ok-side clause is
        payload-free -- struct payload reads in catalog ensures clauses
        false-fire on v0.64.4, known_failures payload family);
        sync_io.open_rw new. FIX-FIRST (probe-first catch): the
        fd-open/read/write externs returned C int but were declared i64,
        so a -1 read as 4294967295 -- open_read on a missing path
        returned Ok(bogus fd) and the downstream Int32 cast crashed
        0xC0000409 (wave-119 ABI family completion: open_append/
        open_read/open_rw/read/write are Int32 + casts now, matching the
        socket recv pattern). Probe p_wave120_shapes.xi (297th) red pre
        (compile: open_rw missing; the stubs return Err) / green post:
        anon write/copy/lock/protect/unmap; file writeable copy + 1-byte
        write + msync visible through a fresh read; read-only copy +
        read_exact; fs_ffi roundtrip; Err rows (bad fd, null ptr, zero
        length, missing path). Platform lore: the Windows UCRT
        fast-fails the process on _read/_write of a closed/out-of-range
        fd before any return value exists (C-verified; invalid-fd probe
        rows are deliberately absent). smoke_os_ffi remerged to the real
        semantics (stub-Err asserts retired; resize + bad-fd stay Err);
        targeted smokes os 8/8, io 20/20, ffi 2/2, net 11/11.
        Coverage: pubFns 6520, pubCovered 4589 -> 4606 (clauses 6136 ->
        6155, global 70.4% -> 70.6%, os 57.8% -> 62.2%); floors154
        wired. Battery on v0.64.4-rel: corpus 954/954 (617.1s), probes
        297/297 (209.3s), modules 509/509 (179.6s), barename 0/509
        (249.7s), coverage + module-smoke (497/517, 3481/6219) + doc
        ratchets OK. Follow-up: the async/io.xi and io/pipe.xi copies of
        the xiom_read/xiom_write Int returns need the same Int32
        treatment (same family; outside this wave's probe scope).
        Wave 121 (2026-10-13): websocket I/O fix + server-side helpers +
        chunked-transfer stream helpers (REL-20261012-1946-pulse
        stdlib-side rows). websocket.xi FIX-FIRST: ws_connect closed the
        socket before returning it and read the handshake to EOF, and
        ws_recv read every frame to EOF (both hang a persistent
        connection); now ws_connect consumes the head exactly at CRLFCRLF
        (leftover bytes carried in the new WsConnection.pending buffer)
        and keeps the fd live, and ws_recv is a bounded incremental
        reader over pending+socket (1 MiB cap) built on the new pure
        ws_frame_take (frame + consumed count; Err("incomplete frame") =
        read more). New server-side helpers: ws_request_key
        (case-insensitive Sec-WebSocket-Key extraction),
        ws_handshake_response (101 builder, 129 bytes; RFC 6455 vector
        verified), ws_close_code, ws_frame_encode_fin (FIN flag for
        fragmentation; ws_frame_encode delegates). Partial sends fixed
        for every request/frame via ws_send_all; ws_ping/ws_pong/ws_close
        return Result now (close clears open). Client I/O goes through
        xiom.net.socket (no raw externs); the shared send shim got the
        wave-119 Int32 return fix (send's -1 read as 4294967295 before).
        socket.xi: socket_send_all (full-send loop) + chunked-transfer
        writers socket_chunk_encode / socket_chunked_end /
        socket_stream_chunk / socket_stream_end (lowercase-hex frames,
        empty data = no-op; the head with Transfer-Encoding: chunked is
        written by the caller, e.g. server_build_response_headers).
        Probe p_wave121_shapes.xi (298th) red pre / green post: RFC
        accept vector through the response builder; request-key variants;
        header split with byte-exact leftover; frame take for every
        truncated prefix, concatenated frames, 16-bit length, masked
        roundtrip; close codes; chunk encodes; loopback wire exchange
        (handshake request/response + verify, unmasked server frame,
        masked client frame, chunked head+2 chunks+end byte-exact).
        Platform note: the live threaded ws_connect leg is deliberately
        not in the probe (thread spawn in probes is untested and probes
        have no per-file timeout) -- the client glue composes the locked
        pure pieces and the wire exchange locks the protocol end to end.
        p_wave62_shapes remerged (WsConnection.pending); smoke_net_url
        extended with the new pure helpers; smoke_net 11/11. Coverage:
        pubFns 6531, pubCovered 4617 (clauses 6169, global 70.7%);
        floors155 wired. Battery on v0.64.4-rel: corpus 954/954
        (578.1s), probes 298/298 (211.4s), modules 509/509 (188s),
        barename 0/509 (280.2s), coverage + module-smoke (497/517,
        3490/6230) + doc ratchets OK. Follow-ups: ws_random_key is
        time-seeded (predictable handshake keys -- random source when
        the RNG lands); socket create/accept/bind/listen POSIX -1
        returns still read as 4294967295 (Windows-ABI-correct
        declarations; audit for a POSIX consumer needing failure
        classification).
       Ratchet:
        tools/coverage_scan.ps1 -RatchetFile tools/coverage_floors155.json
        tools/module_smoke_scan.ps1 -BaselineFile tools/module_smoke_floors.json

       (repo tooling as of the split; positive + negative runs verified;
       earlier floors kept at
       coverage_floors32/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/50/51/52/53/54/55/56/57/58/59/60/61/62/63/64/65/66/67/68/69/70/71/72/73/74/75/76/77/78/79/80/81/82/83/84/85/86/87/88/89/90/91/92/93/94/95/96/97/98/99/100/101/102/103/104.json).
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

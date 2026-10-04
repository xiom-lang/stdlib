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
       Ratchet:
        tools/coverage_scan.ps1 -RatchetFile tools/coverage_floors101.json
       tools/module_smoke_scan.ps1 -BaselineFile tools/module_smoke_floors.json

       (repo tooling as of the split; positive + negative runs verified;
       earlier floors kept at
       coverage_floors32/34/35/36/37/38/39/40/41/42/43/44/45/46/47/48/49/50/51/52/53/54/55/56/57/58/59/60/61/62/63/64/65/66/67/68/69/70/71/72/73/74/75/76/77/78/79/80/81/82/83/84/85/86/87/88/89/90/91/92/93/94/95/96/97/98/99/100/101.json).
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

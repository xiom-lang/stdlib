# XIOM Stdlib Session -- Clean Handoff (2026-08-25, early morning)

> Written for the next session. Branch: `feat/architect`. HEAD = this
> doc's commit. **Round-15 sweep: 874/907** (corrected classification --
> child status is the printed "exit code:" stderr line, NOT $LASTEXITCODE;
> naive sweeps false-report 907/907). This continuation session RESOLVED
> both top stdlib crypto/compress defects and shipped StringBuilder.

---

## 0. Read first

- docs/STDLIB_READINESS_PLAN.md -- this campaign's plan (phases T/E/O/C/S)
- docs/REPORT_TO_COMPILER_SESSION.md -- cross-boundary findings + 7 new
  compiler defect probes (all under %TEMP%\kilo\stdlib_campaign\probes\)
- docs/STR_OWNERSHIP.md -- normative Str.from_cstring ownership convention
- Sweep tooling (reusable): %TEMP%\kilo\stdlib_campaign\
  {launch_sweep.ps1,sweep_worker.ps1,reclassify.ps1}. Isolated binary =
  %TEMP%\kilo\tgt_std\debug\xiom.exe built from worktree
  %TEMP%\kilo\axiom_r15 (HEAD). GOTCHA: module resolution also scans a
  CWD-relative stdlib root AND the binary's baked CARGO_MANIFEST_DIR root --
  run verification from %TEMP%\kilo\iso_run (junction to worktree stdlib)
  or results silently mix trees.

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


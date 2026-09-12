# XIOM Stdlib Session -- Handoff

## 0. START HERE -- current handoff (2026-09-12)

Lane boundary: this session owns `stdlib/**`, `examples/stdlib_smoke/**`,
and the docs listed below. A PARALLEL COMPILER SESSION owns `crates/**`
and edits `stdlib/runtime/` occasionally; its uncommitted crates changes
can appear in the shared tree at any time -- NEVER `git add -A`; stage
explicit paths only. Branch: `feat/architect`.

State (verified 2026-09-12 late; r34/r35 isolated builds = committed HEAD
8c921c32, after the compiler lane's R9 fix b581184d):
- Sweeps: r33 935/935; r34 935/935 (fast-path re-land); r35 935/935
  (contract wave 2); r36 935/935 (Item A findings burn-down).
  Four consecutive all-green corpora (+ ratchet OK).
- Item A stdlib status (2026-09-12): 237 -> 2 findings, 17 -> 1 parse
  errors; the 2 findings + 1 parse error are the compiler-side D4/D5/D1
  items (iter:413, path:261, time `<=>`). See section 2.10.
- Part-2 deliverables (newest first): contract wave 2 -- 83 clauses
  across 56 collect containers, collect 2.0% -> 18.9%, global 12.6%
  clauses / 11.1% pub-with-clause; dedup audit R15 logged + ascii85
  direction corrected (e42520c1); string fast-path re-land + R16
  (a47ac737); memory-quartet namespace wave 2 (78b107fb).
- Part-3 deliverable: Item A findings burn-down (b71d839f) -- 237 -> 2
  findings, 17 -> 1 parse errors (rest are compiler D4/D5/D1); see 2.10.
- Part-1 deliverables (same day, newest first): xiom.serialize.csv RFC
  4180 + smoke (e398df2f); endian trio dedup shim (9616b72f); contract
  wave 1 + ratchet gate #7 (69a07b7e); collect namespace wave 1
  (0d63c6b0); legacy quarantine (0dc8d90a + 8ea8e324); r32/R11-R13 log.
- Open compiler findings: R15 (same-leaf + same-name codegen key
  collision; blocks base32/percent/punycode + base16/base64/base58
  consolidation), R16 (ptr + int in call args; Int-cast workaround in
  use), R14 (latent combined-iter AV, compiler lane). R9 FIXED by
  b581184d; Item A step 2 (843a5a88) + stdlib findings report
  (695af0f0) drive the next work block.
NEXT QUEUE (ordered):
1. Compiler lane: R9 FIXED (b581184d); R11-R13 fixed (b8e2fa43); open
   R15 (encoding-family dedup gate), R16 (ptr+int workaround), R14
   (latent). Re-sweep per compiler round (r34/r35 tooling ready).
2. Item A stdlib findings (docs/ITEM_A_STDLIB_FINDINGS.md, 237 findings,
   0 hard errors): D2.1 unsafe confinement (~60), T003 (7), T007 (8),
   T006 (3), numeric mixing (~30), missing returns (9), individual bugs.
   Re-measure with `cargo test -p xiom-check catalog_corpus_is_clean
   -- --ignored --nocapture` (isolated CARGO_TARGET_DIR).
3. Contract wave 3: collect depth (18.9%), string (17.1%), io (38.9%)
   toward the 60% gate; refresh ratchet floors each wave (current:
   coverage_floors34.json).
4. Dedup: after R15, consolidate base32/percent/punycode +
   base16/base64/base58; ip4/ip6 translation unit; console/terminal and
   platform audited (layered / name-collision hazard); json after heap.
5. Capability: TOML, tzdata phase 1 (OS timezone FFI), async stress
   suite, TLS schannel binding.

Environment & tooling:
- Isolated binary build (preferred; ~30s warm):
  `$env:CARGO_TARGET_DIR="C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\target_rNN"; cargo build -p xiom`
  then use `...\target_rNN\debug\xiom.exe`. A fresh target dir is a
  from-scratch build (~10 min); reuse per round.
- Binary provenance: r32 = clean-HEAD artifact copied from r31 (excludes
  the compiler lane's then-WIP); r33 = fresh build of b8e2fa43;
  r34 = fresh build of committed HEAD 8c921c32 (R9 fix + Item A step 2);
  r34/r35 sweeps are the current all-green baselines (sweep35 tooling:
  sweep_worker35/launch_sweep35/triage_sweep35). The triage script also
  runs the coverage ratchet (gate #7) on the floors file.
- Coverage ratchet (gate #7): stdlib_ws\coverage_scan.ps1
  [-Detail] [-DumpFloors coverage_floors34.json] [-RatchetFile ...];
  per-top-level-dir pub-coverage floors; positive + negative runs
  verified 2026-09-12; wave-1 floors kept at coverage_floors32.json.
  Re-dump floors after each contract wave.
- Sweep tooling (copy + bump the paths per round; r32 set current):
  C:\Users\lefte\AppData\Local\Temp\kilo\stdlib_ws\
  {sweep_worker32.ps1, launch_sweep32.ps1, triage_sweep32.ps1,
  compare_r29_r32.ps1, launch_verify32.ps1} + coverage_scan.ps1.
  8 workers; per-file CSV rows; error logs per worker. Workers redirect
  child stdin from NUL (a stdin-reading smoke must not hang a worker).
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
most recent (rounds 26-32, incl. the seeded-siphash unit) is section 2.7.
Key docs: STDLIB_READINESS_PLAN.md (phases T/E/O/C/S + section 9 status),
COMPILER_BUGS.md (open: R9 latent only), STDLIB_DEDUP_INVENTORY.md
(progress + parity convention), STDLIB_CONTAINER_TUNING.md (iteration
order + hash-DoS posture), STR_OWNERSHIP.md, REPORT_TO_COMPILER_SESSION.md.

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

- **237 -> 2 findings and 17 -> 1 parse errors.** Both remaining findings
  are the compiler-side items from the report: D4 xiom.iter:413 (generic
  fn substitution) and D5 xiom.path:261 (bare-name collision); the last
  parse error is xiom.time's `<=>` operator (D1).
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


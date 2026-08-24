# XIOM Stdlib Session -- Clean Handoff (2026-08-24, late evening)

> Written for the next session. Branch: `feat/architect`. HEAD = 00237fe7
> (KAT corpus + crypto C-backing + readiness plan) on top of the round-15
> line. **Full sweep on round-15: 874/907 PASS** (corrected classification;
> the naive exit-code method false-reports 907/907 -- the child's real
> status is the printed "exit code:" stderr line, NOT $LASTEXITCODE).
> The 33 failures map exactly onto the compiler clusters below; three were
> new discoveries now fixed or catalogued.

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

## 2. New stdlib-side defects found (next-session queue, priority order)

1. **ChaCha20-Poly1305 interop**: ciphertext byte-exact vs RFC 8439 but tag
   deviates => Poly1305 layer wrong somewhere; self-roundtrip consistent so
   it silently produces non-interoperable AEAD today. Focused session with
   RFC text; kat file gates the exact-tag assert.
2. **gzip >= 4096 input AV** (compress.gzip_compress; per-process bisect
   probes gz_*.xi) + deflate.deflate_compress returns EMPTY Vec at every
   size probed while lz77/huffman pass standalone. Possibly compiler return-
   path bug -- joint investigation flagged.
3. Legacy-cipher quarantine (crypto/legacy/ move) -- pure docs+headers, safe.
4. StringBuilder + alloc-free predicates (plan phase E) -- untouched yet.

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

## 5. Next session queue

1. ChaCha20-Poly1305 interop root-cause + fix (top stdlib crypto defect).
2. gzip >=4096 AV + deflate empty-return joint probe with compiler session.
3. Re-run sweep after compiler round-16 lands; verify geom/array_zip/CRT/
   stack-cookie clusters flip; un-gate kdf/json/blocked KAT asserts.
4. Flip secure_random_bytes to OS entropy once cross-module miscompile fixed.
5. StringBuilder + dealloc-free predicate rewrites (phase E1-E3).
6. Legacy cipher quarantine move (phase O prep safe NOW).

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

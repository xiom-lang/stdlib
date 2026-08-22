# XIOM Stdlib Session -- Clean Handoff (2026-08-22, late night)

> Written at session end for a seamless continuation. Branch: `feat/architect`
> (HEAD = the compiler session's round-14c 135d684c + 14 stdlib commits).
> Round-14c fixed the write-back bug, generic fn-param aggregates, narrow
> casts, and the const-N map path. This session verified those, then fixed
> ~15 stdlib defects and realigned ~15 smokes. Sweep on the round-14c
> binary (mid-flight -- several of this session's fixes landed after the
> sweep passed their files): 850/907 PASS, zero hangs. A fresh sweep on
> the current tree should be ~885+.

---

## 1. Round-14c verified GREEN (compiler fixes confirmed)

- Write-back bug: the whole time.Duration battery (16 smokes incl. the
  new stress family) passes.
- Generic fn-param aggregates: probe_iter_terminals (ZipIter tuple
  predicates + find/all/any/nth through _find_via) PASSES. The by-value
  `fn(T) -> Bool` variant still degrades (probe_zip_j/k -- residual,
  stdlib uses the &-form so no impact).
- Narrow casts: smoke_string_narrow + convert_narrow_roundtrip green.
- Vec[Str] elements + runtime encoding: the internal string encoding is
  now STANDARD UTF-8 (probe: `\u{e9}` -> C3 A9; raw literals E2 91 A0
  etc. round-trip; normalize/unicode/ea_width/emoji/text2 all green).

## 2. This session's stdlib fixes (14 commits, all verified)

| Fix | Smokes unblocked |
|-----|------------------|
| RefCell.replace `self` -> `&mut self` (forgot to commit in the morning -- now d904282f) | smoke_cell_refcell_replace |
| array first/last/get/get_mut: Option[&T] is value-boxed by the mono (payload stores the VALUE, call sites auto-deref -> AV at the value's address). Switched to Option[T] (Vec.get-consistent) + derefs dropped in smokes | array_get_first_last, array_edge, array_narrow (Int paths), array_len_empty |
| unary minus on nested index (`-m[r][c]` binds the minus to the ROW -- wrong element). 10 sites parenthesized across linear/approximation/factorial/finance/numerical | (correctness; the mono &Vec[Vec[Float64]] param read bug dominates the geom/math family -- compiler-side, logged) |
| round(-3.5) is ties-away-from-zero (documented): smoke expectations realigned to -4 | math_floor_ceil_round, num_float_classify |
| sync Arc/AtomicInt/AtomicBool constructors: `ptr.write(...)` module prefix collided with the `ptr` FIELD -> phantom receiver param injected (ABI mismatch). Fixed with direct deref-assign `*(p as *Int) = v` | sync_arc_new/clone/chain, atomic_compare_exchange/swap |
| compress aggregate facade (compress.xi) had RLE-based duplicate gzip/deflate/zlib/brotli/lz4/snappy with `requires: data.len() > 0` (empty traps). Now delegates to the real sublibs (-428 lines) | stress_compress_deflate_empty/gzip_empty/lz4_roundtrip/zlib_roundtrip + the 9-smoke compress battery |
| base64url_decode ensures used the PADDED bound (len/4)*3 -- traps for unpadded url-safe input. Fixed to floor(len*3/4) | stress_encoding_base64url |
| float_to_string(2-arg) never existed (the compiler SILENTLY DROPPED the extra arg -- logged). Smoke realigned to convert.float_to_fixed_str | stress_convert_float_to_string_prec |
| serialize.is_valid_bytes was a `return true` STUB | stress_serialize_is_valid_bytes |
| str_slice/str_concat copied bytes via xiom_char_at -> `as UInt8` (multibyte truncated: C3->E9, D0->1F). Now byte_at | smoke_text2 (transliterate), the whole string family |
| str_lower/str_upper same truncation via the char path -- now byte-safe ASCII mapping (multibyte passthrough) | smoke_encoding_punycode (idna pipeline lowercases labels) |
| BinaryHeap.push/pop `self` by value -> bare data.push mutated a copy; now &mut self (the remaining peek-order divergence is the Ord interface dispatch -- compiler queue item 7, logged) | smoke_core_binary_heap (partial: len works, order still wrong -- compiler-side) |
| regex Regex.replace_all called bare `find_all(self.pattern, text)` which leaf-matched the Regex.find_all METHOD (pattern as receiver -> garbage matches). Now engine.regex_find_all(self, text) | stress_regex_replace_all + the regex battery |
| Smoke realignments: regex validation/new-pattern/find_all to the engine's documented minimal syntax (no alternation/groups; leading quantifiers + unclosed classes rejected), normalize/escape/truncate inputs from ascii-stripped to `\u{...}` escapes, byte_at OOB to 0 | regex family (6), string family (15/15 battery) |

## 3. New compiler findings logged (docs/COMPILER_BUGS.md, all with probes)

1. **By-value same-type self-method write-back** -- FIXED by round-14c.
2. **Generic fn-param aggregates** -- FIXED by round-14c (& form). Residual: by-value `fn(T) -> Bool` tuple instantiation still degrades (probe_zip_j/k).
3. **Narrow casts** -- FIXED by round-14c.
4. **Const-N arrays** -- PARTIAL (explicit-args map works). Residual: `array.len` const-N STALE across call sites (probe_stale: len(&[7,8])=2 then len(&[1,2,3,4])=2); typed [N]T annotations lose N; array.map's [N]U result type unresolved implicitly (probe_map); array_zip T001.
5. **Option[&T] payloads are value-boxed** (stdlib resolved: Option[T]).
6. **Unary minus on nested index** binds to the row (stdlib resolved with parens; compiler root remains).
7. **Nested Vec[Vec[Float64]] reads through &params garbage** (mono'd param path; the round-14c "offset+1" family) -- blocks geom/math matrix smokes.
8. **Fn-typed params returning Float64 return 0** (fn-ref wrapper i64 return) -- blocks math numerical/analysis/calculus/integral/optimization.
9. **Extra call args silently dropped** (no arg-count check on module-prefix calls).
10. **Ord[T].compare dispatch misbehaves in stdlib contexts** (heap order; user-space replica correct) -- smoke_core_binary_heap exit 4.
11. **smoke_error2 has-mid layout flip** (round-13 era, still open).

## 4. Remaining failure clusters (current tree, compiler-side unless marked)

- CRT-layout AVs (queue 5/7): smoke_iter_collect, smoke_array_sort_by,
  smoke_array_slice/fold (AV even with the Option[T] fix), smoke_convert_url,
  smoke_core_box, smoke_stress_regex_find/match_count,
  smoke_stress_serialize_jsonvalue_get/parse_nested
- json heap (0xC0000374, queue 4): json_nested, json_parse_valid,
  json_parse_nested
- stack cookie: smoke_math_edge, stress_crypto_argon2/pbkdf2 x2,
  stress_io_bufreader
- clang variants (queue 6): ptr_offset, io_copy, io_copy_file,
  io_read_int_float, hash_values, convert_escape, regex_captures x4
- mono &Vec[Vec[Float64]] reads (finding 7): geom_vec/mat/quat,
  math_finance, math_edge
- fn-typed Float64 returns (finding 8): math analysis/calculus/integral/
  numerical/optimization
- Ord dispatch (finding 10): smoke_core_binary_heap (4)
- const-N (finding 4): array_len_empty [0] case (single-literal form
  green), array_map (1), array_zip (T001), array_slice/fold AVs
- smoke_math_analysis/calculus exit -1 (crash variants of finding 8)

## 5. Key workflows (unchanged)

- **Sweep**: sweep3.ps1 (background, ~1.5h). DON'T edit stdlib files
  mid-sweep (transient mixed results -- this session's unicode-family
  false alarms).
- **Battery**: verify2.ps1 -ListFile.
- **Probes**: C:\Users\lefte\AppData\Local\Temp\kilo\*.xi
- **Conventions**:
  - stdlib files CRLF; Edit preserves on hunks; PowerShell ReadAllText/
    WriteAllText roundtrips preserve endings; git autocrlf covers the rest
  - by-value self methods that mutate must be &mut self (BinaryHeap was
    the missed one; the write-back bug's removal exposed it)
  - byte-copying string fns must use byte_at, NEVER xiom_char_at as UInt8
  - module prefixes that collide with receiver FIELDS misresolve
    (ptr.write in ptr-field types) -- use deref-assign instead
  - aggregate facade modules (compress.xi) must delegate to the sublibs,
    not re-implement
  - smokes written against the ascii-stripped era need \u{...} escapes
    for multibyte test data
  - pure-ASCII policy enforced by the commit hook

## 6. Next session's queue

1. Fresh sweep on the current tree (expect ~885+).
2. Re-test geom/math + binary_heap + array_map after the compiler's next
   round (findings 7/8/10/4).
3. Triage the remaining CRT-layout/json/stack-cookie/clang-variant items
   (their queue 4/5/6/7).
4. smoke_math_analysis/calculus/integral/numerical/optimization re-check
   once fn-typed Float64 returns land.
5. Consider extending smoke coverage for the new fixes (zip tuple
   predicates are covered by smoke_iter_find_all_any? -- probe-level only;
   a permanent smoke could be added once the compiler round settles).

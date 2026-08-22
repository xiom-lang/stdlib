# XIOM Stdlib Session -- Clean Handoff (2026-08-22, evening)

> Written at session end for a seamless continuation. Current branch:
> `feat/architect`. Compiler session works in parallel on crates/ (commits
> interleave with ours). Sweep re-run completed this session (819/907, zero
> hangs). This doc supersedes the morning handoff (committed as `700fdc56`).

---

## 1. Current state (verified 2026-08-22 evening, binary 0ba41521 round-13)

Full 907-smoke sweep re-run: **819/907 PASS, zero hangs** (trajectory 802 ->
819). The +17 = the round-13 closure/tuple wins now visible in the sweep +
this session's iter API (find/all/any/nth/last).

**This session's wins (all committed, probe-verified):**

| Family | Status |
|--------|--------|
| iter find/all/any/nth/last on Range + MapIter/FilterIter/TakeIter/SkipIter/ChainIter/ZipIter | **GREEN** (3 smokes: find_all_any, nth_last, edge) |
| sync Once (`ensures: state == 2` compared the *Int field with literal 2 -> clang reject) | **GREEN** (3 smokes: sync_once, stress_sync_once, stress_sync_once_completed) |
| error context pretty-print (Vec[Str]-element method calls -> invalid GEP) | **GREEN** (smoke_error2 -- see layout note below) |
| error wrap_error `E: Error` bound (C001 wrong-param resolution) -> bound-free | **GREEN** (error_chain, error_edge) |
| string requires on graceful fns (str_split/str_slice/replace/str_to_int/str_to_float) | **GREEN** (5 smokes: edge, parse, parse_edge, replace_edge, stress_slice_outofbounds) |
| format text/textual/fmt text_columns/format_columns (latent Vec[Str]-element GEP sites) | fixed, verified by probe_fmt_cols |

**New compiler findings logged in docs/COMPILER_BUGS.md (all with probes):**

1. **Aggregate-typed CLOSURE params corrupt on call** -- struct/tuple/Vec
   params (by value or &ref) read garbage in closures; top-level fns and
   scalar closure params are correct (probe_zip_f/c2/c3/b/e/g fail,
   probe_zip_d/c4 pass). Blocks ZipIter.find/all/any tuple predicates and
   EnumerateIter.map's latent fn((Int,T))->U path. Shipped iter API is
   correct; re-test zip-predicates once fixed.
2. **Method call on a Vec[Str] element emits invalid GEP** --
   `e.free[0].len()` / `items[i].len()` -> `getelementptr i8*, i8**,
   i32 0, i32 1` (clang reject). Str (i8*) is the only affected element
   type; struct elements (Vec[Vec[Float64]]) fine. Workaround proven:
   bind element to a local first (probe_err_ctx_g fails, h passes).
   stdlib fixed at all known sites; the compiler fix should make the
   workaround removable.
3. **smoke_error2 layout flip** -- has-mid check flips PASS/FAIL with
   unrelated stdlib code (wrap_error body change); identical chain code
   passes as a chain-only program (probe_err_chain2). Same family as the
   documented clang -O2/MSVC-CRT layout miscompiles.
4. **Multibyte char** -- `char.len_utf8(xiom_char_at(s, i))` wrong for
   2-byte chars (byte-oriented reader, BUG 26 #7 family); str_chars
   returns byte count for multibyte strings (smoke_string_slice check 25
   blocked).
5. **narrow-SIGNED zext re-confirmed** -- pop/get of negative Int16/Int8
   returns the zext pattern (35536 for -30000; probe_narrow_zext).

---

## 2. Sweep failure breakdown (88 remaining, all pre-existing)

- **CRT-layout startup AVs (-1073741819)**: smoke_array_edge/fold/
  get_first_last/slice/sort_by, smoke_iter_collect, smoke_convert_url,
  smoke_core_box, smoke_stress_regex_find/match_count,
  smoke_stress_serialize_jsonvalue_get/parse_nested -- queue items 5/7,
  stash-verified pre-existing, compiler-side.
- **Stack cookie (0xC0000409)**: smoke_math_edge, smoke_stress_crypto_
  argon2_basic/pbkdf2/pbkdf2_iterations, smoke_stress_io_bufreader.
- **json heap layer (0xC0000374)**: smoke_stress_serialize_json_nested/
  parse_valid -- queue item 4, compiler-side, their fix not landed.
- **clang variants (queue item 6)**: smoke_ptr_offset, smoke_io_copy,
  smoke_io_copy_file, smoke_io_read_int_float, smoke_hash_values,
  smoke_stress_env_constants, smoke_convert_escape, smoke_array_map,
  smoke_array_narrow, smoke_stress_regex_captures x4.
- **narrow-zext family**: smoke_collections_vec_narrow (5),
  smoke_convert_narrow_roundtrip (3), smoke_string_narrow (4).
- **Bounded/Ord builtin resolution (queue item 7)**: smoke_num_saturating
  (C001) -- compiler-side.
- **array_zip T001** ("cannot access field on non-struct type Int") --
  stale smoke or checker gap, untriaged.
- **Untriaged value-mismatch families (next session candidates)**:
  string (slice 25, truncate_indent 11, block_escape 51, normalize 1,
  byte_at_negative 2 -- chars/multibyte blocked by BUG 26 #7; the rest
  need per-file triage), time (duration_ops 2, time_normalize 2,
  stress_time_duration_add_sub 2, stress_time_duration_negative 3),
  math (analysis 14, calculus 1, finance 13, floor_ceil_round 12,
  integral 1, numerical 1, optimization 2, num_float_classify 17),
  sync (arc_new 4, arc_clone 2, arc_chain 2, atomic_compare_exchange 1,
  atomic_swap 1), geom (mat 4, quat 18, vec 57), convert (traits 47,
  utf 40), compress (deflate_empty 1, gzip_empty 1, lz4_roundtrip 1),
  misc (cell_refcell_replace 2, io_path 3, array_len_empty 3,
  convert_float_to_string_prec 1, base64url 1, regex smalls,
  serialize_is_valid_bytes 1).

---

## 3. Key workflows (unchanged)

- **Sweep**: `powershell -File C:\Users\lefte\AppData\Local\Temp\kilo\sweep3.ps1`
  (background; ~1.5h; sweep_results.csv written at the end; check
  sweep_progress.txt meanwhile)
- **Battery verify**: `verify2.ps1 -ListFile <list.txt>`
- **Compiler interaction**: log findings in docs/COMPILER_BUGS.md with
  minimal repros + user-space proof; probes live in
  C:\Users\lefte\AppData\Local\Temp\kilo\*.xi
- **Conventions that still hold**:
  - stdlib files are CRLF on disk (the Edit tool preserves CRLF when
    matching hunks, but may convert a file to LF on rewrite -- re-check
    with a byte scan and normalize after editing)
  - `requires:` traps instead of graceful Err/None -- redundant requires
    must be removed (this session: string str_split/str_slice/replace/
    str_to_int/str_to_float, sync Once ensures)
  - method call on a Vec[Str] element (`v[i].len()`) miscompiles --
    bind to a local first
  - `xiom run` lies about exit codes -- always `-o file.exe` + direct run
  - Method form dispatch; sublib prefixes; field-copy write-back;
    pure-ASCII policy (commit hook checks it)
  - Generic-bound checker resolution (C001) is compiler-side; bound-free
    forms keep the stdlib usable until the checker closes the gap
  - smoke_error2's pass/fail is layout-sensitive -- don't chase its
    value failures; verify chain/context modules with chain-only probes
    (probe_err_chain2/probe_err_ctx_a-b) instead

## 4. Next session's queue

1. Re-run the sweep after the compiler session's next round (layout
   family + heap layer + narrow-zext are their queue items 3/4/5/7).
2. Re-test ZipIter.find/all/any tuple predicates + EnumerateIter.map once
   the aggregate-closure-param fix lands.
3. Triage the untriaged value-mismatch families (string/time/math/sync
   arc/geom/convert/compress) with the probe -> log -> verify loop.
4. json_nested re-test after the heap-layer fix.

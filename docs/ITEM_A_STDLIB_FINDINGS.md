# Report to the STDLIB session -- Stage 3 Item A step 2 (compiler-lane triage)

From: compiler lane. To: stdlib session.
Status (2026-09-12, updated): the corpus-isolation fix (synthetic corpus
`use` aliases no longer leak into catalog-body contexts -- the gate now
models what a real program sees) exposed a SECOND class: **modules using
qualified aliases they never import**. 149 findings, see section Q. The
previous 0/0/1 measurement was taken with the alias leak and was too
permissive. The flip is re-pending on section Q.

## TL;DR (paste-ready)

> The corpus gate now checks each module under its OWN imports (a synthetic
> `use` list only loads modules; it no longer binds aliases for bodies). That
> exposed 149 real findings of one kind: **qualified aliases used but not
> imported** -- `xiom.os` uses `env.*`, `io.*`, `string.*` without
> `use xiom.env/io/string;`; `xiom.log` uses `io.*`; `xiom.net.https` uses
> `string.*`; `xiom.crypto`/`xiom.collections` use `malloc`/`realloc`/`free`;
> `xiom.simd` uses `math.sqrt`; `xiom.encoding` self-qualifies as
> `encoding.url_encode`. Add the missing `use` lines (full per-site list in
> section Q). Everything else (sections A-P) is still fixed. Re-measure:
> `cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture`
> (`$env:XIOM_CATALOG_DUMP='1'` for every site).

Measurement: live, both lanes; the last compiler check is 149 findings / 0
hard errors / 0 parse errors (section Q only). Nothing below is a compiler
artifact -- if a fix looks wrong, ping the compiler lane in chat before
working around it.

## Q. Missing imports / unbound aliases (149 findings)

BLOCKING THE FLIP. Groups (module:lines -> missing binding):

| Module | Sites | Missing import / fix |
|---|---|---|
| `xiom.os` | 60,95,99,105,115,121,127,327,331,335,339,639,644,694 | `use xiom.env;` (`env.set_var/remove_var/current_dir/set_current_dir/temp_dir/home_dir/var_opt/current_exe`) |
| `xiom.os` | 136,146,201,347,352,353,379,386,387,437,442,443,593,679,682,683,687 | `use xiom.io;` (`io.set_permissions/metadata/time_now/list_dir/join_paths/time_now`) |
| `xiom.os` | 202,203,223,385 | `use xiom.string;` (`string.str_concat/str_contains`) |
| `xiom.log` | 61,79,82,189 | `use xiom.io;` (`io.time_now/append_file/println/write_file`) |
| `xiom.net.https` | 80,84,140,144,180 (+88,89,93,97 cascades) | `use xiom.string;` (`string.str_slice`; the `len`/`byte_at`/compare cascades should clear once the slice type resolves) |
| `xiom.crypto` | 263,288 (+276 cascade) | bind `malloc`/`free` (`use xiom.alloc;` + `alloc.malloc/free`, or the bare helpers if alloc exports them) |
| `xiom.collections` | 40,98,136,153 | bind `realloc` (same -- alloc module) |
| `xiom.simd` | 238 | `use xiom.math;` (`math.sqrt`) |
| `xiom.encoding` | 472 | `encoding.url_encode` is a SELF-qualified call (`module xiom.encoding`); drop the qualifier or import self |

After adding imports, re-run the gate: remaining cascades (e.g. `cannot
compare <error> with Str` in net.https) should disappear with the root
unbound alias.

## P. Catalog parse diagnostics -- HARD ERRORS once the flip lands (D1)

STATUS: fixed except `xiom.time:232`. At the last check the gate reported:
`PARSE 232:29: catalog parse [xiom.time]: expected identifier, found '>'`.
Everything else in the table below is history (kept for context).

The parser recovers from syntax errors by returning a partial AST; before
D1 those diagnostics were discarded and whole declarations silently vanished
(downstream `undefined variable` cascades were the only symptom). The gate
now records and prints them and treats them as hard errors. Sites at the
original measurement (line numbers move with stdlib edits -- use the gate):

| Module:line | Diagnostic | Likely cause / fix |
|---|---|---|
| `xiom.char:211` | `expected identifier, found ''` | `'GBP'` multi-char literal (line 211); use `'G'` etc. or a `Str` compare |
| `xiom.char:213`, `:222` | `expected declaration, found '}'` | cascades of the two bad literals (211 and 220 `'+/-'`); fixing the literals clears all four |
| `xiom.collections:1749` (now 1753) | `expected declaration, found 'result'` | stray `result` + extra `}` after the fn's `return result;` |
| `xiom.convert.ascii85:212` | `expected declaration, found '}'` | stray closing brace (removed `unsafe` block left its `}`) |
| `xiom.convert.base64:210` | same | same |
| `xiom.convert.base64url:177` | same | same (verified: fn closes at 176, 177 is extra) |
| `xiom.encoding.idna:320`, `:372` | same | same |
| `xiom.sync:76` | same | same (fn closes at 75, 76 extra; verified) |
| `xiom.test.assert:152` | same | same |
| `xiom.math.finance:522` | `'var' is a reserved keyword` | `pub fn var(...)` -- rename (e.g. `value_at_risk`) |
| `xiom.path:209` | `expected declaration, found 'path'` | `ensures: result is Ok => canonical path without . or .. components` is English prose, not an expression; replace with a boolean condition (e.g. `result.is_ok`) |
| `xiom.time:226` (now 232) | `expected identifier, found '>'` | `ensures: result.is_ok <=> self.secs >= earlier.secs` -- `<=>` is NOT an XIOM operator (no spec/test/doc usage; the parser reads `<=` then chokes on `>`). STDLIB-OWNED one-line fix: `ensures: result.is_ok == (self.secs >= earlier.secs)` |

The `xiom.char` undefined-variable findings from the earlier report are
SUPERSEDED by these parse errors; nothing else needs to change there.

## A. Unsafe confinement (D2.1)

### A1. Extern call outside `unsafe` in a fn without `requires` (T002)

Rule: requirement (a) unsafe block, or (c) declare a whole-fn `requires`.
The stdlib already used both patterns elsewhere; these are the stragglers.

`xiom_char_at` (25):
```
xiom.core:94, 106, 127, 143, 156, 166
xiom.string:336, 341, 515, 567, 569
xiom.encoding:901
xiom.misc:269, 282
xiom.string.interleave:36, 41, 89
xiom.string.indent:89
xiom.string.block:144, 146, 151, 156, 168
xiom.hash:349, 367
```

`time` (libc) (14):
```
xiom.time:192, 196, 218, 297, 332, 343, 345, 350, 352, 357, 396, 600
xiom.rand:388
xiom.hash.siphash:235
```

`sqrt` (17):
```
xiom.text.similarity:430 (x2)
xiom.num:353
xiom.string.cosine:141, 142
xiom.simd.vec8:79 col 14, 52, 90, 128, 166, 204, 242, 280
xiom.simd.vec4:72 col 13, 49, 85, 121
```

`clock` (4): `xiom.rand:39, 377`, `xiom.convert.uuid:29`, `xiom.convert.mac:29`.
`atan2` (3): `xiom.math.inverse_trig:77, 83, 90`.
`floor`/`ceil` (4): `xiom.num:1039, 1040, 1104, 1105`.
`pow` (2): `xiom.num:2395, 2399`.
`xiom_popcnt64`/`xiom_clz64`/`xiom_ctz64` (3): `xiom.num:218, 227, 232`.
`xiom_byte_at` (1): `xiom.string:234`.
`xiom_asm_memcpy/memset/memcmp` (4): `xiom.mem:111, 117, 124, 130`.
`xiom_crypto_aesni_available` (2): `xiom.crypto:1456, 1514`.
`free` (1): `xiom.ffi:75`.
`xiom_getpid` (1): `xiom.process:64`.
`xiom_get_argc`/`xiom_get_argv` (2): `xiom.os.args:60, 63`.

### A2. Casts outside `unsafe` (T002 cast rule)

pointer-to-pointer (20):
```
xiom.sync:73, 356, 387 (x2), 427, 465
xiom.sync.atomics:38, 135, 176
xiom.simd:149, 167, 176, 185, 192, 201, 292, 300, 308
xiom.rc:31, 78 (x2)
```
integer-to-pointer (5): `xiom.ptr:8, 12`, `xiom.thread.park:34, 38`,
`xiom.collections:19`.
pointer-to-integer (3): `xiom.io:481`, `xiom.sync.rwlock:189`,
`xiom.sync.mutex:98`.

### A3. T003 -- safe fn returning a raw pointer (7)

`xiom.mem:110` (`mem_copy`), `116` (`mem_set`), `129` (`mem_move`);
`xiom.ptr:7` (`null`), `11` (`null_mut`), `146` (`from_ref`), `150`
(`from_mut`). Fix: `unsafe fn` (unsafe-internal helper) or return an owned
type. Note the matching call sites may need an `unsafe` block once the fn is
marked unsafe.

### A4. T007 -- whole-body `unsafe` with no `requires` (8)

`xiom.mem:9` (`swap`); `xiom.hash.siphash:164, 171, 178, 185`;
`xiom.cell:143, 167` (`release` overloads); `xiom.async:299`
(`async_yield_now`). Fix: `requires: true` (or a real precondition).

### A5. T006 -- extern raw-pointer result not converted (3)

`xiom.io:665, 675, 685`. Convert inside the block with
`ffi.safe_ptr_from_raw` / `box_from_ptr` / `vec_from_ptr_with_free` /
`str_from_ptr_owned`.

## B. Numeric mixing Int/Float (T003 no-implicit-conversion rule)

`xiom.math:129, 141`; `xiom.math.approximation:155, 156, 372, 606, 607`;
`xiom.math.trigonometry:93, 94, 108, 109`; `xiom.rand:95, 98`;
`xiom.stats.histogram:164`; `xiom.geom.polyhedra:79, 84`;
`xiom.geom.curves:118, 223`; `xiom.geom.linear:611, 693`.
Fix: explicit `as` (`Int as Float64` / narrowing casts).

## C. Type errors / invalid calls

| Site | Finding | Fix |
|---|---|---|
| `xiom.math.optimization:241` | `Bool as Float64` unsupported | `if c { 1.0 } else { 0.0 }` |
| `xiom.crypto.curves:247` | `Result[Int, Str] as UInt8` | unwrap/match first |
| `xiom.crypto.curves:329` | arg `BigInt` where `Vec[UInt8]` expected | convert |
| `xiom.crypto.cipher:1130, 1153` | arg `Result[Int, Str]` where `Int` expected | handle Result |
| `xiom.ffi.c:77` | `() as Int` | missing branch return |
| `xiom.num:1539, 1540` | `.hi` on native `Int128` | `(w >> 64) as UInt64` / `w as UInt64` |
| `xiom.collections:215, 224` | `Slice[T]{data, len}` vs declared `{data; invariant}` (line 878) | reconcile shapes |
| `xiom.os:525` | `buf.capacity()` -- no such fn/method | `buf.len()` or add a real accessor |
| `xiom.regex.syntax:48, 109, 137` | `.unwrap()` on `char_at` METHOD (`Char`, not Option) | drop unwrap or use free `xiom.string.char_at` |
| `xiom.rand:325, 327` | same `unwrap()` pattern | same |
| `xiom.compress:515, 516` | `to_char` returns `Char` (core.xi:227) -- no `.is_some`/`.value`; `xiom.string.from_char` does not exist (`convert.from_char`) | use the Option API / fix qualifier |
| `xiom.char:191, 192` | `is_currency`/`is_math_symbol` undefined: their decls (209/217) are dropped by the parser because `'GBP'` / `'+/-'` are invalid Char literals | single chars or `Str` compare (compiler-side D1 tracks the silent recovery) |
| `xiom.math.special:100` | `_pi` undefined -- module declares `_PI` (line 25) | case typo |
| `xiom.log:70` | `convert.int_to_string` without `use xiom.convert;` | add the import |
| `xiom.format.terminal:406, 422` | `convert.str_to_int` (`str_to_int` is in xiom.string) | fix qualifier |
| `xiom.hash:104, 113` | `value.hash()` with `T: Hash`: same-name `Hash` interfaces with different arities | FIXED COMPILER-SIDE (D5c: any same-name declaration whose arity fits is accepted) -- no stdlib change needed |
| `xiom.serialize.yaml_lite` | non-exhaustive match (`Scalar`/`Sequence`/`Mapping`), spans 0:0 | cover variants (compiler-side D2 tracks the span) |

Missing-return / tail-type mismatches (arm yields `()`):

```
xiom.math.numerical:1097   expected Vec[Float64]
xiom.serialize.json:108, 166  expected Result[JsonValue, Str]
xiom.convert.json:254, 289 expected Bool
xiom.os.err:150            expected Unit
xiom.ffi:502               expected Result[*UInt8, FFIError]
```

Regex cascade: once the `.unwrap()` sites are fixed, the seven
`cannot compare <error> with Char` findings (`regex.syntax:110, 115, 120,
123 (x3), 138, 141`) disappear with them.

## D. Compiler-side items (do NOT fix in stdlib)

Status after the D1/D2/D4/D5 slice:

- **D1 LANDED** -- catalog parse diagnostics are recorded and gate hard
  errors (see section P). User-facing surfacing is staged for the flip.
  **D1b LANDED** -- parser fix for tuple type args in generic struct literals
  (`MapIter[(A, B), C]{...}`); the previously dropped
  `EnumerateIter.map/take` declarations are live again.
- **D2 LANDED** -- non-exhaustive match diagnostics now carry the match
  span (was `0:0`). yaml_lite points at the match.
- **D3 NOT REPRODUCING** -- `xiom.path:204` types `e: IOError` correctly at
  HEAD (the free `metadata` wins the bare call). No action needed unless it
  reappears in the gate.
- **D4 LANDED** -- `(Fn, Fn)` structural compatibility: concrete closures
  now fill generic fn-typed struct fields (`fn(T) -> U`). The `xiom.iter`
  findings are gone.
- **D5 LANDED** -- argument-aware bare-name selection: when the first-wins
  global sig cannot accept the call, a compatible same-named pub fn is
  selected from imported items / module surfaces. `xiom.path:262`
  (`is_empty(str)`) is gone.
- **D6 OPEN** -- `ChainIter[T, U].next` returns `Option[U]` from `second()`
  where `Option[T]` is declared. If the stdlib keeps the design, the
  compiler needs a generic-relation rule; otherwise constrain `T == U`.
  This remains the only queued compiler-side item from this report.

## E. How to measure

```
cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
# every site, no collapsing:
$env:XIOM_CATALOG_DUMP='1'; cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
```

The gate flips to hard errors when the report is clean (`is_clean()` also
requires the section-P parse list to be empty). The corpus is re-measured
continuously by both lanes; run the command above for the live count. At the
D1/D2/D4/D5 compiler freeze the top classes were mixed-numeric (~27),
`regex.syntax` unwrap cascades (8), `unwrap` (5), the remaining extern/unsafe
confinement sites, plus the 14 catalog parse errors in section P (hard,
first priority).

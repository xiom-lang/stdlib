# Report to the STDLIB session -- Stage 3 Item A step 2 (compiler-lane triage)

From: compiler lane. To: stdlib session.
Status: all compiler-side artifacts fixed; **all remaining catalog-corpus
findings are stdlib-side**. The gate flips warnings -> hard errors once the
corpus is clean, so these must reach zero as well.

## TL;DR (paste-ready)

> Compiler lane finished the Item A triage. Corpus 779 -> 237 findings, all
> remaining ones are stdlib. Groups: (1) D2.1 unsafe confinement -- extern
> calls and casts outside `unsafe` in fns without `requires` (~60 sites; the
> `time`/`xiom_char_at`/`sqrt` families dominate); (2) T003 raw-pointer
> returns from safe fns (7); (3) T007 whole-body unsafe without `requires`
> (8); (4) T006 unconverted extern pointers (3); (5) numeric mixing
> Int/Float (~30); (6) missing-return/tail-type mismatches (9); (7)
> individual call/type bugs (`capacity()`, `char_at().unwrap()`,
> `'GBP'` char literals, `_pi` typo, `from_char`/`str_to_int` qualifiers,
> Int128 `.hi`, Slice shape, Hash interface arity). Full per-site list:
> docs/ITEM_A_STDLIB_FINDINGS.md. Re-measure with
> `cargo test -p xiom-check catalog_corpus_is_clean -- --ignored
> --nocapture` and `$env:XIOM_CATALOG_DUMP='1'` for every site.

Measurement: **237 findings, 0 hard errors** (count moves while both lanes
work; compiler-lane freeze commit 843a5a88 measured 235). Nothing below is a
compiler artifact -- if a fix looks wrong, ping the compiler lane in chat
before working around it.

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
| `xiom.hash:104, 113` | `value.hash()` with `T: Hash`: the module's local hasher-based `Hash` declares `hash(self, hasher)` | unify/rename the hasher interface (the code comment already flags it) |
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

Tracked in COMPILER_BUGS.md; listed here so the stdlib session knows these
findings are NOT theirs:

- **D1** catalog parse errors are swallowed: invalid `'GBP'` literals lose
  `is_currency`/`is_math_symbol` silently. Compiler will persist parse
  diagnostics on `CachedModule`.
- **D2** non-exhaustive-match spans are `0:0` (yaml_lite).
- **D3** `xiom.path:204` -- checker bound `e: Str` for
  `Result[Metadata, IOError]` (`Err(e) => e.message`); suspected
  registration-order artifact. `xiom.path:262` (`is_empty`) is the
  cross-module bare-name collision (argument-aware resolution queued).
- **D4** `xiom.iter:261, 266, 308, 328, 333, 338, 413, 433, 438, 476, 506,
  511, 516, 818, 875, 880, 885` -- generic struct-literal / higher-order
  `fn(T) -> U` substitutions; suspected checker limitation, not stdlib.
  If you keep the current generic designs, ping us and we will finish the
  substitution pass.
- **D5** same as D3 second item.
- **D6** `ChainIter[T, U].next` returns `Option[U]` where `Option[T]` is
  declared (`xiom.iter:413`) -- if the design is intentional, the compiler
  needs a generic-relation rule; otherwise constrain `T == U`.

## E. How to measure

```
cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
# every site, no collapsing:
$env:XIOM_CATALOG_DUMP='1'; cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
```

The gate flips to hard errors when the report is clean; the compiler lane
re-measures after each stdlib drop. Current measurement: 237 findings,
0 hard errors, 0 other warnings.

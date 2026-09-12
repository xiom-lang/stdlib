# Stage 3 Item A -- stdlib findings report (compiler-lane triage output)

Audience: the **stdlib session**. Everything in this file is a finding that
survives compiler-side triage and must be fixed in `stdlib/` -- the compiler
lane does not edit stdlib. The catalog-body gate flips from warning to hard
error once the corpus is clean, so these must reach zero too.

## How to measure

```
cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
# every finding, one line per site (no 1-per-class collapsing):
$env:XIOM_CATALOG_DUMP='1'; cargo test -p xiom-check catalog_corpus_is_clean -- --ignored --nocapture
```

Current status after the compiler-side artifact fixes (2026-09-12):
**235 findings, 0 hard errors** (was 19,287 / 779 / 385 across the session).
Fixed compiler-side since: alias-scoped module resolution, catalog impl
registrations (`Num[T].one()`), builtin fns through module paths
(`xiom.char.to_int_from_char`, `xiom.core.panic`), current-module ambiguity
preference, extern owner tracking, string `char_at` -> Char, interface arity
(`Self` / first-param receiver), interface `Self` return substitution,
same-name interface bound matching, generic-param receivers, G-10
implicit/explicit receiver shapes (`get(0)` and `len(self)`), local fn-typed
call parameters, `Unit` literal, `to_str` builtin. The findings below are what
remains.

## A. Unsafe confinement (D2.1) -- wrap in `unsafe` or add `requires`

T002: an extern call / cast outside `unsafe { }` in a fn that does NOT declare
`requires`/`ensures`. Sanctioned fix (requirement c): either put the operation
in an `unsafe` block, or declare a pre-entry contract on the wrapper.

| Sites | Construct | Fix |
|---|---|---|
| `xiom.core:94` | `xiom_char_at(s, 0)` | unsafe block or `requires` on wrapper |
| `xiom.string:234` | `xiom_byte_at(s, pos)` | unsafe block |
| `xiom.mem:111,117,124` | `xiom_asm_memcpy/memset/memcmp` | unsafe block or `requires` |
| `xiom.time:192` (+ more `Instant` sites) | libc `time(0)` | unsafe block or `requires` |
| `xiom.text.similarity:430` | extern `sqrt` | unsafe block or `requires` |
| `xiom.math.inverse_trig:77` (+ ~2 more) | extern `atan2` | unsafe block or `requires` |
| `xiom.rand:39` (+3) | extern `clock` | unsafe block or `requires` |
| `xiom.crypto:1456` | `xiom_crypto_aesni_available` | unsafe block or `requires` |
| `xiom.num:218,227,232` | `xiom_popcnt64/clz64/ctz64` | unsafe block or `requires` |
| `xiom.num:1039,1040` | `floor`/`ceil` | unsafe block or `requires` |
| `xiom.num:2395` | `pow` | unsafe block or `requires` |
| `xiom.process:64` | `xiom_getpid` | unsafe block |
| `xiom.os.args:60,63` | `xiom_get_argc/argv` | unsafe block |
| `xiom.ffi:75` | `free` | unsafe block |

Pointer casts in safe code (same D2.1 cast rule):

| Sites | Construct | Fix |
|---|---|---|
| ~20 occurrences (rep. `xiom.sync:73`, `xiom.sync:356,387,427,465`, `xiom.sync.atomics:38,135,176`, `xiom.simd:149,167,176,185,192,201,292,300,308`, `xiom.rc:31,78`) | pointer-to-pointer cast (`data as *UInt8`) | move into `unsafe` |
| ~5 occurrences (`xiom.ptr:8,12`, `xiom.thread.park:34,38`, `xiom.collections:19`) | integer-to-pointer cast | move into `unsafe` |
| `xiom.io:481`, `xiom.sync.rwlock:189`, `xiom.sync.mutex:98` | pointer-to-integer cast | move into `unsafe` |

T006 -- extern raw-pointer result must be converted before the unsafe tail:

| Site | Fix |
|---|---|
| `xiom.io:665,675,685` | use `ffi.safe_ptr_from_raw` / `box_from_ptr` / `vec_from_ptr_with_free` / `str_from_ptr_owned` inside the block |

T003 -- a SAFE fn must not return a raw pointer:

| Sites | Construct | Fix |
|---|---|---|
| `xiom.mem:110,116,129` | `mem_copy/mem_set/mem_move -> *UInt8` | `unsafe fn` (unsafe-internal helper) or return an owned type |
| `xiom.ptr:7,11,146,150` | `null/null_mut/from_ref/from_mut -> *T` | `unsafe fn` |

T007 -- whole-body `unsafe` block but no `requires` (requirement c):

| Sites | Fix |
|---|---|
| `xiom.mem:9` (`swap`) | add `requires: true` or real pre-conditions |
| `xiom.hash.siphash:164,171,178,185` | same |
| `xiom.cell:143` (`release`) | same |
| `xiom.async:299` (`async_yield_now`) | same |

## B. Numeric / type errors

| Site | Finding | Fix |
|---|---|---|
| `xiom.math:129` | `Float64`/`Int` mixed arithmetic | explicit `as` |
| `xiom.rand:95` | `Float64 == Int` compare | explicit `as` |
| `xiom.stats.histogram:164` | `Int`/`Float64` compare | explicit `as` |
| ~27 total mixed-numeric sites | | explicit casts |
| `xiom.math.optimization:241` | `Bool as Float64` cast unsupported | branch (`if c { 1.0 } else { 0.0 }`) |
| `xiom.crypto.curves:247` | `Result[Int, Str] as UInt8` | unwrap/match first |
| `xiom.crypto.curves:329` | arg 2: `BigInt` where `Vec[UInt8]` expected | convert first |
| `xiom.crypto.cipher:1130` | arg 2: `Result[Int, Str]` where `Int` expected | handle the Result |
| `xiom.ffi.c:77` | `() as Int` | missing return/branch value |
| `xiom.num:1539` | `w.hi` on native `Int128` (no fields) | `(w >> 64) as UInt64` / `w as UInt64` |
| `xiom.collections:215` | `Slice[T]{ data, len }` vs declared `{ data; invariant }` (line 878) | reconcile the two Slice shapes / construct the declared fields |

Missing-return / tail-type mismatches (function arm yields `()`):

| Site | Finding |
|---|---|
| `xiom.math.numerical:1097` | expected `Vec[Float64]`, found `()` |
| `xiom.serialize.json:108` | expected `Result[JsonValue, Str]`, found `()` |
| `xiom.convert.json:254` | expected `Bool`, found `()` |
| `xiom.os.err:150` | expected `Unit`, found `()` |
| `xiom.ffi:502` | expected `Result[*UInt8, FFIError]`, found `()` |

## C. Missing / invalid calls (stdlib bugs, valid-language fixes)

| Site | Finding | Fix |
|---|---|---|
| `xiom.os:525` | `buf.capacity()` -- no `capacity` exists (checker + codegen) | use `buf.len()` or a real accessor |
| `xiom.regex.syntax:48,110` | `.unwrap()` on `char_at` METHOD (method returns `Char`, free fn returns `Option[Char]`) | drop `.unwrap()` or call the free fn |
| `xiom.compress:515` | `opt.is_some` after `to_char` (returns `Char`, not `Option`) | use the Option-returning API |
| `xiom.compress:516` | `xiom.string.from_char` does not exist (`convert.from_char`) | fix qualifier |
| `xiom.char:191,192` | `is_currency` / `is_math_symbol` UNDEFINED because their declarations (lines 209/217) are dropped at parse: `'GBP'` and `'+/-'` are not valid Char literals | single chars / `Str` compare; also see compiler note D1 |
| `xiom.math.special:100` | `_pi` undefined -- the module declares `_PI` (line 25) | case typo |
| `xiom.log:70` | `convert.int_to_string` without `use xiom.convert;` | add the import (or qualify through an imported module) |
| `xiom.format.terminal:406,422` | `convert.str_to_int` (`str_to_int` lives in xiom.string) | fix qualifier |
| `xiom.hash:104,113` | `value.hash()` with `T: Hash`: the module's LOCAL hasher-based `Hash` declares `hash(self, hasher)` (arity), while the code dispatches to the concrete 0-arg methods | unify or rename the hasher-based interface; the comment there already flags the design as incomplete |
| `xiom.serialize.yaml_lite` | non-exhaustive match (`Scalar`/`Sequence`/`Mapping` not covered), spans 0:0 | cover variants; compiler note D2 |

## D. Compiler-side items found while triaging these

These are NOT stdlib work; recorded here so the compiler lane fixes its side.

1. **Catalog parse errors are swallowed.** `CachedModule::parse_file` builds
   the AST even when the parser recovered from errors, and drops the
   error list. `xiom.char:209` (`'GBP'`) therefore silently lost two
   declarations instead of failing the catalog load. Planned fix: persist
   parse diagnostics on `CachedModule` and surface/aggregate them in the
   corpus gate (and fail the load for real compiles if the module is used).
2. **`non-exhaustive match` spans `0:0`** for multi-line match expressions
   (yaml_lite) -- diagnostic span assignment gap.
3. **`metadata(...)` Result error-type binding** (`xiom.path:204`, source uses
   `Err(e) => e.message` against `Result[Metadata, IOError]`): the checker
   bound `e: Str`. Suspected checker artifact (registration order / first-wins
   bare `metadata` sig), NOT a stdlib change. Queued for the next corpus
   triage pass.
4. **Generic struct-literal field substitution** (`xiom.iter:261,266,308,328`
   `fn(T) -> U` vs `fn(Int) -> U`): container type args are not substituted
   into the field map at literal-check time. Suspected checker limitation.
5. **Cross-module bare-name collisions in the all-imports corpus**
   (rep. `xiom.path:262` `is_empty` binding `array.is_empty`): the global
   first-wins bare slot can pick a same-named fn from an unrelated module.
   Compiler-side resolution robustness item (argument-aware overload pick or
   per-module import scoping). Do NOT "fix" the stdlib call unless the stdlib
   session prefers qualification.
6. **`ChainIter[T, U].next` (`xiom.iter:413`)** returns `Option[U]` from
   `second()` where `Option[T]` is declared. Real generic typing laxity; if
   the stdlib keeps the current design, pin the types.

## E. Status snapshot (measurement run at 235)

Top classes, all stdlib-side:

```
CLS 25  extern "C" function 'xiom_char_at' requires unsafe
CLS 21  pointer-to-pointer cast requires an unsafe block
CLS 17  cannot mix Float64 with Int
CLS 17  extern "C" function 'sqrt' requires unsafe
CLS 14  extern "C" function 'time' requires unsafe
CLS 10  cannot mix Int with Float64
CLS  8  cannot compare <error> with Char (regex.syntax unwrap cascade)
CLS  5  cannot call 'unwrap' on this expression
CLS  5  integer-to-pointer cast requires unsafe
CLS  4  extern "C" function 'clock' requires unsafe
...
```

The ignored gate stays pending until this list reaches zero; the count is
re-measured by the compiler lane after each stdlib drop.

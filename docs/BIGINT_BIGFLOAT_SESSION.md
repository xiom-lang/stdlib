# XIOM -- BigInt/BigFloat Production-Grade Stdlib Session

**Version:** v0.57 | **Branch:** `feat/architect` | **Date:** 2026-08-10
**Goal:** Upgrade `xiom.bigint` to production grade and build `xiom.bigfloat` from scratch, with full contract coverage, exhaustive tests, and a categorized lib map so **parallel sessions** can work independently.
**Deliverable:** one merged commit per phase (conventional: `feat(stdlib): ...`), fast-gates green (checker 178, stdlib-exec 70, stdlib-compile 40, API-freeze green).

---

## 1. Current State (read-only inventory, 2026-08-10)

### 1.1 `stdlib/xiom/bigint.xi` (exists -- 14 KB, 44 pub fns)
- Representation: `pub type BigInt = { digits: Vec[Int]; negative: Bool; }` -- base-109 limbs, little-endian (limb 0 = least significant).
- Existing API (all `bigint_*` free functions):
  `bigint_from_int`, `bigint_from_str`, `bigint_to_str`, `bigint_add`, `bigint_sub`, `bigint_mul`, `bigint_div_mod`, `bigint_compare`, `bigint_is_zero`, `bigint_abs`, `bigint_neg`, `bigint_sign`, `bigint_mod`, `bigint_pow`, `bigint_gcd`, `bigint_shift_left`
- Private helpers: `_trim`, `_copy`, `_abs_compare`, `_BASE`, `_BASE_DIGITS`.
- Smoke: `examples/stdlib_smoke/smoke_bigint.xi` (3 assertions: parse/roundtrip, mulx2, compare).

### 1.2 `BigFloat` -- DOES NOT EXIST. Must be a NEW module.
- Decision D3 (STDLIB_EXTENSION.md SD3, APPROVED): `BigFloat` is its **own module** (NOT inside bigint.xi), built on bigint + Fraction-style internals: sign/exponent/significand, add/sub/mul/div, rounding modes, parse/format. MPFR-style transcendentals = later phase (or C-MPFR binding as a PACKAGE; stdlib = zero deps).

### 1.3 Categorization rule (Decision D4, APPROVED)
- New code goes into **category folders ONLY** (`stdlib/xiom/<category>/<lib>.xi`).
- Every module belongs to a category, even single-lib categories.
- `use xiom.bigint;` (flat aggregate) stays valid -- aggregate file lists sub-modules as `use` statements (D4b, VERIFIED).

**IMPORTANT (freeze gate):** `bigint.xi` is currently a FLAT frozen file imported as `xiom.bigint`. The freeze gate scans flat files byte-identical. **Strategy:** keep `bigint.xi` as the flat aggregate (all fns stay there, signatures unchanged) and put NEW production fns + `bigfloat.xi` in category `stdlib/xiom/num/`. See S7 for the migration-safe plan.

---

## 2. Production-Grade BigInt API (target)

All functions FREE functions in module `xiom.bigint` (consistent with existing style). Every function with a precondition gets a `requires` contract; every arithmetic function gets a `ensures` where decidable.

### 2.1 Constants
```xiom
const BIGINT_ZERO: BigInt
const BIGINT_ONE: BigInt
const BIGINT_TEN: BigInt
```

### 2.2 Constructors / conversions
```xiom
fn bigint_from_int(n: Int) -> BigInt                        // EXISTS
fn bigint_from_str(s: Str) -> Result[BigInt, Str]           // EXISTS
fn bigint_from_u64(n: UInt64) -> BigInt
fn bigint_from_hex(s: Str) -> Result[BigInt, Str]           // "ff" / "-1a"
fn bigint_from_base(s: Str, base: Int) -> Result[BigInt, Str]  // 2..36
fn bigint_to_int(b: &BigInt) -> Result[Int, Str]            // range-checked
fn bigint_to_str(b: &BigInt) -> Str                         // EXISTS
fn bigint_to_hex(b: &BigInt) -> Str
fn bigint_to_base(b: &BigInt, base: Int) -> Str
```

### 2.3 Predicates
```xiom
fn bigint_is_zero(b: &BigInt) -> Bool                       // EXISTS
fn bigint_is_one(b: &BigInt) -> Bool
fn bigint_is_even(b: &BigInt) -> Bool
fn bigint_is_odd(b: &BigInt) -> Bool
fn bigint_sign(b: &BigInt) -> Int                           // EXISTS (-1/0/1)
fn bigint_is_negative(b: &BigInt) -> Bool
```

### 2.4 Arithmetic
```xiom
fn bigint_add(a: &BigInt, b: &BigInt) -> BigInt             // EXISTS
fn bigint_sub(a: &BigInt, b: &BigInt) -> BigInt             // EXISTS
fn bigint_mul(a: &BigInt, b: &BigInt) -> BigInt             // EXISTS
fn bigint_div(a: &BigInt, b: &BigInt) -> BigInt
  requires: !bigint_is_zero(b)
fn bigint_mod(a: &BigInt, b: &BigInt) -> BigInt             // EXISTS
  requires: !bigint_is_zero(b)
fn bigint_div_mod(a: &BigInt, b: &BigInt) -> (BigInt, BigInt)  // EXISTS
  requires: !bigint_is_zero(b)
fn bigint_neg(b: &BigInt) -> BigInt                         // EXISTS
fn bigint_abs(b: &BigInt) -> BigInt                         // EXISTS
fn bigint_pow(base: &BigInt, exp: Int) -> BigInt            // EXISTS
  requires: exp >= 0
fn bigint_pow_mod(base: &BigInt, exp: &BigInt, m: &BigInt) -> BigInt
  requires: !bigint_is_zero(m)
fn bigint_sqrt(b: &BigInt) -> BigInt                        // integer sqrt, floor
  requires: !bigint_is_negative(b)
fn bigint_sqrt_rem(b: &BigInt) -> (BigInt, BigInt)          // (sqrt, remainder)
```

### 2.5 Number theory
```xiom
fn bigint_gcd(a: &BigInt, b: &BigInt) -> BigInt             // EXISTS
fn bigint_lcm(a: &BigInt, b: &BigInt) -> BigInt
fn bigint_ext_gcd(a: &BigInt, b: &BigInt) -> (BigInt, BigInt, BigInt)  // (g, x, y): a*x + b*y = g
fn bigint_is_prime(b: &BigInt) -> Bool                      // Miller-Rabin (deterministic for < 3.3e24, probabilistic above)
fn bigint_next_prime(b: &BigInt) -> BigInt
fn bigint_factorial(n: Int) -> BigInt
  requires: n >= 0
fn bigint_binomial(n: Int, k: Int) -> BigInt
  requires: n >= 0
  requires: k >= 0
  requires: k <= n
fn bigint_fibonacci(n: Int) -> BigInt
  requires: n >= 0
```

### 2.6 Bitwise
```xiom
fn bigint_bit_and(a: &BigInt, b: &BigInt) -> BigInt         // two's-complement semantics
fn bigint_bit_or(a: &BigInt, b: &BigInt) -> BigInt
fn bigint_bit_xor(a: &BigInt, b: &BigInt) -> BigInt
fn bigint_shift_left(b: &BigInt, n: Int) -> BigInt          // EXISTS
  requires: n >= 0
fn bigint_shift_right(b: &BigInt, n: Int) -> BigInt
  requires: n >= 0
fn bigint_popcount(b: &BigInt) -> Int                       // for b >= 0
fn bigint_bit_len(b: &BigInt) -> Int                        // bits needed to represent |b|
```

### 2.7 Comparison
```xiom
fn bigint_compare(a: &BigInt, b: &BigInt) -> Int            // EXISTS (-1/0/1)
fn bigint_eq(a: &BigInt, b: &BigInt) -> Bool
fn bigint_lt(a: &BigInt, b: &BigInt) -> Bool
fn bigint_le(a: &BigInt, b: &BigInt) -> Bool
fn bigint_gt(a: &BigInt, b: &BigInt) -> Bool
fn bigint_ge(a: &BigInt, b: &BigInt) -> Bool
```

### 2.8 Contracts (requires/ensures -- compiler-enforced)
- All div-family: `requires: !bigint_is_zero(b)`.
- `bigint_pow`: `requires: exp >= 0`.
- `bigint_from_base`: `requires: base >= 2 && base <= 36`.
- `bigint_mul` ensures (example): `ensures: bigint_eq(&result, &bigint_mul(a, b))` is NOT decidable cheaply -- instead use property tests (S5) for correctness; contracts cover preconditions + cheap invariants (`ensures: bigint_is_zero(&bigint_mod(&result, &bigint_from_int(10)))` style only where meaningful).

---

## 3. Production-Grade BigFloat API (target -- NEW module `xiom.bigfloat`)

Decision D3: `BigFloat` is its **own module** built on bigint. Recommendation: **`stdlib/xiom/num/bigfloat.xi`** (category `num`), aggregate re-export from flat `num.xi` (already exists as aggregate? -- verify; if `num.xi` is a flat frozen file, create `stdlib/xiom/bigfloat.xi` flat aggregate instead -- see S7 rule).

### 3.1 Representation
```xiom
pub enum RoundMode {
  Nearest,   // round to nearest, ties to even
  Up,        // round toward +inf
  Down,      // round toward -inf
  Zero,      // round toward zero
}

pub type BigFloat = {
  sign: Bool;          // false = positive, true = negative
  exponent: Int;       // power of 2 (or 10 -- DECIDE: power-of-10 keeps parse/format simple; see S3.2)
  significand: BigInt; // mantissa, normalized (no trailing zeros)
  precision: Int;      // bits (or decimal digits) of precision
}
```

### 3.2 Design decision -- radix
- **Option A (power-of-10, like BigInt's base-109):** parse/format trivial, arithmetic needs digit-shift normalization.
- **Option B (power-of-2, IEEE-754 style):** efficient rounding/shifts, format needs radix conversion.
- **RECOMMENDATION: power-of-10 with `exponent` = decimal exponent and `significand` an integer BigInt** (matches BigInt base-109, parse/format are string-level, arithmetic is schoolbook on BigInt). Transcendentals later (MPFR binding package) regardless.

### 3.3 Constants
```xiom
const BIGFLOAT_ZERO: BigFloat
const BIGFLOAT_ONE: BigFloat
const BIGFLOAT_TWO: BigFloat
const BIGFLOAT_TEN: BigFloat
const BIGFLOAT_HALF: BigFloat
const BIGFLOAT_PI: BigFloat        // 3.14159... (100 digits, computed once)
const BIGFLOAT_E: BigFloat         // 2.71828... (100 digits)
```

### 3.4 Constructors / conversions
```xiom
fn bigfloat_from_int(n: Int) -> BigFloat
fn bigfloat_from_float(f: Float64) -> BigFloat
fn bigfloat_from_str(s: Str) -> Result[BigFloat, Str]       // "3.14159", "-1e-10", "2.5E+3"
fn bigfloat_from_bigint(b: &BigInt) -> BigFloat
fn bigfloat_with_precision(n: Int, precision: Int) -> BigFloat  // requires precision >= 1
fn bigfloat_to_str(f: &BigFloat) -> Str                     // shortest round-trip
fn bigfloat_to_str_prec(f: &BigFloat, digits: Int) -> Str   // requires digits >= 1
fn bigfloat_to_float64(f: &BigFloat) -> Float64             // range-checked -> Result? (decide: return Option[Float64])
fn bigfloat_to_bigint(f: &BigFloat) -> BigInt               // truncates toward zero
```

### 3.5 Predicates
```xiom
fn bigfloat_is_zero(f: &BigFloat) -> Bool
fn bigfloat_is_negative(f: &BigFloat) -> Bool
fn bigfloat_sign(f: &BigFloat) -> Int
fn bigfloat_precision(f: &BigFloat) -> Int
```

### 3.6 Arithmetic (all honor `precision` = max of operands)
```xiom
fn bigfloat_add(a: &BigFloat, b: &BigFloat) -> BigFloat
fn bigfloat_sub(a: &BigFloat, b: &BigFloat) -> BigFloat
fn bigfloat_mul(a: &BigFloat, b: &BigFloat) -> BigFloat
fn bigfloat_div(a: &BigFloat, b: &BigFloat) -> BigFloat
  requires: !bigfloat_is_zero(b)
fn bigfloat_neg(f: &BigFloat) -> BigFloat
fn bigfloat_abs(f: &BigFloat) -> BigFloat
fn bigfloat_inv(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_zero(f)
fn bigfloat_sqrt(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(f)
fn bigfloat_floor(f: &BigFloat) -> BigFloat
fn bigfloat_ceil(f: &BigFloat) -> BigFloat
fn bigfloat_round(f: &BigFloat) -> BigFloat                 // ties-to-even
fn bigfloat_trunc(f: &BigFloat) -> BigFloat
fn bigfloat_fract(f: &BigFloat) -> BigFloat                 // fractional part
fn bigfloat_pow(base: &BigFloat, exp: Int) -> BigFloat
  requires: exp >= 0
fn bigfloat_compare(a: &BigFloat, b: &BigFloat) -> Int
fn bigfloat_eq(a: &BigFloat, b: &BigFloat) -> Bool
fn bigfloat_lt(a: &BigFloat, b: &BigFloat) -> Bool
fn bigfloat_le(a: &BigFloat, b: &BigFloat) -> Bool
fn bigfloat_gt(a: &BigFloat, b: &BigFloat) -> Bool
fn bigfloat_ge(a: &BigFloat, b: &BigFloat) -> Bool
```

### 3.7 Rounding
```xiom
fn bigfloat_set_round_mode(mode: RoundMode)          // thread-local default for ops
fn bigfloat_get_round_mode() -> RoundMode
fn bigfloat_with_rounding(f: &BigFloat, mode: RoundMode, digits: Int) -> BigFloat
```

### 3.8 Transcendentals -- LATER PHASE (do NOT implement in this session unless time permits)
`bigfloat_exp`, `bigfloat_ln`, `bigfloat_log10`, `bigfloat_sin`, `bigfloat_cos`, `bigfloat_tan`, `bigfloat_atan`, `bigfloat_atan2`, `bigfloat_pi(precision)`, `bigfloat_e(precision)` -- MPFR-style series/argument reduction. **Plan them in the doc; implement in a follow-up session** (or as a C-MPFR PACKAGE per D3).

---

## 4. File Layout & Category Placement

### 4.1 Target tree (categorization rule D4)
```
stdlib/xiom/
|-- bigint.xi          (FLAT AGGREGATE -- stays; freeze gate)
|     module xiom.bigint
|     use xiom.num.bigint;      <- NEW home for production code (or keep all in flat? SEE 4.2)
|-- bigfloat.xi        (FLAT AGGREGATE -- NEW, mirrors bigint.xi pattern)
|     module xiom.bigfloat
|     use xiom.num.bigfloat;
`-- num/               (category)
    |-- bigint.xi      (PRODUCTION BigInt -- move/extend HERE)
    `-- bigfloat.xi    (PRODUCTION BigFloat)
```

### 4.2 Migration decision (READ FIRST -- freeze-gate constraint)
The API-freeze gate scans FLAT files for byte-identical signatures. Two options:

- **Option 1 (recommended for THIS session):** keep ALL functions in the flat
  `bigint.xi` (extend it in place; existing signatures untouched -> freeze green).
  Put ONLY `bigfloat.xi` in category `num/` (new file, no freeze impact) with a
  flat aggregate `bigfloat.xi` at root (D4b pattern: `use xiom.num.bigfloat;`).
- **Option 2 (cleaner long-term, more churn):** move bigint production code to
  `num/bigint.xi`, keep flat `bigint.xi` as aggregate re-export. Requires
  freeze-gate-compatible refactor (flat keeps signature + delegates) -- the
  documented migration path (D4). **Verify the aggregate-use pattern against the
  freeze gate BEFORE choosing.**

**Session default: Option 1.** New fns are additive (no signature churn), BigFloat
lives in `num/` + flat aggregate. Freeze stays green.

---

## 5. Test Plan (must all pass before commit)

### 5.1 Extend `examples/stdlib_smoke/smoke_bigint.xi` (keep existing 3 assertions)
Add property-style checks (values chosen to avoid full property fuzzing):
1. `bigint_from_str("0")` -> "0", `is_zero` true.
2. `bigint_from_str("-9999999999999999999999")` round-trips.
3. `bigint_from_hex("ff")` -> "255"; `bigint_from_hex("-1a")` -> "-26".
4. `bigint_from_base("zz", 36)` -> "1295" (35*36+35).
5. add/sub commutativity + identity: `a + 0 == a`, `a - a == 0`.
6. mul by 10: `bigint_mul(&b, bigint_from_int(10))` shifts decimal digits.
7. div_mod: `(q, r) = div_mod(a, b)` => `q*b + r == a && 0 <= r < |b|` (for positive b).
8. pow: `bigint_pow(2, 10) == 1024`.
9. pow_mod: `bigint_pow_mod(2, 10, 1000) == 24`.
10. sqrt: `bigint_sqrt(81) == 9`; `bigint_sqrt_rem(82) == (9, 1)`.
11. gcd/lcm: gcd(48, 18) == 6; lcm(4, 6) == 12.
12. ext_gcd: `4*5 + 6*(-3) == 2`? (use small: gcd(10,6): 10*(-1)+6*2=2).
13. is_prime: 2,3,5,7,11,13 prime; 4,9,15,21 composite; 97 prime.
14. next_prime(14) == 17.
15. factorial(5) == 120; binomial(10,3) == 120; fibonacci(10) == 55.
16. bit ops: and(0b1100, 0b1010) == 0b1000; or/ xor; shl(1,3) == 8; shr(8,3) == 1; popcount(0b1011) == 3; bit_len(255) == 8.
17. to_int range: `bigint_to_int(&bigint_from_int(42))` -> Ok(42); huge -> Err.
18. Comparison chain: -5 < -1 < 0 < 1 < 5.

### 5.2 New `examples/stdlib_smoke/smoke_bigfloat.xi` (~30 assertions)
1. `bigfloat_from_str("3.14")` -> to_str round-trips "3.14".
2. `bigfloat_from_str("-1e-10")` round-trips.
3. add: 0.1 + 0.2 at precision 60 digits -> 0.3 (exact at this precision).
4. mul: 1.5 * 2 == 3.0; div: 1.0 / 3.0 * 3.0 ~= 1.0 within precision.
5. sqrt(2)^2 ~= 2 within precision.
6. floor/ceil/round/trunc/fract on -3.7, 3.7, -0.5, 0.5 (ties-to-even: round(2.5)=2, round(3.5)=4).
7. comparisons: 0.1 < 0.2; -1.5 < 1.5; eq after normalize.
8. precision honored: with_precision(1.0, 10) ops stay within 10 digits.
9. from_bigint/to_bigint: 2.5 -> 2 (trunc); -2.5 -> -2.
10. inv(2) == 0.5; pow(2, 10) == 1024.0.
11. to_float64(3.14) ~= 3.14 within f64 eps.
12. Constants: BIGFLOAT_PI starts "3.14159"; BIGFLOAT_E starts "2.71828".

### 5.3 Fast gates (MANDATORY before commit)
- `cargo test -p xiom-check --lib` -> 178/178
- `cargo test -p xiom-codegen --test stdlib_execution_tests` -> 70+ (new smokes included; complex+net pre-existing failures OK)
- `cargo test -p xiom-codegen --test stdlib_tests` -> 40/40
- API-freeze suite (if runnable standalone) -> green

---

## 6. Phased Execution Plan (commit per phase)

### Phase A -- BigInt production extension (in flat `bigint.xi`, additive)
1. Add constants `BIGINT_ZERO/ONE/TEN`.
2. Add constructors: `from_u64`, `from_hex`, `from_base`, `to_int`, `to_hex`, `to_base`.
3. Add predicates: `is_one`, `is_even`, `is_odd`, `is_negative`.
4. Add arithmetic: `div`, `pow_mod`, `sqrt`, `sqrt_rem` (schoolbook: Newton for sqrt).
5. Add number theory: `lcm`, `ext_gcd`, `is_prime` (Miller-Rabin with small bases + deterministic below 3.3e24), `next_prime`, `factorial`, `binomial`, `fibonacci`.
6. Add bitwise: `bit_and/or/xor`, `shift_right`, `popcount`, `bit_len` (two's-complement semantics for negatives -- decide + document).
7. Add comparisons: `eq/lt/le/gt/ge` (wrap `compare`).
8. Extend smoke_bigint.xi (S5.1). Run fast gates. **COMMIT** `feat(stdlib): production BigInt -- full arithmetic, number theory, bitwise, base conversion, contracts + smoke`.

### Phase B -- BigFloat core (NEW `stdlib/xiom/num/bigfloat.xi` + flat aggregate)
1. `RoundMode` enum + thread-local default (runtime global `var` + set/get).
2. `BigFloat` type (power-of-10: sign, exponent, significand BigInt, precision).
3. Normalization: `_normalize` (strip trailing zeros, adjust exponent).
4. Constructors: from_int/float/str/bigint, with_precision.
5. to_str / to_str_prec / to_float64 / to_bigint.
6. Arithmetic: add/sub (align exponents), mul/div (BigInt op + exponent math), neg/abs/inv.
7. Rounding: with_rounding (Nearest/Up/Down/Zero), floor/ceil/round/trunc/fract.
8. sqrt (Newton on significand), pow (Int exp).
9. Comparisons.
10. `smoke_bigfloat.xi` (S5.2). Fast gates. **COMMIT** `feat(stdlib): BigFloat -- arbitrary-precision float core (add/sub/mul/div/sqrt/rounding/parse/format)`.

### Phase C -- Transcendentals (OPTIONAL this session; else plan doc)
- `pi(precision)`, `e(precision)` via series (Machin for pi, Taylor for e).
- exp/ln/log10/sin/cos/tan/atan via series with argument reduction.
- If skipped: add a `TODO` block in bigfloat.xi documenting the planned signatures so a follow-up session picks it up without re-design.

---

## 7. Parallel-Work Categorization Map (ALL stdlib libs)

The rest of the stdlib is already categorized; independent sessions can pick any
unclaimed lib family below. **Do not touch** flat frozen files (`core`, `string`,
`collections`, `io`, `math`...) unless the task explicitly requires it -- the API-freeze
gate scans them.

### 7.1 Existing categories (D4 tree as of 2026-08-10)
| Category | Libs | Status |
|----------|------|--------|
| `num/` | convert.xi (+ this session: bigint.xi, bigfloat.xi) | PARTIAL -- bigint basic done; bigfloat NEW |
| `math/` | core.xi | DONE |
| `text/` | similarity.xi | DONE |
| `collect/` | cache, graph, hash, heap, queue, tree | DONE |
| `hash/` | city, crc, jenkins, murmur, xxhash | DONE |
| `format/` | dump, number | DONE |
| `os/` | fs, proc, term | DONE |
| `net/` | dns, proto, url | DONE |
| `rand/` | chacha, mt19937, pcg | DONE |

### 7.2 Flat frozen files (aggregate/root -- freeze-gated, DO NOT extend with NEW libs)
`aes, alloc, array, async, bench, bigint, bits, cell, chacha, char, cmp, collections, complex, compress, contracts, convert, core, crypto, debug, des, ecc, encoding, env, error, ffi, fmt, geom, hash, io, iter, log, math, md5, mem, misc, net, num, os, path, platform, poly1305, process, ptr, rand, rc, reflect, regex, rsa, search, serialize, sha, simd, sort, stats, string, sync, test, thread, time, utf8`

### 7.3 Candidate parallel sessions (unclaimed production-grade gaps -- pick ONE per session)
| # | Session | Scope | Depends on | Est. |
|---|---------|-------|-----------|------|
| S1 | **BigInt production** (THIS doc) | S6 Phase A | -- | 1 session |
| S2 | **BigFloat core** (THIS doc) | S6 Phase B | S1 (bigint) | 1 session |
| S3 | **BigFloat transcendentals** | S6 Phase C | S2 | 1-2 sessions |
| S4 | Decimal/`Fixed[N]` | fixed-point decimal (money-safe) | -- | 1 session |
| S5 | Interval arithmetic | `interval.xi` for verified numerics | bigfloat | 1 session |
| S6 | Rationals | `rational.xi` (fraction arithmetic) | bigint | 1 session |
| S7 | Matrix/vector algebra | `linalg.xi` (from geom) | -- | 1 session |
| S8 | Statistics hardening | `stats.xi` (distributions, moments) | -- | 1 session |
| S9 | Units/dimensional analysis | `units.xi` | -- | 1 session |
| S10 | Date/time ISO8601 hardening | `time.xi` extensions | -- | 1 session |
| S11 | Serialization v2 (bincode-style) | `serialize.xi` binary formats | -- | 1 session |
| S12 | Compression suite | `compress.xi` (deflate/gzip/lz4) | -- | 1 session |

**Rule:** every parallel session works on a DIFFERENT category; shared dependencies
are read-only. Each session commits its own phase with fast-gates green.

---

## 8. Constraints & Gates (non-negotiable)

1. **Docs-only? NO -- this session WRITES CODE** (unlike the doc-update session). The
   only doc updates here are `AI_CONTEXT.md` S8 additions IF new public API lands
   (BigFloat module section) -- add a `### 8.x bigfloat` block mirroring S8.31 style.
2. `stdlib` must stay **zero-dependency** (no C MPFR; pure XIOM).
3. New public functions go into category folders OR the flat bigint aggregate --
   never into frozen flat files of OTHER modules.
4. Every pub fn: type-annotated params/return, `requires` where a precondition
   exists, doc comment.
5. Fast gates green before commit (S5.3); commit per phase with conventional
   message; verify stdlib-compile (40) -- the bigint/bigfloat fns must compile in
   the monolithic stdlib build.
6. Do NOT touch `xiom-benchmark-chaos/` or `.xiom_ai.json`.
7. Selfhost tests stay `#[ignore]`d. e2e only at phase boundaries if time permits.
8. BigFloat radix = **power-of-10** (per S3.2 recommendation) -- unless a strong
   argument for power-of-2 is made in the session; if so, document the change in
   STDLIB_EXTENSION.md D3 before implementing.

---

## 9. Definition of Done

- [ ] All S2 API present in `xiom.bigint` with contracts.
- [ ] All S3 core API present in `xiom.bigfloat` with contracts (transcendentals may be TODO-documented).
- [ ] `smoke_bigint.xi` >= 20 assertions; `smoke_bigfloat.xi` >= 30 assertions; both pass.
- [ ] checker 178/178, stdlib-exec >= 70, stdlib-compile 40/40, freeze green.
- [ ] `AI_CONTEXT.md` updated with `bigfloat` module section (and any new bigint fns noted).
- [ ] One commit per phase (A, B, [C]).

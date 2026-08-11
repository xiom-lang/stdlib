# XIOM Stdlib Session — Clean Handoff (2026-08-11)

> Written at session end for a seamless continuation. Current branch:
> `feat/architect`. Compiler session works in parallel on crates/ (commits
> interleave with ours). All gates green at handoff.

---

## 1. What was delivered (all committed, gates green)

| Commit | Content |
|--------|---------|
| `dc1dd8e4` | **Phase A — production BigInt** (additive, ~40 new pub fns): constants-as-constructors (`bigint_zero/one/two/ten`), `from_u64` (full 0..2^64-1), `from_hex`/`from_base(2..36)`/`to_hex`/`to_base`, range-checked `to_int`, predicates, `div`, `pow_mod`, `sqrt`/`sqrt_rem`, `lcm`, `ext_gcd`, Miller-Rabin `is_prime`, `next_prime`, `factorial`, `binomial`, `fibonacci`, two's-complement bit ops (`bit_and/or/xor`, arithmetic `shift_right`, `popcount`, `bit_len`), comparison wrappers. **`bigint_div_mod` reworked to Knuth Algorithm D** (D1 normalization, D4-refined qhat with window `(u[idx+1], u[idx])`, D7 denormalization, single-limb schoolbook fast path, upward fixup, **top-limb-zero digit test** — see §4). |
| `dc1dd8e4` | **Phase B — production BigFloat** (`stdlib/xiom/num/bigfloat.xi` + flat aggregate `bigfloat.xi`): power-of-10 representation `sign × significand × 10^exponent` (normalized), `RoundMode` (Nearest ties-to-even/Up/Down/Zero) + module default, constructors (`from_int/float/str/bigint/with_precision`), string-exact `to_str`/`to_str_prec`, `to_bigint`, range-checked `to_float64`, add/sub/mul/div/inv/sqrt/pow/neg/abs, floor/ceil/round/trunc/fract, `with_rounding`, comparisons, `bigfloat_pi()`/`e()` (100-digit string constants). All arithmetic rounds to max(operand precisions). |
| `de756136` | **Phase C — transcendentals**: `pi_with_precision` (Machin), `e_with_precision` (Taylor), `exp` (ln10 reduction + exact 10^k scaling), `ln` (m·10^k extraction + √10 reduction + atanh), `log10`, `sin/cos` (π/2 quadrant reduction), `tan`, `atan` (argument-halving identity), `atan2`, `pow_bf` (exp(exp·ln(base))). Working precision = max(operand precisions, 64) + 4 guard digits; O(prec²) series. |
| `bb06b37c` | **Perf: BigInt Karatsuba** (`_abs_mul_karatsuba`), threshold **4000 limbs** (measured: schoolbook wins < ~10k digits, equal at 10k, karatsuba ~12% faster at 100k digits — by-value Vec semantics make the crossover high). |
| `437592e6` | **Phase C.5**: `log2`, `exp2`, `cbrt`, `hypot`, `sinh/cosh/tanh`, `asin/acos` (exact endpoints), `asinh/acosh/atanh`, `to_str_sci`, `from_ratio`, `pow10` (exact exponent shift), `floor_int/ceil_int/round_int/trunc_int`. Plus the **Knuth div_mod top-limb fix** (§4). |
| `afe871a6` | **misc expansion** (23 fns): `damerau_levenshtein_distance` (OSA), `jaro_similarity`, `jaro_winkler_similarity`, `hamming_distance`, `longest_common_subsequence`, `to_camel/pascal/snake/kebab_case` (camelCase-boundary aware), `to_roman`/`from_roman` (1..3999), `ordinal`, `pluralize`, `is_anagram`, temperature/length units, `human_size`. |
| `1cfcb01b` | **hash**: `xxhash64` (canonical, verified against a clang-built C reference) + `fnv1_32`. |
| `605bb985` | AI_CONTEXT.md §8.41–8.45 (bigint, bigfloat, C.5, misc, hash). |

**Gates at handoff:** stdlib-exec **72/72**, stdlib_tests **40/40**, API-freeze **2/2**.
Smokes (all exit 0): `smoke_bigint.xi` (21 sections), `smoke_bigfloat.xi` (55 sections),
`smoke_misc.xi` (8 sections), `smoke_hash2.xi` (13 sections).

**Stdlib size:** 64+ modules, ~2,215 pub fns (flat ~1,934 + folder modules).

---

## 2. STDLIB_EXTENSION.md — the big audit (next major workstream)

The doc (5,300+ lines) has: the master plan (§1-12, mostly accurate) and a huge
flat wish-list (HASHING / COLLECTIONS / STRING / CONVERSION / NETWORK / FILE
FORMATS, lines 388+) that needs **categorization + duplicate detection** and a
**status refresh** (§10 says "60 modules, 1,922 fns" — now 64+/~2,215; Phases
C/C.5/Karatsuba not mentioned).

### THE RULE (user-mandated, applies to every wish-list item)

- **STDLIB**: implementable with **ZERO external dependencies** — pure XIOM,
  plus SIMD/C-FFI/ASM **for performance/optimization only** (the §7 pattern:
  asm hot path + pure-XIOM fallback + runtime dispatch). Examples that belong
  in stdlib: all math, hashing, collections, string, conversion, text metrics,
  compress, rand, crypto primitives.
- **PACKAGES** (ignore for the stdlib audit): anything that **requires an
  external dependency/library** — vulkan, directx12, tensorflow, sqlite
  bindings, openssl, etc. (the FFI-bound 51 in §8.1 + the placeholders that
  wrap C libs).
- **Categories with even ONE sublib are created now** — `stdlib/xiom/<cat>/`
  folder + flat aggregate manifest — because this allows future expansion
  (new sublibs) **without breaking packages that `use xiom.<cat>`**. The
  stdlib is pre-public so we pay the cost now.
- Existing folder categories (D4 pattern): `collect/`, `format/`, `hash/`,
  `math/`, `net/`, `num/`, `os/`, `rand/`, `text/` (see §5 for contents).

### Audit method (suggested, docs-only — perfect agent fan-out)

For each wish-list item (`net/tcp`, `collect/rbtree`, `conv/base58`, ...):
1. **HAVE** → map to the existing module/fn (note the name + module).
2. **GAP** → decide STDLIB (pure XIOM, zero deps) vs PACKAGE (external dep).
3. Duplicate detection: e.g. `str/compare`→`cmp`, `str/search`→`string.index_of`,
   `conv/base64`→`encoding`, `hash/crc`→`hash.crc32_ieee`,
   `collect/vector`→`collections.Vec`, `str/regex`→`regex`, `conv/uuid`→`rand.uuid_v4`.
4. Produce a categorized table: Category → Sublibs → Items (HAVE/GAP/PACKAGE).
5. Refresh §10 status block with current numbers.

---

## 3. Remaining stdlib work (priority order)

1. **printf/scanf-style formatting (G13, the last named gap).** Verified
   missing: no `sprintf`/`sscanf` anywhere. Add `fmt.sprintf(spec, ...)` +
   `fmt.sscanf` with `%d/%x/%f/%s/%e/%g` (implement with `format1..9` +
   string ops). Also check `format/` folder (10 fns) for hexdump/table/wrap
   gaps vs the wish-list.
2. **256-bit framing (user note).** BigInt/BigFloat are arbitrary precision
   (cover 256+). Add the explicit bridge: `bigint_to_i128`/`bigint_to_u128`/
   `bigint_to_u64` (bigint has `to_int` only), `bigfloat_to_float128`, and a
   doc note in AI_CONTEXT §8.41.
3. **Generics audit (user note).** Review where generics are used vs not —
   especially `math` (the biggest family; 186 fns in geom, 52 in math flat +
   folder). Math should stay `Float64`-specialized (native f64 ABI) but verify
   `num`/`bits`/`geom` use generics where semantically right (Vec[T],
   Complex[T] patterns exist). Document the policy in the audit.
4. **CI wiring:** `smoke_bigfloat`, `smoke_misc`, `smoke_hash2` are manual-only
   (the harness list lives in crates/ — ask the compiler session to add them,
   like they did `smoke_bigint`).
5. **NASM/SIMD §7 tracks** (math/crypto/hash/compress asm): compiler/runtime
   session domain (crates/ + stdlib/runtime/*.c are OFF-LIMITS to us). Pure
   fallbacks exist. BUG 2/3 fix would also enable π/ln10 precision caching in
   bigfloat.

---

## 4. Stdlib bugs found & fixed in these sessions (log for future reference)

- **Knuth div_mod**: (a) estimator window must be `(u[idx+1], u[idx])` not
  `(u[idx], u[idx-1])`; (b) when the remainder's top limb is zero the true
  digit is 0-or-1 — the estimator returns **-1** and div_mod tests
  `r >= v·B^shift` directly (a guessed 0 is an uncorrectable underestimate at
  that position's weight; the final fixup only repairs the bottom). Both
  verified against 64-nines/10^44 and bigfloat rounding cases.
- **`str_index_of` returns `Option[Int]`** — never compare it to Int directly;
  unwrap with `match { Some(v) => ..., None => ... }` (garbage index → OOB
  slice → AV).
- **`_rotl64` mask**: keep the low `c` bits (`mask = (1 << c) - 1`), and
  avalanche shifts must be masked (`(x >> n) & ((1 << (64-n)) - 1)`) since i64
  `>>` is arithmetic.
- **XXH64 round** is `rotl(acc + input·P2, 31)·P1` (not the XXH32-style
  double-rotate).
- Smoke-writing rules learned: `str_slice(s, 0, 6)` is 6 chars; `requires`
  violations TRAP at entry (don't call fns with out-of-contract args in
  smokes); `core.to_string` on Float64 truncates (fptosi) — use comparisons or
  scaled-integer prints; match arms must match the enum type (Option vs
  Result); don't chain `.len()` on module-qualified Str-returning calls (bind
  to a var first).

---

## 5. Module inventory for the audit (current reality)

Flat modules (pub fn counts, 2026-08-11): bigint 52, num 243, math 52, geom
186 (folder), collections 57, string 45, time 59, sync 66, io 51, ffi 47,
iter 44, char 42, os 41, core 54, rand 31, serialize 31, log 31, array 28,
bits 28, encoding 24, reflect 24, regex 22, hash 23 (+15 folder), stats 23,
cmp 22, sort 20, complex 20, mem 18, path 28, alloc 15, cell 16, rc 15,
platform 14, env 28, error 11, debug 10, misc 33, process 10, utf8 8, search 8,
aes 7, crypto 25, sha 23, ecc 16, compress 28, contracts 34, test 30, fmt 28,
simd 26, thread 22, convert 8, md5 2, des 4, chacha 4, poly1305 1, rsa 6,
bigfloat 40+ (num/bigfloat.xi), async 27, bench 16.

Folder categories (D4): `collect/` (cache, graph, hash, heap, queue, tree — 81
fns: Avl, Bst, PHeap, FibHeap, WorkQueue, Deque, BloomFilter, LhMap), `format/`
(10), `hash/` (15), `math/` (11), `net/` (26: url, dns, proto...), `num/` (82:
bigfloat, convert...), `os/` (26), `rand/` (19: chacha, mt19937, pcg), `text/` (11).

**Verified GAPs (from §6 wish-list):** printf/scanf (G13), murmur3_128,
xxhash128/XXH3, city/highway/spooky/t1ha/metro/farm/jenkins hashes, base58/62,
ascii85, uuencode/xxencode, quoted-printable, punycode, skiplist, trie, radix
tree, cuckoo, LFU/ARC/TinyLFU caches, fenwick, sparse/dense sets, HAMT,
interval/range/KD/octree/quadtree, union-find, object pool, mpmc/mpsc/spmc/spsc
queues, metaphone, n-gram similarity, cosine/jaccard similarity, lcp/lcsuffix,
tr/rot/caesar/atbash ciphers, wrap/indent/align (check `format/` first),
strftime/strptime, base-N string parsing. Each must be classified STDLIB vs
PACKAGE per §2.

---

## 6. Agent workflow rules (user-mandated, apply to all bulk work)

1. Agents work **in bulk**; commit **ONLY** `stdlib/xiom/**` + the smoke files
   they write to verify their sublibs (`examples/stdlib_smoke/`). Docs updates
   to AI_CONTEXT/STDLIB_EXTENSION per batch.
2. **Compiler bug encountered?** Do NOT work around it. Append a dated section
   to `docs/COMPILER_BUGS.md` (file, construct, error, repro, impact) and
   either stop for the compiler session or — if the batch can continue without
   the broken construct — leave a `// TODO(compiler): ...` comment in the
   module and continue the batch.
3. Verify before commit: manual smoke exit 0 (`target/debug/xiom.exe -o x.exe
   <smoke>; ./x.exe`), plus `cargo test -p xiom-codegen --test stdlib_tests`
   (40/40) and `--test stdlib_api_freeze_tests` (2/2). Run
   `--test stdlib_execution_tests` (72/72) after multi-module batches.
4. Contracts (`requires:`) + doc comments on EVERY pub fn. No silent failures.
5. Stdlib stays **zero external deps** (pure XIOM; SIMD/C-FFI/ASM only for
   perf with pure fallback + runtime dispatch).

---

## 7. Compiler-side status (other session's domain)

- **FIXED (verified):** BUG 1 (tuple-of-struct codegen), BUG 8 (`&Vec[Int]`
  catalog params), BUG 9 (private catalog struct types), BUG 10 (float literal
  6-decimal emission), BUG 11 (unsafe-extern double marshalling), parser
  `bits[L-1]`, catalog import slowness, circular imports verified safe.
- **STILL OPEN:** BUG 2 (module-global struct FIELD writes lost — use
  whole-value assignment), BUG 3 (module-global fn-call initializers silently
  zero — use constructor fns). Stdlib already works around both; fixing them
  enables `const BIGINT_*`/`BIGFLOAT_*` style and π/ln10 caching.
- Pre-existing quirks (stdlib works around): Result[Vec[T]] mono collision,
  chained-method inttoptr, `is Ok`+.value, Bool→Int cast, match-arm type
  mixing. Full details in docs/COMPILER_BUGS.md.

---

## 8. Environment notes

- Compiler binary: build via `cargo rustc -p xiom --bin xiom -- -o
  <custom>\xiom.exe` when the parallel session's harness locks
  `target/debug/xiom.exe` (copy/execute works while locked; replace doesn't).
- Run smokes with the SAME compiler revision you built against.
- `xiom --emit-ir <file>.xi` dumps IR to stdout (useful for codegen checks).
- The harness dirs (target_bf/, probe files) are throwaway — clean up before
  commit.
- The session doc constraint: only `stdlib/xiom/**`, `examples/**`,
  `docs/COMPILER_BUGS.md`, `docs/AI_CONTEXT.md` §8 are ours to commit.

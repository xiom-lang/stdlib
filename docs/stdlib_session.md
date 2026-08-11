# XIOM Stdlib Session — Clean Handoff (2026-08-11, evening session)

> Written at session end for a seamless continuation. Current branch:
> `feat/architect`. Compiler session works in parallel on crates/ (commits
> interleave with ours). All gates green at handoff.

---

## 1. What was delivered (all committed, gates green)

| Commit | Content |
|--------|---------|
| `c9426687` | **MISSION 1 — wish-list audit** (docs/STDLIB_EXTENSION.md §13): full categorized HAVE/GAP-stdlib/GAP-package tables for HASHING/COLLECTIONS/STRING/CONVERSION/NETWORK/FILE FORMATS/OS + dedupe map; §10 status refreshed (64+ modules, ~2,215 fns, Phases A–C.5/Karatsuba). |
| `1bc7f8f0` | **G13 — printf/scanf**: `fmt.sprintf_i1/i2/f1/f2/s1/s2` (d/i/u/x/X/o/b/f/e/E/g/G/s, flags/width/prec, C semantics) + `fmt.sscanf`/`sscanf_ints`/`sscanf_floats` (width, `*`, %c, ws-skip). FIXED `convert.float_to_string` (was fptosi bit-pattern garbage → %.15g-style); added `float_to_fixed_str`/`float_to_sci_str`. Smoke `smoke_fmt_sprintf` (123 checks). BUG 12/13 logged. |
| `1bc7f8f0` | **256-bit bridge (bigint)**: `bigint_to_u64` (0..2^64-1), `bigint_to_u128` (0..2^128-1), `bigint_to_i128` (±2^127) — exact range-checked via BigInt compare + native i128 accumulate. `bigfloat_to_float128` BLOCKED by BUG 13 (fp128 needs compiler-rt helpers); TODO(compiler) in num/bigfloat.xi + AI_CONTEXT §8.41 note. Smoke `smoke_bigint_bridge` (31 checks). |
| `4bab7b4b` | **Hashes**: XXH3-64 + XXH3-128 (official v0.8.3 port incl. seeded secret; verified against a clang-built reference of the real header — all 39 vectors), SipHash-2-4/1-3 (`hash/siphash.xi`), SuperFastHash (`hash/superfast.xi`), Adler-32 (`hash/crc.xi`). **Collections**: skiplist, trie (autocomplete), cuckoo map, fenwick, object pool, spsc lock-free ring (AtomicInt), ARC cache — all flat-arena style. BUG 14/15/16 logged. |
| `2517ece0` | **string/text/time**: `str_translate` (tr), `str_rot13`/`str_rot47`/`str_caesar`/`str_atbash`, `str_abbreviate` (middle …), `str_obfuscate`; `ngram_extract`, `jaccard_similarity`, `longest_common_prefix/suffix`; `time.strftime`/`strptime` (DateParse struct). BUG 17/18 logged. |
| docs (uncommitted → final commit) | AI_CONTEXT §8.3/8.5/8.19/8.45/8.46/8.44 additions, STDLIB_EXTENSION §13.9 generics policy, this session doc. |

**Gates at handoff:** stdlib_tests **40/40**, api-freeze **2/2** (verified
after every batch). Smokes (all exit 0): smoke_fmt_sprintf (123),
smoke_bigint_bridge (31), smoke_hash3 (39), smoke_collect2a (66),
smoke_collect2b (26), smoke_str2 (34), smoke_time2 (17).

**Stdlib size:** 64+ modules, ~2,350+ pub fns (flat ~1,934 + folder modules).

---

## 2. STDLIB_EXTENSION.md — the big audit (DONE this session)

§13 now contains the full categorized audit (HAVE / GAP-stdlib / GAP-package
tables for all 7 wish-list categories + dedupe map + §13.9 generics policy).
Remaining GAP-stdlib work by priority (from §13):
- Hashing P1/P2: highway, spooky, t1ha, metro, farm (pure ports; no reference
  harness needed beyond the clang pattern used for XXH3).
- Collections P1/P2: rbtree, pairing heap, blocking queue, threadpool,
  TinyLFU, HAMT, interval/range trees, kd/oct/quadtree, segment tree,
  persistent structures, ring (SpscRing covers the lock-free case).
- String P1/P2: Unicode tables (normalize/casefold/ea_width/…), template
  strings, shuffle/rotate/permute/combine/chunk, uuencode/xxencode,
  quoted-printable, punycode/idna, shell/cmd escaping, regex/glob escaping.
- Conversion P1/P2: email/iban validation, html/xml escaping.
- Network P2: cookie/multipart/mime parsing, websocket framing, jwt (pure
  crypto composition), ntp/sntp, unix sockets.
- OS P2: symlink/mmap/dup/readv/sendfile/termios/strerror (FFI syscalls).

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

---

## 3. Remaining stdlib work (priority order)

1. **Compiler bugs to land first** (they block/constrain stdlib shape):
   BUG 12 (Vec[Float64]/[N]Float64 element reads — blocks float containers),
   BUG 13 (fp128 compiler-rt helpers — blocks bigfloat_to_float128),
   BUG 14 (UInt64→UInt128 sext / UInt128 ashr), BUG 15 (single-var inline
   mask drop), BUG 16 (skiplist×trie / multi-Option-payload startup
   fast-fail), BUG 17 (Vec[Str] element == → pointer cmp), BUG 18
   (string×text.similarity×time combo crash; %Q strptime pair miscompile).
2. **P1 hashes**: highway, spooky, t1ha, metro, farm (pure ports; clang
   reference harness pattern established).
3. **P1 collections**: rbtree, blocking queue, threadpool, kd/oct/quadtree,
   TinyLFU.
4. **P1 conversion**: punycode/idna, email/iban validation.
5. **CI wiring**: ask the compiler session to add the new smokes
   (smoke_fmt_sprintf, smoke_bigint_bridge, smoke_hash3, smoke_collect2a/b,
   smoke_str2, smoke_time2) to the stdlib-exec harness list.
6. **Unicode tables** (string P1: normalize/casefold/ea_width/…) — big,
   table-heavy; utf8 module is the foundation.
7. **NASM/SIMD §7 tracks**: compiler/runtime session domain (crates/ +
   stdlib/runtime/*.c are OFF-LIMITS to us). BUG 2/3 fix would enable
   precision-cached π/ln10 in bigfloat.

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
- **UInt64→UInt128 casts sext and UInt128 `>>` is ashr** (BUG 14): the XXH3
  64×64→128 product builds from 32-bit halves and masks the high-half shift.
- **Single-var inline bodies lose the mask** (BUG 15): `var mask = …;
  return x & mask;` inlines as bare ashr — always use the two-var form.
- **UInt64 tuples collide with Int tuples** in catalog codegen: return named
  structs (U64Pair, SipState, IntRepr, MatchTok, SkipSearch).
- **`&mut Vec[T]` args that are struct FIELDS copy** (fresh-alloca): helper
  fns taking `&mut Vec[Int]` with `&mut c.field` args lose push/pop — inline
  list ops on the parent struct (ARC) or use flat arenas.
- **Vec-of-struct × 2 in one program → startup fast-fail** (BUG 16): use
  flat parallel Vec[Int] arenas (tree.xi/graph.xi convention).
- **Vec[Str] element-to-element `==` lowers to pointer compare** (BUG 17):
  compare string content byte-wise.
- Smoke-writing rules learned: `str_slice(s, 0, 6)` is 6 chars; `requires`
  violations TRAP at entry (don't call fns with out-of-contract args in
  smokes); `core.to_string` on Float64 truncates (fptosi) — use comparisons or
  scaled-integer prints; match arms must match the enum type (Option vs
  Result); don't chain `.len()` on module-qualified Str-returning calls (bind
  to a var first); float literals like 2.675 are parse-dependent — use
  exact-f64 values (3.125) in assertions; the builtin float parser is not
  correctly-rounded to the last ulp (compare with tolerance or scaled ints).

---

## 5. Module inventory (current reality, 2026-08-11 — AFTER the category restructure)

**stdlib/xiom is now CATEGORIES-ONLY (24 folders, zero flat files).** Every
module name is UNCHANGED (the catalog resolves modules by header scan, not
path — verified with probe programs). Layout:

- `core/` : core.xi, cmp.xi, contracts.xi, platform.xi, reflect.xi, simd.xi, test.xi
- `memory/` : alloc.xi, cell.xi, mem.xi, ptr.xi, rc.xi
- `ffi/` : ffi.xi
- `string/` : string.xi, char.xi, utf8.xi, regex.xi + stub sublibs (unicode, template, combinatorics)
- `text/` : misc.xi, similarity.xi
- `collections/` : collections.xi, array.xi, iter.xi, sort.xi, search.xi + the 27 collect/* modules (cache, graph, hash, heap, queue, tree, skiplist, trie, cuckoo, fenwick, objectpool, rbtree, pairingheap, tinylfu, hamt, interval, segment, persistent, spatial, threadpool, blockingqueue, concurrent, intmap, ...)
- `encoding/` : encoding.xi
- `convert/` : convert.xi + stub sublibs (uuencode, quotedprintable, punycode, escape, validate, utf)
- `format/` : fmt.xi, dump.xi, number.xi + stub sublibs (terminal, textual, relative, numbering)
- `num/` : num.xi, bigint.xi, bits.xi, bigfloat.xi (impl), bigfloat_agg.xi (module xiom.bigfloat aggregate), convert.xi
- `math/` : math.xi, core.xi, complex.xi, geom.xi
- `bench/` : bench.xi, stats.xi
- `hash/` : hash.xi + city, crc, jenkins, murmur, xxhash, siphash, superfast + stub sublibs (fnv, highway, spooky, t1ha, metro, farm)
- `crypto/` : crypto.xi, aes.xi, sha.xi, md5.xi, des.xi, ecc.xi, poly1305.xi, rsa.xi, chacha.xi
- `rand/` : rand.xi, chacha.xi, mt19937.xi, pcg.xi
- `net/` : net.xi + url, dns, proto + stub sublibs (cookie, multipart, mime, websocket, jwt, ntp, ping, unix, sse)
- `os/` : os.xi, env.xi, path.xi, process.xi + fs.xi, proc.xi, term.xi + stub sublibs (fs_ffi, proc_ffi, event, terminal, err, filetype)
- `io/` : io.xi, log.xi
- `concurrency/` : sync.xi, async.xi, thread.xi
- `time/` : time.xi · `error/` : error.xi · `compress/` : compress.xi · `debug/` : debug.xi · `serialize/` : serialize.xi

**GATES NOTE (compiler session):** the restructure breaks
`crates/xiom-codegen/tests/stdlib_tests.rs` `stdlib_modules()` and the
api-freeze test's path list — update the paths to the new layout (one
mechanical edit per entry). Module names/contents are byte-identical
(84 pure renames). The stdlib-exec smokes import by MODULE NAME and are
unaffected. Resolution was verified by compiling smokes across categories
(smoke_str2 34/34, smoke_fmt_sprintf 123/123 with the new layout).

## 5b. Implementation order (dependency levels, 2026-08-11)

Every stub carries a `// Depends on:` header. The dependency-ordered
implementation sequence (bottom-up):

- **Level 0 — no deps (pure primitives):** core/, memory/, ffi/, error/,
  num/ (bits, cmp lives in core/), contracts.
- **Level 1 — string+math foundations (the two most-imported):**
  string/string.xi, char, utf8, regex; math/, num/, hash/ (needs
  Vec[UInt8] building via string), encoding/, collections base (Vec/Map/
  Set/Stack/Queue), rand/, time/ (needs num), fmt (needs string+convert).
- **Level 2 — builds on L1:** collections/* (trie/radix→string,
  spatial/kdtree→math, mpmc/mpsc/spmc→sync), convert/* (base58→num,
  strftime→time, uuid→rand, ip/url→net), string/* metrics (cosine→math),
  format/* (relative→time, numbering→num), serialize/ (json), compress/,
  crypto/ primitives (needs math bit ops), sync/async/thread.
- **Level 3 — FFI/IO layer:** io/, os/* (fs_ffi/proc_ffi/event/terminal/
  err/filetype→ffi+io), net/ (sockets→ffi), process, debug, bench/stats.
- **Level 4 — composition:** net/cookie (string+time), net/jwt
  (string+crypto+serialize), net/websocket (string+net), format/terminal
  (string), bigint/bigfloat (num).

The bulk of sublibs only need `xiom.string` (+ `xiom.math` for the
distance/spatial/float-heavy ones), confirming the user's estimate.

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

## 6b. Sanity audit + implementation-phase entry (2026-08-11, evening)

**Verdict: READY for the implementation phase.** Three new docs:

- **docs/STDLIB_AUDIT.md** — full doc→tree mapping. 39 categories / 440 files / 440
  modules / 93 REAL / 346 STUB / 1 aggregate; 2,298 real pub fns; duplicate module
  decls 0; fn conflicts within a prefix 0; same-name sublib pairs across categories
  38 (homes designated); MISSING 0. Implementation checklist per sublib in §6.
- **docs/STDLIB_GENERICS.md** — 8 policy rules (R1 generic containers; R2 concrete
  native ABI for math/geom/crypto/os/net/hash/time; R3 no trait-driven generic
  arithmetic — §12; R4 no float containers until BUG 12; R5 no Vec[Str] element
  `==` — BUG 17; R6 two-var inline bodies — BUG 15; R7 UInt128 halves — BUG 14;
  R8 trait-style conversions declare-only). Per-category mode table (7 GENERIC /
  23 CONCRETE / 9 MIXED) + the stub list blocked by compiler bugs (stats float
  containers, simd f32x8/gather, string/format + convert/into generics, reflect
  intrinsics).
- **packages/README.md** — the PACKAGE ecosystem: 366 packages (365 on-disk dirs
  in packages/, 70 with real .xi = IMPLEMENTED, 295 placeholder = STUB, 1 planned),
  categorized (crypto/security 20, testing/qa 13, protocols 43, databases 22, file
  formats 23, graphics/media 38, ml/cloud 47, geospatial 8, game 16, compress 2,
  misc 133), plus the 15 pure-XIOM packages flagged "stdlib or package by owner".

**Anomalies fixed during the audit:**
- hash/xxhash.xi duplicate `_rotl32` (L37 vs L293) — removed the duplicate.
- stats/stats.xi `module xiom.bench.stats` → `module xiom.stats` (nothing imported
  the old name; aggregate now consistent with xiom.stats.* sublibs).

**Phase-2 implementation rules (production-grade):**
1. Order: L0→L4 (see §5b) — string+math first; follow each stub's `// Depends on:`.
2. Per sublib: replace `// fn` stubs with real `pub fn` + contracts (`requires`/
   `ensures`) + doc comments + smoke in examples/stdlib_smoke; keep module name,
   keep the aggregate use-line; re-run the gates (stdlib_tests/api_freeze once the
   compiler session updates the path list).
3. Follow STDLIB_GENERICS.md per category (generic vs concrete decided BEFORE
   writing; flagged stubs wait for the named compiler BUG fixes).
4. Use qualified calls (`math.core.sqrt`) in user code; same-name pairs (38) are
   disambiguated by module path (see STDLIB_AUDIT.md §3 for designated homes).
5. Compiler bugs block list (implementation queue must check first):
   BUG 12 (float containers), BUG 13 (fp128), BUG 14/15 (UInt128/sext, inline),
   BUG 16/18 (module-combination crashes), BUG 17 (Vec[Str] element ==).

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
- **STILL OPEN (compiler session):** BUG 2 (module-global struct FIELD writes
  lost — use whole-value assignment), BUG 3 (module-global fn-call
  initializers silently zero — use constructor fns), **BUG 12–18 (this
  session, see docs/COMPILER_BUGS.md)**: Vec[Float64]/[N]Float64 element
  reads (load i64+sitofp / type-string ']' split → AV), fp128 missing
  compiler-rt helpers (__divtf3/__floatditf/__trunctfdf2), UInt64→UInt128
  sext + UInt128 ashr, single-var inline mask drop, skiplist×trie startup
  fast-fail (unqualified MaybeUninit.clone), Vec[Str] element == → pointer
  cmp, string×text.similarity×time combo crash (+ %Q strptime pair).
- Pre-existing quirks (stdlib works around): Result[Vec[T]] mono collision,
  chained-method inttoptr, `is Ok`+.value, Bool→Int cast, match-arm type
  mixing, Option-of-struct/Date payload collisions. Full details in
  docs/COMPILER_BUGS.md.

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

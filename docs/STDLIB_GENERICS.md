# STDLIB GENERICS VS CONCRETE - Implementation Policy

Status: authoritative 2026-08-11. Source of truth for signature mode selection in
the stdlib implementation phase. Read BEFORE writing any stdlib signature.

Normative inputs:
- docs/COMPILER_BUGS.md STATUS SUMMARY (2026-08-11) and BUG 12, BUG 14, BUG 15,
  BUG 16, BUG 17, BUG 18 sections.
- docs/STDLIB_EXTENSION.md section 12 (GENERICS/INTERFACES vs NUMERIC TOWER).
- Verified generic patterns already in the tree: math/core.xi ([T: Num]/[T: Real]),
  num.xi ([T: Bounded]), collections.xi (Vec[T], Map[K,V], Set[T], BTreeMap[K: Ord, V]),
  sort.xi / search.xi / cmp.xi ([T: Ord]/[T: Eq] comparison-based), array.xi
  ([T, const N: Int]), iter.xi (Iterator[T], MapIter[T, U]), memory (Cell[T],
  RefCell[T], Rc[T], ptr.[T]).

Note: docs/STDLIB_AUDIT.md is NOT present in the tree. The "38 same-name pairs"
figure was derived from module basenames instead (39 overlapping basenames / 41
duplicate file instances - see section 4, qualification rule).

===============================================================================
1. POLICY SUMMARY - 8 RULES
===============================================================================

R1. GENERIC - Container/algorithms that touch caller-chosen T.
    collections core types, iter, sort, search, array, cmp, test/assert,
    core memory wrappers (Option/Result/Box/Cow/MaybeUninit), memory ptr/cell/rc.
    Bounds: `[T]`, `[T: Ord]`, `[T: Eq]`, `[T: Clone]`. The fn body may use only
    `.compare` / `.eq` / indexing / copy / swap. It must NEVER use arithmetic
    operators (+, -, *, /, %) on T.

R2. CONCRETE - Native ABI, one fn per width.
    math flat contract, num numeric tower, convert numeric codecs, stats
    numeric, geom, crypto, hash, rand, compress, encoding, format, os, ffi,
    net, time, bits, log, error, io, debug, regex. Signature style:
    `i64_*` / `u64_*` / `f32_*` / `f64_*` / `i128_*` / `fraction_*`, native
    `Float64` / `UInt64` / `Int` / `Str` / `&Vec[UInt8]` ABI. Callers pick the
    width; no generic dispatch.

R3. FORBIDDEN - Trait-driven generic arithmetic.
    `[T: Num]`, `[T: Real]`, `[T: Bounded + Add]` bodies that compute `a + b`
    or `Num[T].add(a, b)` do NOT dispatch: interface `impl` blocks are parsed
    but ignored by checker + codegen (STDLIB_EXTENSION.md section 12). Generic
    operator monomorphization corrupts Float64. Keep the interface declarations
    (freeze-gated surface) but write concrete per-width fns. math/core.xi is a
    compile-only pattern module, not an executable tower.

R4. FORBIDDEN until fixed - Float containers (BUG 12).
    `Vec[Float64]`, `Vec[Float32]`, `[N]Float64`, `[N]Float32`: element READS
    lower to `load i64` + `sitofp` (silent value corruption) and `[N]Float64`
    degrades to `[N]i64` (0xC0000005 AV). STORE/push is intact; reads are wrong.
    Substitutes, in order of preference:
      a. scalar `Float64` / `Float32` params and returns (proven: geom, bigfloat,
         math, stats dist);
      b. fixed-slot structs for N-float results (exemplar: `FloatScan` in
         format/fmt.xi:1271 - 8 named Float64 fields + ok flag);
      c. scaled-Int storage (multiply by 10^k, do Int math, scale back).
    Float64 as a plain struct FIELD (non-array, non-container) is proven safe
    (geom Vec2, num/bigfloat IntFrac).

R5. FORBIDDEN - `==` between two runtime Str values loaded from Vec[Str]
    ELEMENTS (BUG 17): the element loads degrade the operand type and the
    equality lowers to pointer compare (`ga[i] == gb[j]` is false even for
    equal strings). Use a byte-wise helper: `_str_eq` pattern
    (text/similarity.xi:737, str_len + byte_at loop). `Str == Str` on vars and
    slices still emits strcmp and is fine; literal-element compare is fine.

R6. MANDATORY - Two-var body for small inline fns (BUG 15).
    A body that is exactly `var mask = <expr>; return <expr2> & mask;` drops
    the mask statement when inlined. Always write `var shift = ...; var mask =
    ...;` (or otherwise two statements before the return). Applies to every
    hash / shift / rotate / mask helper (siphash.xi:21, xxhash.xi:278).

R7. MANDATORY - UInt128 construction and shift (BUG 14).
    `UInt64 as UInt128` emits SEXT (wrong when bit 63 is set) and `UInt128 >>`
    emits ASHR (wrong when bit 127 is set). Build i128 from 32-bit halves and
    mask the high half after `>>` - the `_u64_to_u128` pattern
    (hash/xxhash.xi:336). Applies to any 64x64->128 wide-multiply / 128-bit
    mixing code (hash, bigint bridges, PRNG state combining).

R8. GENERIC BY DESIGN but DECLARE-ONLY - Trait-style conversion/serialization.
    Interfaces From / Into / TryFrom / TryInto / FromStr (convert), Serialize /
    Deserialize (serialize), ToString / Display style helpers: declare the
    interface, implement CONCRETE per-width/per-type fns. Generic wrappers that
    rely on per-type dispatch - `into_str[T]` (convert/into.xi), `str_format1/
    2/3[T,U,V]` (string/format.xi), `to_json[T: Serialize]` / `from_json[T:
    Deserialize]` (serialize.xi:158/162) - cannot dispatch; keep them comment-
    only or concrete per type until compiler impl-dispatch lands.

R9. THE NAME `core` BELONGS TO THE PRELUDE. `xiom.core` is the compiler-wired
    prelude (crates/xiom-check PRELUDE array) -- it owns the name `core`. No NEW
    sublib may be named `core` (so `core.core` can never exist). `math.tower` is
    the one accepted exception: it reads naturally as "the core of math" and is
    already established (module xiom.math.tower, renamed from math.core 2026-08-11, smoke_math_tower.xi). The same
    "category.core = foundational sublib" convention from the old D4b note is
    retired; a category's foundation is its flat aggregate (math.xi, num.xi,
    collections.xi) unless a separate concern genuinely needs its own module
    (math.tower = the generic Num/Real tower). Never create `<cat>/core.xi`.

===============================================================================
2. PER-CATEGORY TABLE (39 categories)
===============================================================================

Category   | Default mode | Rationale | Compiler constraints | Notable exceptions
-----------|--------------|-----------|----------------------|-------------------
array      | GENERIC      | `[T, const N: Int]` verified in array/array.xi (len/map/zip/fold/sort/binary_search); stubs array/fixed.xi + dynamic.xi declare `[T]`/`[T,U]` | Float element T forbidden (BUG 12: `[N]Float64` -> `[N]i64` AV) | array_sum is concrete `[const N: Int](&[N]Int)`; float-typed arrays deferred
async      | MIXED        | Channel[T]/Broadcast[T] are generic containers (async/channel.xi stubs); executor/io/timer are concrete fd/Future | Multi-Option-payload module combos crash at startup (BUG 16/18) - smokes split | async_read/write stay `&Vec[UInt8]` concrete
bench      | MIXED        | `black_box[T]` is a generic identity (bench.xi:120); timing/analytics concrete Int/Float64 | none | -
bits       | CONCRETE     | Int/UInt64 bit ops; bitarray/bitfield/popcount stubs concrete Int | two-var body for shifts/masks (BUG 15) | -
collections| GENERIC core + CONCRETE stubs | Vec[T]/Map[K,V]/Set[T]/BTreeMap[K: Ord,V]/HashMap[K,V] verified generic in collections.xi | skiplist.xi + trie.xi in ONE program crashes (BUG 16) - split smokes (smoke_collect2a/2b); Vec[Str] element compare via byte helper (BUG 17) | ~40 advanced-collection stubs (avl/lru/btree/rbtree/...) are frozen CONCRETE Int-keyed - do not retrofit generics without a freeze-gate change
compress   | CONCRETE     | Byte-stream codecs (`&Vec[UInt8]`/`Vec[UInt8]`): deflate/gzip/lz4/lz77/snappy/zlib/brotli/huffman | none (byte ABI proven, smoke_compress green) | -
convert    | MIXED        | Numeric/binary/string codecs concrete (Int/Float64/Str/bytes); trait interfaces From/Into/TryFrom/FromStr declare-only (convert.xi:9-20) | Generic wrappers into_str[T] and as_ref_bytes[T] cannot dispatch (section 12) - flagged | asref.xi as_ref_bytes[T] is phantom-byte-view; base16/32/58/62/64, ascii85, punycode all `&Vec[UInt8]` concrete
core       | GENERIC      | Option[T]/Result[T,E]/Box[T]/Cow[T: Clone]/MaybeUninit[T]/BinaryHeap[T: Ord], size_of[T], is_sorted[T: Ord] verified (core.xi) | Option/Result payload clone symbol collision in multi-Option programs (BUG 16/18) | -
crypto     | CONCRETE     | Block ciphers, hashes, key exchange over `&Vec[UInt8]` + fixed widths; AES/ChaCha/RSA/ECC concrete | none | crypto/rng_crypto.xi shuffle/choice `[T]` stubs are index+swap only - compliant (R1)
debug      | CONCRETE     | trace/heap_report/disasm on Int/Str | none | -
encoding   | CONCRETE     | Str<->bytes: base32/64, hex, percent, punycode, idna, ascii85 | none | overlaps convert/ (same-name fns) - qualify calls
error      | CONCRETE     | Error chain/context/backtrace on Error/Str | none | -
ffi        | CONCRETE     | Int handles, errno, dl_open/sym/close | none | -
format     | CONCRETE     | fmt concrete; FloatScan fixed-slot struct is the BUG 12 exemplar (fmt.xi:1271); number/numbering/relative/table/units | Float container avoided by design | string/scanf.xi stub must keep the FloatScan pattern, NOT switch to Vec[Float64]
geom       | CONCRETE     | Native f64 vector/matrix/quat math; float struct FIELDS proven (Vec2) | float containers forbidden (BUG 12) | -
hash       | CONCRETE     | UInt64 seeds, `&Vec[UInt8]` data; SipHash/XXH use two-var bodies (BUG 15) + `_u64_to_u128` halves (BUG 14) | BUG 14/15 constraints baked into code | farm/city/metro/spooky/t1ha/highway stubs concrete
io         | CONCRETE     | Byte buffers, BufReader/Cursor, fs/console/pipe | invariant_check/clone stub symbols unqualified in combos (BUG 16) | -
iter       | GENERIC      | Iterator[T], MapIter[T,U], adapters verified (iter.xi); stubs chain/filter/fold/map/zip `[T]`/`[T,U]` match | fn-pointer params need NAMED fns (inline lambdas crash - sort.xi comparator note) | iter_sort[T]/iter_cmp[T] should bound `[T: Ord]` at implementation, stub is bare `[T]`
log        | CONCRETE     | Str levels/sinks/json | none | -
math       | MIXED        | Flat math.xi frozen contract CONCRETE per-width f64 (sqrt/pow/sin...); math/core.xi `[T: Num]`/`[T: Real]` tower is DECLARE-ONLY (no impl dispatch, section 12) | generic tower bodies must not be trusted to run; concrete shims authoritative | qualify `math.core.sqrt` to disambiguate from flat `math.sqrt` (D4b)
memory     | GENERIC      | Cell[T]/RefCell[T]/Rc[T]/Weak[T]/ManuallyDrop[T], ptr.[T]/mem.[T] verified | Rc/Cell monomorphization fine; no float containers | -
misc       | CONCRETE     | glob/levenshtein/semver/soundex on Str | none | natural_sort_by[T] with `key: fn(&T) -> Str` is comparator-style - compliant
net        | CONCRETE     | Wire protocols over Str/bytes: socket/http/websocket/mime/jwt/sse | none | overlaps convert/ (ip, url) - qualify calls
num        | CONCRETE     | Per-width tower `i64_*`/`u64_*`/`i128_*`/`fraction_*` verified (num.xi); bigint/bigfloat structs; Bounded interface declare-only | min_value[T: Bounded] etc. are non-dispatching wrappers - keep | bigfloat Float64 FIELDS fine; `bigfloat_to_float128` blocked by BUG 13 (fp128 link)
os         | CONCRETE     | fd Int syscalls via FFI; path/env/fs/proc | none | termios stubs concrete
rand       | CONCRETE     | UInt64 state; mt19937/pcg/chacha | none | -
reflect    | GENERIC stubs| typeinfo.xi/fields.xi declare `[T]` phantom generics | FLAGGED: type_name/type_id/variant_count/field_offset need type-metadata intrinsics that do not exist (only size_of[T]/align_of[T] proven via memory/mem.xi) - keep comment-only | -
regex      | CONCRETE     | Str patterns; engine/pcre_lite/syntax | none | -
search     | GENERIC      | `[T: Eq]`/`[T: Ord]` verified (search.xi); binary_by/linear_by `[T]` comparator stubs match | comparator/pred fns must be named | interpolation_search stays `&Vec[Int]` concrete (arithmetic on values)
serialize  | MIXED        | Serialize/Deserialize interfaces declare-only; JsonValue/varint/endian/yaml_lite concrete | to_json[T: Serialize]/from_json[T: Deserialize] wrappers non-dispatching (section 12) - keep concrete json_* fns | -
simd       | CONCRETE     | Vec4f/Vec8f etc. are pointer-typed structs (`*Float32`), proven | F32x4/F32x8 stub LAYOUTS are fine, but `f32x8_new(&[8]Float32)` and any Vec[Float32] use FLAGGED (BUG 12); i32x4/i32x8 fine | gather_load[T] with float T -> Vec[Float32] FLAGGED
sort       | GENERIC      | `[T: Ord]` + comparator `fn(&T,&T) -> Int` verified (sort.xi); stubs heap/intro/merge/quick `[T]` match | named comparator fns only | sort_counting/sort_radix concrete `&Vec[Int]` (value arithmetic)
stats      | CONCRETE     | Real stats.xi on `&Vec[Int]` + scalar Float64 | FLAGGED: stats/stats.xi stats_sum_f/stats_mean_f/stats_stddev_f_f take `&Vec[Float64]` (BUG 12 LATENT); stubs moments/regress/test/histogram `&Vec[Float64]` BLOCKED | dist.xi scalar-only Float64 params - COMPLIANT; use scalar series / FloatScan / scaled-Int until BUG 12 fixed
string     | CONCRETE     | Str ops (trim/split/join/case/unicode/ngram...); scanf keeps FloatScan | Vec[Str] element compare via byte helper (BUG 17); str_format[T,U,V] generic stub FLAGGED (section 12 dispatch) | string/format.xi should delegate to format/fmt.xi concrete
sync       | MIXED        | Channel[T] generic (sync/channel.xi); mutex/condvar/rwlock/barrier/atomics concrete | multi-Option-payload combos (BUG 16/18) - split smokes | atomic_ptr_new[T] is a phantom T on an Int addr - compliant
test       | MIXED        | assert.xi `[T]` eq/ord + Option[T]/Result[T,Str] generic; harness concrete | assert_eq on Vec[Str] ELEMENTS hits BUG 17 (scalar T fine) | -
text       | CONCRETE     | Str diff/similarity/transliterate; `_str_eq` byte-wise helper (similarity.xi:737) | BUG 17 avoided via helper; text.similarity + time in one program crashes (BUG 18) - smokes split | -
thread     | MIXED        | ThreadLocal[T] generic (thread/local.xi); spawn/pool/park concrete | multi-Option-payload combos (BUG 16/18) - split smokes | -
time       | CONCRETE     | Civil dates with Int fields, Str parse/format (strptime/strftime), Instant/Duration | strptime `%Q` early-return path miscompiles at -O2 in combination (BUG 18); keep `%Q` check removed until fixed; smokes split | time + string + text.similarity in one program crashes (BUG 18)

Mode summary (39 categories):
  GENERIC (7): array, core, iter, memory, reflect (STUBS, compiler-blocked),
              search, sort
  CONCRETE (23): bits, compress, crypto, debug, encoding, error, ffi, format,
              geom, hash, io, log, misc, net, num, os, rand, regex, simd,
              stats, string, text, time
  MIXED (9): async, bench, collections, convert, math, serialize, sync, test,
              thread

===============================================================================
3. STUB GENERIC SIGNATURES - VERIFICATION PER SUBLIB
===============================================================================

Sublibs that declare `[T` stub signatures, verified against the policy above.

3.1 COMPLIANT - keep as declared
  iter/{chain,filter,fold,map,zip}.xi      `[T]`/`[T,U]` + fn(&T)->Bool etc.
      Matches the proven iter.xi + sort comparator pattern. Constraint: pass
      NAMED fns only (inline lambdas crash the runtime).
  search/{binary,linear}.xi                `[T]` comparator/predicate.
  sort/{heap,intro,merge,quick}.xi         `[T]` comparator.
  array/{fixed,dynamic}.xi                 `[T]`/`[T,U]` (+ const N).
      OK for Int/struct element types; DO NOT monomorphize with Float64
      element types (BUG 12).
  misc/natural.xi                          `natural_sort_by[T]`, key fn(&T)->Str.
  crypto/rng_crypto.xi                     `crypto_random_shuffle[T]` /
      `crypto_random_choice[T]` - index + swap/read only, no arithmetic (R1).
  sync/atomics.xi                          `atomic_ptr_new[T]` - phantom T.
  sync/channel.xi, async/channel.xi        `Channel[T]`/`AsyncChannel[T]`/
      `Broadcast[T]` generic containers. Keep; split smokes so several Option
      payload shapes do not coexist (BUG 16/18).
  thread/local.xi                          `ThreadLocal[T]` - storage slot.
  stats/dist.xi                            scalar Float64 params only - no
      containers - COMPLIANT. (uniform_pdf/normal_cdf/... stay scalar.)

3.2 FLAGGED - blocked by compiler, do not implement as declared
  stats/stats.xi  (REAL module, not a stub)
      stats_sum_f (stats.xi:255), stats_mean_f (:267), stats_stddev_f_f (:274)
      take `&Vec[Float64]` and READ elements - BUG 12 silent corruption.
      BUG 12's status note ("no pre-existing stdlib module uses Vec[Float64]")
      predates these fns. REWORK: scalar-series signatures
      (`stats_sum_f(v: &FloatScan)` or per-element `fn(x0..xN)`) or scaled-Int,
      or leave unexposed until BUG 12 is fixed. BUG 12.
  stats/moments.xi                         all fns take `&Vec[Float64]` -
      mean/variance/stddev/skewness/kurtosis/covariance/quantile. BUG 12.
  stats/regress.xi                         linear_regression/slope/intercept/
      r_squared/pearson/spearman/polynomial/residuals take `&Vec[Float64]`.
      BUG 12.
  stats/test.xi                            t_test_*, f_test, anova_one_way
      (`&Vec[Vec[Float64]]`), chi_squared_test take `&Vec[Float64]`. BUG 12.
  stats/histogram.xi                       histogram_edges/histogram_normalize
      RETURN Vec[Float64] (push-then-read by caller). BUG 12.
  simd/vec8.xi                             `f32x8_new(v: &[8]Float32)` - fixed
      `[N]Float32` array param. BUG 12. (F32x8 struct with *Float32 pointer
      field is fine, mirroring simd.xi.)
  simd/vec4.xi                             F32x4 struct with *Float32 pointer -
      fine. Flag ONLY if an implementation introduces Vec[Float32]/[4]Float32
      storage. BUG 12.
  simd/gather.xi                           gather_load[T]/gather_mask[T]/
      gather_iota[T] return `Vec[T]`; with float T these are float containers.
      BUG 12 (int T fine). Do not implement float-lane gathers until fixed.
  string/format.xi                         str_format1/2/3[T,U,V] require
      per-type Display/ToString dispatch - declare-only (section 12). Use
      format/fmt.xi concrete instead. Section 12.
  convert/into.xi                          into_str[T] - same dispatch problem.
      Implement concrete to_string_int / to_string_float / to_string_bool.
      Section 12.
  convert/asref.xi                         as_ref_bytes[T]/as_mut_bytes[T]:
      generic &T -> &Vec[UInt8] byte view needs a struct-to-bytes intrinsic;
      only Vec/Slice as_slice is proven. Keep comment-only. Compiler feature.
  reflect/typeinfo.xi                      type_name[T]/type_id[T]/
      type_variant_count[T]/type_is_*[T]: no type-metadata intrinsic exists
      (only size_of[T]/align_of[T] proven via memory/mem.xi). Keep comment-only.
      Compiler feature.
  reflect/fields.xi                        field_count[T]/field_name[T]/
      field_offset[T]/field_value[T](&T, i): field-reflection intrinsic does
      not exist. Keep comment-only. Compiler feature.
  test/assert.xi                           assert_eq[T]/assert_ne[T] are fine
      for scalars but comparing two Vec[Str] ELEMENTS reuses the degraded
      pointer-compare path - assert_eq on string elements is unsafe until
      BUG 17 is fixed; assert_lt/gt/ge/le need `[T: Ord]` (stub is bare `[T]`).
      BUG 17 (soft flag - scalar usage compliant).

3.3 Combination cautions (signatures fine, smokes must be split)
  sync/channel.xi + async/channel.xi + thread/local.xi + collections
  {skiplist,trie}: multiple Option payload shapes in ONE program crash at
  startup or exit (0xC0000405 / 0xC0000409) - BUG 16 / BUG 18. Keep the
  stubs comment-only (they already are) and never combine those modules in a
  single smoke. Same for time + string + text.similarity (BUG 18) and the
  strptime `%Q` path (keep removed until fixed).

===============================================================================
4. IMPLEMENTATION-PHASE RULES
===============================================================================

4.1 Decision tree - generic vs concrete for a NEW sublib

  Q1. Does the fn operate on a container of caller-chosen T and only compare /
      index / copy / swap elements?      YES -> GENERIC.
        Bound selection:
          - no comparison at all              -> `[T]`
          - `a == b` / `.eq` only             -> `[T: Eq]`
          - ordering via `.compare` / `<`     -> `[T: Ord]`
          - copies elements (`value.clone()`) -> `[T: Clone]`
        Allowed body ops: .compare, .eq, `[i]` indexing, assignment, swap,
        push/pop/len, fn-pointer predicates (`fn(&T) -> Bool`).
        NEVER: `+ - * / %` on T, `as` casts of T, per-width constants.

  Q2. Does the body need arithmetic on T, per-width math (sqrt/pow/sin), or
      numeric formatting?                YES -> CONCRETE, one fn per width.
        Signature family: `foo_i64`, `foo_u64`, `foo_f64`, `foo_f32`,
        `foo_i128`, `foo_fraction`. The generic interface (`Num[T]`,
        `Real[T]`, `Bounded[T]`) may be DECLARED for the freeze gate but must
        not be relied on to execute (section 12).

  Q3. Does the fn take or return Float VALUES?  YES -> scalar or fixed-slot.
        - Scalar Float64/Float32 params + returns: safe, proven.
        - N float results: fixed-slot struct (FloatScan pattern, fmt.xi:1271).
        - Bulk float data: scaled-Int (document the scale factor in the header).
        - NEVER `Vec[Float64]`, `Vec[Float32]`, `[N]Float64`, `[N]Float32`.

  Q4. Does the fn compare Str values that may be Vec[Str] ELEMENTS?
                                                      YES -> byte-wise helper.
        Use the `_str_eq` pattern (str_len + byte_at loop, similarity.xi:737).
        Never `a[i] == b[j]` on two Vec[Str] elements (BUG 17).

  Q5. Does the fn need per-type dispatch (Serialize/FromStr/ToString/Display)?
        Declare the interface; write CONCRETE per-type fns; any generic
        wrapper (into_str[T], str_format[T], to_json[T: Serialize]) stays
        comment-only.

  Q6. Does the fn shift/mask in a small inline body?   -> two-var form (R6).
      Does it build/use UInt128 from UInt64?          -> halves + mask (R7).

  Q7. FFI / OS / net / time / byte codecs / concurrency primitives?
                                                        YES -> CONCRETE.

4.2 Qualification rule (same-name ambiguity)
  STDLIB_AUDIT.md (the 38 same-name pairs) is absent; derived from module
  basenames. 39 names are duplicated across categories (41 extra files):
    ascii85, base32, base64, chacha, chain, channel, convert, core, curves,
    date, duration, endian, escape, float, fold, fs, glob, hash(3), heap, io,
    ip, json(3), levenshtein, mac, map, percent, punycode, radix, range,
    search, segment, soundex, terminal, test, time, unix, url, utf8.
  RULE: any call to a fn whose SHORT name exists in more than one stdlib
  sublib MUST be module-qualified: `math.tower.sqrt`, `serialize.json.json_parse`,
  `convert.base64.base64_encode`, `sync.channel.channel_send`,
  `encoding.hex.hex_encode`, `time.date.date_from_iso8601`. Unqualified calls
  inside the owning module are fine (self-context). Cross-module same-name
  calls without qualification are a compile error or silently resolve to the
  wrong module - always qualify.
  Aggregate caveat (COMPILER_BUGS.md NOTE 5): a leaf sub-module's fns are only
  reachable through a 1-segment aggregate when the aggregate leaf equals the
  parent segment (math.tower works; num.bigfloat via xiom.num does not). Import
  `use xiom.num.bigfloat;` directly when the D4b shortcut fails.

4.3 Smoke-split rule (BUG 16/18)
  Do not combine in one smoke: skiplist+trie, or string+text.similarity+time,
  or several generic channels/TLS with different Option payload shapes. Follow
  the existing split (smoke_collect2a/2b, smoke_str2, smoke_time2) until the
  compiler qualifies generated clone/invariant-check symbols per module.

4.4 Freeze-gate note
  Freeze the CONCRETE signatures now. When the compiler lands interface
  dispatch + correct float monomorphization (section 12 unblocking items), the
  concrete fns remain available as re-export shims and the tower can be
  collapsed into `impl Num[Width]` blocks. Do NOT design around a future that
  has not landed - write the concrete signatures today.


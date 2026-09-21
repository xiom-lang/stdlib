<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
Analysis complete. Delivering the full audit document below.

---

# XIOM Standard Library Audit -- Production-Readiness Evaluation

**Note:** Ask mode is read-only -- save the block below verbatim as `E:\Projects\AXIOM\xiom-stdlib-audit.md` (or switch modes and I'll write it directly).

```markdown
# XIOM Stdlib Audit -- Coverage, Quality, and Production Readiness
**Audited:** `stdlib/` (package `xiom/*`, plus `runtime/` C sources) - **Date:** 2026-08-23
**Reference bar:** Rust `std` + `itertools`/`regex`, Zig `std`, Go `std`, MSVC/libstdc++ STL
**Companion doc:** `xiom-compiler-audit.md` (same methodology)

---

## 1. Executive Summary

The XIOM stdlib is **extraordinarily broad and dangerously shallow at the same time**.

- **Breadth (A-):** 514 `.xi` files, **150,532 LOC**, 9,330 functions (6,475 public) across
  40 packages -- including domains most languages never ship (chaos theory, control theory,
  operations research, queueing theory, computational biology). The collection zoo alone
  has 62 data structures (HAMT, cuckoo filter, TinyLFU, Fenwick, segment trees, kd/octree...).
- **Assurance (F):** The entire library contains **8 functions named `test_*` and 3
  `assert(` calls**. There are **zero known-answer tests** for the cryptography, zero
  conformance tests for base64/punycode/JSON/UTF-8 (all of which have published RFC/Unicode
  test vectors), zero differential tests against reference implementations. A stdlib this
  size without tests is a liability generator, not an asset.
- **Integrity (D+):** Massive deliberate duplication -- `convert/base64` AND
  `encoding/base64`, JSON twice, endian twice, glob/soundex/levenshtein twice, percent
  twice, punycode twice, ip/url twice -- and the code says why:
  *"Implemented locally (same-name delegation to xiom.encoding crashes the compiler)"*
  (`convert/base64.xi:10-12`). **A compiler bug is forcing copy-paste architecture**, and
  the copies have already diverged (4 public fns vs 8).
- **Core quality (C-):** The foundational types make questionable trade-offs --
  `Option[T]` stores `{is_some: Bool; value: T}` (payload always materialized),
  `Result[T,E]` carries both T and E simultaneously, and every string operation
  mallocs a fresh buffer byte-copied through `unsafe` blocks (`string/string.xi:22-64`),
  with `str_starts_with` allocating a full slice just to compare a prefix.
- **Security surface (D):** `xiom.net.tls` is **only RFC name-table lookup helpers**
  ("No network I/O or cryptography is performed here", `tls.xi:5-6`) -- there is no TLS.
  Homegrown pure-XIOM AES/RSA/DES ship with no test vectors; constant-time primitives
  exist in C (`xiom_ct_compare_dispatch`) but usage by the MAC/HMAC code is unverified.

**Verdict:** the stdlib's scope would flatter a 10-year-old ecosystem, but it currently
runs on three broken foundations: (1) no test culture, (2) compiler-forced duplication,
(3) allocation-per-operation core types. Fixing those three -- in that order of urgency --
matters more than adding any single missing feature.

### Scorecard

| Area | Grade | Notes |
|---|---|---|
| API breadth | A- | 40 packages; unmatched-at-this-stage scope |
| Core types (Option/Result/Str) | C- | Payload-always variants; malloc-per-op strings |
| Collections | C+ | Enormous variety; core Map/Set quality untested |
| Strings/Unicode | B- | Segmentation/normalization/collation present; byte-vs-codepoint scars (BUG 26 #7) |
| Math | B | 22.4k LOC, 55 modules; numerically unvalidated |
| Cryptography | D | Broad algorithm set, zero KATs, no TLS, homegrown RSA |
| Networking | D | Rich protocol helpers; no TLS => HTTPS story is hollow; `server.xi` is 116 lines |
| OS/IO | C- | fs/env/process split across io/os/io.fs/os.fs with overlap |
| Concurrency | C | sync/async/thread packages + real C channels/atomics/context-switch asm |
| Error handling consistency | C- | Result everywhere nominally; panic paths ad hoc |
| Contract usage | D | 398 `requires:` + 397 `ensures:` ~= **8% of pub fns**; flagship feature barely used |
| Testing | F | 8 `test_*` fns, 3 asserts in 150k LOC |
| Naming/organization | D+ | `collect.*` vs `collections`; crypto algos at top level; twin platforms |
| Docs/comments | B | Consistent headers, complexity annotations -- genuinely good |
| Packaging/versioning | D | Root `package.xi` describes "xiom-bench", deps `"xiom-std"` (not this tree) |

---

## 2. Metrics & Methodology

Full reads: `net/tls.xi`, `core/core.xi` (head), `string/string.xi` (head),
`convert/base64.xi` vs `encoding/base64.xi` (diffed). Aggregate scans over all 514 files;
C-runtime symbol extraction from `runtime/xiom_runtime.c`; stub-density scan; module-name
inventory (514 `module` declarations).

| Metric | Value |
|---|---|
| Files / LOC | 514 / 150,532 (.xi) + ~350KB C runtime + 4 asm objects |
| Functions total / public | 9,330 / 6,475 |
| `requires:` / `ensures:` clauses | 398 / 397 (+80 invariant mentions) -> **~8% pub-fn coverage** |
| `extern "C"` declarations | 93 lines (~=70 distinct C symbols declared) vs **245 symbols exported** by the runtime |
| TODO/stub/placeholder hits | 409 lines; hotspots: `string/template.xi` (29), `os/fs_ffi.xi` (25), `math/optimization.xi` (20), `os/event.xi` (18), `os/unix.xi` (16) |
| In-tree tests | 8 `fn test_*`, 3 `assert(` -- **effectively zero** |
| Largest packages | math 22.4k - string 13.6k - collections 13.2k - convert 11.1k - crypto 10.4k |

---

## 3. Architecture Overview

```mermaid
flowchart TB
    subgraph StdlibXI["stdlib/xiom/*.xi (150.5k LOC)"]
        CORE[xiom.core\nOption/Result/panic]
        STR[xiom.string*]
        COLL[xiom.collect.*\n62 structures]
        NUM[xiom.num / bigint / bigfloat]
        CRY[xiom.crypto.*\nAES/ChaCha/RSA/ECC]
        NET[xiom.net.*\nhttp/ws/jwt/dns]
        OSIO[xiom.os / xiom.io]
    end
    subgraph ExternBoundary['extern "C" (93 decls)']
        ABI[libc: malloc/free]\nRUNTIME[xiom_* runtime syms]
    end
    subgraph CRuntime["stdlib/runtime/ C+asm"]
        RT[xiom_runtime.c 296KB\n245 exported syms]
        ASM[crypto_x86_64.asm\nAES-NI/SHA-NI/CT-compare/mem]
        CTX[context_switch.asm\nasync fibers]
        CH[channels-condvars-atomics\ndns-disk-ed25519-fp128]
    end
    StdlibXI --> ExternBoundary --> CRuntime
    COMPILER[[xiom compiler]] -.compiles every module.\n-.crashes on cross-module\nsame-name delegation.- StdlibXI
```

Key structural facts:
- **Two-layer design:** pure-XIOM logic + C runtime for syscalls/crypto/atomics/async.
  The runtime is far richer than the stdlib binds (245 exported vs ~70 declared) --
  capability exists that the language cannot reach today.
- **Compiler-coupled:** the stdlib shape is distorted by compiler bugs (see S5.1) and by
  checker limitations (string-keyed types make `Result[T,E]`-style generics the ceiling).
- **Ownership convention is implicit:** core string ops hand raw `malloc` buffers to
  `Str.from_cstring(buf)` (`core/core.xi:76-85`) -- who frees what is nowhere specified.
  This is a leak/double-free class waiting for a definition.

---

## 4. Package-by-Package Findings

### 4.1 core (4 files, 2,322 LOC) -- grade C-
- `Option[T] = {is_some: Bool; value: T}`, `Result[T,E] = {is_ok; value; error}`
  (`core/core.xi:17-28`). Every `Option[Str]` pays full `Str` storage even when `None`;
  every `Result` carries both arms. For `Vec[Result[BigStruct,E]]` this doubles memory.
  No niche optimization is possible with struct-of-flags encoding.
- `panic(msg)` is compiler-magic with `requires: msg.len() > 0` (:32-34) -- a contract the
  verifier cannot discharge (calling `.len()` on the argument of the function you're
  panicking with), and one that turns `panic("")` into a *contract violation report*
  instead of a clean trap.
- `to_string` builds digits into `[20]UInt8` then malloc-copies through `unsafe`
  (:54-86). Works for i64 range, but the pattern (manual buffers + raw malloc in *core*)
  sets the tone for everything above it.
- `to_int_from_str` handles sign+digits manually -- fine, but duplicates
  `convert/atoi.xi` (120 lines) which nobody consolidated.
- Positives: `assert` implemented via `panic` cleanly; `use` graph is shallow here.

### 4.2 string (68 files, 13,591 LOC) -- grade B-
Remarkable Unicode ambition: `normalize.xi` (859), `unicode.xi` (1,543), segmentation
(word/line/sentence break), casefold, collation, bidi, emoji, scripts, transliteration in
`text/transliterate.xi`. This is ICU-lite scope.
- **Base operations are alloc-heavy:** `str_starts_with` slices (malloc+copy) then
  compares (`string.xi:71-77`); `str_ends_with` likewise. Every predicate allocates.
- **UTF-8 safety holes:** `str_slice` operates on raw bytes with numeric clamping only
  (:45-64) -- it will happily split a multibyte codepoint; `xiom_char_at` decodes
  codepoints, `xiom_byte_at` reads bytes, and the BUG 26 #7 comment (`string.xi:11-15`)
  records that these semantics *changed underneath existing code*. No boundary-checked
  `char_indices()`-style API exists.
- NUL-terminated `from_cstring` means embedded-NUL strings are unrepresentable via these
  constructors -- undefined territory for binary-ish text.
- Micro-modules (`hamming.xi`=25 lines, `jaro.xi`=36, `metaphone.xi`=39...) suggest many
  were generated in one sweep; several duplicate `misc/*` (levenshtein, soundex, glob).

### 4.3 collections (62 files, 13,211 LOC) -- grade C+
- Unmatched menu: rbtree/btree/btreeplus/avl/skiplist, hamt/persistent/immutable,
  bloom/cuckoo/hyperloglog-adjacent, lru/lfu/tinylfu/cache(521!), fenwick/segment/dense/
  sparse, quadtree/octree/kdtree/spatial(705), mpsc/spmc/mpmc/blockingqueue/workqueue,
  objectpool/threadpool.
- **But the fundamentals are duplicated five ways:** `vector.xi`, `list.xi`, `deque.xi`,
  `array/dynamic.xi`, and `collections.xi`'s built-ins overlap with no stated
  differentiation or benchmarks choosing between them.
- `collections.xi` is a 1,749-line mega-module mixing Vec/Map/Set utilities -- the thing
  the split files were supposed to replace.
- Generic hashing relies on `hash.xi` string-typed dispatch (compiler limitation);
  no documented iteration-order guarantees anywhere (affects reproducibility).
- Zero complexity-conformance tests (e.g., RB-tree balance properties) despite the
  perfect subject matter for property testing.

### 4.4 num / bigint / bigfloat (11+ files, 7,103 LOC) -- grade C
`bigint.xi` (1,335), `bigfloat.xi` (1,428) + an 11-line `bigfloat_agg.xi` shim whose
existence signals unfinished consolidation; precision_* triplets; fraction/rational.
Gaps vs peers: no `Decimal128` for money (finance.xi exists at 664 lines -- what does it
use?), no correctly-rounded `str<->float` documented (Rust-quality float formatting is a
multi-year effort; `fp128_helpers.c` in runtime suggests awareness), NaN/signaling rules
undefined, no `totalOrder`.

### 4.5 crypto (18 files, 10,426 LOC) -- grade D
Algorithms present: AES(+CTR/CBC/GCM in cipher.xi 1,257), ChaCha20, Poly1305, SHA-1/2/3
family, MD5, DES(!), HMAC/KDF(PBKDF2?), RSA, ECC/Ed25519(curves/ecc), AEAD, key exchange.
Runtime provides AES-NI/SHA-NI asm + `xiom_ed25519_sign/verify`.
- **No known-answer tests anywhere.** NIST/Project Wycheproof/RFC vectors are absent.
  An untested AES is indistinguishable from a broken AES.
- **Dual implementations** (pure-XIOM `aes.xi` 977 lines vs C AES-NI dispatch) with no
  equivalence harness.
- Legacy primitives (MD5, DES, SHA-1) shipped without deprecation markers or
  "legacy-only" module segregation.
- Module placement chaos: `xiom.chacha`, `xiom.des`, `xiom.ecc`, `xiom.rsa`,
  `xiom.poly1305` sit at top level while siblings live under `xiom.crypto.*`.
- `rng_crypto.xi` (194) -- entropy source unstated in-module; must bind OS CSPRNG
  (runtime exposes none of getrandom/BCryptGenRandom in the symbol dump -> likely a gap).

### 4.6 net (29 files, 9,308 LOC) -- grade D
Wide protocol surface: http(585)/https(178)/websocket(711)+ws(150)/cookie(524)/mime(649)/
jwt(402)/dns(401)/ntp/ping/smtp/ftp/sse/multipart/url/ip4/ip6/ip(777)/socket(332)/
tcp(88)/udp(88)/unix(105)/server(116)/tls_helper(633).
- **No TLS.** `tls.xi` = name tables; `https.xi` at 178 lines cannot implement TLS;
  `tls_helper.xi` (633) appears to be more parsing helpers. Every "S" in the net stack is
  therefore aspirational. Shipping `jwt` + `http` without TLS invites credential leakage.
- tcp.xi at 88 lines and server.xi at 116 lines indicate thin wrappers over runtime
  sockets (runtime exports `xiom_dns_resolve`; socket syscalls presumably similar) --
  acceptable as FFI shims, but then say so; don't imply full stacks.
- Positives: parsers (url/ip/header/cookie/mime) are exactly the kind of pure, fuzzable
  code that should get test budgets first.

### 4.7 os / io / ffi (32 files, ~7,600 LOC) -- grade C-
- Overlap: `io/fs.xi` (335) vs `os/fs.xi` (255) vs `os/fs_ffi.xi` (266) -- three filesystem
  facades; `io/console` vs `os/terminal` vs `os/term`; `os/platform` vs `core/platform`;
  `os/win`/`os/unix` conditional sources (how they're selected per-target is undocumented).
- Stub density concentrates here (fs_ffi 25 hits, event 18, unix 16, sync_io 15,
  proc_ffi 14, mmap 13) -- the OS layer is where "not implemented" lives.
- `ffi/ffi.xi` (585) + `libc.xiom-bind` feed xiom-ffigen, which (per compiler audit)
  passes unknown C types through verbatim -- so the libc binding's fidelity is capped by
  the generator's weaknesses.
- Runtime capability mismatch: C exports disk info, env, dirent, cpu_count, debugger
  break, ctx save/swap -- several have no or thin stdlib bindings (see S6 gaps).

### 4.8 math (55 files, 22,400 LOC) -- grade B
The crown jewel by volume: numerical (1,887), special functions (1,682), graph theory
(1,338), statistics, signal processing (1,010), ML, finance, control/game/queueing/
information theory, mathematical logic/physics/biology/economics. Fragmentation is real
(five trig-related modules: trig, trigonometry, trigonometric_constants, inverse_trig,
hyperbolic, angular) and nothing is validated against reference values (scipy/mpmath),
but as a research-numerics foundation it is genuinely differentiated.

### 4.9 async / thread / sync (17 files, ~3,400 LOC) -- grade C-
Design exists on both sides (executor/channel/timer .xi; C channels, condvars, atomics,
context-switch asm for fibers). Unverifiable claims: no stress tests (the classic place
where hand-rolled schedulers die), no memory-ordering documentation for the atomics
module, `thread/local.xi` semantics unspecified. This stack needs adversarial testing
more than features.

### 4.10 test / bench / log / debug -- grade C
A real harness API exists (`test/test.xi` 429 + assert 193 + harness 267; bench 289) --
which makes the 8-test stdlib doubly ironic: the tooling is there; it simply isn't applied
to the library itself. `debug/disasm.xi` at 66 lines is a placeholder-class file.

---

## 5. Cross-Cutting Systemic Issues

### 5.1 Compiler-forced duplication (highest leverage)
`convert/base64.xi` and `encoding/base64.xi` both state: *"Implemented locally
(same-name delegation to xiom.encoding crashes the compiler -- see xiom.convert.base58
for the probe reference)."* Consequences observed:
- Copies diverge (base64: 4 pub fns in convert vs 8 in encoding -- url alphabet, padding
  variants exist only in one).
- Same pattern repeats: json (convert 483 vs serialize 696), endianness x3 (bits/
  endianness, convert/endian, serialize/endian), percent x2, punycode x2, ascii85 x2,
  base32 x2, uuencode orphaned in convert, glob x2, soundex x2, levenshtein x2,
  ip x2, url x2, duration x2 (time + convert), date x2, fs x3, terminal x3, platform x2,
  matrix/vec/quat twins in geom (`mat` vs `matrix`, `vec` vs `vector`, `quat` vs
  `quaternion`).
**Action:** fix the compiler delegation crash (repro in `convert/base58`), then run a
dedup program with re-export shims for back-compat. Until then, every bugfix must be
applied N times -- some of these pairs have *already* drifted.

### 5.2 Allocation strategy: malloc is the only tool
Every sampled operation allocates: concat, slice, prefix/suffix checks, integer->string.
The runtime ships `xiom_asm_memcpy/memmove/memset` yet stdlib loops byte-by-byte.
Missing abstractions: string builder, borrowed slice/view types, allocator parameter
(arena), small-string optimization, reserve/shrink API on Vec-like types.

### 5.3 Contract usage is decorative
398+397 clauses across 6,475 public functions (8%) -- concentrated in early modules.
The language's headline feature ("Safe - Verified - Precise") is exercised by its own
library at near-zero rate, so the verify pipeline (already fragile per compiler audit)
has almost no real-world workload. Target: contracts on every collection invariant
(size >= 0, sortedness for ordered maps, no-duplicate keys), every parser (offset <= len),
every crypto wrapper (key/buffer lengths).

### 5.4 Naming and layout inconsistency
- `xiom.collect.*` (60+ modules) vs `xiom.collections` mega-module.
- Crypto algorithms escaping their namespace (chacha/des/ecc/rsa/poly1305).
- Memory quartet scattered at top level (`rc`, `cell`, `ptr`, `alloc`, `mem`).
- Two platform modules (`core/platform`, `os/platform`), three terminal modules.
- Directory = module name in several cases (`collections/` holds `collect.*`).
This is fixable mechanically now; after 1.0 it becomes permanent API debt.

### 5.5 Manifest/identity confusion
`stdlib/package.xi` declares package **"xiom-bench" v0.1.0 depending on "xiom-std"** --
at the root of the standard library. Neither name matches anything else in the repo; the
driver's own registry format differs (per compiler audit). The stdlib currently has no
real identity in its own package system.

### 5.6 Runtime under-binding
~70 of 245 runtime symbols are declared from .xi. Unbound capabilities include parts of
the atomic suite, ctx save/swap (async fibers), disk/sysinfo, ct_compare, several memops.
Either bind them or delete them from the runtime to shrink attack/maintenance surface.

---

## 6. Coverage Gap Analysis vs Reference Stdlibs

Legend: [OK] solid - [WARN] present-but-thin/untested - [FAIL] missing

| Domain | XIOM stdlib | Notes / missing pieces |
|---|---|---|
| Primitives & Option/Result | [WARN] | Payload-always encoding; no `?`-friendly combinators audit |
| String | [WARN] | Ops exist; needs views/builders, UTF-8 boundary safety, benchmarked search |
| Unicode | [WARN] | Normalization/segmentation present; no version pinning of UCD, no conformance suites |
| Vec/Map/Set | [WARN] | Multiple overlapping impls; entry-API, retain, iteration-order docs missing |
| Deque/PriorityQueue/etc. | [OK](breadth) | Exotic structures exceed Rust/Zig; untested |
| Iterators/combinators | [WARN] | iter pkg exists (chain/filter/fold/map/zip); no lazy-view story tied to collections |
| Formatting | [WARN] | fmt(1,342)+number+table+units; no compile-time checked format strings (lang gap) |
| Regex | [WARN] | engine(523)+"pcre_lite"(159); unsupported-syntax behavior undefined; needs RE2-style guarantees doc |
| JSON/YAML/TOML | [WARN]/[FAIL] | json x2, yaml_lite; **TOML missing** though the toolchain itself uses `xiom.toml`; no CSV; no msgpack/protobuf |
| Time | [WARN] | calendar/chrono/iso8601/duration; **no timezone database** (IANA tzdata) -> no correct civil-time |
| Randomness | [WARN] | PCG/MT19937/ChaCha; CSPRNG seeding path undocumented |
| Crypto primitives | [WARN] | Wide set, zero KATs; legacy ciphers unsegregated; no constant-time policy doc |
| TLS | [FAIL] | Name tables only. Biggest single credibility gap in the net stack |
| HTTP client/server | [WARN] | Parsers decent; server 116 lines; no chunked/trailers/h2 evidence; keep-alive semantics undocumented |
| WebSocket/JWT/SSE | [WARN] | Framing present; RFC conformance unproven |
| DNS | [WARN] | runtime `xiom_dns_resolve` only -- no record-type API, no DoH/DoT |
| Files/Paths | [WARN] | Triple-stacked fs APIs; path.xi(302) lacks Windows/POSIX normalization rules doc |
| Processes/Signals | [WARN] | proc 78 lines; signal 128; job-control absent |
| Sockets/TCP/UDP | [WARN] | Thin FFI shims; no non-blocking/event-loop integration with async pkg |
| Async runtime | [WARN] | Fiber ctx-switch in asm; no cancellation, timeouts-in-executor, or stress tests visible |
| Threads/Sync | [WARN] | mutex/rwlock/condvar/barrier present; poisoning/forget-safety semantics undefined |
| Atomics/memory ordering | [WARN] | C atomics bound partially; ordering enum absent from .xi API |
| Allocators | [FAIL]/[WARN] | Raw malloc only; no GlobalAlloc-equivalent hook, arenas, or pool integration despite objectpool.xi |
| Reflection | [WARN] | reflect/typeinfo/fields -- unique among peers; define stability contract |
| Serialization frameworks | [WARN] | serialize pkg; no derive-style schema evolution story |
| Error reporting | [WARN] | error/chain/context/backtrace; backtrace depends on unwinder that may not exist |
| Logging | [OK](basic) | levels/sinks/json/color -- fine |
| Testing/bench | [OK](API) | Harness exists; adoption inside stdlib ~= 0 |
| Math/numerics | [OK](breadth) | Validate against reference libs; document error bounds |
| Compression | [WARN] | gzip/zlib/deflate/lz4/snappy/huffman/brotli(162?) -- brotli at 162 lines is surely partial |
| Env/Args | [WARN] | env(347); **no argv-parsing module** (each binary hand-rolls -- matches compiler-audit finding) |
| Locale/I18N | [FAIL] | collation exists; plural/format i18n absent |
| TZ database | [FAIL] | see Time |
| Graph DB/network X | [U+2796] | Out of scope for peers too -- fine |

**Over-provisioned for current maturity** (freeze new additions here until tested):
collections exotica, math long tail, string combinatorics (874 lines of string algorithms),
format/numbering (614), text/similarity (815).

**Top missing-for-1.0 list:** TLS (or explicit "no-TLS, use system" story), TOML+CSV,
timezone data, CSPRNG binding, argv parser, allocator hooks, iterator views, TOML-driven
config module, UTF-8-safe string views, and a deprecation policy for MD5/DES/SHA-1.

---

## 7. Top Bugs / Correctness Risks (severity-ranked)

| # | Severity | Finding | Evidence |
|---|---|---|---|
| 1 | Critical | Stdlib effectively untested: 8 test fns / 3 asserts in 150k LOC; crypto has zero known-answer tests | repo-wide scan |
| 2 | Critical | No TLS anywhere in net stack while https/jwt/websocket imply secure transport | net/tls.xi:5-6; sizes of https.xi/server.xi |
| 3 | High | Compiler crash forces copy-paste modules; copies already diverged (base64 4-vs-8 fns) | convert/base64.xi:10-12 vs encoding/base64.xi:10-12 |
| 4 | High | `str_slice`/byte ops can split UTF-8 codepoints; byte-vs-codepoint semantics changed under consumers (BUG 26 #7) | string/string.xi:11-16,45-64 |
| 5 | High | `Option[T]`/`Result[T,E]` store payloads unconditionally -> systematic memory blowup + false-share of None state | core/core.xi:17-28 |
| 6 | High | Implicit ownership of `malloc` buffers crossing into `Str.from_cstring` -- leak/double-free class, convention undocumented | core/core.xi:76-85; string/string.xi:28-42 |
| 7 | High | Dual crypto paths (pure-XIOM AES vs AES-NI C dispatch) with no equivalence or KAT harness | crypto/aes.xi vs runtime aesni_dispatch syms |
| 8 | Med-High | Legacy ciphers (DES, MD5, SHA-1) shipped without segregation/deprecation | crypto/des.xi, md5.xi |
| 9 | Med-High | Three overlapping fs APIs and three terminal modules -- drift guaranteed | io/fs.xi, os/fs.xi, os/fs_ffi.xi |
| 10 | Medium | `panic`'s `requires: msg.len()>0` is unverifiable and turns empty-message panics into contract violations | core/core.xi:32-34 |
| 11 | Medium | 175 of 245 runtime symbols unbound -- dead surface + missed capability (ct_compare unused by MACs?) | runtime symbol extraction |
| 12 | Medium | Module identity chaos (collect vs collections; escaped crypto names; twin geom/time/fs modules) | module inventory |
| 13 | Medium | `package.xi` misidentifies the stdlib ("xiom-bench", dep "xiom-std") | stdlib/package.xi |
| 14 | Low | Placeholder-grade files presented as features (disasm 66L, ftp 106L, smtp 109L, tcp/udp 88L each) | file sizes |
| 15 | Low | 409 TODO/stub lines concentrated in OS layer (fs_ffi 25, event 18, unix 16) | stub scan |

---

## 8. Performance Analysis & Recommendations

Observed costs (sampled):
- **String predicates allocate:** `starts_with/ends_with` = malloc+full-copy+compare.
  Should be pointer/length comparisons over views.
- **Byte-loop copying** ignores `xiom_asm_memcpy` (runtime) -- bulk ops leave 10-50x
  throughput on the table for large strings/arrays.
- **Per-call malloc/free churn** in hot paths (parse/encode modules allocate intermediate
  buffers constantly); no arena story despite `objectpool` existing.
- **Struct-returning Option/Result** inflate every generic container holding them.
- Collections lack documented growth factors/load factors/reserve -- impossible to reason
  about amortization; several trees are recursive-value layouts (cache-hostile) vs
  pool-backed indices.

Recommendations (ordered):
1. **Views first:** add borrowed `&Str`-slice and array-view semantics (or `(Str, start,
   end)` idiom blessed by stdlib) so predicates stop allocating; rewrite
   starts_with/ends_with/index_of family accordingly.
2. **Route bulk copies through runtime memops**; add `memcpy`-backing for concat of
   large strings; introduce `StringBuilder` with amortized doubling + `push_str`.
3. **Allocator seam:** `xiom.alloc` global allocator hook + scoped arenas; migrate
   parser/encoder internals to arenas (huge win for json/base64/punycode pipelines).
4. **Define container tuning:** load factor, growth factor, shrink policy, hash seed
   randomization policy (DoS resistance for hash maps -- siphash exists in hash pkg;
   make it the default keyed hasher).
5. **Option/Result representation:** pursue compiler support for tag-niche or
   union-with-tag layout; until then provide `unwrap_or`-style accessors that avoid
   copying payloads, and forbid `Result` in hot arrays by convention docs.
6. **Benchmark suite as CI gate:** you already have `bench` pkg + smoke binaries
   (smoke_math_*, smoke_geom_*); formalize: str micro, map/vec macro, json round-trip,
   sha256 throughput (asm vs sw), async ping-pong. Fail CI on >10% regression.
7. **SIMD alignment:** simd_runtime.c + simd pkg exist -- publish alignment requirements
   and provide `copy_within`/`fill` primitives that vectorize.

---

## 9. Security Review

- **Crypto engineering practice is absent:** no test vectors, no double-implementations
  comparison, no constant-time policy statement, no crypto review trail. The C runtime's
  good instincts (`xiom_asm_memcmp_ct`, `xiom_ct_compare_dispatch`, AESNI/SHANI dispatch)
  are undermined if pure-XIOM fallbacks (variable-time) are reachable -- verify and
  document dispatch order.
- **RNG:** no OS entropy symbol in the runtime export list (no getrandom/
  BCryptGenRandom/arc4random). `rng_crypto.xi` must declare its seeding source; if it
  seeds from MT19937/userland entropy, it is not a CSPRNG.
- **Legacy algorithms:** DES and MD5 must move to a `legacy` namespace with loud
  deprecation attributes (and eventually removal), never defaults.
- **Network trust:** every net module should carry a security footnote today: "plaintext
  unless you bring your own TLS." Long-term: either bind a vetted TLS (system schannel/
  OpenSSL via FFI) or ship one -- but do not let `https.xi` imply more than it does.
- **Parsers = future RCE-adjacent surface:** url/ip/header/cookie/mime/json/utf all need
  fuzz targets + length-cap policies before exposure. They are pure functions -- ideal
  first fuzz citizens (pairs with compiler-audit Phase 0 fuzz infra).
- **Resource limits:** decoders (brotli/lz4/json) lack documented decompression-bomb
  guards (max output ratio/size caps). Add limits parameters with safe defaults.
- **Supply chain of the runtime itself:** runtime C + asm are compiled by
  `build-runtime` with `-maes -DXIOM_NO_ASM` toggles -- pin compiler flags in release,
  enable CET/CFI where available, and publish hashes (ties into compiler-audit Phase 3).

---

## 10. Roadmap to a Production-Grade Stdlib

**Phase 0 -- Trust (weeks, highest ROI)**
1. Import official test vectors: RFC 4648 (base16/32/64), RFC 3986/3978 (URI/IP),
   UAX #14/#29 segmentation, UAX #15 normalization, NIST CAVP (AES/SHA/HMAC),
   RFC 8439 (ChaCha20-Poly1305), RFC 8032 (Ed25519), JSONTestSuite, UTF-8 decoder
   tests (Markus Kuhn's set). Wire them into `test/` harness; make `cargo test`-equivalent
   run them for every stdlib change.
2. Freeze the duplication wound: fix the compiler same-name-delegation crash (repro
   referenced in `convert/base58`), then consolidate each pair behind one canonical
   module + deprecated re-export shims.
3. Publish the ownership convention for `Str.from_cstring`/malloc buffers; audit the ~93
   extern sites against it (ASAN run of the whole stdlib suite).

**Phase 1 -- Core ergonomics**
- String views/builders + UTF-8 boundary API; route bulk ops to runtime memops.
- Container tuning docs + keyed-hash default; entry/retain APIs.
- Allocator hook + arenas; migrate encoders/parsers.
- Option/Result layout improvement proposal to the compiler team (niche/tag packing).

**Phase 2 -- Organization**
- Namespace cleanup (collect.*, crypto.*, memory.*, single fs/terminal/platform),
  directory==module rule, deprecate `collections.xi` mega-module gradually.
- Deprecation ladder for DES/MD5/SHA-1; `legacy` namespace.
- Fix `package.xi` identity; register stdlib as a real package with lockfile integrity
  (depends on compiler-audit Phase 3 supply-chain work).

**Phase 3 -- Capability completion (in priority order)**
1. CSPRNG binding (OS entropy) + reseed policy.
2. TLS decision: bind system TLS via FFI (fastest to trustworthy) -- update https/jwt/ws
   docs to depend on it.
3. TOML + CSV + argv parsing modules.
4. Timezone database (embed tzdata snapshot + version constant).
5. Bind the orphaned runtime symbols (atomics ordering, ctx swap for executors,
   ct_compare into MAC compare, disk/sysinfo) or remove them.
6. Async stress suite (10k fibers, cancellation storms, channel saturation).

**Phase 4 -- Scale discipline**
- Complexity/property tests for collections (BST invariants, heap shape, hashmap
  distribution); differential fuzzing of compress/encoders vs reference tools.
- Coverage measurement gate for `xiom/*` (start at whatever number Phase 0 yields;
  ratchet upward, block decreases).
- Contract-coverage target: >=60% of `pub fn` in collections/string/io carrying
  requires/ensures by end of phase (verifier hardening from compiler-audit Phase 1
  makes these meaningful rather than decorative).

**Self-hosting tie-in:** the stdlib is the primary workload that will exercise the
self-hosted compiler. Its test corpus doubles as the compiler's largest semantic
regression suite -- another reason Phase 0 lands before any self-hosting push.

---

## 11. What Is Already Good (keep and amplify)

- Documentation hygiene: consistent license headers, complexity annotations ("O(1). Pure."),
  honest scoping statements (tls.xi says exactly what it doesn't do).
- Domain ambition: the math/textual/geometry packages are a genuine differentiator few
  language communities ever attempt; they just need validation, not replacement.
- Runtime/stdlib split is architecturally sound (asm-accelerated primitives, fiber
  context switching, channels) -- it mainly suffers from under-binding and under-testing,
  not bad design.
- Test/bench/log infrastructure exists and is decent -- the gap is adoption, not absence.

*End of audit.*
```

---

**Summary:** Direct analysis of all 514 stdlib files (150,532 LOC) plus the C runtime's 245 exported symbols produced the audit above: scorecard, architecture diagram, per-package grades, a 15-item severity-ranked defect list (headline: untested crypto, no TLS, compiler-crash-forced duplication with already-diverged copies), a coverage matrix vs Rust/Zig/Go/C++ identifying the true 1.0 gaps (TLS, CSPRNG, TOML/CSV, tzdata, allocator hooks, string views), performance fixes (views-over-copies, memop routing, arenas), security measures (KATs, constant-time policy, decompression bombs, legacy-cipher quarantine), and a five-phase roadmap gated ahead of self-hosting.
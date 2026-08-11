# XIOM Standard Library & Package Architecture Plan

> **Status: PLANNING (v0.56.0, 2026-08-07)**
> **Owner:** Compiler team â€” `feat/architect`
> **Strategy: CLEAN BREAK NOW, 3 tiers, ZERO test churn.** The language is pre-public
> and the monorepo will be split into separate repos before going public (no history
> to preserve) â€” so we build the stdlib the RIGHT way now, with no shims, no
> deprecation windows, no legacy compat.
> **Constraint:** Stdlib = `stdlib/xiom/`, packages = `packages/`, external projects =
> repo top level. This document is the master plan; it only POINTS at locations.
> Placeholder folders + READMEs for planned packages/projects are created now; specs
> come later.

---

## 1. Strategy & Principles

### 1.1 The three-tier plan

| Tier | What | Test churn |
|------|------|-----------|
| **Tier 1 â€” Cleanup & consolidation** | Delete `demo`; absorb orphan/duplicate modules into their canonical homes (`b64`/`hex`â†’`encoding`, `random`â†’`rand`, `runner`/`types`â†’`bench`, `ed25519`/`pbkdf`â†’crypto family) | **ZERO** (all orphans have 0 external import sites) |
| **Tier 2 â€” Reorganization** | Split huge domains into proper module families: **math** â†’ `num`/`bits`/`math`/`geom`/`complex`/`bigint`/`stats`/`rand`/`convert`; **crypto** â†’ `crypto`/`sha`/`md5`/`aes`/`chacha`/`poly1305`/`ecc`/`rsa`/`des`. No forced renames of the 40 test-imported modules. | **ZERO** (splits are new modules + internal moves) |
| **Tier 3 â€” Comprehensive expansion** | Fill every gap to production grade: full string/UTF-8, sorting, searching, Date/ISO8601, bigint, complex, geom, full crypto suite, more hashes, more compression, platform abstraction, debug, misc algos | **ZERO** (additive: new fns + new modules) |

### 1.2 Principles

1. **Stdlib has NO external dependencies** â€” only pure XIOM + OS syscalls via minimal FFI + the compiler substrate (LLVM/clang, NASM) the language is built on.
2. **Packages build ON stdlib**; may wrap third-party C libraries (FFI).
3. **External projects** (frameworks, engines, apps) live at repo top level: `xiom-pulse` (Node.js-like web framework), `xiom-game-engine`, and the existing ones (`xiom-db`, `xiom-vector`, `xiom-playground`, â€¦). They are NOT packages.
4. **The no-break contract = module name + public fn signature** of the 40 test-imported modules (2,090 regression files, 687 smokes, eco fixtures, 66 packages). Both `use xiom.x;` and `use stdlib.xiom.x;` must keep resolving.
5. **No shims, no deprecation cycles.** Pre-public: rename/delete freely, update callers in the same commit. Everything below is designed so that the *externally visible* surface (the 40 modules) stays byte-identical anyway.
6. **Every heavy domain gets a NASM/SIMD optimization track** (math, crypto, hash, compress) with pure-XIOM fallback + runtime dispatch (see Â§7).
7. **Clean state stays clean** â€” an API-freeze test (Â§10) snapshots all stdlib pub signatures after the rework.

---

## 2. Current State Inventory (scanned 2026-08-06 â€” read-only)

### 2.1 Stdlib â€” 51 modules in `stdlib/xiom/*.xi` (~1,300 pub fns)

| Module | fns | Module | fns | Module | fns |
|--------|----:|--------|----:|--------|----:|
| core | 72 | collections | 93 | math | 61 |
| io | 38 | os | 49 | net | 18 |
| sync | 46 | thread | 17 | async | 20 |
| crypto | 80 | sha | 38 | md5 | 11 |
| aes | 28 | ed25519 | 3 | pbkdf | 2 |
| compress | 29 | encoding | 27 | b64 | 4 |
| hex | 3 | serialize | 29 | string | 25 |
| char | 16 | convert | 8 | fmt | 15 |
| num | 43 | iter | 42 | cmp | 15 |
| hash | 11 | rand | 29 | random | 1 |
| time | 44 | env | 19 | path | 27 |
| ffi | 32 | ptr | 19 | alloc | 15 |
| mem | 14 | cell | 16 | rc | 17 |
| regex | 23 | reflect | 13 | contracts | 39 |
| error | 6 | log | 25 | simd | 26 |
| stats | 8 | bench | 5 | runner | 8 |
| types | 2 | test | 17 | demo | 10 |
| array | 23 | | | | |

**Orphans / duplicates (ZERO external imports â€” free to absorb):** `b64`, `hex`, `random`, `runner`, `types`, `stats`(keep, expand), `md5`(keep), `aes`(keep), `sha`(keep), `ed25519`, `pbkdf`, `demo`(DELETE).

### 2.2 Packages â€” 66 dirs in `packages/` (all `deps: xiom-std`)

- **Pure XIOM (15):** xiom-json, xiom-http, xiom-net, xiom-rest, xiom-graphql, xiom-websocket, xiom-micro, xiom-realtime, xiom-algo, xiom-math, xiom-core, xiom-ffi, xiom-log, xiom-test, xiom-arrow
- **FFI-bound (51):** openssl, libsodium, sqlite, postgres/libpq, redis, kafka, zeromq, grpc, protobuf, wasmtime, libuv, zstd, lzfse, tensorflow, libtorch/torch, onnx, numpy, pandas, scipy, blas, openblas, cuda, eigen, opencv, ffmpeg, sql, dxc, moveit, ros2, gazebo, sensor, control, bullet, jolt, box2d, ozz, meshopt, assimp, raylib, glfw, sdl3, imgui, ui, miniaudio, openal, portaudio, phonon, vulkan, opengl, directx11, directx12, vma, stb
- **Namespace note:** packages declare `module xiom.json`, `xiom.algo`, `xiom.http.client` â€” they share `xiom.*` with stdlib. Guarded by the reserved-name list (Â§3).

### 2.3 Test/ecosystem surface (the no-break contract)

- `tests/regression/` â€” 2,090 files, 467 with `use` imports
- `examples/stdlib_smoke/` â€” 687 files
- `tests/ecosystem/` â€” internal E2E fixtures
- 40 stdlib modules imported by tests: alloc, array, async, bench, cell, char, cmp, collections, compress, contracts, convert, core, crypto, encoding, env, error, ffi, fmt, hash, io, iter, log, math, mem, net, num, os, path, ptr, rand, rc, reflect, regex, serialize, simd, string, sync, test, thread, time
- Import forms: `use xiom.x;` + `use stdlib.xiom.x;` (35 files) â€” alias is a prefix rewrite (crates/xiom/src/lib.rs:2139), stays name-based.
- **Compiler hardcode to keep in mind:** `xiom.collections.Vec` (crates/xiom-codegen/src/lib.rs:2253/2270) â€” `collections` name must stay (it does).

---

## 3. Namespace Policy & Reserved Names

| Scope | Namespace | Rule |
|-------|-----------|------|
| Stdlib | `xiom.<name>` (`stdlib/xiom/<name>.xi`) | Reserved list below; no external deps |
| Package | `xiom.<name>` or `xiom.<pkg>.<feature>` | Only if name NOT reserved; else rename to `xiom.<pkg>.<feature>` |
| External project | repo top level | Depends on stdlib + packages like any user |

**Reserved by stdlib (monotonic â€” extend as stdlib grows):**
`core, io, os, sys, env, args, path, file, dir, time, date, duration, thread, sync, mutex, atomic, condvar, rwlock, semaphore, once, process, signal, memory, alloc, mem, ptr, ffi, string, str, utf8, utf16, char, array, slice, range, iter, vector, list, stack, queue, ring, deque, priority, map, set, tree, btree, rbtree, avl, heap, bheap, fheap, filter, num, math, int, uint, float, const, abs, minmax, clamp, sqrt, pow, log, exp, trig, atrig, hyper, floor, modf, ldexp, bit, bits, rotate, endian, crc, adler, checksum, bitarray, hash, fnv, murmur, city, xxhash, siphash, highway, composite, rand, random, mt, pcg, xorshift, chacha, dist, seed, source, crypto, sha, sha1, sha256, sha512, md5, blake2, keccak, aes, des, poly1305, curve25519, ed25519, rsa, dh, otp, entropy, kdf, hmac, padding, mode, compress, deflate, inflate, zlib, gzip, lz4, snappy, huffman, lz, rle, serial, binary, varint, fixed, zero, buffer, stream, sort, quick, merge, heap, insert, bubble, select, radix, count, tim, stable, search, binary, linear, interp, exponential, jump, ternary, concurrent, channel, select, spawn, join, future, promise, yield, convert, conv, parse, atoi, itoa, tostring, toint, tofloat, compare, replace, trim, split, join, case, strip, repeat, pad, slice, escape, printf, scanf, format, fmt, regex, reflect, typeid, align, offset, unsafe, builtin, callconv, platform, linux, windows, darwin, bsd, unix, posix, debug, trace, symbol, break, print, assert, source, perf, counter, cycle, bench, prof, test, misc, uuid, guid, version, semver, glob, diff, patch, natural, levenshtein, soundex, error, option, result, panic, defer, log, stats, simd, async, cell, rc, contracts, serialize, net, socket, tcp, udp, dns, ip, port, url, host, protocol, icmp, mac, websocket, sse, sql, sqlite, postgres, mysql, mongo, redis, oauth, jwt, tls, ssl, cert, x509, ldap, saml, bcrypt, argon2, password, sanitize, escape, audit, encrypt, decrypt, key, secret, vault, i18n, locale, translate, plural, collation, transliteration, unicode, icu, unit, currency, timezone, qrcode, slug, emoji, phone, email, geo, calendar, holiday, units, license, notice, legal, game, engine, physics, collision, particle, scene, entity, ai, pathfinding, steering, state, save, achievement, leaderboard, multiplayer, input, audio, ui, level, event, web, server, router, middleware, auth, session, cookie, cache, static, template, form, validation, csrf, xss, rate, cors, docs, ml, tensor, neural, deep, training, inference, optimizer, layers, activation, loss, metrics, dataset, preprocess, feature, selection, ensemble, boosting, randomforest, svm, clustering, dimensionality, media, image, png, jpeg, gif, bmp, webp, svg, mp3, wav, ogg, flac, aac, video, mp4, avi, mkv, codec, subtitle, embedded, gpio, i2c, spi, uart, adc, dac, pwm, interrupt, timer, rtc, eeprom, flash, sd, ble, zigbee, blockchain, ethereum, bitcoin, smartcontract, wallet, transaction, consensus, merkle, hashchain, nft, defi, web3, oracle, bridge, cloud, aws, azure, gcp, docker, k8s, terraform, ansible, puppet, chef, salt, helm, serverless, cfn, monitoring, tracing, metrics, alerting, scaling, util, logger, config, flag, option, retry, cache, pool, worker, lru, ttl, backoff, timeout, context, cancel, benchmark, profiling, fuzz, mock, stub, coverage, property, golden, snapshot, performance, security, compliance, report, compiler, parser, lexer, ast, codegen, optimizer, linter, formatter, analyzer, refactor, plugin, macro, inline, jit, wasm, llvm, geom, bigint, bigfloat, complex, sort, search`

---

## 4. TIER 1 â€” Cleanup & Consolidation (ZERO test churn)

All targets below have **0 external import sites** (verified 2026-08-06). Only internal stdlib cross-imports change (~15 statements).

| Action | Module | â†’ Canonical home | Internal imports to update |
|--------|--------|------------------|---------------------------|
| DELETE | `demo.xi` (10 fns, example cruft) | â€” | none |
| MERGE | `b64.xi` (4) | `encoding` (base64/base64url already there) | b64â†’encoding |
| MERGE | `hex.xi` (3) | `encoding` (hex already there) | hexâ†’encoding |
| MERGE | `random.xi` (1) | `rand` (random() already there) | randomâ†’rand |
| MERGE | `runner.xi` (8) | `bench` (benchmark reporting) | runnerâ†’bench.typesâ†’bench |
| MERGE | `types.xi` (2, BenchConfig/BenchSuite) | `bench` | arrayâ†’bench |
| MERGE | `ed25519.xi` (3) | `ecc` (new Tier-2 module) | none |
| MERGE | `pbkdf.xi` (2) | `crypto` (PBKDF2/HKDF) | pbkdfâ†’crypto |
| KEEP+EXPAND | `stats.xi` (8) | becomes full statistics module | â€” |
| KEEP | `md5`, `aes`, `sha`, `crypto` | crypto family (Â§5.2) | â€” |

**Result:** 51 â†’ 43 modules before Tier 2. Zero tests touched. `stdlib-pin/` snapshot regenerated at the end of the tier.

---

## 5. TIER 2 â€” Reorganization into Module Families

No forced renames of the 40 test-imported modules (their names are already good). Reorganization = NEW modules + internal moves. Two domains are split because they are huge and need optimization tracks: **math** and **crypto**.

### 5.1 Math family (split `math`/`num` + new modules)

| Module | Status | Scope |
|--------|--------|-------|
| `num` | KEEP/EXPAND | integer bounds, gcd/lcm, bit ops (count_ones/zeros, rotate, reverse_bits, byte_swap, bit read/write, endian conversion), power-of-two |
| `bits` | **NEW** | BitArray, bit reader/writer, bit streams, base-N conversion |
| `math` | KEEP/EXPAND (+NASM) | constants (Ï€/e/Ï„), abs/minmax/clamp, sqrt (fast), pow (int/float), trig (sin/cos/tan), inverse trig, hyperbolic, log (ln/log2/log10), exp, floor/ceil/round/trunc, modf, ldexp/frexp, fma, remainder, hypot, signum, lerp |
| `geom` | **NEW** | Vec2/3/4, dot/cross/normalize, Quaternion, Matrix2/3/4, transforms (translate/rotate/scale/look_at/projection), collision primitives (AABB/sphere/ray) |
| `complex` | **NEW** | Complex[T], arithmetic, conjugate, abs/arg, exp/log/pow/sqrt, trig |
| `bigint` | **NEW** | arbitrary-precision int, add/sub/mul/div/mod, pow, gcd, primality, base conversion (+NASM montgomery/multiply) |
| `stats` | EXPAND | mean/median/mode/stddev/variance/percentile/quartiles/min/max/sum, covariance, correlation, linear regression, histogram |
| `rand` | EXPAND | StdRng + MT19937, PCG, Xorshift, ChaCha; distributions: uniform/normal/exponential/binomial/poisson; seed/entropy |
| `convert` | EXPAND | int/float/string/bool/char, radix 2â€“36, float formatting (scientific/fixed), parse-from-str |

### 5.2 Crypto family (split `crypto` + new modules)

| Module | Status | Scope |
|--------|--------|-------|
| `crypto` | EXPAND (umbrella) | HMAC, KDF (PBKDF2, HKDF â€” absorbs pbkdf), entropy, OTP (HOTP/TOTP), padding (PKCS7), block modes (CBC/CTR/GCM/CCM), crypto_random, constant-time compare, random_bytes |
| `sha` | EXPAND | SHA-1, SHA-224/256/384/512, SHA-3 (Keccak), BLAKE2 (+SHA-NI asm) |
| `md5` | KEEP | MD5 digest (legacy) |
| `aes` | EXPAND | AES-128/192/256, ECB/CBC/CTR/GCM/CCM, constant-time (+AES-NI asm) |
| `chacha` | **NEW** | ChaCha20, XChaCha20, ChaCha20-Poly1305 AEAD |
| `poly1305` | **NEW** | Poly1305 authenticator |
| `ecc` | **NEW** (absorbs ed25519) | Curve25519, X25519, Ed25519 sign/verify, secp256k1 |
| `rsa` | **NEW** | keygen, encrypt/decrypt, sign/verify, OAEP/PKCS1v15 |
| `des` | **NEW** | DES/3DES |

### 5.3 Text family

| Module | Status | Scope |
|--------|--------|-------|
| `string` | MAJOR EXPAND | existing + UTF-8 encode/decode/validate, codepoint iteration, UTF-16, case (upper/lower/title), strip, pad, repeat, escape/unescape, printf/scanf, format, index_of/rfind, replace_all, split (multi-delim), join, is_* predicates, char_at/byte_at, byte_len, reverse, natural compare |
| `char` | EXPAND | full Unicode categories, case conversion, to_digit/from_digit, codepointâ†”UTF-8 |
| `utf8` | **NEW** | dedicated UTF-8/UTF-16 codec + validation + BOM handling |
| `fmt` | EXPAND | Formatter, to_str, format1â€“9, printf-style, table, columns, wrap, indent, hexdump, pretty, duration/date formatting |
| `regex` | EXPAND | full syntax: quantifiers, groups, alternation, classes, anchors, lookahead, captures, replace, split, find_iter |

### 5.4 System family

| Module | Status | Scope |
|--------|--------|-------|
| `io` | EXPAND | console + stdin/out/err, buffered IO, seek/flush, file modes, append, binary read/write |
| `os` | EXPAND | platform, cpu, memory, env, cwd, perms, links + pipe, fd, dup, select/poll, mmap, stat, rename/remove, realpath, temp, mkdir/rmdir, walk |
| `process` | **NEW** | spawn, exec, wait, exit_code, signals, stdio redirect |
| `env` | KEEP | var/args/current_exe/dirs |
| `path` | EXPAND | Path/PathBuf: normalize, is_absolute, join, extension ops, components |
| `time` | MAJOR EXPAND | Duration (full) + **Date** (y/m/d, weekday, ordinal), ISO 8601 parse/format, RFC 3339, timestamp conversion, tick/timer, stopwatch |
| `thread` | EXPAND | spawn/join/sleep/yield/scope + park/unpark, thread-local |
| `sync` | EXPAND | Mutex/RwLock/Atomics/Condvar/Once + Semaphore, Barrier, CountDownLatch, channel select |
| `async` | EXPAND | Executor + Future, Promise, timer wheel, spawn_blocking |
| `platform` | **NEW** | OS detection, arch, endianness, page size, cfg helpers (linux/windows/darwin/bsd/unix/posix) |
| `debug` | **NEW** | stack trace, source location, symbol name, breakpoint, hexdump, timing |

### 5.5 Collections & Algorithms

| Module | Status | Scope |
|--------|--------|-------|
| `collections` | EXPAND | Vec (+all), Map (open addressing), Set, VecDeque, BinaryHeap, LinkedList + HashMap (chaining), Tree, AVL, RBTree, FibonacciHeap, PriorityQueue, RingBuffer |
| `iter` | EXPAND | range variants; Iterator: map/filter/enumerate/take/skip/chain/zip/flat_map/fold/reduce/collect/sum/product/any/all/count/nth/last/position |
| `sort` | **NEW** | quick/merge/heap/insert/bubble/select/radix/count/tim/stable + partial_sort, nth_element, is_sorted, sort_by |
| `search` | **NEW** | binary/linear/interp/exponential/jump/ternary + lower_bound/upper_bound, search_range |
| `cmp` | KEEP | Ordering, min/max/clamp, min_by/max_by |
| `array` | EXPAND | fixed-size array ops: len/get/first/last/map/zip + sort/search on arrays |

### 5.6 Encoding & Data

| Module | Status | Scope |
|--------|--------|-------|
| `encoding` | EXPAND (absorbs b64/hex) | base16/32/64/base64url, hex, percent-encoding, URL encoding |
| `serialize` | EXPAND | binary read/write, varint, fixed, zero-copy, buffer, stream, JSON (kept) |
| `hash` | EXPAND | DefaultHasher, siphash + fnv1a, fnv1, murmur3, xxhash32/64, city, highway, composite (+SIMD) |
| `compress` | EXPAND | gzip/deflate/inflate/zlib/rle + huffman, lz77/lz78, lz4, snappy |

### 5.7 Language core & quality

| Module | Status | Scope |
|--------|--------|-------|
| `core` | EXPAND | panic/assert, Option/Result helpers, tuple ops, conversions, INT_MAX/MIN, size_of, is_sorted/all/none/contains, identity |
| `error` | EXPAND | Error trait, chain, wrap/context, capture_backtrace, display, exit codes |
| `reflect` | EXPAND | TypeId, type_name/size/align/field_count, field names/offsets, variant info, is_primitive/is_struct/is_enum |
| `contracts` | KEEP | registry, verify_invariants, check_invariant, pre/post |
| `test` | EXPAND | assert family + property-based (for_all), golden files, snapshots |
| `bench` | EXPAND (absorbs runner/types) | run_bench(_n), black_box, compare, BenchConfig/BenchSuite, reports, cycle counter, allocation tracking, profiling |
| `log` | EXPAND | levels, text/json entries, sinks, rotation, structured fields |
| `misc` | **NEW** | uuid v4, guid, semver, version compare, glob, diff (Myers), patch, levenshtein, soundex, natural sort, slug, units |

### 5.8 Networking

| Module | Status | Scope |
|--------|--------|-------|
| `net` | EXPAND | TCP/UDP sockets, DNS, addresses, http_get/post, IPv6, URL parse, host/port, protocol helpers, ICMP ping |

**Target stdlib: ~57 modules** (51 âˆ’ 6 absorbed/deleted + 12 new in Tiers 1â€“2, then Tier 3 additions). Every existing pub fn signature preserved.

---

## 6. TIER 3 â€” Comprehensive Expansion (the "go nuts" coverage)

Every module above carries its full coverage list (Â§5). The expansion priorities (gaps closed):

| # | Gap | Home | Priority |
|---|-----|------|----------|
| G1 | Sorting algorithms | `sort` | P0 |
| G2 | Searching algorithms | `search` | P0 |
| G3 | Date + ISO 8601 | `time` | P0 |
| G4 | Non-crypto hashes (fnv, murmur, xxhash, city) | `hash` | P1 |
| G5 | Bit manipulation (read/write, byte swap, bitarray) | `num`+`bits` | P1 |
| G6 | Data structures (list, tree/avl/rbtree, chained map, fib heap) | `collections` | P1 |
| G7 | Compression (huffman, lz77, lz4, snappy) | `compress` | P1 |
| G8 | BigInt / complex / geom | `bigint`/`complex`/`geom` | P1 |
| G9 | Platform abstraction | `platform` | P1 |
| G10 | Debug utilities (trace, source, symbols) | `debug` | P2 |
| G11 | Perf counters, allocation tracking | `bench` | P2 |
| G12 | Misc algos (uuid, semver, glob, diff, levenshtein, soundex) | `misc` | P2 |
| G13 | printf/scanf, escape | `string`/`fmt` | P2 |
| G14 | UTF-8/16 + calling conventions | `utf8`/`ffi` | P2 |
| G15 | Future/Promise, select, semaphore/barrier | `async`/`sync` | P2 |
| G16 | PRNGs (MT/PCG/xorshift), chacha20/poly1305/keccak/curve25519/rsa/des | `rand`/crypto family | P2 |
| G17 | Full statistics (covariance, regression, histogram) | `stats` | P2 |

**"Comprehensive and top-tier" means:** every module is (a) fully covered per its Â§5 scope, (b) documented with examples in `docs/`, (c) tested by dedicated smoke files, (d) optimized where heavy (Â§7), (e) designed for future extension (generic traits: `Hash`, `Ord`, `Serialize`, `Deserialize`, `Iterator`).

---

## 7. Optimization Plan (NASM/SIMD for heavy computing)

Heavy domains get assembly-accelerated hot paths with pure-XIOM fallback, runtime-dispatched by CPUID. Pattern already proven in repo: `stdlib/runtime/mem_x86_64.asm`, `crypto_x86_64.asm`, `context_switch.asm`, `simd_runtime.c`, compiled by `xiom build-runtime`.

| Domain | Accelerated ops | Instruction sets |
|--------|-----------------|------------------|
| math | sqrt/rsqrt, trig/exp/log (polynomial minimax), vector/matrix multiply | SSE2, AVX2, FMA |
| bigint | multiplication (schoolbook â†’ Karatsuba â†’ Montgomery), division | SSE2, AVX2 |
| crypto | AES round (AES-NI), SHA-1/256 (SHA-NI), GHASH/GCM (PCLMULQDQ), ChaCha20, Poly1305, constant-time primitives | AES-NI, SHA-NI, PCLMULQDQ, AVX2 |
| hash | xxhash/highway/murmur streaming | SSE2, AVX2 |
| compress | deflate match finding (hash chains), huffman encode, lz4/snappy fast paths | SSE2, AVX2 |
| rand | ChaCha20 generator | SSE2/AVX2 (or AES-NI for crypto rand) |

**Rules:**
1. Every asm op has a pure-XIOM fallback (portability: arm64/darwin later).
2. Dispatch via `simd.simd_supported()`/CPUID at first call; cache result.
3. New asm files live in `stdlib/runtime/` and are selected by platform in `build-runtime`.
4. Correctness gate: asm path vs pure path must produce identical results (diff tests).
5. Constant-time crypto ops are NOT optimized for speed at the expense of secrecy â€” branch-free even in the pure path.

---

## 8. Packages Catalog

### 8.1 Existing (66) â€” `packages/` â€” half-done, revisit later

Pure-XIOM: xiom-json, xiom-http, xiom-net, xiom-rest, xiom-graphql, xiom-websocket, xiom-micro, xiom-realtime, xiom-algo, xiom-math, xiom-core, xiom-ffi, xiom-log, xiom-test, xiom-arrow.
FFI-bound: openssl, libsodium, sqlite, postgres/libpq, redis, kafka, zeromq, grpc, protobuf, wasmtime, libuv, zstd, lzfse, tensorflow, libtorch/torch, onnx, numpy, pandas, scipy, blas, openblas, cuda, eigen, opencv, ffmpeg, sql, dxc, moveit, ros2, gazebo, sensor, control, bullet, jolt, box2d, ozz, meshopt, assimp, raylib, glfw, sdl3, imgui, ui, miniaudio, openal, portaudio, phonon, vulkan, opengl, directx11, directx12, vma, stb.

### 8.2 Planned placeholders (folder + README created now, spec later)

Each placeholder has a README.md with planned scope/modules; no implementation yet.

| Group | Packages |
|-------|----------|
| Data formats | xiom-xml, xiom-yaml, xiom-toml, xiom-csv, xiom-tsv, xiom-msgpack, xiom-thrift, xiom-bson, xiom-avro, xiom-parquet, xiom-orc, xiom-xlsx, xiom-pdf, xiom-docx, xiom-pptx |
| Databases | xiom-mysql, xiom-mongo, xiom-cassandra, xiom-elastic, xiom-oracle, xiom-mssql, xiom-db2, xiom-firebird, xiom-leveldb, xiom-rocksdb, xiom-badger, xiom-bolt, xiom-etcd, xiom-consul, xiom-zookeeper, xiom-dynamo |
| Protocols | xiom-ftp, xiom-smtp, xiom-pop3, xiom-imap, xiom-dhcp, xiom-telnet, xiom-irc, xiom-mqtt, xiom-amqp, xiom-rpc, xiom-proxy, xiom-ntp, xiom-snmp, xiom-tftp, xiom-upnp, xiom-bonjour, xiom-multicast |
| Crypto/security | xiom-tls, xiom-pgp, xiom-jwt, xiom-oauth, xiom-zkp, xiom-auth, xiom-rbac, xiom-password, xiom-sanitize, xiom-escape, xiom-audit, xiom-keymgmt, xiom-secret, xiom-vault, xiom-saml, xiom-ldap |
| Text/NLP | xiom-parsing, xiom-lexing, xiom-template, xiom-markdown, xiom-html, xiom-diff, xiom-patch, xiom-stemming, xiom-lemmatization, xiom-nlp, xiom-tokenizer, xiom-ngram, xiom-sentiment, xiom-summary, xiom-translation, xiom-spell |
| Media | xiom-image, xiom-png, xiom-jpeg, xiom-gif, xiom-bmp, xiom-webp, xiom-svg, xiom-mp3, xiom-wav, xiom-ogg, xiom-flac, xiom-aac, xiom-video, xiom-mp4, xiom-avi, xiom-mkv, xiom-codec, xiom-subtitle, xiom-streaming |
| Science/engineering | xiom-physics, xiom-chemistry, xiom-biology, xiom-astronomy, xiom-geology, xiom-weather, xiom-climate, xiom-environment, xiom-materials, xiom-mechanics, xiom-thermo, xiom-quantum, xiom-nuclear, xiom-particle, xiom-relativity, xiom-electronics, xiom-robotics, xiom-signal, xiom-imaging, xiom-spectroscopy, xiom-chromatography, xiom-microscopy, xiom-geography, xiom-meteorology |
| ML/AI | xiom-tensor, xiom-neural, xiom-deep, xiom-training, xiom-inference, xiom-optimizer, xiom-layers, xiom-activation, xiom-loss, xiom-metrics, xiom-data, xiom-preprocess, xiom-feature, xiom-selection, xiom-ensemble, xiom-boosting, xiom-randomforest, xiom-svm, xiom-clustering, xiom-dimred |
| Cloud/DevOps | xiom-aws, xiom-azure, xiom-gcp, xiom-docker, xiom-k8s, xiom-terraform, xiom-ansible, xiom-puppet, xiom-chef, xiom-salt, xiom-helm, xiom-serverless, xiom-cfn, xiom-monitoring, xiom-cloudlog, xiom-tracing, xiom-metrics, xiom-alerting, xiom-autoscale |
| Embedded/IoT | xiom-gpio, xiom-i2c, xiom-spi, xiom-uart, xiom-adc, xiom-dac, xiom-pwm, xiom-interrupt, xiom-timer, xiom-rtc, xiom-eeprom, xiom-flash, xiom-sd, xiom-ble, xiom-zigbee |
| Blockchain/Web3 | xiom-chaincore, xiom-ethereum, xiom-bitcoin, xiom-smartcontract, xiom-wallet, xiom-transaction, xiom-consensus, xiom-chaincrypto, xiom-merkle, xiom-hashchain, xiom-nft, xiom-defi, xiom-web3, xiom-oracle, xiom-bridge |
| i18n | xiom-locale, xiom-translate, xiom-plural, xiom-l10n-date, xiom-l10n-time, xiom-l10n-number, xiom-l10n-currency, xiom-l10n-name, xiom-l10n-address, xiom-l10n-phone, xiom-l10n-unit, xiom-collation, xiom-l10n-unicode, xiom-transliteration, xiom-icu |
| Concurrency | xiom-forkjoin, xiom-actor, xiom-stm, xiom-lockfree, xiom-barrier, xiom-countdown, xiom-exchanger, xiom-phaser, xiom-executor, xiom-scheduler |
| Utilities | xiom-config, xiom-flags, xiom-option, xiom-retry, xiom-cache, xiom-pool, xiom-worker, xiom-lru, xiom-ttl, xiom-semaphore, xiom-backoff, xiom-timeout, xiom-context, xiom-cancel, xiom-profiling, xiom-tracing |
| Testing/QA | xiom-itest, xiom-fuzz, xiom-mock, xiom-stub, xiom-coverage, xiom-property, xiom-golden, xiom-snapshot, xiom-perf, xiom-sectest, xiom-compliance, xiom-report |
| Compiler tools | xiom-parser-fw, xiom-lexer-fw, xiom-ast, xiom-codegen-fw, xiom-optimizer-fw, xiom-linter, xiom-formatter-fw, xiom-analyzer, xiom-refactor, xiom-plugin, xiom-macro, xiom-inline-asm, xiom-jit-fw, xiom-wasm, xiom-llvm |

---

## 9. Projects Catalog (external, top level)

| Project | Proposal mapping | Status |
|---------|------------------|--------|
| **xiom-pulse** | Node.js-like web framework: server, router, middleware, auth, session, cookie, cache, static, template, form, validation, csrf, xss, rate, cors, sse, rest, graphql | ðŸ”² PLACEHOLDER â€” README created; consumes xiom-http/json/websocket/graphql/rest |
| **xiom-game-engine** | game/*: engine, math, physics, collision, particle, scene, entity (ECS), ai, pathfinding, steering, state, save, achievement, leaderboard, multiplayer, input, audio, ui, level, event | ðŸ”² PLACEHOLDER â€” README created; consumes binding packages (raylib, sdl3, jolt, bullet, imgui, miniaudio, â€¦) |
| xiom-db | database product | âœ… EXISTS |
| xiom-vector | vector database | âœ… EXISTS |
| xiom-debugger-pro | debugger | âœ… EXISTS |
| xiom-playground | WASM playground | âœ… EXISTS |
| xiom-website | website | âœ… EXISTS |
| xiom-Book | language book | âœ… EXISTS |
| xiom-benchmark-chaos | benchmark harness | âœ… EXISTS (other owner) |
| xiom-research_paper | research | âœ… EXISTS |

---

## 10. IMPLEMENTATION STATUS (2026-08-07) — ALL PHASES COMPLETE

### Completed
| Phase | Scope | Result |
|-------|-------|--------|
| Phase 0 | Plan + 260 package / 2 project placeholders | ? Done |
| Phase 1 | Tier 1 cleanup: 8 orphan modules deleted, API-freeze gate (905?1,922 sigs) | ? Done |
| Phase 2 | Tier 2: 16 new modules (sort, search, bits, geom, complex, bigint, chacha, poly1305, ecc, rsa, des, utf8, platform, debug, misc, process) + resolve_module_call leaf-first compiler fix + runtime getpid | ? Done |
| Phase 3 | Tier 3: +600 fns across 30 modules (text, time/Date+ISO8601, collections, num, crypto/data, core/quality families) | ? Done |
| Phase 4 | NASM/SIMD: hardware popcnt/clz/ctz intrinsics, SIMD mem_copy/set/compare; existing SHA-NI/AES-NI/SSE2 asm retained | ? Done |

### Final stdlib: 64+ modules, ~2,215 public fns (was 51/~1,300) — status refreshed 2026-08-11

All 16 Tier-2 modules have CI smokes in examples/stdlib_smoke (stdlib_execution_tests: 72/72).
Freeze gate: 2/2. stdlib compile: 40/40. feature-reg: 510/510. integration: 128/128. checker: 156/156.

**Phases landed since this doc was written (see docs/stdlib_session.md):**
- **Phase A — production BigInt** (~40 new pub fns): constants-as-constructors, `from_u64` (full 0..2^64-1), `from_hex`/`from_base`/`to_base`, range-checked `to_int`, predicates, `div`, `pow_mod`, `sqrt(_rem)`, `lcm`, `ext_gcd`, Miller-Rabin `is_prime`/`next_prime`, `factorial`/`binomial`/`fibonacci`, two's-complement bit ops, comparisons. `bigint_div_mod` = Knuth Algorithm D (two-limb window, single-limb fast path, upward fixup).
- **Phase B — production BigFloat** (`num/bigfloat.xi` + flat aggregate): power-of-10 representation, RoundMode, string-exact to_str, all arithmetic with precision-aware rounding, `pi()`/`e()`.
- **Phase C — BigFloat transcendentals**: Machin p, Taylor e, exp/ln/log10, sin/cos/tan, atan/atan2, pow_bf (O(prec²) series).
- **Phase C.5**: log2/exp2/cbrt/hypot/hyperbolics/inverse-hyperbolics/asin/acos, to_str_sci, from_ratio, pow10, int helpers.
- **Perf**: BigInt Karatsuba (`_abs_mul_karatsuba`, threshold 4000 limbs, measured ~12% faster at 100k digits).
- **misc expansion** (23 fns): string metrics (damerau/jaro/jaro-winkler/hamming/LCS), case converters, roman numerals, ordinal/pluralize, units.
- **hash 64-bit additions**: canonical xxhash64 (C-reference-verified), fnv1_32.
- **Full categorized audit of the wish-list**: §13 below (HAVE / GAP-stdlib / GAP-package, deduped).

**Known compiler bugs discovered (stdlib works around them; fix in compiler later)**
— superseded by docs/COMPILER_BUGS.md STATUS SUMMARY (2026-08-11): BUG 1/8/9/10/11 and
the parser/catalog/&T-param/inline-hang findings are all FIXED; BUG 2 (module-global
struct field writes) and BUG 3 (module-global fn-call initializers) remain OPEN
(advisory — stdlib uses whole-value assignment and constructor fns).

## 11. Migration Sequencing & Gates

### Phase 0 â€” THIS DOCUMENT + placeholders (done now)
- Full plan written; placeholder folders + READMEs for all Â§8.2 packages and Â§9 projects; no implementations.

### Phase 1 â€” Tier 1 cleanup (~1 session, zero test churn)
1. Merge orphans per Â§4 (update ~15 internal imports).
2. Delete `demo.xi`.
3. Add **API-freeze test** (`stdlib_api_freeze_tests`) snapshotting every pub fn signature of the 40 contract modules â€” any future rename/removal/resignature fails CI.
4. Add **import-alias gate**: fixtures for `use xiom.string;` and `use stdlib.xiom.string;`.
5. Regenerate `stdlib-pin/`; run FULL suite: 2,231 E2E + 1,284 unit green.

### Phase 2 â€” Tier 2 reorganization (internal only)
- Create `bits`, `geom`, `complex`, `bigint`, `utf8`, `sort`, `search`, `platform`, `debug`, `misc`, `process`, `chacha`, `poly1305`, `ecc`, `rsa`, `des` skeletons; move absorbed fns; verify API-freeze still green (contract modules untouched).

### Phase 3 â€” Tier 3 expansion (additive, per area)
- Order: string/utf8 â†’ collections/sort/search â†’ time/date â†’ math family â†’ crypto family â†’ system (os/process/platform/debug) â†’ hash/compress â†’ misc.
- Each area lands with smokes + docs; suite stays green after every area.

### Phase 4 â€” Optimization (NASM/SIMD)
- Per Â§7, one domain at a time (math â†’ crypto â†’ hash â†’ compress â†’ rand); correctness diff-tests asm vs pure.

### Phase 5 â€” Packages/projects specs
- Write SPEC.md for placeholder packages/projects as the ecosystem grows; publish after public split.

### Gates (every phase)
- `cargo test` full: E2E 2,230/2,231 (1 known pre-existing flake: spawn_capture), feature-reg 510/510, integration 128/128, stdlib-exec 41/41, stdlib-compile 40/40, checker 156/156, parser 96/96 + API-freeze gate green.
- No phase requires coordinated republish of the 66 packages (they're unused/half-done anyway; revisit later).
- `stdlib-pin/` regenerated whenever stdlib changes.

---

## 12. Decision Log

| Date | Decision |
|------|----------|
| 2026-08-07 | **Clean break now.** Pre-public + monorepo will be split before going public (no history to preserve) â†’ NO shims, NO deprecation cycles. Build stdlib right the first time. |
| 2026-08-07 | 3-tier plan: cleanup (zero churn) â†’ reorganization (module families: math split, crypto split) â†’ comprehensive expansion. No forced renames of the 40 test-imported modules; their fn signatures are the frozen contract. |
| 2026-08-07 | Stdlib = zero external deps; packages build on stdlib and may wrap C; frameworks/engines = top-level external projects (xiom-pulse, xiom-game-engine). |
| 2026-08-07 | Heavy domains (math, crypto, hash, compress, rand) get NASM/SIMD tracks with pure fallback + CPUID dispatch (Â§7). |
| 2026-08-07 | Placeholder folders + READMEs for 260 planned packages and 2 projects created now; specs later. |
| 2026-08-07 | API-freeze test + import-alias gate enforce the contract mechanically after the rework. |








STD EXTENSION PLANNING
/// STDLIB FOR INSPECTION CROSS REFFERENCE IMPLEMTATION TO OUR STDLIB OR TO PACKAGING
// Need to cross reference what we have what we dont have. and from what we dont have to decide either package or add in to existing package or to add to our lib as a module or add to existing.

HASHING (Expanded)
hash/fnv - FNV-1/FNV-1a hash (32, 64, 128-bit)
hash/murmur - MurmurHash2, MurmurHash3 (32, 128-bit)
hash/city - CityHash (64, 128, 256-bit)
hash/xxhash - xxHash32, xxHash64, xxHash128, XXH3
hash/siphash - SipHash (SipHash-2-4, SipHash-1-3)
hash/highway - HighwayHash (64, 128, 256-bit)
hash/spooky - SpookyHash (128-bit)
hash/t1ha - Fast positive hash
hash/metro - MetroHash (64, 128-bit)
hash/farm - FarmHash (fingerprint family)
hash/jenkins - Jenkins hash (lookup3)
hash/superfast - SuperFastHash
hash/crc - CRC32, CRC64 (with hardware acceleration)
hash/adler - Adler-32 checksum
hash/checksum - BSD, SysV, and Internet checksums

COLLECTIONS (Full)
collect/list - Singly/doubly linked list
collect/vector - Dynamic array (Vec)
collect/stack - Stack (LIFO)
collect/queue - Queue (FIFO)
collect/ring - Ring buffer (circular)
collect/map - Hash map (open addressing)
collect/mapch - Hash map (chaining)
collect/treemap - Ordered map (tree-based)
collect/treeset - Ordered set (tree-based)
collect/tree - Binary tree
collect/avl - AVL balanced tree
collect/rbtree - Red-black tree
collect/bheap - Binary heap
collect/fheap - Fibonacci heap
collect/pairing - Pairing heap
collect/deque - Double-ended queue
collect/priority - Priority queue
collect/skiplist - Skip list
collect/trie - Trie (prefix tree)
collect/radix - Radix tree
collect/bitmap - Bitmap/Bitset
collect/bloom - Bloom filter
collect/cuckoo - Cuckoo hash map
collect/hashset - Hash set (open addressing)
collect/linkedhash - Linked hash map (insertion order)
collect/lru - LRU cache
collect/lfu - LFU cache
collect/tinylfu - TinyLFU cache
collect/arc - Adaptive Replacement Cache
collect/btree - B-Tree
collect/btreeplus - B+Tree
collect/segment - Segmented tree
collect/fenwick - Fenwick tree
collect/sparse - Sparse set
collect/dense - Dense set
collect/hasharray - Hash array mapped trie
collect/immutable - Immutable collections
collect/persistent - Persistent data structures
collect/concurrent - Concurrent collections
collect/interval - Interval tree
collect/range - Range tree
collect/kdtree - KD-Tree
collect/octree - Octree
collect/quadtree - Quadtree
collect/spatial - Spatial hashing
collect/graph - Graph adjacency
collect/dag - Directed acyclic graph
collect/unionfind - Union-find (disjoint set)
collect/intmap - Integer-keyed map (optimized)
collect/stringmap - String-keyed map (optimized)
collect/objectpool - Object pool
collect/threadpool - Thread pool
collect/workqueue - Work queue
collect/blocking - Blocking queue
collect/mpmc - Multi-producer multi-consumer queue
collect/mpsc - Multi-producer single-consumer queue
collect/spmc - Single-producer multi-consumer queue
collect/spsc - Single-producer single-consumer queue

STRING OPERATIONS
str/compare - String comparison (eq, ne, lt, gt, cmp)
str/search - Search (contains, index, rindex, find)
str/replace - Replace (all, first, last, with callback)
str/trim - Trim (whitespace, chars, prefixes, suffixes)
str/split - Split (separator, n, whitespace, lines)
str/join - Join with separator
str/case - Case conversion (upper, lower, title, swap)
str/strip - Strip prefixes/suffixes
str/repeat - Repeat string N times
str/pad - Pad (left, right, center, with char)
str/slice - Safe string slicing (by chars, not bytes)
str/escape - Escape (C-style, JSON, XML, URL, HTML)
str/unescape - Unescape (C-style, JSON, XML, URL, HTML)
str/format - Format (sprintf-style, positional)
str/printf - Printf-style formatting
str/scanf - Scanf-style parsing
str/template - Template strings (with placeholders)
str/glob - Glob pattern matching
str/regex - Regular expressions (if not separate)
str/levenshtein - Levenshtein distance
str/damerau - Damerau-Levenshtein distance
str/jaro - Jaro-Winkler similarity
str/soundex - Soundex algorithm
str/metaphone - Metaphone (double metaphone)
str/ngram - N-gram extraction
str/ngram_similarity - N-gram similarity
str/cosine - Cosine similarity
str/jaccard - Jaccard similarity
str/lcs - Longest common subsequence
str/lcp - Longest common prefix
str/lcsuffix - Longest common suffix
str/editdistance - Edit distance (general)
str/hamming - Hamming distance
str/tr - Translate characters (tr utility)
str/rot - ROT13, ROT47
str/caesar - Caesar cipher
str/atbash - Atbash cipher
str/shuffle - Shuffle string (Fisher-Yates)
str/reverse - Reverse string
str/rotate - Rotate string
str/permute - Generate permutations
str/combine - Combine/merge strings
str/interleave - Interleave strings
str/chunk - Chunk/group strings
str/wrap - Word wrap
str/indent - Indent/dedent
str/align - Align (left, right, center)
str/truncate - Truncate with ellipsis
str/abbreviate - Abbreviate (middle/end)
str/obfuscate - Obfuscate (hide middle chars)
str/normalize - Unicode normalization (NFC, NFD, NFKC, NFKD)
str/collate - Unicode collation
str/casefold - Unicode case folding
str/titlecase - Unicode title case
str/segment - Unicode grapheme segmentation
str/wordbreak - Unicode word boundaries
str/sentencebreak - Unicode sentence boundaries
str/linebreak - Unicode line boundaries
str/ea_width - East Asian width
str/emoji - Emoji detection
str/script - Script detection
str/block - Unicode block detection
str/category - Unicode category
str/bidi - Bidirectional text
str/mirror - Mirror characters
str/compat - Compatibility decomposition
str/fold - Case folding
str/lowercase - Lowercase mapping
str/uppercase - Uppercase mapping
str/titlecase_map - Titlecase mapping
str/nfkc - NFKC normalization
str/nfd - NFD normalization
str/nfc - NFC normalization
str/nfkd - NFKD normalization

CONVERSION
conv/int - String to int (base 2-36)
conv/float - String to float (hex, scientific)
conv/toint - To integer (various bases, signed/unsigned)
conv/tofloat - To float (32, 64, 128)
conv/tostring - To string (basic types with formatting)
conv/parse - Generic parsing utilities
conv/itos - Integer to string (base 2-36)
conv/ftos - Float to string (scientific, fixed, general)
conv/atoi - ASCII to integer (fast path)
conv/itoa - Integer to ASCII (fast path)
conv/fromstr - FromStr trait
conv/tryfrom - TryFrom trait
conv/into - Into trait
conv/asref - AsRef trait
conv/asmut - AsMut trait
conv/from - From trait
conv/bytes - Bytes to/from primitives
conv/endian - Endian-aware conversions
conv/bigendian - Big endian conversions
conv/littleendian - Little endian conversions
conv/nativeendian - Native endian conversions
conv/network - Network byte order
conv/host - Host byte order
conv/swap - Byte swapping utilities
conv/saturating - Saturating conversions
conv/wrapping - Wrapping conversions
conv/overflow - Overflow checking conversions
conv/checked - Checked conversions
conv/unchecked - Unchecked conversions (unsafe)
conv/exact - Exact conversion (fails if lossy)
conv/lossy - Lossy conversions
conv/roundtrip - Round-trip conversion utilities
conv/cstring - C string conversions
conv/wstring - Wide string conversions
conv/utf8 - UTF-8 conversions
conv/utf16 - UTF-16 conversions
conv/utf32 - UTF-32 conversions
conv/base64 - Base64 (standard, URL-safe, MIME)
conv/base32 - Base32 (RFC 4648, z-base-32)
conv/base16 - Base16 (hex)
conv/base58 - Base58 (Bitcoin)
conv/base62 - Base62
conv/base64url - URL-safe Base64
conv/ascii85 - Ascii85 (Adobe, Z85)
conv/uuencode - UUencode
conv/xxencode - XXencode
conv/quotedprintable - Quoted-printable
conv/punycode - Punycode (IDNA)
conv/idna - Internationalized domain names
conv/percent - Percent encoding (URL)
conv/html - HTML entity encoding
conv/xml - XML entity encoding
conv/json - JSON string escaping
conv/csv - CSV escaping
conv/tsv - TSV escaping
conv/yaml - YAML escaping
conv/toml - TOML escaping
conv/regex - Regex escaping
conv/glob - Glob escaping
conv/shell - Shell escaping
conv/cmd - Command-line escaping
conv/printf - Printf-style escaping
conv/strftime - Strftime formatting
conv/strptime - Strptime parsing
conv/duration - Duration to/from string
conv/date - Date to/from string
conv/time - Time to/from string
conv/datetime - DateTime to/from string
conv/timestamp - Timestamp conversions
conv/uuid - UUID to/from string
conv/mac - MAC address to/from string
conv/ip - IP address to/from string
conv/url - URL to/from string
conv/uri - URI to/from string
conv/urn - URN to/from string
conv/iri - IRI to/from string
conv/email - Email address to/from string
conv/phone - Phone number to/from string
conv/creditcard - Credit card number validation
conv/iban - IBAN validation
conv/swift - SWIFT/BIC code validation

NETWORK
net/socket - Socket primitives (socket, bind, connect, accept)
net/address - Socket address parsing
net/tcp - TCP utilities (stream, listener)
net/udp - UDP utilities (datagram)
net/unix - Unix domain sockets
net/dns - DNS resolution (A, AAAA, CNAME, MX, TXT, SRV)
net/host - Hostname/port utilities
net/ip - IP address operations (v4, v6)
net/port - Port utilities (well-known, registered, dynamic)
net/protocol - Protocol utilities
net/url - URL parsing (scheme, host, path, query, fragment)
net/uri - URI parsing
net/iri - IRI parsing (internationalized)
net/query - Query string parsing
net/form - Form data encoding
net/multipart - Multipart form parsing
net/cookie - Cookie parsing and generation
net/header - HTTP header utilities
net/accept - Content negotiation (Accept header)
net/accept_language - Language negotiation
net/accept_encoding - Encoding negotiation
net/etag - ETag generation and validation
net/cache - Cache control headers
net/range - Range requests
net/compress - Content compression negotiation
net/mime - MIME type utilities
net/charset - Charset utilities
net/link - Link header parsing
net/alternates - Alternate link handling
net/webfinger - WebFinger protocol
net/hostmeta - Host-meta discovery
net/wellknown - Well-known URIs
net/oauth - OAuth 1.0/2.0 utilities
net/jwt - JWT generation and validation
net/pem - PEM encoding/decoding
net/x509 - X.509 certificate parsing
net/tls - TLS (client, server) - basic
net/ssl - SSL utilities
net/ssh - SSH protocol
net/telnet - Telnet protocol
net/ftp - FTP client
net/sftp - SFTP client
net/scp - SCP client
net/smtp - SMTP client
net/pop3 - POP3 client
net/imap - IMAP client
net/nntp - NNTP client
net/irc - IRC client
net/matrix - Matrix protocol
net/xmpp - XMPP/Jabber
net/sip - SIP protocol
net/rtp - RTP protocol
net/rtsp - RTSP protocol
net/rtmp - RTMP protocol
net/hls - HLS streaming
net/dash - DASH streaming
net/webrtc - WebRTC
net/websocket - WebSocket (client, server)
net/sse - Server-Sent Events
net/http - HTTP client/server
net/https - HTTPS
net/http2 - HTTP/2
net/http3 - HTTP/3 (QUIC)
net/h2c - HTTP/2 cleartext
net/grpc - gRPC
net/grpcweb - gRPC-Web
net/rest - REST utilities
net/graphql - GraphQL client
net/graphql_server - GraphQL server
net/jsonrpc - JSON-RPC (1.0, 2.0)
net/xmlrpc - XML-RPC
net/soap - SOAP
net/thrift - Thrift
net/avro - Avro RPC
net/zeromq - ZeroMQ
net/nanomsg - Nanomsg
net/mqtt - MQTT client
net/amqp - AMQP (RabbitMQ)
net/stomp - STOMP
net/kafka - Kafka protocol
net/pulsar - Pulsar protocol
net/nats - NATS protocol
net/redis - Redis protocol (RESP)
net/memcached - Memcached protocol
net/elastic - Elasticsearch protocol
net/mongo - MongoDB wire protocol
net/postgres - PostgreSQL wire protocol
net/mysql - MySQL wire protocol
net/sqlite - SQLite network (remote)
net/odbc - ODBC
net/jdbc - JDBC bridge
net/dbus - D-Bus
net/avahi - Avahi (Zeroconf)
net/mdns - mDNS (Bonjour)
net/upnp - UPnP
net/ssdp - SSDP
net/wsdiscovery - WS-Discovery
net/slp - SLP
net/ldap - LDAP client
net/kerberos - Kerberos
net/ntlm - NTLM authentication
net/digest - Digest authentication
net/basic - Basic authentication
net/bearer - Bearer token authentication
net/apikey - API key authentication
net/hawk - Hawk authentication
net/aws - AWS Signature V4
net/azure - Azure shared key
net/gcp - GCP authentication
net/proxy - HTTP/SOCKS proxy
net/socks - SOCKS5
net/tor - Tor (SOCKS, onion)
net/i2p - I2P
net/zerotier - ZeroTier
net/wireguard - WireGuard
net/ipsec - IPsec
net/ike - IKE
net/ppp - PPP
net/l2tp - L2TP
net/gre - GRE
net/vxlan - VXLAN
net/geneve - Geneve
net/nvgre - NVGRE
net/mpls - MPLS
net/vlan - VLAN
net/bridge - Bridging
net/ipip - IP-in-IP
net/sit - SIT
net/6to4 - 6to4
net/teredo - Teredo
net/isatap - ISATAP
net/icmp - ICMP (ping)
net/traceroute - Traceroute
net/arp - ARP
net/ndp - NDP (IPv6)
net/dhcp - DHCP client
net/dhcpv6 - DHCPv6
net/bootp - BOOTP
net/tftp - TFTP
net/nfs - NFS
net/smb - SMB/CIFS
net/netbios - NetBIOS
net/wins - WINS
net/rpc - RPC (SunRPC, ONC)
net/nlm - NLM
net/mount - Mount protocol
net/yp - NIS/YP
net/ntp - NTP client
net/sntp - SNTP
net/ptp - PTP (IEEE 1588)
net/chrony - Chrony
net/radar - Radar detection
net/sonar - SONAR
net/lidar - LiDAR
net/gnss - GNSS (GPS, GLONASS, Galileo, BeiDou)
net/dme - Distance Measuring Equipment
net/vor - VOR
net/ils - Instrument Landing System
net/atc - Air Traffic Control
net/adsb - ADS-B
net/flarm - FLARM
net/acars - ACARS
net/vdl - VDL Mode 2
net/hfdl - HFDL
net/satcom - Satellite communications
net/inmarsat - Inmarsat
net/iridium - Iridium
net/starlink - Starlink
net/oneweb - OneWeb
net/kubernetes - Kubernetes API
net/docker - Docker API
net/nomad - Nomad API
net/mesos - Mesos API
net/swarm - Docker Swarm
net/openshift - OpenShift API
net/cloudfoundry - Cloud Foundry
net/heroku - Heroku API
net/netlify - Netlify API
net/vercel - Vercel API
net/cloudflare - Cloudflare API
net/akamai - Akamai API
net/fastly - Fastly API
net/cloudfront - CloudFront API
net/lambda - AWS Lambda API
net/ec2 - EC2 API
net/s3 - S3 API
net/sqs - SQS API
net/sns - SNS API
net/dynamodb - DynamoDB API
net/rds - RDS API
net/route53 - Route53 API
net/vpc - VPC API
net/iam - IAM API
net/cloudtrail - CloudTrail API
net/cloudwatch - CloudWatch API
net/lambda - AWS Lambda
net/azure_compute - Azure Compute
net/azure_storage - Azure Storage
net/azure_sql - Azure SQL
net/azure_cosmos - Cosmos DB
net/gcp_compute - GCP Compute
net/gcp_storage - GCP Storage
net/gcp_sql - GCP Cloud SQL
net/gcp_bigtable - Bigtable
net/gcp_bigquery - BigQuery
net/gcp_pubsub - Pub/Sub
net/gcp_firestore - Firestore
net/gcp_spanner - Spanner
net/alibaba_ecs - Alibaba ECS
net/alibaba_oss - Alibaba OSS
net/alibaba_rds - Alibaba RDS
net/tencent_cvm - Tencent CVM
net/tencent_cos - Tencent COS
net/tencent_cdb - Tencent CDB
net/huawei_ecs - Huawei ECS
net/huawei_obs - Huawei OBS
net/huawei_rds - Huawei RDS
net/oracle_cloud - Oracle Cloud
net/ibm_cloud - IBM Cloud
net/digitalocean - DigitalOcean API
net/linode - Linode API
net/vultr - Vultr API
net/scaleway - Scaleway API
net/hetzner - Hetzner API
net/ovh - OVH API
net/rackspace - Rackspace API
net/softlayer - SoftLayer API
net/vmware - VMware vSphere
net/xen - XenServer
net/kvm - KVM
net/hyperv - Hyper-V
net/esxi - ESXi
net/vcenter - vCenter
net/openstack - OpenStack
net/opennebula - OpenNebula
net/cloudstack - CloudStack
net/eucalyptus - Eucalyptus
net/openshift - OpenShift
net/rancher - Rancher
net/portainer - Portainer
net/k3s - K3s
net/microk8s - MicroK8s
net/minikube - Minikube
net/kind - KinD
net/k3d - K3d
net/talos - Talos Linux
net/flatcar - Flatcar
net/coreos - CoreOS
net/ignition - Ignition
net/cloudinit - Cloud-init
net/userdata - User data
net/metadata - Cloud metadata
net/instanceid - Instance ID
net/region - Region utilities
net/zone - Availability zone
net/az - AZ utilities
net/faultdomain - Fault domain
net/updatedomain - Update domain
net/placement - Placement groups
net/securitygroups - Security groups
net/firewall - Firewall utilities
net/nacl - Network ACLs
net/subnet - Subnet utilities
net/cidr - CIDR utilities
net/route - Routing utilities
net/gateway - Gateway utilities
net/nat - NAT utilities
net/vpn - VPN utilities
net/ipsec_vpn - IPsec VPN
net/ssl_vpn - SSL VPN
net/wireguard_vpn - WireGuard VPN
net/openvpn - OpenVPN
net/pptp - PPTP
net/l2tp_vpn - L2TP VPN
net/ikev2 - IKEv2
net/sstp - SSTP
net/sonicwall - SonicWall
net/cisco - Cisco VPN
net/juniper - Juniper VPN
net/checkpoint - Check Point
net/f5 - F5 BIG-IP
net/citrix - Citrix
net/pulse - Pulse Secure
net/globalprotect - GlobalProtect
net/anyconnect - AnyConnect
net/forticlient - FortiClient
net/paloalto - Palo Alto
net/watchguard - WatchGuard
net/sophos - Sophos
net/barracuda - Barracuda
net/meraki - Meraki
net/ubiquiti - Ubiquiti
net/mikrotik - MikroTik
net/zyxel - Zyxel
net/dlink - D-Link
net/netgear - Netgear
net/asus - Asus
net/tp_link - TP-Link


FILE FORMATS
format/hex - Hex dump (xxd, hexdump, od)
format/bytes - Byte formatting (human-readable)
format/dump - Memory dump (full, partial, structured)
format/pretty - Pretty printing (with colors, indentation)
format/table - Table formatting (ASCII, Markdown, CSV, HTML)
format/indent - Indentation utilities
format/wrap - Text wrapping
format/column - Column formatting
format/json - JSON formatting (pretty, compact)
format/xml - XML formatting
format/yaml - YAML formatting
format/toml - TOML formatting
format/csv - CSV formatting
format/tsv - TSV formatting
format/markdown - Markdown formatting
format/html - HTML formatting
format/textile - Textile formatting
format/rtf - RTF formatting
format/latex - LaTeX formatting
format/troff - Troff formatting
format/roff - Roff formatting
format/man - Man page formatting
format/help - Help text formatting
format/usage - Usage message formatting
format/progress - Progress bar formatting
format/spinner - Spinner/loading indicator
format/ansi - ANSI escape codes
format/colors - Color utilities
format/emoji - Emoji formatting
format/unicode - Unicode formatting
format/box - Box drawing (ASCII, Unicode)
format/border - Border formatting
format/separator - Separator lines
format/header - Header formatting
format/footer - Footer formatting
format/title - Title formatting
format/subtitle - Subtitle formatting
format/section - Section formatting
format/list - Bulleted/numbered lists
format/enum - Enumerated lists
format/definition - Definition lists
format/glossary - Glossary formatting
format/index - Index formatting
format/toc - Table of contents
format/appendix - Appendix formatting
format/bibliography - Bibliography formatting
format/citation - Citation formatting
format/footnote - Footnote formatting
format/endnote - Endnote formatting
format/margin - Margin formatting
format/line - Line numbering
format/page - Page formatting
format/pagination - Pagination utilities
format/landscape - Landscape orientation
format/portrait - Portrait orientation
format/a4 - A4 paper formatting
format/letter - Letter paper formatting
format/legal - Legal paper formatting
format/font - Font formatting (bold, italic, underline)
format/size - Font size utilities
format/weight - Font weight
format/face - Font face
format/fallback - Font fallback
format/glyph - Glyph utilities
format/diacritic - Diacritic handling
format/ligature - Ligature utilities
format/kerning - Kerning utilities
format/leading - Leading utilities
format/tracking - Tracking utilities
format/justify - Text justification
format/ragged - Ragged text
format/hyphenation - Hyphenation utilities
format/soft_hyphen - Soft hyphen
format/hard_hyphen - Hard hyphen
format/nobreak - No-break space
format/zwsp - Zero-width space
format/zwnj - Zero-width non-joiner
format/zwnj - Zero-width joiner
format/rtl - Right-to-left formatting
format/ltr - Left-to-right formatting
format/bidi_override - Bidi override
format/arabic - Arabic formatting
format/hebrew - Hebrew formatting
format/indic - Indic script formatting
format/cjk - CJK formatting
format/vertical - Vertical text formatting
format/ruby - Ruby annotation
format/furigana - Furigana
format/pinyin - Pinyin
format/zhuyin - Zhuyin
format/hanzi - Hanzi formatting
format/kanji - Kanji formatting
format/hangul - Hangul formatting
format/kana - Kana formatting
format/romaji - Romaji
format/transliterate - Transliteration
format/romanize - Romanization
format/numbering - Numbering systems
format/arabic_num - Arabic numerals
format/roman_num - Roman numerals
format/chinese_num - Chinese numerals
format/japanese_num - Japanese numerals
format/korean_num - Korean numerals
format/indian_num - Indian numerals
format/ethiopic_num - Ethiopic numerals
format/mayan_num - Mayan numerals
format/binary_num - Binary
format/octal_num - Octal
format/decimal_num - Decimal
format/hexadecimal_num - Hexadecimal
format/base_num - Base-N numbers
format/fraction - Fraction formatting
format/percent - Percent formatting
format/per_mille - Per-mille formatting
format/per_ten_thousand - Per-ten-thousand
format/ratio - Ratio formatting
format/scientific - Scientific notation
format/engineering - Engineering notation
format/si - SI units formatting
format/binary_prefix - Binary prefixes (KiB, MiB)
format/decimal_prefix - Decimal prefixes (KB, MB)
format/metric - Metric prefixes
format/imperial - Imperial units
format/us_customary - US customary
format/time_duration - Duration formatting
format/date_time - Date/time formatting
format/relative_time - Relative time formatting
format/age - Age formatting
format/clock - Clock formatting
format/stopwatch - Stopwatch formatting
format/countdown - Countdown formatting
format/calendar - Calendar formatting
format/timeline - Timeline formatting
format/gantt - Gantt chart formatting
format/waterfall - Waterfall chart
format/bar - Bar chart formatting
format/column - Column chart
format/line - Line chart
format/pie - Pie chart
format/scatter - Scatter plot
format/histogram - Histogram
format/boxplot - Box plot
format/violin - Violin plot
format/heatmap - Heatmap
format/treemap - Treemap
format/sunburst - Sunburst chart
format/sankey - Sankey diagram
format/network - Network diagram
format/mindmap - Mind map
format/flowchart - Flowchart
format/uml - UML diagram
format/sequence - Sequence diagram
format/class - Class diagram
format/state - State diagram
format/activity - Activity diagram
format/timing - Timing diagram
format/use_case - Use case diagram
format/component - Component diagram
format/deployment - Deployment diagram
format/object - Object diagram
format/package - Package diagram
format/profile - Profile diagram
format/composite - Composite structure
format/interaction - Interaction diagram
format/communication - Communication diagram
format/interaction_overview - Interaction overview
format/timing - Timing diagram
format/message - Message diagram
format/entity - Entity relationship
format/er - ER diagram
format/chen - Chen notation
format/crowfoot - Crow's foot notation
format/uml_notation - UML notation
format/bpmn - BPMN
format/archimate - ArchiMate
format/dmn - DMN
format/cmmn - CMMN
format/sysml - SysML
format/mermaid - Mermaid diagram
format/plantuml - PlantUML
format/graphviz - Graphviz DOT
format/dot - DOT format
format/neato - NEATO
format/fdp - FDP
format/sfdp - SFDP
format/twopi - Twopi
format/circo - Circo
format/osage - Osage
format/patchwork - Patchwork
format/radial - Radial layout
format/force - Force-directed layout
format/spring - Spring layout
format/sugiyama - Sugiyama layout
format/tree - Tree layout
format/radial_tree - Radial tree
format/bubble - Bubble chart
format/wordcloud - Word cloud
format/tagcloud - Tag cloud
format/matrix - Matrix formatting
format/spreadsheet - Spreadsheet formatting
format/excel - Excel formatting
format/csv_table - CSV table
format/tsv_table - TSV table
format/sql_table - SQL table
format/ascii_table - ASCII table
format/unicode_table - Unicode table
format/markdown_table - Markdown table
format/html_table - HTML table
format/latex_table - LaTeX table
format/rest_table - reStructuredText table
format/org_table - Org-mode table
format/medit_table - Markdown edit table
format/grid - Grid formatting
format/matrix_grid - Matrix grid
format/sudoku - Sudoku grid
format/chess - Chess board
format/checkers - Checkers board
format/board - Board game utilities
format/maze - Maze formatting
format/map - Map formatting
format/terrain - Terrain formatting
format/elevation - Elevation map
format/contour - Contour lines
format/topographic - Topographic map
format/geographic - Geographic map
format/political - Political map
format/road - Road map
format/satellite - Satellite view
format/hybrid - Hybrid map
format/terrain_map - Terrain map
format/heat_map - Heat map
format/choropleth - Choropleth map
format/cartogram - Cartogram
format/flowmap - Flow map
format/connection - Connection map
format/bubble_map - Bubble map
format/symbol - Symbol map
format/point - Point map
format/line_map - Line map
format/polygon - Polygon map
format/geojson - GeoJSON formatting
format/kml - KML formatting
format/gpx - GPX formatting
format/shapefile - Shapefile formatting
format/wkt - WKT formatting
format/wkb - WKB formatting
format/ewkt - EWKT formatting
format/geohash - Geohash formatting
format/mgrs - MGRS formatting
format/utm - UTM formatting
format/latlong - Latitude/longitude
format/dms - Degrees/minutes/seconds
format/dec - Decimal degrees
format/radians - Radians formatting
format/gradians - Gradians
format/mils - Mils formatting
format/azimuth - Azimuth formatting
format/bearing - Bearing formatting
format/heading - Heading formatting
format/course - Course formatting
format/track - Track formatting
format/waypoint - Waypoint formatting
format/route - Route formatting
format/tracklog - Tracklog formatting
format/segment - Segment formatting
format/geofence - Geofence formatting
format/geotag - Geotag formatting
format/exif - EXIF formatting
format/metadata - Metadata formatting
format/id3 - ID3 tag formatting
format/vorbis - Vorbis comment
format/apetag - APE tag
format/mp4 - MP4 metadata
format/mkv - Matroska metadata
format/avi - AVI metadata
format/mov - QuickTime metadata
format/asf - ASF metadata
format/flac - FLAC metadata
format/ogg - OGG metadata
format/opus - Opus metadata
format/webm - WebM metadata
format/m4a - M4A metadata
format/aac - AAC metadata
format/mp3 - MP3 metadata
format/wav - WAV metadata
format/aiff - AIFF metadata
format/au - AU metadata
format/snd - SND metadata
format/raw - RAW audio metadata
format/midi - MIDI metadata
format/smf - SMF metadata
format/rmi - RMI metadata
format/mod - MOD metadata
format/xm - XM metadata
format/s3m - S3M metadata
format/it - IT metadata
format/xm - XM metadata
format/mo3 - MO3 metadata
format/umx - UMX metadata
format/psf - PSF metadata
format/minipsf - MiniPSF metadata
format/gsf - GSF metadata
format/ssf - SSF metadata
format/qsf - QSF metadata
format/psf2 - PSF2 metadata
format/dsf - DSF metadata
format/minidsf - MiniDSF metadata
format/2sf - 2SF metadata
format/mini2sf - Mini2SF metadata
format/usf - USF metadata
format/miniusf - MiniUSF metadata
format/vsf - VSF metadata
format/minivsf - MiniVSF metadata
format/gsf - GSF metadata
format/minigsf - MiniGSF metadata
format/sid - SID metadata
format/minisid - MiniSID metadata
format/hvl - HVL metadata
format/ay - AY metadata
format/gym - GYM metadata
format/spc - SPC metadata
format/nsf - NSF metadata
format/nsfe - NSFE metadata
format/gbs - GBS metadata
format/hes - HES metadata
format/kss - KSS metadata
format/kss - KSS metadata
format/mml - MML metadata
format/sap - SAP metadata
format/tfmx - TFMX metadata
format/cust - CUST metadata
format/sc68 - SC68 metadata
format/ym - YM metadata
format/vgm - VGM metadata
format/vgz - VGZ metadata
format/s98 - S98 metadata
format/gzi - GZI metadata
format/rsn - RSN metadata
format/psf - PSF metadata
format/psflib - PSFlib metadata
format/ssf - SSF metadata
format/qsf - QSF metadata
format/gsflib - GSFlib metadata
format/usflib - USFlib metadata
format/psf2 - PSF2 metadata
format/ssf - SSF metadata
format/qsf - QSF metadata
format/2sf - 2SF metadata
format/vsf - VSF metadata
format/gsf - GSF metadata
format/miniusf - MiniUSF metadata
format/mini2sf - Mini2SF metadata
format/minivsf - MiniVSF metadata
format/minigsflib - MiniGSFlib
format/hexdump - Hex dump with ASCII
format/octaldump - Octal dump
format/binarydump - Binary dump
format/disassembly - Disassembly formatting
format/opcode - Opcode formatting
format/instruction - Instruction formatting
format/mnemonic - Mnemonic formatting
format/register - Register formatting
format/stackdump - Stack dump
format/heapdump - Heap dump
format/tracedump - Trace dump
format/coredump - Core dump
format/backtrace - Backtrace formatting
format/symbol - Symbol formatting
format/address - Address formatting
format/offset - Offset formatting
format/size - Size formatting
format/count - Count formatting
format/quantity - Quantity formatting
format/magnitude - Magnitude formatting
format/scale - Scale formatting
format/proportion - Proportion formatting
format/percentage - Percentage formatting
format/permille - Permille formatting
format/ppm - Parts per million
format/ppb - Parts per billion
format/ppt - Parts per trillion
format/ratio_format - Ratio formatting
format/fraction_format - Fraction formatting
format/decimal - Decimal formatting
format/fixed - Fixed-point formatting
format/floating - Floating-point formatting
format/exponent - Exponent formatting
format/sign - Sign formatting
format/sign_aware - Sign-aware formatting
format/sign_optional - Optional sign
format/sign_forced - Forced sign
format/parentheses - Parentheses for negative
format/currency - Currency formatting
format/accounting - Accounting format
format/financial - Financial formatting
format/investment - Investment formatting
format/tax - Tax formatting
format/deduction - Deduction formatting
format/interest - Interest formatting
format/compound - Compound interest
format/amortization - Amortization
format/depreciation - Depreciation
format/royalty - Royalty formatting
format/commission - Commission formatting
format/tip - Tip formatting
format/discount - Discount formatting
format/markup - Markup formatting
format/margin_format - Margin formatting
format/profit - Profit formatting
format/loss - Loss formatting
format/breakeven - Breakeven formatting
format/roi - ROI formatting
format/roe - ROE formatting
format/roa - ROA formatting
format/eps - EPS formatting
format/pe - P/E ratio formatting
format/peg - PEG ratio formatting
format/debt - Debt formatting
format/equity - Equity formatting
format/asset - Asset formatting
format/liability - Liability formatting
format/revenue - Revenue formatting
format/expense - Expense formatting
format/cashflow - Cash flow formatting
format/income - Income formatting
format/balance - Balance formatting
format/ledger - Ledger formatting
format/journal - Journal formatting
format/entry - Entry formatting
format/account - Account formatting
format/invoice - Invoice formatting
format/receipt - Receipt formatting
format/purchase - Purchase formatting
format/order - Order formatting
format/bill - Bill formatting
format/payment - Payment formatting
format/refund - Refund formatting
format/credit - Credit note formatting
format/debit - Debit note formatting
format/statement - Statement formatting
format/report - Report formatting
format/summary - Summary formatting
format/overview - Overview formatting
format/detail - Detail formatting
format/breakdown - Breakdown formatting
format/category - Category formatting
format/subcategory - Subcategory formatting
format/group - Group formatting
format/total - Total formatting
format/subtotal - Subtotal formatting
format/grand_total - Grand total
format/balance_sheet - Balance sheet
format/income_statement - Income statement
format/cash_flow - Cash flow statement
format/equity_statement - Equity statement
format/comprehensive - Comprehensive income
format/retained_earnings - Retained earnings
format/dividend - Dividend formatting
format/stock - Stock formatting
format/bond - Bond formatting
format/future - Futures formatting
format/option - Options formatting
format/swap - Swap formatting
format/forward - Forward formatting
format/derivative - Derivative formatting
format/hedge - Hedge formatting
format/arbitrage - Arbitrage formatting
format/portfolio - Portfolio formatting
format/fund - Fund formatting
format/etf - ETF formatting
format/mutual - Mutual fund formatting
format/pension - Pension formatting
format/retirement - Retirement formatting
format/annuity - Annuity formatting
format/insurance - Insurance formatting
format/premium - Premium formatting
format/claim - Claim formatting
format/deductible - Deductible formatting
format/coverage - Coverage formatting
format/beneficiary - Beneficiary formatting
format/policy - Policy formatting
format/underwriting - Underwriting
format/actuarial - Actuarial formatting
format/risk - Risk formatting
format/volatility - Volatility formatting
format/correlation - Correlation formatting
format/covariance - Covariance formatting
format/beta - Beta formatting
format/alpha - Alpha formatting
format/sharpe - Sharpe ratio
format/sortino - Sortino ratio
format/calmar - Calmar ratio
format/sterling - Sterling ratio
format/max_drawdown - Maximum drawdown
format/var - VaR formatting
format/cvar - CVaR formatting
format/backtest - Backtest formatting
format/fwdtest - Forward test formatting
format/montecarlo - Monte Carlo formatting
format/bootstrapping - Bootstrapping
format/permutation - Permutation formatting
format/validation - Validation formatting
format/crossval - Cross-validation
format/confusion - Confusion matrix
format/roc - ROC curve
format/pr - PR curve
format/auc - AUC formatting
format/lift - Lift chart
format/gain - Gain chart
format/response - Response formatting
format/sensitivity - Sensitivity formatting
format/specificity - Specificity formatting
format/precision - Precision formatting
format/recall - Recall formatting
format/f1 - F1 score
format/fbeta - F-beta score
format/accuracy - Accuracy formatting
format/error - Error formatting
format/mse - MSE formatting
format/rmse - RMSE formatting
format/mae - MAE formatting
format/mape - MAPE formatting
format/smape - SMAPE formatting
format/mase - MASE formatting
format/logloss - Log loss
format/hinge - Hinge loss
format/huber - Huber loss
format/quantile - Quantile loss
format/pinball - Pinball loss
format/crps - CRPS formatting
format/brier - Brier score
format/auc - AUC formatting
format/aucpr - AUCPR formatting
format/lift_format - Lift formatting
format/decile - Decile formatting
format/quartile - Quartile formatting
format/percentile - Percentile formatting
format/median - Median formatting
format/mean - Mean formatting
format/mode - Mode formatting
format/stddev - Standard deviation
format/variance - Variance formatting
format/skewness - Skewness formatting
format/kurtosis - Kurtosis formatting
format/entropy - Entropy formatting
format/mutual_info - Mutual information
format/gini - Gini coefficient
format/atkinson - Atkinson index
format/theil - Theil index
format/herfindahl - Herfindahl index
format/gibbs - Gibbs sampling formatting
format/mcmc - MCMC formatting
format/stan - Stan formatting
format/bayes - Bayesian formatting
format/prior - Prior formatting
format/posterior - Posterior formatting
format/likelihood - Likelihood formatting
format/credible - Credible interval
format/hdri - HDR interval
format/bayes_factor - Bayes factor
format/odds - Odds formatting
format/log_odds - Log odds
format/risk_ratio - Risk ratio
format/odds_ratio - Odds ratio
format/hazard - Hazard ratio
format/incidence - Incidence rate
format/prevalence - Prevalence
format/mortality - Mortality rate
format/morbidity - Morbidity rate
format/survival - Survival formatting
format/kaplan_meier - Kaplan-Meier
format/cph - Cox proportional hazards
format/af - Attributable fraction
format/nnt - Number needed to treat
format/nnh - Number needed to harm
format/arr - Absolute risk reduction
format/rrr - Relative risk reduction
format/effect_size - Effect size
format/cohens_d - Cohen's d
format/hedges_g - Hedges' g
format/glass_delta - Glass's delta
format/eta_squared - Eta squared
format/omega_squared - Omega squared
format/cohens_f - Cohen's f
format/r_squared - R-squared
format/adjusted_r2 - Adjusted R-squared
format/partial_eta2 - Partial eta squared
format/effect_size - Effect size
format/power - Statistical power
format/sample_size - Sample size
format/confidence - Confidence interval
format/credible_int - Credible interval
format/tolerance - Tolerance interval
format/prediction - Prediction interval
format/coverage - Coverage formatting
format/undercoverage - Undercoverage
format/overcoverage - Overcoverage
format/noncoverage - Noncoverage
format/margin_of_error - Margin of error
format/standard_error - Standard error
format/degrees_freedom - Degrees of freedom
format/p_value - P-value formatting
format/significance - Significance level
format/alpha_level - Alpha level
format/beta_level - Beta level
format/test_statistic - Test statistic
format/z_score - Z-score
format/t_score - T-score
format/f_score - F-score
format/chi_square - Chi-square
format/chi_square_stat - Chi-square statistic
format/phi_coeff - Phi coefficient
format/cramers_v - Cramer's V
format/ccc - Cramér's V
format/kendall - Kendall's tau
format/spearman - Spearman's rho
format/pearson - Pearson correlation
format/pointbiserial - Point-biserial
format/biserial - Biserial
format/polychoric - Polychoric
format/polyserial - Polyserial
format/intraclass - Intraclass correlation
format/icc - ICC formatting
format/alpha_reliability - Cronbach's alpha
format/guttman - Guttman's lambda
format/split_half - Split-half reliability
format/test_retest - Test-retest reliability
format/inter_rater - Inter-rater reliability
format/krippendorff - Krippendorff's alpha
format/fleiss - Fleiss' kappa
format/cohens_kappa - Cohen's kappa
format/sensitivity - Sensitivity
format/specificity - Specificity
format/ppv - Positive predictive value
format/npv - Negative predictive value
format/lr_plus - Positive likelihood ratio
format/lr_minus - Negative likelihood ratio
format/dor - Diagnostic odds ratio
format/youden - Youden index
format/mcc - Matthews correlation coefficient
format/fowlkes - Fowlkes-Mallows index
format/rand_index - Rand index
format/adj_rand - Adjusted Rand index
format/mutual_info_score - Mutual information score
format/adj_mutual_info - Adjusted mutual information
format/homogeneity - Homogeneity
format/completeness - Completeness
format/v_measure - V-measure
format/silhouette - Silhouette coefficient
format/davies_bouldin - Davies-Bouldin index
format/calinski_harabasz - Calinski-Harabasz index
format/dunn_index - Dunn index
format/ch_index - CH index
format/db_index - DB index
format/xb_index - XB index
format/trace_w - Within-cluster scatter
format/trace_b - Between-cluster scatter
format/trace_t - Total scatter
format/elbow - Elbow method
format/gap_statistic - Gap statistic
format/silhouette_plot - Silhouette plot
format/dendrogram - Dendrogram formatting
format/clustergram - Clustergram
format/heatmap_dendro - Heatmap with dendrogram
format/phylogenetic - Phylogenetic tree
format/cladogram - Cladogram
format/phylogram - Phylogram
format/chronogram - Chronogram
format/ultrametric - Ultrametric tree
format/additive - Additive tree
format/splits - Split network
format/consensus - Consensus tree
format/bootstrapping_tree - Bootstrapped tree
format/bayesian_tree - Bayesian tree
format/maximum_likelihood - Maximum likelihood tree
format/parsimony - Parsimony tree
format/neighbor_joining - Neighbor-joining
format/upgma - UPGMA
format/wpgma - WPGMA
format/single_link - Single linkage
format/complete_link - Complete linkage
format/average_link - Average linkage
format/centroid - Centroid linkage
format/median_link - Median linkage
format/ward - Ward's method
format/mclust - Mclust formatting
format/gaussian_mixture - Gaussian mixture
format/em_algorithm - EM algorithm
format/viterbi - Viterbi algorithm
format/baum_welch - Baum-Welch
format/hmm - Hidden Markov model
format/crf - Conditional random field
format/markov_chain - Markov chain
format/hidden_markov - Hidden Markov model
format/state_space - State space
format/transition - Transition matrix
format/emission - Emission matrix
format/initial - Initial probabilities
format/stationary - Stationary distribution
format/absorbing - Absorbing Markov chain
format/ergodic - Ergodic Markov chain
format/periodic - Periodic chain
format/aperiodic - Aperiodic chain
format/recurrent - Recurrent chain
format/transient - Transient chain
format/closed_class - Closed class
format/open_class - Open class
format/gamblers_ruin - Gambler's ruin
format/birth_death - Birth-death process
format/markov_chain_mc - MCMC
format/gibbs_sampling - Gibbs sampling
format/metropolis_hastings - Metropolis-Hastings
format/hmc - Hamiltonian Monte Carlo
format/nuts - NUTS sampler
format/slice_sampling - Slice sampling
format/rejection_sampling - Rejection sampling
format/importance_sampling - Importance sampling
format/sequential_monte - Sequential Monte Carlo
format/particle_filter - Particle filter
format/kalman_filter - Kalman filter
format/extended_kalman - Extended Kalman filter
format/unscented_kalman - Unscented Kalman filter
format/particle_kalman - Particle Kalman filter
format/adaptive_kalman - Adaptive Kalman filter
format/h_infinity - H-infinity filter
format/wiener_filter - Wiener filter
format/adaptive_filter - Adaptive filter
format/lms_filter - LMS filter
format/rls_filter - RLS filter
format/recursive_least - Recursive least squares
format/linear_regression - Linear regression
format/logistic_regression - Logistic regression
format/poisson_regression - Poisson regression
format/negative_binomial - Negative binomial
format/zero_inflated - Zero-inflated
format/hurdle_model - Hurdle model
format/multinomial - Multinomial regression
format/ordinal - Ordinal regression
format/nominal - Nominal regression
format/proportional_odds - Proportional odds
format/cox_regression - Cox regression
format/competing_risks - Competing risks
format/fine_gray - Fine-Gray model
format/rsf - Random survival forest
format/coxnet - Coxnet
format/ridge - Ridge regression
format/lasso - Lasso
format/elastic_net - Elastic net
format/adaptive_lasso - Adaptive lasso
format/group_lasso - Group lasso
format/fused_lasso - Fused lasso
format/tv_lasso - Total variation lasso
format/oscar - OSCAR
format/mcp - MCP penalty
format/scad - SCAD penalty
format/mnet - MNET
format/glmnet - GLMNET
format/bayesian_glm - Bayesian GLM
format/brms - BRMS formatting
format/rstanarm - RStanArm formatting
format/lme4 - LME4 formatting
format/nlme - NLME formatting
format/mixed_model - Mixed model
format/random_effects - Random effects
format/fixed_effects - Fixed effects
format/random_intercept - Random intercept
format/random_slope - Random slope
format/nested_model - Nested model
format/crossed_model - Crossed model
format/multilevel - Multilevel model
format/hierarchical - Hierarchical model
format/grouped_model - Grouped model
format/clustered_model - Clustered model
format/panel_model - Panel model
format/longitudinal - Longitudinal model
format/repeated_measures - Repeated measures
format/within_subject - Within-subject
format/between_subject - Between-subject
format/mixed_anova - Mixed ANOVA
format/repeated_anova - Repeated ANOVA
format/manova - MANOVA
format/ancova - ANCOVA
format/mancova - MANCOVA
format/rm_manova - Repeated MANOVA
format/rm_ancova - Repeated ANCOVA
format/gls - Generalized least squares
format/wls - Weighted least squares
format/ols - Ordinary least squares
format/iv - Instrumental variables
format/2sls - Two-stage least squares
format/3sls - Three-stage least squares
format/sur - Seemingly unrelated regression
format/var - Vector autoregression
format/svar - Structural VAR
format/vecm - Vector error correction
format/cointegration - Cointegration
format/engle_granger - Engle-Granger
format/johansen - Johansen test
format/adf - Augmented Dickey-Fuller
format/kpss - KPSS test
format/pp - Phillips-Perron
format/df - Dickey-Fuller
format/ers - Elliott-Rothenberg-Stock
format/ng - Ng-Perron
format/le - Leybourne
format/ks - Kolmogorov-Smirnov
format/ad - Anderson-Darling
format/sw - Shapiro-Wilk
format/ks_test - KS test
format/ctest - Chi-square test
format/ftest - F-test
format/ttest - T-test
format/utest - U-test
format/mwtest - Mann-Whitney
format/wilcoxon - Wilcoxon test
format/sign_test - Sign test
format/mcnemar - McNemar's test
format/cq - Cochran's Q
format/mantel - Mantel test
format/mantel_haenszel - Mantel-Haenszel
format/breslow_day - Breslow-Day
format/tarone - Tarone's test
format/barnard - Barnard's test
format/boschloo - Boschloo's test
format/fisher_exact - Fisher's exact test
format/chi2_test - Chi-square test
format/g_test - G-test
format/log_likelihood - Log-likelihood
format/score_test - Score test
format/lrtest - Likelihood ratio test
format/wald_test - Wald test
format/rao_test - Rao test
format/durbin_watson - Durbin-Watson
format/breusch_pagan - Breusch-Pagan
format/goldfeld_quandt - Goldfeld-Quandt
format/harvey - Harvey test
format/glesjer - Glesjer test
format/white_test - White test
format/cook_weisberg - Cook-Weisberg
format/levene - Levene's test
format/bartlett - Bartlett's test
format/fligner - Fligner-Killeen
format/brown_forsythe - Brown-Forsythe
format/ansari - Ansari-Bradley
format/mood - Mood's test
format/conover - Conover's test
format/dunn_test - Dunn's test
format/games_howell - Games-Howell
format/tamhane - Tamhane's T2
format/dunnet - Dunnett's test
format/tukey_hsd - Tukey HSD
format/scheffe - Scheffe's test
format/bonferroni - Bonferroni correction
format/holm - Holm correction
format/hochberg - Hochberg correction
format/hommel - Hommel correction
format/benjamini_hochberg - Benjamini-Hochberg
format/benjamini_yekutieli - Benjamini-Yekutieli
format/bh - BH correction
format/by - BY correction
format/fdr - False discovery rate
format/fwer - Family-wise error rate
format/permutation_test - Permutation test
format/boot_test - Bootstrap test
format/monte_carlo_test - Monte Carlo test
format/randomization_test - Randomization test
format/exact_test - Exact test
format/asymptotic_test - Asymptotic test
format/approximate_test - Approximate test
format/resampling - Resampling formatting
format/boot_ci - Bootstrap CI
format/percentile_boot - Percentile bootstrap
format/bca_boot - BCa bootstrap
format/t_boot - Bootstrap t
format/studentized_boot - Studentized bootstrap
format/parametric_boot - Parametric bootstrap
format/nonparametric_boot - Nonparametric bootstrap
format/smooth_boot - Smooth bootstrap
format/mcmc_boot - MCMC bootstrap
format/wild_boot - Wild bootstrap
format/block_boot - Block bootstrap
format/moving_block - Moving block bootstrap
format/circular_boot - Circular bootstrap
format/stationary_boot - Stationary bootstrap
format/sieve_boot - Sieve bootstrap
format/subset_boot - Subset bootstrap
format/bayesian_boot - Bayesian bootstrap
format/weights_boot - Weighted bootstrap
format/jackknife - Jackknife
format/delete_d - Delete-d jackknife
format/delete_group - Delete-group jackknife
format/random_delete - Random delete jackknife
format/influence - Influence function
format/hijacked - Hijacked
format/dfbetas - DFBETAS
format/dffits - DFFITS
format/cook_d - Cook's distance
format/covratio - Covariance ratio
format/leverage - Leverage
format/mahalanobis - Mahalanobis distance
format/studentized - Studentized residual
format/deleted_residual - Deleted residual
format/standardized_residual - Standardized residual
format/pearson_residual - Pearson residual
format/deviance_residual - Deviance residual
format/working_residual - Working residual
format/response_residual - Response residual
format/partial_residual - Partial residual
format/component_plus - Component-plus residual
format/ceres - CERES residual
format/avplot - Added-variable plot
format/crplot - Component-residual plot
format/cooksd_plot - Cook's distance plot
format/leverage_plot - Leverage plot
format/residual_plot - Residual plot
format/qq_plot - Q-Q plot
format/pp_plot - P-P plot
format/probability_plot - Probability plot
format/boxcox - Box-Cox plot
format/cleveland - Cleveland dot plot
format/stripplot - Strip plot
format/swarmplot - Swarm plot
format/violinplot - Violin plot
format/boxenplot - Boxen plot
format/letter_value - Letter-value plot
format/beanplot - Bean plot
format/raincloud - Raincloud plot
format/jitterplot - Jitter plot
format/beeswarm - Beeswarm plot
format/ridgeline - Ridgeline plot
format/joyplot - Joy plot
format/quantile_plot - Quantile plot
format/empirical_cdf - Empirical CDF
format/ecdf_plot - ECDF plot
format/survival_plot - Survival plot
format/hazard_plot - Hazard plot
format/cumulative_hazard - Cumulative hazard
format/incidence_plot - Incidence plot
format/prevalence_plot - Prevalence plot
format/timeline_plot - Timeline plot
format/event_plot - Event plot
format/gantt_plot - Gantt plot
format/waterfall_plot - Waterfall plot
format/waterfall - Waterfall chart
format/cascade - Cascade chart
format/marimekko - Marimekko chart
format/mekko - Mekko chart
format/treemap_plot - Treemap plot
format/sunburst_plot - Sunburst plot
format/circle_packing - Circle packing
format/voronoi - Voronoi diagram
format/delaunay - Delaunay triangulation
format/convex_hull - Convex hull
format/concave_hull - Concave hull
format/alpha_shape - Alpha shape
format/ellipse - Ellipse formatting
format/circle - Circle formatting
format/sphere - Sphere formatting
format/cylinder - Cylinder formatting
format/cone - Cone formatting
format/torus - Torus formatting
format/cuboid - Cuboid formatting
format/polyhedron - Polyhedron
format/tetrahedron - Tetrahedron
format/octahedron - Octahedron
format/dodecahedron - Dodecahedron
format/icosahedron - Icosahedron
format/pyramid - Pyramid formatting
format/prism - Prism formatting
format/antiprism - Antiprism
format/frustum - Frustum formatting
format/geodesic - Geodesic sphere
format/platonic - Platonic solid
format/archimedean - Archimedean solid
format/catalan - Catalan solid
format/johnson - Johnson solid
format/kepler_poinsot - Kepler-Poinsot polyhedron
format/regular_polygon - Regular polygon
format/star_polygon - Star polygon
format/heptagram - Heptagram
format/octagram - Octagram
format/nonagram - Nonagram
format/decagram - Decagram
format/pentagram - Pentagram
format/hexagram - Hexagram
format/tridecagram - Tridecagram
format/tetradecagram - Tetradecagram
format/pentadecagram - Pentadecagram
format/hexadecagram - Hexadecagram
format/heptadecagram - Heptadecagram
format/octadecagram - Octadecagram
format/enneadecagram - Enneadecagram
format/icosagram - Icosagram
format/star_shapes - Star shapes
format/spiral - Spiral formatting
format/helix - Helix formatting
format/curve - Curve formatting
format/bezier - Bezier curve
format/spline - Spline curve
format/bspline - B-spline
format/nurbs - NURBS curve
format/hermite - Hermite spline
format/catmull_rom - Catmull-Rom spline
format/kochanek_bartels - Kochanek-Bartels spline
format/beta_spline - Beta spline
format/rational_curve - Rational curve
format/surface - Surface formatting
format/mesh - Mesh formatting
format/triangle_mesh - Triangle mesh
format/quad_mesh - Quad mesh
format/subdivision - Subdivision surface
format/catmull_subdiv - Catmull-Clark subdivision
format/loop_subdiv - Loop subdivision
format/doo_sabin - Doo-Sabin subdivision
format/butterfly_subdiv - Butterfly subdivision
format/kobbelt_subdiv - Kobbelt subdivision
format/midpoint_subdiv - Midpoint subdivision
format/sqrt3_subdiv - Sqrt(3) subdivision
format/quad_trisection - Quad-trisection
format/tri_trisection - Tri-trisection
format/quad_quadrisection - Quad-quadrisection
format/tri_quadrisection - Tri-quadrisection
format/smooth_mesh - Smooth mesh
format/fairing - Fairing
format/laplacian_smooth - Laplacian smoothing
format/taubin_smooth - Taubin smoothing
format/humphrey_smooth - Humphrey smoothing
format/cotangent_smooth - Cotangent smoothing
format/mean_curvature - Mean curvature flow
format/volume_preserving - Volume preserving flow
format/shrinkwrap - Shrinkwrap
format/remesh - Remeshing
format/decimate - Decimation
format/simplify - Simplification
format/subdivide - Subdivision
format/refine - Refinement
format/upsample - Upsampling
format/downsample - Downsampling
format/resample - Resampling
format/relax - Relaxation
format/optimize - Optimization
format/smooth - Smoothing
format/sharp - Sharpening
format/flatten - Flattening
format/unfold - Unfolding
format/parameterize - Parameterization
format/uvmap - UV mapping
format/texture_coords - Texture coordinates
format/normal_map - Normal map
format/displacement - Displacement map
format/bump_map - Bump map
format/parallax_map - Parallax map
format/environment_map - Environment map
format/cube_map - Cube map
format/sphere_map - Sphere map
format/equirectangular - Equirectangular projection
format/mercator - Mercator projection
format/gall_peters - Gall-Peters projection
format/robinson - Robinson projection
format/winkel_tripel - Winkel Tripel projection
format/mollweide - Mollweide projection
format/hammer - Hammer projection
format/aitoff - Aitoff projection
format/lambert - Lambert projection
format/albers - Albers projection
format/conic - Conic projection
format/azimuthal - Azimuthal projection
format/gnomonic - Gnomonic projection
format/stereographic - Stereographic projection
format/orthographic - Orthographic projection
format/equal_area - Equal area projection
format/equidistant - Equidistant projection
format/conformal - Conformal projection
format/pseudo - Pseudo-projection
format/sinusoidal - Sinusoidal projection
format/bonne - Bonne projection
format/van_der_grinten - Van der Grinten
format/eckert - Eckert projection
format/goode - Goode's homolosine
format/interrupted - Interrupted projection
format/butterfly_proj - Butterfly projection
format/waterman - Waterman butterfly
format/cahill - Cahill projection
format/peirce - Peirce quincuncial
format/guyou - Guyou projection
format/lee - Lee projection
format/eisenlohr - Eisenlohr projection
format/august - August projection
format/nell - Nell projection
format/oblate - Oblate projection
format/prolate - Prolate projection
format/transverse - Transverse projection
format/oblique - Oblique projection
format/equatorial - Equatorial projection
format/polar - Polar projection
format/universal - Universal projection
format/utm_projection - UTM projection
format/mgrs_projection - MGRS projection
format/gars - GARS projection
format/georef - GEOREF projection
format/maidenhead - Maidenhead locator
format/open_location - Open Location Code
format/plus_code - Plus Code
format/what3words - what3words
format/geocode - Geocoding formatting
format/reverse_geocode - Reverse geocoding
format/place - Place formatting
format/address_format - Address formatting
format/street - Street formatting
format/city - City formatting
format/state - State formatting
format/postal_code - Postal code formatting
format/country - Country formatting
format/continent - Continent formatting
format/region - Region formatting
format/district - District formatting
format/neighborhood - Neighborhood formatting
format/landmark - Landmark formatting
format/point_of_interest - Point of interest
format/poi - POI formatting
format/way - Way formatting
format/relation - Relation formatting
format/node - Node formatting
format/waypoint_format - Waypoint formatting
format/route_format - Route formatting
format/track_format - Track formatting
format/gpx_format - GPX formatting
format/kml_format - KML formatting
format/geojson_format - GeoJSON formatting
format/topo_json - TopoJSON formatting
format/geobuf - GeoBuf formatting
format/pbf - PBF formatting
format/shapefile_format - Shapefile formatting
format/dbf - DBF formatting
format/shx - SHX formatting
format/prj - PRJ formatting
format/qix - QIX formatting
format/cpg - CPG formatting
format/sbn - SBN formatting
format/sbx - SBX formatting
format/fbn - FBN formatting
format/fbx - FBX formatting
format/ain - AIN formatting
format/aih - AIH formatting
format/ixs - IXS formatting
format/mxs - MXS formatting
format/atx - ATX formatting
format/iso - ISO formatting
format/ecw - ECW formatting
format/sid - SID formatting
format/mrsid - MrSID formatting
format/jp2 - JP2 formatting
format/jpeg2000 - JPEG 2000
format/geotiff - GeoTIFF formatting
format/tiff - TIFF formatting
format/geopdf - GeoPDF formatting
format/geojp2 - GeoJP2 formatting
format/geohe - GeoHE formatting
format/geoep - GeoEP formatting
format/geobmp - GeoBMP formatting
format/geopng - GeoPNG formatting
format/geogif - GeoGIF formatting
format/geojpg - GeoJPG formatting
format/geosvg - GeoSVG formatting
format/geowebp - GeoWebP formatting
format/geobpg - GeoBPG formatting
format/geoavif - GeoAVIF formatting
format/geoheif - GeoHEIF formatting
format/geojxl - GeoJXL formatting

OS INTERACTION 
os/pipe - Anonymous pipes
os/fd - File descriptor utilities
os/dup - Duplicate file descriptors
os/select - Select/poll operations
os/event - Event polling (epoll, kqueue, IOCP)
os/ioctl - IOCTL operations
os/mmap - Memory-mapped files
os/stat - File status (size, permissions, timestamps)
os/perm - Permission operations (chmod)
os/owner - Owner operations (chown)
os/link - Hard/symbolic links
os/rename - Rename files/directories
os/remove - Delete files/directories
os/symlink - Symbolic link operations
os/readlink - Read symbolic link target
os/realpath - Resolve canonical path
os/temp - Temporary directory/file creation
os/cwd - Current working directory
os/chdir - Change directory
os/mkdir - Make directory (with parents)
os/rmdir - Remove directory
os/walk - Directory walking/traversal
os/glob - Glob pattern expansion
os/find - File finding
os/locate - File locating
os/which - Which command
os/where - Where command
os/type - File type detection
os/magic - Magic number detection
os/mime - MIME type detection
os/encoding - File encoding detection
os/eol - Line ending detection (LF, CRLF, CR)
os/bom - Byte order mark handling
os/utf8bom - UTF-8 BOM handling
os/utf16bom - UTF-16 BOM handling
os/binary - Binary file detection
os/text - Text file detection
os/empty - Empty file detection
os/size - File size utilities
os/truncate - Truncate file
os/fallocate - Pre-allocate space
os/punch_hole - Punch hole in file
os/collapse - Collapse file holes
os/seek - File seeking
os/tell - File position
os/read - File reading (various sizes)
os/write - File writing (various sizes)
os/read_at - Read at offset
os/write_at - Write at offset
os/pread - Pread (atomic read at offset)
os/pwrite - Pwrite (atomic write at offset)
os/readv - Read vector (scatter)
os/writev - Write vector (gather)
os/preadv - Preadv (scatter at offset)
os/pwritev - Pwritev (gather at offset)
os/sendfile - Sendfile (zero-copy)
os/splice - Splice (zero-copy)
os/tee - Tee (zero-copy)
os/vmsplice - Vmsplice (zero-copy)
os/io_uring - io_uring interface
os/aio - Asynchronous I/O
os/posix_aio - POSIX AIO
os/libaio - Linux AIO
os/uring - io_uring
os/iocp - IOCP (Windows)
os/overlapped - Overlapped I/O
os/completion - Completion ports
os/eventfd - Eventfd
os/timerfd - Timerfd
os/signalfd - Signalfd
os/epoll - Epoll (Linux)
os/kqueue - Kqueue (BSD/macOS)
os/poll - Poll
os/ppoll - ppoll
os/select_sys - select
os/pselect - pselect
os/kevent - kevent
os/port - Event ports (Solaris)
os/wait - Wait for processes
os/waitpid - Wait for specific PID
os/waitid - Wait for specific ID
os/wait3 - Wait with resource usage
os/wait4 - Wait with resource usage
os/fork - Fork process
os/exec - Execute process
os/execve - Execve
os/execv - Execv
os/execl - Execl
os/execle - Execle
os/execlp - Execlp
os/execvp - Execvp
os/execvpe - Execvpe
os/posix_spawn - POSIX spawn
os/posix_spawnp - POSIX spawn with PATH
os/spawn - Process spawn
os/spawnp - Spawn with PATH
os/system - System call
os/popen - Popen
os/pclose - Pclose
os/pipe2 - Pipe2 (with flags)
os/fifo - FIFO (named pipe)
os/mknod - Make node (device)
os/mkfifo - Make FIFO
os/dev - Device files
os/dev_null - /dev/null
os/dev_zero - /dev/zero
os/dev_random - /dev/random
os/dev_urandom - /dev/urandom
os/stdin - Standard input
os/stdout - Standard output
os/stderr - Standard error
os/tty - TTY operations
os/pty - Pseudoterminal
os/console - Console operations
os/terminal - Terminal operations
os/termios - Terminal I/O
os/termcap - Termcap
os/terminfo - Terminfo
os/tput - Tput utilities
os/resize - Terminal resize
os/clear - Clear screen
os/cursor - Cursor movement
os/color - Color support
os/input - Input modes
os/echo - Echo control
os/canonical - Canonical mode
os/raw - Raw mode
os/cbreak - Cbreak mode
os/nonblock - Non-blocking I/O
os/blocking - Blocking I/O
os/timeout - I/O timeout
os/async_io - Asynchronous I/O
os/signal_io - Signal-driven I/O
os/thread_io - Threaded I/O
os/stream - Stream utilities
os/buffer - Buffering utilities
os/line_buffer - Line buffering
os/full_buffer - Full buffering
os/no_buffer - No buffering
os/flush - Flush buffer
os/sync - Sync file
os/fsync - File sync
os/fdatasync - Data sync
os/syncfs - Sync filesystem
os/sync_file_range - Sync file range
os/msync - Memory sync
os/madvise - Memory advise
os/mlock - Memory lock
os/munlock - Memory unlock
os/mlockall - Lock all memory
os/munlockall - Unlock all memory
os/mincore - Memory residency
os/mprotect - Memory protection
os/mremap - Memory remap
os/madvise - Memory advise
os/memset - Memory set
os/memcpy - Memory copy
os/memmove - Memory move
os/memchr - Memory find
os/memcmp - Memory compare
os/memmem - Memory find substring
os/memrchr - Memory reverse find
os/strcpy - String copy
os/strncpy - String copy with length
os/strcat - String concatenate
os/strncat - String concatenate with length
os/strcmp - String compare
os/strncmp - String compare with length
os/strcasecmp - Case-insensitive compare
os/strncasecmp - Case-insensitive with length
os/strchr - Find character
os/strrchr - Reverse find character
os/strstr - Find substring
os/strcasestr - Case-insensitive substring
os/strpbrk - Find any character
os/strspn - Span string
os/strcspn - Complement span
os/strtok - Tokenize string
os/strtok_r - Tokenize reentrant
os/strerror - Error string
os/perror - Print error
os/errno - Error number
os/errno_list - Error number list
os/strsignal - Signal string
os/psignal - Print signal
os/backtrace - Backtrace
os/backtrace_symbols - Backtrace symbols
os/backtrace_symbols_fd - Backtrace symbols to FD
os/demangle - Symbol demangling
os/addr2line - Address to line
os/objdump - Object dump
os/readelf - Read ELF
os/readpe - Read PE
os/readmacho - Read Mach-O
os/objcopy - Object copy
os/objdump_syms - Symbol dump
os/nm - Symbol listing
os/strings - Strings extraction
os/file - File command
os/ldd - Library dependencies
os/ldconfig - Library config
os/dlopen - Dynamic loading
os/dlclose - Dynamic unloading
os/dlsym - Dynamic symbol
os/dlerror - Dynamic error
os/dladdr - Dynamic address
os/dladdr1 - Dynamic address extended
os/dlinfo - Dynamic info
os/rtld_next - RTLD_NEXT
os/rtld_default - RTLD_DEFAULT
os/rtld_self - RTLD_SELF
os/libc - Libc access
os/libm - Libm access
os/librt - Librt access
os/libdl - Libdl access
os/libpthread - Libpthread access
os/libcrypto - OpenSSL/libcrypto
os/libssl - OpenSSL/libssl
os/libz - Zlib
os/libbz2 - Bzip2
os/liblzma - LZMA
os/libzstd - Zstandard
os/liblz4 - LZ4
os/libsnappy - Snappy
os/libiconv - Iconv
os/libintl - Gettext
os/libxml2 - Libxml2
os/libxslt - Libxslt
os/libexpat - Expat
os/libyaml - Libyaml
os/libjson - JSON-C
os/libjansson - Jansson
os/libcurl - Curl
os/libgit2 - Libgit2
os/libssh2 - Libssh2
os/libssl - SSL
os/libcrypto - Crypto
os/libpcap - PCAP
os/libnet - Libnet
os/libpcap - PCAP
os/libnftnl - NFTNL
os/libmnl - MNL
os/libnl3 - Netlink
os/libnetfilter - Netfilter
os/libipq - IPQ
os/libnfnetlink - NFNetlink
os/libnetfilter_queue - NFQueue
os/libnetfilter_log - NFLog
os/libnetfilter_conntrack - NFConntrack
os/libnetfilter_cttimeout - NFCTTimeout
os/libnetfilter_cthelper - NFCTHelper
os/libnetfilter_queue - NFQueue
os/libnetfilter_log - NFLog
os/libnetfilter_conntrack - NFConntrack
os/libnetfilter_cttimeout - NFCTTimeout
os/libnetfilter_cthelper - NFCTHelper
os/libnfnetlink - NFNetlink
os/libnftnl - NFTNL
os/libmnl - MNL
os/libnl-3 - Netlink
os/libnl-route - Netlink route
os/libnl-genl - Netlink generic
os/libnl-nf - Netlink netfilter
os/libnl-idiag - Netlink inetdiag
os/libnl-cli - Netlink CLI
os/libnl - Netlink
os/rtnetlink - Rtnetlink
os/netlink - Netlink
os/genetlink - Generic netlink
os/nl80211 - nl80211 (wireless)
os/rfkill - RFKill
os/iw - Wireless utilities
os/iwconfig - Wireless config
os/iwlist - Wireless list
os/iwpriv - Wireless private
os/iwspy - Wireless spy
os/wpa - WPA supplicant
os/wpa_cli - WPA CLI
os/hostapd - Hostapd
os/hostapd_cli - Hostapd CLI
os/ath9k - Atheros
os/ath10k - Atheros 10k
os/ath11k - Atheros 11k
os/brcmfmac - Broadcom
os/rtlwifi - Realtek
os/rtl8xxxu - Realtek USB
os/rtlwifi - Realtek PCIe
os/mt76 - MediaTek
os/mt7915 - MediaTek 7915
os/mt7921 - MediaTek 7921
os/iwlwifi - Intel wireless
os/iwllegacy - Intel legacy
os/iwlwifi - Intel WiFi
os/iwlmei - Intel MEI
os/i915 - Intel graphics
os/amdgpu - AMD graphics
os/nouveau - NVIDIA nouveau
os/nvidia - NVIDIA proprietary
os/mesa - Mesa graphics
os/drm - DRM
os/drm_fourcc - DRM fourcc
os/drm_mode - DRM mode
os/gbm - GBM
os/egl - EGL
os/gl - OpenGL
os/gles - GLES
os/glx - GLX
os/wgl - WGL
os/vulkan - Vulkan
os/dx - DirectX
os/dxgi - DXGI
os/d3d11 - Direct3D 11
os/d3d12 - Direct3D 12
os/d2d - Direct2D
os/dwrite - DirectWrite
os/dcomp - DirectComposition
os/mf - Media Foundation
os/wmf - Windows Media Foundation
os/quartz - QuickTime
os/core_video - Core Video
os/core_audio - Core Audio
os/core_media - Core Media
os/cf - Core Foundation
os/cg - Core Graphics
os/cg_image - Core Graphics Image
os/cg_context - Core Graphics Context
os/cg_font - Core Graphics Font
os/cg_color - Core Graphics Color
os/cg_path - Core Graphics Path
os/cg_shader - Core Graphics Shader
os/cg_ps - Core Graphics PDF
os/core_text - Core Text
os/core_animation - Core Animation
os/scenekit - SceneKit
os/spritekit - SpriteKit
os/metal - Metal
os/metal_kit - MetalKit
os/model_io - Model I/O
os/arkit - ARKit
os/reality_kit - RealityKit
os/vision - Vision
os/natural_language - Natural Language
os/speech - Speech
os/sound_analysis - Sound Analysis
os/core_ml - Core ML
os/createml - CreateML
os/turi - Turi Create
os/core_image - Core Image
os/core_video - Core Video
os/core_media - Core Media
os/core_audio - Core Audio
os/core_midi - Core MIDI
os/core_audio_kit - Core Audio Kit
os/av_foundation - AVFoundation
os/av_kit - AVKit
os/audio_toolbox - AudioToolbox
os/audio_unit - Audio Unit
os/core_haptics - Core Haptics
os/corenfc - Core NFC
os/cornea - CoreNEA
os/core_telephony - CoreTelephony
os/coredata - CoreData
os/cloudkit - CloudKit
os/storekit - StoreKit
os/identity - Identity
os/local_authentication - Local Authentication
os/security - Security
os/keychain - Keychain
os/kerberos_os - Kerberos
os/ldap_os - LDAP
os/open_directory - Open Directory
os/authentication - Authentication
os/authorization - Authorization
os/sandbox - Sandbox
os/entitlements - Entitlements
os/protected - Protected resources
os/photo - Photos
os/photo_kit - PhotoKit
os/camera - Camera
os/microphone - Microphone
os/location - Location
os/motion - Motion
os/pedometer - Pedometer
os/health_kit - HealthKit
os/research_kit - ResearchKit
os/care_kit - CareKit
os/school_kit - SchoolKit
os/class_kit - ClassKit
os/map_kit - MapKit
os/map_kit_js - MapKit JS
os/address_book - Address Book
os/contacts - Contacts
os/contacts_ui - ContactsUI
os/event_kit - EventKit
os/event_kit_ui - EventKitUI
os/calendar - Calendar
os/reminders - Reminders
os/notes - Notes
os/reminders_kit - RemindersKit
os/messages - Messages
os/message_ui - MessageUI
os/mail - Mail
os/mail_ui - MailUI
os/game_kit - GameKit
os/game_center - Game Center
os/game_controller - GameController
os/game_play - GamePlay
os/replay_kit - ReplayKit
os/screen_kit - ScreenKit
os/device_check - DeviceCheck
os/device_activity - DeviceActivity
os/family_controls - FamilyControls
os/managed - Managed
os/mdm - MDM
os/profiles - Profiles
os/configuration - Configuration
os/enterprise - Enterprise
os/edition - Edition
os/platform - Platform
os/version - Version
os/build - Build
os/update - Update
os/restore - Restore
os/recovery - Recovery
os/secure_enclave - Secure Enclave
os/crypto_kit - CryptoKit
os/security_interface - SecurityInterface
os/accessibility - Accessibility
os/siri - Siri
os/siri_kit - SiriKit
os/shortcuts - Shortcuts
os/shortcuts_kit - ShortcutsKit
os/intents - Intents
os/intents_ui - IntentsUI
os/app_clips - App Clips
os/app_library - App Library
os/app_store - App Store
os/mac_app_store - Mac App Store
os/play_store - Play Store
os/amazon_store - Amazon Appstore
os/galaxy_store - Galaxy Store
os/huawei_store - Huawei AppGallery
os/xiaomi_store - Xiaomi GetApps
os/oppo_store - OPPO App Market
os/vivo_store - Vivo App Store
os/tencent_store - Tencent MyApp
os/alibaba_store - Alibaba App Store
os/baidu_store - Baidu App Store
os/360_store - 360 App Store
os/meizu_store - Meizu App Store
os/lenovo_store - Lenovo Store
os/samsung_store - Samsung Galaxy Store
os/lg_store - LG SmartWorld
os/sony_store - Sony Select
os/microsoft_store - Microsoft Store
os/chrome_web_store - Chrome Web Store
os/firefox_addons - Firefox Add-ons
os/opera_addons - Opera Add-ons
os/edge_addons - Edge Add-ons
os/packaging - Packaging
os/signing - Code signing
os/notarization - Notarization
os/entitlements_signing - Entitlements signing
os/provisioning - Provisioning profiles
os/certs - Certificates
os/keys - Keys
os/secrets - Secrets
os/passwords - Passwords
os/tokens - Tokens
os/sessions - Sessions
os/cookies - Cookies
os/cache - Cache
os/preferences - Preferences
os/settings - Settings
os/configuration_os - Configuration
os/plist - Property lists
os/pbplist - Binary plist
os/xmlplist - XML plist
os/jsonplist - JSON plist
os/registry - Windows registry
os/reg_key - Registry key
os/reg_value - Registry value
os/reg_hive - Registry hive
os/reg_acl - Registry ACL
os/reg_transaction - Registry transaction
os/gac - Global Assembly Cache
os/assembly - Assembly
os/manifest - Manifest
os/publisher - Publisher
os/authenticode - Authenticode
os/signtool - SignTool
os/winverify - WinVerify
os/certmgr - CertMgr
os/makecert - MakeCert
os/pvk2pfx - PVK2PFX
os/certutil - CertUtil
os/certreq - CertReq
os/certoc - CertOC
os/certtmpl - CertTmpl
os/certsrv - CertSrv
os/pkicert - PKI Cert
os/msca - MSCA
os/mscep - MSCEP
os/ocsp - OCSP
os/crl - CRL
os/crl_dist - CRL distribution
os/aia - AIA
os/cdp - CDP
os/ocsp_stapling - OCSP stapling
os/must_staple - Must-staple
os/ct - Certificate transparency
os/sct - Signed certificate timestamp
os/precert - Precertificate
os/precert_sct - Precertificate SCT
os/akid - Authority key ID
os/skid - Subject key ID
os/basic_constraints - Basic constraints
os/key_usage - Key usage
os/ext_key_usage - Extended key usage
os/subject_alt - Subject alternative name
os/issuer_alt - Issuer alternative name
os/auth_info - Authority info
os/subj_info - Subject info
os/crl_dist_points - CRL distribution points
os/cert_policies - Certificate policies
os/policy_mapping - Policy mapping
os/policy_constraints - Policy constraints
os/inhibit_any - Inhibit any policy
os/name_constraints - Name constraints
os/permitted_subtrees - Permitted subtrees
os/excluded_subtrees - Excluded subtrees
os/private_key_usage - Private key usage period
os/issuer_cert - Issuer certificate
os/cert_serial - Certificate serial
os/thumbprint - Thumbprint
os/fingerprint - Fingerprint
os/spki - Subject public key info
os/subject_key - Subject key
os/issuer_key - Issuer key
os/authority_key - Authority key
os/cross_cert - Cross-certification
os/bridge_ca - Bridge CA
os/root_ca - Root CA
os/intermediate_ca - Intermediate CA
os/sub_ca - Sub CA
os/end_entity - End entity
os/client_cert - Client certificate
os/server_cert - Server certificate
os/email_cert - Email certificate
os/code_signing_cert - Code signing certificate
os/domain_validation - Domain validation
os/org_validation - Organization validation
os/ev_cert - Extended validation
os/dv_cert - Domain validation certificate
os/ov_cert - Organization validation certificate
os/wildcard_cert - Wildcard certificate
os/multi_domain_cert - Multi-domain certificate
os/san_cert - SAN certificate
os/sni_cert - SNI certificate
os/ecdsa_cert - ECDSA certificate
os/rsa_cert - RSA certificate
os/dsa_cert - DSA certificate
os/ed25519_cert - Ed25519 certificate
os/ed448_cert - Ed448 certificate
os/pqc_cert - Post-quantum certificate
os/x509_v1 - X.509 v1
os/x509_v2 - X.509 v2
os/x509_v3 - X.509 v3
os/pkcs1 - PKCS#1
os/pkcs7 - PKCS#7
os/pkcs8 - PKCS#8
os/pkcs10 - PKCS#10 (CSR)
os/pkcs11 - PKCS#11 (HSM)
os/pkcs12 - PKCS#12 (PFX)
os/pkcs15 - PKCS#15
os/pkix - PKIX
os/pki - PKI
os/cms - CMS
os/smime - S/MIME
os/pgp_os - PGP/GPG
os/ssh_os - SSH
os/ssh_agent - SSH agent
os/ssh_key - SSH key
os/ssh_cert - SSH certificate
os/known_hosts - Known hosts
os/authorized_keys - Authorized keys
os/ssh_config - SSH config
os/sshd_config - SSHD config
os/ssl_cert - SSL certificate
os/tls_cert - TLS certificate
os/dtls_cert - DTLS certificate
os/webrtc_cert - WebRTC certificate
os/mqtt_cert - MQTT certificate
os/coap_cert - CoAP certificate
os/zigbee_cert - Zigbee certificate
os/z_wave_cert - Z-Wave certificate
os/ble_cert - Bluetooth LE certificate
os/nfc_cert - NFC certificate
os/rfid_cert - RFID certificate
os/device_cert - Device certificate
os/user_cert - User certificate
os/group_cert - Group certificate
os/role_cert - Role certificate
os/attribute_cert - Attribute certificate
os/attribute_cert - Attribute certificate (AC)
os/ac - Attribute certificate
os/attr_cert - Attribute certificate
os/pmi - PMI
os/privilege - Privilege
os/privilege_mgmt - Privilege management
os/privilege_cert - Privilege certificate
os/sa - Security attribute
os/soa - Source of authority
os/grant - Grant
os/deny - Deny
os/permit - Permit
os/prohibit - Prohibit
os/audit - Audit
os/audit_trail - Audit trail
os/audit_log - Audit log
os/security_log - Security log
os/access_log - Access log
os/error_log - Error log
os/syslog - Syslog
os/eventlog - Event log (Windows)
os/trace_log - Trace log
os/debug_log - Debug log
os/perf_log - Performance log
os/monitor_log - Monitor log
os/metric_log - Metric log
os/json_log - JSON log
os/structured_log - Structured log
os/query_log - Query log
os/transaction_log - Transaction log
os/journal - Journal
os/systemd_journal - Systemd journal
os/bsd_syslog - BSD syslog
os/rfc5424 - RFC 5424
os/rfc3164 - RFC 3164
os/syslog_ng - syslog-ng
os/rsyslog - rsyslog
os/logrotate - Log rotation
os/log_rotate - Log rotation utilities
os/log_compress - Log compression
os/log_archive - Log archiving
os/log_retention - Log retention
os/log_audit - Log auditing
os/log_analysis - Log analysis
os/log_correlation - Log correlation
os/log_enrichment - Log enrichment
os/log_parsing - Log parsing
os/log_filtering - Log filtering
os/log_aggregation - Log aggregation
os/log_shipping - Log shipping
os/log_streaming - Log streaming
os/log_realtime - Real-time log
os/log_forward - Log forwarding
os/log_forwarder - Log forwarder
os/log_agent - Log agent
os/log_client - Log client
os/log_server - Log server
os/log_collector - Log collector
os/log_indexer - Log indexer
os/log_search - Log search
os/log_visualize - Log visualization
os/log_dashboard - Log dashboard
os/log_alert - Log alerting
os/log_notification - Log notification
os/log_report - Log reporting
os/log_scheduling - Log scheduling
os/log_trigger - Log trigger
os/log_action - Log action
os/log_script - Log script
os/log_hook - Log hook
os/log_plugin - Log plugin
os/log_api - Log API
os/log_rest - Log REST
os/log_graphql - Log GraphQL
os/log_grpc - Log gRPC
os/log_protobuf - Log Protobuf
os/log_flatbuffers - Log FlatBuffers
os/log_capnproto - Log Cap'n Proto
os/log_avro - Log Avro
os/log_parquet - Log Parquet
os/log_orc - Log ORC
os/log_arrow - Log Arrow
os/log_binary - Log binary
os/log_text - Log text
os/log_format - Log format
os/log_structured - Log structured
os/log_semantic - Log semantic
os/log_contextual - Log contextual


RANDOM 


---

# -------------------------------------------------------------------
# CROSS-REFERENCE & PRODUCTION PLAN (v2 — 2026-08-07)
# Purpose: for EVERY entry in the STD EXTENSION PLANNING list below,
# decide: HAVE (in stdlib/package) | STDLIB (no deps, implement here)
# | PACKAGE (needs deps or domain-specific, goes to packages/<name>).
# After each section: audit notes (folder grouping, refactoring).
# -------------------------------------------------------------------

## 0. RULES (final)

1. **STDLIB = ZERO external dependencies.** Only pure XIOM + OS syscalls via
   minimal FFI + the compiler substrate (LLVM/clang/NASM). Everything that
   needs a 3rd-party C library (OpenSSL, libcurl, ICU, zlib is fine — we have
   pure impls — but OpenSSL/ICU/etc are NOT) ? **PACKAGE**.
2. **Package = built on stdlib, may wrap C.** Lives in `packages/<name>/`.
3. Every package folder gets a `README.md` listing the libs/modules to create
   (NOT full specs — just the inventory + one-line scope). 257 placeholder
   folders already exist; this plan assigns the list entries to them.
4. **Folder grouping is VERIFIED WORKING**: `use xiom.foo.bar` resolves
   `stdlib/xiom/foo/bar.xi` (catalog strategy a: path-based). Tested with
   `use xiom._foldertest.sub` ? exit 42. So we CAN organize stdlib into
   subfolders (e.g. `stdlib/xiom/str/`, `stdlib/xiom/net/`) WITHOUT breaking
   `use` — BUT the 40 test-imported module NAMES must stay resolvable.
   ?? IMPORTANT: moving `string.xi` ? `str/string.xi` changes `use xiom.string`
   resolution (strategy a fails, strategy b matches declared module header —
   the header says `module xiom.string` so strategy b WOULD still find it).
   VERIFY before moving; safest = keep contract modules at top level, put NEW
   grouped modules in folders with dotted names.
5. **File-size refactoring rule**: any module > 1,000 lines gets split into
   folder modules (`num/`, `str/`, `crypto/`, `net/`, `os/`, `collect/`,
   `format/`, `text/`) with the ORIGINAL file kept as the aggregate re-export
   for the frozen contract, and new fns added to the sub-modules. The API-freeze
   test guards the flat files; folder modules are additive.

## 1. HASHING (15 entries)

| Entry | Decision | Where / Status |
|-------|----------|----------------|
| hash/fnv (32,64,128) | ? HAVE 32/64 | stdlib/hash.xi (fnv1a32, fnv1a64, fnv1_64). GAP: 128-bit |
| hash/murmur (2,3; 32,128) | ? HAVE 3-32 | hash.xi murmur3_32. GAP: murmur2, murmur3-128 |
| hash/city (64,128,256) | ? STDLIB | add to hash.xi (pure) |
| hash/xxhash (32,64,128,XXH3) | ? HAVE 32 | hash.xi xxhash32. GAP: xxhash64, 128, XXH3 |
| hash/siphash (2-4,1-3) | ? HAVE 2-4 | hash.xi sip_hash. GAP: 1-3 variant |
| hash/highway (64,128,256) | ? STDLIB | add (pure) |
| hash/spooky (128) | ? STDLIB | add |
| hash/t1ha | ? STDLIB | add |
| hash/metro (64,128) | ? STDLIB | add |
| hash/farm | ? STDLIB | add |
| hash/jenkins (lookup3) | ? STDLIB | add |
| hash/superfast | ? STDLIB | add |
| hash/crc (32,64 + HW accel) | ? HAVE 32 | hash.xi crc32_ieee + compress crc32. GAP: crc64 + asm |
| hash/adler | ? HAVE | compress.xi adler32 |
| hash/checksum (BSD,SysV,Internet) | ? STDLIB | add |

**Audit**: hash.xi = 23 fns, small. All hashes are pure ? all STDLIB. No folder needed; keep flat. Optimization: xxhash/city/highway SIMD later (Phase 4).

## 2. COLLECTIONS (58 entries)

| Entry | Decision | Where / Status |
|-------|----------|----------------|
| collect/list (singly/doubly) | ? HAVE LinkedList | collections.xi |
| collect/vector | ? HAVE Vec | collections.xi |
| collect/stack | ? HAVE | collections.xi (Vec-based) |
| collect/queue | ? HAVE | collections.xi (VecDeque) |
| collect/ring | ? HAVE | collections.xi (VecDeque/circular) |
| collect/map (open addressing) | ? HAVE Map | collections.xi |
| collect/mapch (chaining) | ? HAVE HashMap | collections.xi |
| collect/treemap | ? STDLIB | add (ordered map, AVL-based) |
| collect/treeset | ? STDLIB | add |
| collect/tree | ? STDLIB | add (binary tree) |
| collect/avl | ? STDLIB | add (AVL) |
| collect/rbtree | ? STDLIB | add (red-black) |
| collect/bheap | ? HAVE BinaryHeap | collections.xi |
| collect/fheap | ? STDLIB | add (Fibonacci) |
| collect/pairing | ? STDLIB | add (pairing heap) |
| collect/deque | ? HAVE VecDeque | collections.xi |
| collect/priority | ? HAVE | collections.xi (BinaryHeap) |
| collect/skiplist | ? STDLIB | add |
| collect/trie | ? STDLIB | add (prefix tree) |
| collect/radix | ? STDLIB | add (radix tree) |
| collect/bitmap | ? HAVE bits | bits.xi (BitArray planned) |
| collect/bloom | ? STDLIB | add (Bloom filter) |
| collect/cuckoo | ? STDLIB | add (cuckoo hash) |
| collect/hashset | ? HAVE Set | collections.xi |
| collect/linkedhash | ? STDLIB | add (insertion-order map) |
| collect/lru | ? STDLIB | add (LRU cache) |
| collect/lfu | ? STDLIB | add |
| collect/tinylfu | ? STDLIB | add |
| collect/arc | ? STDLIB | add |
| collect/btree | ? STDLIB | add (B-tree) |
| collect/btreeplus | ? STDLIB | add (B+tree) |
| collect/segment | ? STDLIB | add (segment tree) |
| collect/fenwick | ? STDLIB | add (Fenwick tree) |
| collect/sparse | ? STDLIB | add (sparse set) |
| collect/dense | ? STDLIB | add |
| collect/hasharray (HAMT) | ? STDLIB | add |
| collect/immutable | ? STDLIB | add |
| collect/persistent | ? STDLIB | add |
| collect/concurrent | ? STDLIB | add (on sync.xi) |
| collect/interval | ? STDLIB | add (interval tree) |
| collect/range | ? STDLIB | add (range tree) |
| collect/kdtree | ? STDLIB | add (KD-tree) |
| collect/octree | ? STDLIB | add |
| collect/quadtree | ? STDLIB | add |
| collect/spatial | ? STDLIB | add (spatial hash) |
| collect/graph | ? STDLIB | add (adjacency) |
| collect/dag | ? STDLIB | add |
| collect/unionfind | ? STDLIB | add (disjoint set) |
| collect/intmap | ? STDLIB | add (int-keyed map) |
| collect/stringmap | ? STDLIB | add |
| collect/objectpool | ? STDLIB | add |
| collect/threadpool | ? STDLIB | add (on thread.xi) |
| collect/workqueue | ? STDLIB | add |
| collect/blocking | ? STDLIB | add (on sync.xi) |
| collect/mpmc/mpsc/spmc/spsc | ? STDLIB | add (on sync.xi channels) |

**Audit**: collections.xi = 1,732 lines / 148 fns — **REFACTOR CANDIDATE**. Plan:
create `stdlib/xiom/collect/` folder with `tree.xi` (tree/avl/rbtree/btree),
`heap.xi` (fheap/pairing), `cache.xi` (lru/lfu/tinylfu/arc), `hash.xi`
(cuckoo/HAMT/linkedhash), `queue.xi` (blocking/mpmc/mpsc/spsc), `graph.xi`
(graph/dag/unionfind/kdtree/octree/quadtree/interval/range). Keep collections.xi
flat (frozen contract); new structs live in collect/ modules. ALL pure ? stdlib.

## 3. STRING OPERATIONS (74 entries)

| Entry | Decision | Where / Status |
|-------|----------|----------------|
| str/compare | ? HAVE | string.xi str_compare_lexicographic + cmp |
| str/search | ? HAVE | string.xi index_of/rindex_of/contains |
| str/replace | ? HAVE | string.xi replace/replace_all/first/n |
| str/trim | ? HAVE | string.xi trim/strip variants |
| str/split | ? HAVE | string.xi split/split_whitespace/lines/once |
| str/join | ? HAVE | string.xi join/join_with_and |
| str/case | ? HAVE | string.xi upper/lower/title/swap/snake/camel/kebab/pascal/constant |
| str/strip | ? HAVE | string.xi strip_prefix/suffix |
| str/repeat | ? HAVE | string.xi repeat |
| str/pad | ? HAVE | string.xi pad_left/right/center |
| str/slice | ? HAVE | string.xi slice + char-boundary helpers |
| str/escape | ? HAVE | string.xi escape/unescape + json/url via encoding/serialize |
| str/unescape | ? HAVE | string.xi |
| str/format | ? HAVE | fmt.xi format1-9 + string |
| str/printf | ? STDLIB | add (printf-style) |
| str/scanf | ? STDLIB | add (scanf-style parse) |
| str/template | ? STDLIB | add (placeholder substitution) |
| str/glob | ? HAVE | misc.xi glob_match |
| str/regex | ? HAVE | regex.xi |
| str/levenshtein | ? HAVE | misc.xi levenshtein_distance |
| str/damerau | ? STDLIB | add (Damerau-Levenshtein) |
| str/jaro | ? STDLIB | add (Jaro-Winkler) |
| str/soundex | ? HAVE | misc.xi soundex |
| str/metaphone | ? STDLIB | add (double metaphone) |
| str/ngram | ? STDLIB | add |
| str/ngram_similarity | ? STDLIB | add |
| str/cosine | ? STDLIB | add (cosine similarity) |
| str/jaccard | ? STDLIB | add |
| str/lcs | ? STDLIB | add (longest common subsequence) |
| str/lcp | ? STDLIB | add (longest common prefix) |
| str/lcsuffix | ? STDLIB | add |
| str/editdistance | ? STDLIB | add (general edit distance) |
| str/hamming | ? STDLIB | add |
| str/tr | ? STDLIB | add (translate chars) |
| str/rot | ? HAVE rot13 | string.xi. GAP: rot47 |
| str/caesar | ? HAVE | string.xi caesar_shift |
| str/atbash | ? STDLIB | add |
| str/shuffle | ? STDLIB | add (Fisher-Yates, on rand) |
| str/reverse | ? HAVE | string.xi str_reverse (Unicode-aware) |
| str/rotate | ? STDLIB | add |
| str/permute | ? STDLIB | add (permutations) |
| str/combine | ? STDLIB | add |
| str/interleave | ? STDLIB | add |
| str/chunk | ? STDLIB | add |
| str/wrap | ? HAVE | fmt.xi format_wrap |
| str/indent | ? HAVE | fmt.xi format_indent |
| str/align | ? HAVE | fmt.xi align_left/right/center |
| str/truncate | ? HAVE | string.xi truncate_utf8 + fmt |
| str/abbreviate | ? STDLIB | add |
| str/obfuscate | ? STDLIB | add |
| str/normalize (NFC/NFD/NFKC/NFKD) | ? STDLIB | add (pure Unicode tables — big but no deps) |
| str/collate | ? STDLIB | add (basic) |
| str/casefold | ? STDLIB | add |
| str/titlecase | ? HAVE | string.xi title_case |
| str/segment (grapheme) | ? STDLIB | add (UAX #29 tables) |
| str/wordbreak | ? STDLIB | add |
| str/sentencebreak | ? STDLIB | add |
| str/linebreak | ? STDLIB | add |
| str/ea_width | ? STDLIB | add |
| str/emoji | ? HAVE | char.xi is_emoji |
| str/script | ? STDLIB | add (script detection ranges) |
| str/block | ? STDLIB | add (Unicode block) |
| str/category | ? HAVE | char.xi is_* categories |
| str/bidi | ? STDLIB | add (basic bidi) |
| str/mirror | ? STDLIB | add (mirror chars) |
| str/compat | ? STDLIB | add |
| str/fold | ? STDLIB | add |
| str/lowercase/uppercase/titlecase_map | ? HAVE | char.xi + string.xi |
| str/nfkc/nfd/nfc/nfkd | ? STDLIB | add |

**Audit**: string.xi = 765 lines / 45 fns, char.xi = 340/42, fmt.xi = 468/28. All pure.
Grouping: create `stdlib/xiom/text/` folder for the NEW heavy Unicode modules:
`unicode.xi` (normalize/casefold/bidi/mirror), `sim.xi` (damerau/jaro/cosine/
jaccard/lcs/hamming), `transform.xi` (tr/rot47/atbash/shuffle/permute/chunk).
string.xi/char.xi stay flat (contract). Unicode normalization tables are
large-but-pure ? stdlib (with compressed table encoding later).

## 4. CONVERSION (81 entries)

| Entry | Decision | Where / Status |
|-------|----------|----------------|
| conv/int (base 2-36) | ? HAVE | num.xi to_base/from_base + convert |
| conv/float (hex, scientific) | ? STDLIB | add (scientific parse) |
| conv/toint (signed/unsigned) | ? HAVE | convert.xi + num.xi checked converters |
| conv/tofloat (32,64) | ? HAVE | convert.xi + num.xi |
| conv/tostring | ? HAVE | convert.xi + fmt.xi |
| conv/parse | ? HAVE | convert.xi + string.xi |
| conv/itos/itoa | ? HAVE | convert.xi int_to_string + num.xi to_base |
| conv/ftos | ? HAVE | convert.xi float_to_string |
| conv/atoi | ? HAVE | convert.xi |
| conv/fromstr | ? FUTURE | interface trait — impl ignored by compiler; declare only |
| conv/tryfrom | ? FUTURE | interface trait — declare only |
| conv/into | ? FUTURE | interface trait — declare only |
| conv/asref/asmut | ? FUTURE | interface trait — declare only |
| conv/from | ? FUTURE | interface trait — declare only |
| conv/bytes | ? HAVE | ffi.xi + mem.xi + encoding |
| conv/endian (big/little/native) | ? HAVE | num.xi + bits.xi byte_swap/pack |
| conv/network | ? STDLIB | add (network byte order helpers) |
| conv/swap | ? HAVE | bits.xi byte_swap16/32/64 |
| conv/saturating | ? HAVE | num.xi add_sat/sub_sat/mul_sat |
| conv/wrapping | ? STDLIB | add (wrapping add/sub/mul) |
| conv/overflow | ? HAVE | num.xi checked add/sub/mul/div |
| conv/checked | ? HAVE | num.xi *_checked family |
| conv/unchecked | ? STDLIB | add (documented unsafe) |
| conv/exact | ? STDLIB | add (fails if lossy) |
| conv/lossy | ? STDLIB | add |
| conv/roundtrip | ? STDLIB | add (to_str?from_str==value) |
| conv/cstring | ? HAVE | ffi.xi + os.xi cstr |
| conv/wstring | ? STDLIB | add (UTF-16) |
| conv/utf8 | ? HAVE | utf8.xi |
| conv/utf16 | ? STDLIB | add (utf8?utf16) |
| conv/utf32 | ? STDLIB | add |
| conv/base64 | ? HAVE | encoding.xi |
| conv/base32 | ? HAVE | encoding.xi |
| conv/base16 | ? HAVE | encoding.xi hex |
| conv/base58 | ? STDLIB | add (Bitcoin alphabet) |
| conv/base62 | ? STDLIB | add |
| conv/base64url | ? HAVE | encoding.xi |
| conv/ascii85 | ? STDLIB | add |
| conv/uuencode | ? STDLIB | add |
| conv/xxencode | ? STDLIB | add |
| conv/quotedprintable | ? STDLIB | add |
| conv/punycode | ? STDLIB | add (IDNA) |
| conv/idna | ? STDLIB | add |
| conv/percent | ? HAVE | encoding.xi percent_encode/decode |
| conv/html | ? STDLIB | add (HTML entity escape) |
| conv/xml | ? STDLIB | add |
| conv/json | ? HAVE | serialize.xi json_escape |
| conv/csv | ? STDLIB | add (CSV escape) |
| conv/tsv | ? STDLIB | add |
| conv/yaml | ? STDLIB | add |
| conv/toml | ? STDLIB | add |
| conv/regex | ? HAVE | regex.xi regex_escape_literal |
| conv/glob | ? STDLIB | add |
| conv/shell | ? STDLIB | add |
| conv/cmd | ? STDLIB | add |
| conv/printf | ? STDLIB | add |
| conv/strftime | ? HAVE | time.xi format_timestamp/iso8601 |
| conv/strptime | ? STDLIB | add (parse date/time strings) |
| conv/duration | ? HAVE | time.xi Duration |
| conv/date | ? HAVE | time.xi Date |
| conv/time | ? HAVE | time.xi |
| conv/datetime | ? STDLIB | add (Date+Time combined) |
| conv/timestamp | ? HAVE | time.xi |
| conv/uuid | ? HAVE | rand.xi uuid_v4/v7 |
| conv/mac | ? STDLIB | add |
| conv/ip | ? HAVE | net.xi is_valid_ipv4 + parsing |
| conv/url | ? HAVE | net.xi url_parse_scheme/host/path/port |
| conv/uri | ? STDLIB | add (full URI parse) |
| conv/urn | ? STDLIB | add |
| conv/iri | ? STDLIB | add |
| conv/email | ? STDLIB | add (validation) |
| conv/phone | ? STDLIB | add |
| conv/creditcard | ? STDLIB | add (Luhn) |
| conv/iban | ? STDLIB | add |
| conv/swift | ? STDLIB | add |

**Audit**: num.xi = 2,612 lines / 256 fns — **LARGEST FILE, REFACTOR FIRST**.
Plan: create `stdlib/xiom/num/` folder: `checked.xi` (checked/sat ops),
`convert.xi` (cross-type converters), `int128.xi` (Int128), `fraction.xi`,
`base.xi` (base conversions), `float.xi` (round/floor/ceil/fract). num.xi stays
as the flat aggregate (contract) and delegates. ALL pure ? stdlib.

## 5. NETWORK (298 entries)

Policy: **wire protocols implemented in pure XIOM over the socket FFI = STDLIB**.
Anything needing OpenSSL/ICU/libcurl/zlib-C/OS-specific heavy bindings = PACKAGE.
Cloud/vendor APIs (AWS/Azure/GCP/k8s) are HTTP clients ? PACKAGES built on stdlib http.

| Group | Decision | Where |
|-------|----------|-------|
| socket/address/tcp/udp/unix | ? HAVE | net.xi (socket, tcp, udp, dns, resolve_host) |
| dns (A/AAAA/CNAME/MX/TXT/SRV) | ? STDLIB | net.xi expand (record parsing) |
| ip (v4/v6), port, protocol | ? HAVE / ? | net.xi expand (IPv6, well-known ports) |
| url/uri/iri/query/form/multipart | ? STDLIB | net.xi expand (full URL/query/form parsing) |
| cookie/header/mime/charset/link/etag/cache/range | ? STDLIB | net.xi expand (HTTP header utils) |
| http/https/http2/http3 | ? HAVE http1 | net.xi http_get/post. http2/3 ? PACKAGE (h2 spec heavy; http3=QUIC ? PACKAGE) |
| sse/websocket | ? HAVE | net.xi + packages xiom-websocket. SSE ? stdlib |
| rest/graphql/jsonrpc/xmlrpc | ? HAVE pkg | xiom-rest, xiom-graphql pkgs. jsonrpc ? stdlib |
| grpc/grpcweb/thrift/avro-rpc/soap | ?? PACKAGE | xiom-grpc, xiom-protobuf pkgs (C deps) |
| zeromq/nanomsg/mqtt/amqp/stomp/kafka/pulsar/nats | ?? PACKAGE | xiom-zeromq, xiom-kafka exist. mqtt/amqp/nats/pulsar ? new pkgs (protocols are pure-ish but heavy ? PACKAGE per domain) |
| redis/memcached | ?? PACKAGE | xiom-redis exists. memcached ? package (pure RESP is easy — could be stdlib; DECISION: redis/memcached protocol parsers ? STDLIB net, drivers ? PACKAGE). Final: protocol ? stdlib; client drivers stay packages |
| elastic/mongo/postgres/mysql/sqlite/odbc | ?? PACKAGE | xiom-postgres, xiom-sqlite, xiom-sql exist; mongo/mysql/elastic/odbc ? new packages |
| tls/ssl/ssh/sftp/scp/x509/pem/jwt/oauth | ?? PACKAGE | xiom-openssl, xiom-libsodium exist. jwt/oauth ? packages (crypto + protocol) |
| ldap/kerberos/ntlm/digest/basic/bearer/apikey/hawk | ?? PACKAGE | auth protocols ? packages (ldap/kerberos C deps; digest/basic/bearer pure ? stdlib net) |
| proxy/socks/tor/i2p | ?? PACKAGE | proxy ? stdlib (pure). socks/tor/i2p ? packages |
| icmp/ping/traceroute/arp/ndp | ? STDLIB | net.xi expand (raw socket via FFI — OS-specific; keep minimal, ping = stdlib, traceroute = stdlib) |
| dhcp/bootp/tftp/nfs/smb/netbios | ?? PACKAGE | legacy protocols ? packages |
| ntp/sntp | ? STDLIB | net.xi expand (UDP NTP client — pure) |
| wireguard/ipsec/ike/ppp/vpn family | ?? PACKAGE | security protocols ? packages |
| kubernetes/docker/nomad/cloud APIs (AWS/Azure/GCP/OCI/IBM/DO/etc) | ?? PACKAGE | cloud packages (built on stdlib http + auth) |
| CDN/vendor APIs (cloudflare/akamai/fastly/vercel/netlify) | ?? PACKAGE | vendor packages |
| webrtc/rtp/rtsp/rtmp/hls/dash | ?? PACKAGE | media streaming ? packages |
| mDNS/bonjour/upnp/ssdp/ws-discovery/slp | ?? PACKAGE | discovery ? packages (multicast; pure but niche) |
| xmpp/matrix/sip/irc/nntp | ?? PACKAGE | messaging ? packages |
| gnss/gps/adsb/acars/aviation | ?? PACKAGE | aviation/telemetry ? packages |
| vlan/vxlan/geneve/mpls/tunnel family | ?? PACKAGE | network infra ? packages |
| libpcap/netlink/wireless (iw/wpa) | ?? PACKAGE | packet/network tools ? packages |

**Audit**: net.xi = 735 lines / 29 fns. **REFACTOR**: create `stdlib/xiom/net/`
folder: `http.xi` (headers/cookies/mime/charset/etag/sse), `url.xi` (url/uri/
query/form/multipart), `dns.xi` (record parsing), `proto.xi` (ntp/icmp/jsonrpc/
digest/basic). net.xi stays flat (contract) + delegates. New protocol clients
that need C libs ? packages with READMEs.

## 6. FILE FORMATS (1,169 entries — the biggest section)

Policy: **pure text/data formatting = STDLIB**; **rendering-heavy, file-format
binary, chart/diagram, GIS, metadata-tag, statistical-model = PACKAGE**.

| Group | Decision | Where |
|-------|----------|-------|
| hex/octal/binary dump, bytes human | ? HAVE | fmt.xi format_hexdump + serialize |
| table (ascii/markdown/csv/tsv/unicode) | ? HAVE | fmt.xi format_table (ascii). markdown/csv/tsv tables ? stdlib add |
| json/xml/yaml/toml/csv/tsv format | ? HAVE / ? | serialize.xi (json). xml/yaml/toml/csv ? **PACKAGE** (parsers, domain) — stdlib keeps escape helpers only |
| markdown/html/textile/rtf/latex/troff/roff/man | ?? PACKAGE | text markup ? packages |
| text layout (justify/hyphenate/wrap/indent/align/margin) | ? HAVE wrap/indent | fmt.xi expand (justify, hyphenation) |
| ANSI/colors/emoji/unicode/box/border/separator | ? STDLIB | fmt.xi expand (ANSI escape codes, box drawing) |
| font/typeface/glyph/kerning/ligature | ?? PACKAGE | typography ? package |
| bidi/rtl/ltr/arabic/hebrew/indic/cjk | ? STDLIB basic | text/unicode.xi (basic); full shaping ? PACKAGE |
| numbering (roman/chinese/japanese/etc) | ? STDLIB | num.xi expand (roman numerals etc) |
| number format (percent/permille/ppm/ppb/ratio/fraction/scientific/engineering) | ? STDLIB | num.xi + fmt.xi expand |
| SI/metric/binary/decimal/imperial/US units | ? STDLIB | fmt.xi expand (unit formatting) |
| duration/date/time/relative/age/clock/stopwatch/countdown/calendar | ? HAVE time | time.xi expand (relative time, clock) |
| charts (bar/line/pie/scatter/histogram/box/violin/heatmap/treemap/sunburst/sankey/network) | ?? PACKAGE | xiom-charts package (rendering) |
| diagrams (uml/mermaid/plantuml/graphviz/dot/bpmn/sysml) | ?? PACKAGE | xiom-diagrams package (text generators) |
| GIS/geo (geojson/kml/gpx/shapefile/wkt/wkb/geohash/mgrs/utm/latlong/projections) | ?? PACKAGE | xiom-geo package |
| metadata tags (exif/id3/vorbis/ape/mp4/mkv/avi/flac/ogg) | ?? PACKAGE | xiom-metadata package |
| chiptune/audio format metadata (midi/smf/mod/xm/s3m/it/nsf/etc ~150 entries) | ?? PACKAGE | xiom-audio-meta package (niche, one README lists all) |
| financial formatting (currency/accounting/amortization/roi/eps/ledger/invoice/etc) | ?? PACKAGE | xiom-finance package |
| statistical metrics/plots (mse/rmse/auc/roc/confusion/qq/boxcox/etc) | ?? PACKAGE | xiom-stats-ml package (on stdlib stats) |
| statistical tests (t/f/chi2/ks/wilcoxon/mann-whitney/fisher/etc ~150 entries) | ?? PACKAGE | xiom-stats-tests package (on stdlib stats) |
| regression models (linear/logistic/poisson/ridge/lasso/cox/mixed/etc) | ?? PACKAGE | xiom-ml package |
| MCMC/Bayesian (gibbs/metropolis/hmc/nuts/kalman/particle filters) | ?? PACKAGE | xiom-ml package |
| time series (ar/var/vecm/cointegration/adf/kpss) | ?? PACKAGE | xiom-timeseries package |
| 3D geometry (polyhedra/curves/surfaces/meshes/subdivision) | ? STDLIB core / ?? advanced | geom.xi expand (polyhedra, bezier, splines — pure math = stdlib); mesh/subdivision ? xiom-geom3d package |
| map projections (mercator/robinson/mollweide/etc ~100 entries) | ?? PACKAGE | xiom-geo package |
| address/geocoding (place/street/city/postal/poi) | ?? PACKAGE | xiom-geo package |
| raster formats (tiff/jpeg2000/geotiff/mrsid/ecw) | ?? PACKAGE | xiom-imaging package |

**Audit**: fmt.xi = 468 lines / 28 fns, serialize.xi = 926/41. **REFACTOR**:
create `stdlib/xiom/format/` folder: `number.xi` (percent/ratio/scientific/units/
numerals), `text.xi` (justify/hyphenate/box/ansi), `dump.xi` (hex/octal/binary
dump). fmt.xi stays flat + delegates. The rest ? packages with READMEs.

## 7. OS INTERACTION (692 entries)

Policy: **OS syscalls via minimal FFI = STDLIB** (that's the stdlib's job —
no deps, direct FFI allowed). **Library bindings (libcurl/libgit2/openssl/
libpcap/etc) = PACKAGE**. **Platform framework bindings (Apple/Windows APIs) =
PACKAGE**. **Tool-like wrappers (objdump/readelf/nm/strings) = PACKAGE**.

| Group | Decision | Where |
|-------|----------|-------|
| pipe/fd/dup/select/poll/epoll/kqueue | ? STDLIB | os.xi expand (FFI) |
| event/ioctl/mmap/madvise/mlock | ? STDLIB | os.xi expand |
| stat/perm/owner/link/rename/remove/symlink/readlink/realpath | ? HAVE most | os.xi (link/symlink/readlink exist; perm/owner ? add) |
| temp/cwd/chdir/mkdir/rmdir/walk | ? HAVE | os.xi |
| glob/find/locate/which/where | ? STDLIB | os.xi expand (glob exists in misc; which ? FFI) |
| type/magic/mime/encoding/eol/bom detection | ? STDLIB | os.xi expand (pure sniffing) |
| size/truncate/fallocate/seek/tell/read/write/read_at/write_at/pread/pwrite | ? HAVE core | io.xi expand (pread/pwrite/truncate) |
| readv/writev/sendfile/splice/tee/vmsplice | ? STDLIB | os.xi expand (FFI, zero-copy) |
| io_uring/aio/iocp/overlapped/eventfd/timerfd/signalfd | ? STDLIB | os.xi expand (FFI; per-OS) |
| fork/exec*/posix_spawn/spawn/system/popen/wait* | ? HAVE spawn | os.xi + process.xi expand (exec variants) |
| pipe2/fifo/mknod/mkfifo/dev files | ? STDLIB | os.xi expand |
| stdin/stdout/stderr/tty/pty/console/terminal/termios | ? STDLIB | os.xi expand (termios FFI) |
| raw/cbreak/nonblock/blocking/timeout/echo/canonical | ? STDLIB | os.xi expand |
| buffer/line/full/no buffering + flush | ? STDLIB | io.xi expand |
| sync/fsync/fdatasync/syncfs/msync | ? STDLIB | os.xi expand |
| mem*/str* (memcpy/memset/memcmp/strcpy/strtok/strerror) | ? HAVE mem | mem.xi + ffi.xi (SIMD asm). str* ? string.xi |
| errno/perror/strsignal/psignal | ? STDLIB | os.xi expand (FFI) |
| backtrace/demangle/addr2line | ? STDLIB | debug.xi expand (FFI backtrace) |
| dlopen/dlclose/dlsym/dlerror/dladdr | ? STDLIB | ffi.xi expand (dynamic loading) |
| libc/libm/librt/libdl/libpthread access | ? STDLIB | ffi.xi expand (expose common C fns) |
| libcrypto/libssl/libz/libbz2/liblzma/libzstd/liblz4/libsnappy/libcurl/libgit2/libssh2 | ?? PACKAGE | binding packages (openssl/zstd/lz4 exist; curl/git2/ssh2 ? new pkgs) |
| libxml2/libxslt/libexpat/libyaml/libjson/libjansson | ?? PACKAGE | binding packages |
| libpcap/libnet/netlink/nf* family | ?? PACKAGE | packet-capture package |
| wireless (iw/iwconfig/wpa/hostapd + drivers) | ?? PACKAGE | wireless package |
| graphics drivers (drm/gbm/egl/gl/gles/vulkan/dx/d3d) | ?? PACKAGE | exist (vulkan/opengl/directx pkgs); drm/egl ? new |
| Apple frameworks (metal/arkit/vision/coreml/storekit/etc ~90 entries) | ?? PACKAGE | xiom-apple package (macOS/iOS bindings) |
| Windows registry/assembly/authenticode/pki tools | ?? PACKAGE | xiom-windows package |
| certificates (x509/pkcs*/cms/smime/pgp/ssh-certs ~180 entries) | ?? PACKAGE | xiom-pki package (on openssl) |
| logging (syslog/journald/eventlog/rsyslog/logrotate/agents ~90 entries) | ? STDLIB core | log.xi (levels/format exist). Full syslog/journald clients ? PACKAGE xiom-logging |

**Audit**: os.xi = 696/61, io.xi = 907/53, ffi.xi = 32 fns. **REFACTOR**: create
`stdlib/xiom/os/` folder: `fs.xi` (stat/perm/owner/link/glob/find/magic),
`ioctl.xi`, `proc.xi` (fork/exec/wait), `term.xi` (tty/termios/raw),
`mmap.xi`, `sync_io.xi` (fsync/mlock). os.xi stays flat + delegates.
io.xi ? split into `io/fs.xi` (file ops) + io.xi console. ffi.xi ? add
`ffi/dl.xi` (dlopen). Core syscall surface = stdlib; lib bindings = packages.

## 8. RANDOM (section header present, entries cut off)

Expected per original proposal: mt/pcg/xorshift/chacha/dist/seed/source.
Current: rand.xi has StdRng (LCG), Xorshift64, distributions (uniform/normal/
exponential), uuid_v4/v7, random_choice/shuffle, secure_random_bytes.
GAP: MT19937, PCG, ChaCha-based RNG ? **STDLIB** (rand.xi expand, pure).
All pure ? stdlib.

## 9. PACKAGE README ASSIGNMENTS (which list entries ? which package README)

For each package folder, README.md must list its libs (inventory only):

| Package | Libs from the list |
|---------|--------------------|
| xiom-json / xiom-protobuf / xiom-grpc / xiom-arrow / xiom-websocket / xiom-graphql / xiom-rest / xiom-http | exist; extend per NETWORK/format sections |
| xiom-openssl / xiom-libsodium | tls, ssl, x509, pem, cert family, pkcs*, cms, smime |
| xiom-sqlite / xiom-postgres / xiom-sql | sql drivers; mysql, mongo, elastic, odbc ? NEW pkgs |
| xiom-redis | memcached ? NEW pkg |
| xiom-kafka / xiom-zeromq / xiom-mqtt(NEW) / xiom-amqp(NEW) / xiom-nats(NEW) / xiom-pulsar(NEW) | messaging protocols |
| xiom-charts (NEW) | all chart entries (bar..sunburst, statistical plots) |
| xiom-diagrams (NEW) | mermaid, plantuml, graphviz/dot, uml, bpmn, sysml |
| xiom-geo (NEW) | geojson, kml, gpx, shapefile, geohash, mgrs, utm, projections (~150 entries) |
| xiom-metadata (NEW) | exif, id3, vorbis, ape, mp4/mkv/avi tags |
| xiom-audio-meta (NEW) | chiptune formats (midi, mod, xm, s3m, it, nsf, ~150 entries) |
| xiom-finance (NEW) | currency, accounting, amortization, roi, ledger, invoice |
| xiom-stats-tests (NEW) | statistical tests (~150 entries) |
| xiom-stats-ml (NEW) | metrics/plots (mse..silhouette) |
| xiom-ml (NEW) | regression models, MCMC/Bayesian, kalman |
| xiom-timeseries (NEW) | ar, var, vecm, cointegration, adf, kpss |
| xiom-geom3d (NEW) | mesh, subdivision, nurbs advanced |
| xiom-imaging (NEW) | tiff, jpeg2000, geotiff, mrsid, ecw |
| xiom-pki (NEW) | cert/pki tooling (~180 entries) |
| xiom-logging (NEW) | syslog, journald, eventlog, logrotate, log agents |
| xiom-apple (NEW) | Apple frameworks (~90 entries) |
| xiom-windows (NEW) | registry, authenticode, assembly, pki tools |
| xiom-packet (NEW) | libpcap, netlink, nf* |
| xiom-wireless (NEW) | iw, wpa, hostapd, driver bindings |
| xiom-cloud (NEW umbrella) | aws, azure, gcp, k8s, docker, nomad + vendor APIs (~150 entries) |
| xiom-messaging (NEW umbrella) | xmpp, matrix, sip, irc, nntp |
| xiom-streaming (NEW) | webrtc, rtp, rtsp, rtmp, hls, dash |
| xiom-discovery (NEW) | mdns, bonjour, upnp, ssdp, ws-discovery, slp |
| xiom-legacy-proto (NEW) | dhcp, bootp, tftp, nfs, smb, netbios, socks, tor, i2p |
| xiom-c-binding (NEW umbrella) | libcurl, libgit2, libssh2, libxml2, libexpat, libyaml, libjansson |
| xiom-text-markup (NEW) | markdown, html, textile, rtf, latex, troff |
| xiom-typography (NEW) | font, glyph, kerning, ligature, shaping |
| xiom-aviation (NEW) | gnss, adsb, acars, vdl, aviation protocols |

(NEW = create folder + README; existing packages get their READMEs updated.)

## 10. EXECUTION ORDER (backlog)

1. **Refactor first** (folder grouping — verified safe): num/, collect/, str?text/,
   net/, os/, format/, io/fs, ffi/dl. Keep flat contract files as aggregates.
2. **Fill stdlib gaps** (all ? STDLIB entries above) — pure implementations,
   per-module agents, test-vector verified.
3. **Update package READMEs** with the inventory lists from §9.
4. **Create NEW package folders + READMEs** for all (NEW) packages.
5. **Phase 4 optimizations** on hot stdlib paths (hash SIMD, bigint asm,
   deflate, GCM GHASH, string ops).
6. **Verify**: freeze gate + full suite after each step.

## 11. DECISIONS LOGGED

- Folder modules VERIFIED working (`use xiom.foo.bar` ? stdlib/xiom/foo/bar.xi,
  exit 42 test). Contract modules stay flat; new code goes in folders.
- Files >1,000 lines get refactored: num (2,612), crypto (2,538), geom (1,883),
  collections (1,732), core (1,055). Split into folder modules; flat file
  becomes aggregate re-export (frozen contract intact).
- Hash/string/char/fmt/convert/rand = pure ? STDLIB, keep flat or light folder.
- Network: wire protocols (pure) = STDLIB; drivers/C-bound = PACKAGES.
- File formats: text/number formatting = STDLIB; charts/diagrams/GIS/metadata/
  stats-tests/ML/finance = PACKAGES.
- OS: syscalls (FFI) = STDLIB; lib bindings/frameworks/tools = PACKAGES.
- Interfaces (FromStr/TryFrom/Into/AsRef) = declare-only until compiler
  implements impl dispatch (backlog item: compiler hardening).

## 12. GENERICS/INTERFACES vs NUMERIC TOWER — STATUS (READ BEFORE WRITING MATH CODE)

**TL;DR: generic operators and interface `impl` dispatch are NOT usable for
mixed int/float arithmetic yet.** The stdlib numeric tower is deliberately
CONCRETE per-width. Do NOT write `fn foo[T: Bounded + Add](a: T, b: T) -> T`
that does `a + b` and expect it to work for Float64 — it corrupts the value
(compiler bug). Write `fn foo_i64(...) / foo_f64(...) / foo_f32(...)` instead.

### Why (compiler state, 2026-08-07)
1. **Generic operator monomorphization corrupts Float64.** `add2[T](a+b)` with
   `T = Float64` produces garbage in the monomorphized body. Verified by the
   Tier-3 agent work; the numeric tower (num.xi) works around it with concrete
   per-width functions (i64/u32/i16/i8/u64/u32/u16/u8 + f64/f32 variants:
   `i64_add_checked`, `f64_round`, `u32_mul_sat`, `i128_*`, `fraction_*` …).
2. **Interface `impl` blocks are parsed but IGNORED by checker+codegen.**
   Traits are declare-only: `pub interface Num[T] { … }` compiles, but
   `impl Num[Int] { … }` does not dispatch. So trait-based math (`Num[T]` with
   per-type impls) cannot drive generic math functions.
3. **`[T: Ord]` generics work ONLY for algorithms using `.compare` / `.eq`**
   (builtin inline scalar dispatch), e.g. sort/search/cmp/min/max. They do NOT
   work for arithmetic operators.

### Rules for stdlib code
- **Math/numeric functions: concrete per-width signatures** (`i64_*`, `u64_*`,
  `f64_*`, `f32_*`, `i128_*`, `Fraction` …). One fn per width; callers pick.
- `[T: Ord]` generics allowed for comparison-based algorithms only.
- Do NOT add new trait-based numeric abstractions expecting dispatch — they
  will silently not work. Document as declare-only.
- Packages built on stdlib inherit the same rule until the compiler hardens.

### Unblocking (compiler hardening backlog, from SESSION.md)
- (a) interface `impl` dispatch on generic params (`x.add(x)` fails — parser
  handles ImplDecl; checker+codegen ignore it).
- (b) generic operator monomorphization corrupting Float64
  (`add2[T](a+b)` garbage for floats).
- When (a)+(b) land, the numeric tower can be COLLAPSED into generic trait
  impls (`impl Num[Int]`, `impl Num[Float64]` …) with the concrete fns kept as
  thin re-export shims for the frozen API. Revisit §4 numeric tower then.
- The freeze gate locks the concrete signatures NOW, so the collapse is safe:
  concrete fns remain available even after generics land.

## 13. ARCHITECTURE DECISIONS (2026-08-08 — user confirmed)

Four decisions logged by the owner. These shape ALL future stdlib/compiler work.

### D1 — Native integer widths: Int128/UInt128 native; 256 via bigint
- **APPROVED: add native `Int128` / `UInt128` as LLVM `i128` primitives** (parser +
  checker + codegen). Add/sub/mul are native hardware ops; div/rem lower to
  `__divti3`/`__udivti3` libcalls that clang links automatically.
- **REJECTED: native Int256/UInt256** — LLVM emulates them slowly; `bigint.xi`
  (stdlib, 64-bit limbs) is the right home for >128-bit arithmetic.
- Rationale: 64×64?128 wide multiply unlocks pure-XIOM secp256k1/Ed25519 field
  math (currently delegating to runtime C), faster bigint schoolbook multiply,
  PRNG state combining, hash combining. NOTE: SHA-256/512 do NOT need 128-bit
  (they are 32/64-bit ops) — the win is wide multiply, not hashing per se.
- The frozen struct-based `Int128` API (num.xi `i128_*`) stays as a shim;
  native i128 is purely additive. Optional add: `Float128` (`fp128`) — same
  one-session cost, libcalls via compiler-rt.

### D2 — Raw pointers must be gated behind `unsafe`
- **APPROVED: the language must be SAFE. Raw-pointer operations (deref `*p`,
  `Int?Ptr` casts, `Vec/Slice?Ptr` casts, `asm`) require an `unsafe { }`
  context.** Currently the checker has NO gating (verified: `*p` compiles and
  runs outside unsafe) — `unsafe` is only AUDITED (sandbox.rs scoring,
  `--strict` warning). 
- Implementation: checker unsafe-context depth counter; reject pointer deref /
  ptr casts / asm when depth == 0. `unsafe` blocks increment/decrement.
  Sandbox audit stays as the second layer (scoring + `#[safety_audit]`).
- Do this BEFORE going public — the clean-break window is now.
- Note: stdlib itself uses raw pointers extensively (Vec data pointers, ffi,
  alloc) — those internals get wrapped in `unsafe` blocks; the PUBLIC API stays
  safe (SafePtr, Vec, Cursor, …). This is a compiler+stdlib co-change; the
  freeze gate (signatures) is unaffected because signatures don't change.

### D3 — BigFloat = separate stdlib module (NOT inside bigint.xi)
- **APPROVED: `BigFloat` (arbitrary-precision float) is its own stdlib module**
  (e.g. `num/bigfloat.xi` or `bigfloat.xi`), built on `bigint.xi` +
  `Fraction`-style internals: sign/exponent/significand, add/sub/mul/div,
  rounding modes, parse/format. Separate from bigint (bigint = integers only).
- MPFR-style transcendentals are a later phase; a C MPFR binding would be a
  PACKAGE (stdlib = zero deps).

### D4 — Categorize EVERY lib from the start (scale-without-breaking rule)
- **APPROVED: every stdlib module belongs to a category folder, even if the
  category has exactly ONE lib.** `use xiom.foo.bar` ? `stdlib/xiom/foo/bar.xi`
  (catalog strategy a, VERIFIED working).
- Rationale (owner): categories let the stdlib scale by EXPANDING INSIDE a
  category (math/core ? math/algebra ? math/vectors ? math/differential …)
  without ever breaking user code. When a lib is added it lands in its
  category; users who `use xiom.math.core` never see churn. Pre-public, the
  ONLY cost to move a lib is replacing the `use` line in tests — no call-site
  changes, no signature changes.
- RULE: **new code goes into category folders ONLY** — flat files (frozen
  contract) are never extended with new libs; they stay as aggregates.
  Categories are created eagerly (even for one lib) so the tree shows the
  final shape.
- Existing flat files stay byte-identical (freeze gate scans them). Migration
  of EXISTING fns into categories happens only as an intentional,
  freeze-gate-compatible refactor (flat file keeps signature + delegates, or
  snapshot updated with reviewed migration) — NOT part of normal growth.

### D4b — `use math;` imports ALL sub-libs — VERIFIED WORKING (2026-08-08)
- **The aggregate-`use` pattern is PROVEN end-to-end with the current
  compiler — NO compiler change required.** The flat aggregate file (e.g.
  `math.xi`) lists its sub-modules as `use` statements:
  ```xiom
  // stdlib/xiom/math.xi (aggregate)
  module xiom.math
  use xiom.math.core;
  use xiom.math.algebra;
  use xiom.math.vectors;
  ```
  Then a user program that writes `use xiom.math;` gets ALL sub-modules
  registered transitively and can call:
  ```xiom
  use xiom.math;
  var a = math.core.sqrt(x);      // qualified by sub-lib — deterministic
  var b = xiom.math.core.sqrt(y); // full dotted path also resolves
  ```
- **Verified by live probe tests (exit 0):**
  1. `use xiom._probe;` + `_probe.core.core_add(20,22)` == 42 ? (parent imports
     sub-module ? sub-lib callable through parent).
  2. Collision case: `core.core_add` vs `algebra.core_add` (same fn name in
     two sub-libs) — BOTH resolve correctly through their qualifier ?.
  3. Full dotted path `xiom._probe3.core.core_add(1,2)` resolves ?.
  4. Sub-lib named `core` does NOT collide with the flat `core.xi` —
     `_probe4.core.contains` resolves to the sub-lib's fn ? (leaf-qualified
     resolution walks the receiver chain first).
- **KEY MECHANISM**: the parent aggregate MUST contain the `use` lines — the
  checker only loads modules that are `use`d; `use math;` alone does NOT
  auto-discover `stdlib/xiom/math/*.xi`. So the flat aggregate is an EXPLICIT
  MANIFEST of its category: add a sub-lib = add one `use` line. Deterministic,
  no magic, no compiler change.
- **Naming decision (owner, 2026-08-08): use `core` not `basic` for the
  foundational sub-lib** — `math.core`, `math.algebra`, `math.primitives`,
  `math.vectors` … `math.basic` rejected (sounds too basic). `core` is
  reserved as the category's foundational module name; the flat aggregate file
  keeps the category name (`math.xi`) and is the "use manifest".
- **SUPERSEDED (2026-08-11): `math.core` renamed to `math.tower`** — the
  prelude module `xiom.core` owns the name `core`; category foundational
  sublibs must use domain names (tower/base/primitives), never `core`
  (STDLIB_GENERICS.md rule R9). The verified-qualification mechanism is
  unchanged; `math.tower.sqrt` is the deterministic form.
- Qualified call style `math.core.sqrt(a)` is DETERMINISTIC and unambiguous
  (proven: same fn name in two sub-libs disambiguates). Bare `sqrt(a)` after
  `use math;` is NOT guaranteed (keep-first alias across modules) — stdlib
  docs should recommend qualified calls for multi-lib imports.
- Target category map (flat files remain; folders host new libs):

| Category folder | Flat aggregate (frozen, = use-manifest) | New/planned folder libs |
|-----------------|----------------------------------------|--------------------------|
| `num/` | num.xi, convert.xi | core, convert, int128 (native D1), fraction, base, float, bigfloat (D3) |
| `math/` | math.xi | core, algebra, primitives, vectors, matrices, trig, transcendental, differential, integral, series, special |
| `collect/` | collections.xi | core, tree, heap, cache, hash, queue, graph, list, map, set, trie, bloom, unionfind, kdtree (done: tree/heap/cache/hash/queue/graph) |
| `crypto/` | crypto.xi | hash, mac, kdf, cipher, aead, sign, keyx, curves, rng-crypto |
| `hash/` | hash.xi | city, xxhash, murmur, jenkins, crc, highway, spooky, metro, t1ha, farm, superfast, checksum (done: city/xxhash/murmur/jenkins/crc) |
| `text/` | string.xi, char.xi, utf8.xi | similarity (done), unicode, normalize, bidi, case, search, diff, transliterate |
| `fmt/` | fmt.xi | number, text, dump, table, units, ansi, markup (done: format/number, format/dump) |
| `net/` | net.xi | url, dns, proto, http, ip, socket, tls-helper (done: url/dns/proto) |
| `os/` | os.xi, env.xi, path.xi, process.xi, platform.xi | fs, proc, term, mmap, ioctl, sync_io, win, unix (done: fs/proc/term) |
| `io/` | io.xi | fs, buffer, console, pipe |
| `ffi/` | ffi.xi | dl, c, errno |
| `rand/` | rand.xi | mt19937, pcg, chacha, splitmix, xoroshiro (done: mt19937/pcg/chacha) |
| `sync/` | sync.xi | mutex, condvar, barrier, channel, atomics, rwlock |
| `thread/` | thread.xi | pool, spawn, park, local |
| `async/` | async.xi | executor, channel, timer, io |
| `time/` | time.xi | duration, instant, date, iso8601, chrono, calendar |
| `serialize/` | serialize.xi | json, varint, endian, yaml-lite |
| `encoding/` | encoding.xi | base64, hex, base32, percent, ascii85, punycode, idna |
| `compress/` | compress.xi | deflate, lz77, huffman, gzip, zlib, brotli, lz4, snappy |
| `geom/` | geom.xi | vec, mat, quat, collision, curves, polyhedra |
| `stats/` | stats.xi | dist, test, regress, histogram, moments |
| `bits/` | bits.xi | bitarray, bitfield, popcount |
| `sort/` | sort.xi | quick, merge, heap, radix, intro |
| `search/` | search.xi | linear, binary, interpolation, kmp, boyer |
| `iter/` | iter.xi | range, map, filter, zip, chain, fold |
| `regex/` | regex.xi | engine, syntax, pcre-lite |
| `ref`/`core` | core.xi, cell.xi, rc.xi, mem.xi, ptr.xi, alloc.xi | (memory family stays flat for now; category folder `mem/` if it grows) |
| `test/` | test.xi, bench.xi | assert, bench, harness |
| `log/` | log.xi | levels, sinks, json, color |
| `debug/` | debug.xi | trace, disasm, heap-report |
| `misc/` | misc.xi | glob, levenshtein, semver, soundex, natural |
| `error/` | error.xi | chain, context, backtrace |
| `contracts/` | contracts.xi | (stays flat — compiler-backed) |
| `reflect/` | reflect.xi | typeinfo, fields |
| `simd/` | simd.xi | vec4, vec8, mask, gather |
| `array/` | array.xi | fixed, dynamic |
| `string/`?`text/` | string.xi (kept flat, alias) | see text/ |

### Execution order (updated 2026-08-08 — owner directive: PRODUCTION-GRADE FIRST, no workarounds)
Owner decision: the compiler must be REAL before the huge stdlib is written.
Do NOT write 5,000 functions against a known-broken compiler and rewrite them
later. Hardening comes FIRST; stdlib expansion (categories + manifest) starts
only after the numeric/generic foundation is production-grade. The freeze gate
+ D4b manifest pattern make this safe: concrete signatures stay callable
forever, so nothing written later breaks anything written now.

1. **Unsafe gating (D2)** — checker unsafe-context depth counter; reject raw
   pointer deref / Int?Ptr casts / Vec?Ptr casts / asm at depth 0; wrap stdlib
   internals in `unsafe` blocks (public API stays safe). Suite must stay green
   (freeze unaffected — signatures unchanged).
2. **Native Int128/UInt128 (D1)** — parser/checker/codegen; `i128` LLVM;
   div/rem via `__divti3`/`__udivti3` (clang-linked). Optional Float128.
3. **COMPILER HARDENING — production-grade generics/interfaces (PLAN B,
   NO workarounds):**
   a. interface `impl` dispatch on generic params (checker+codegen honor
      ImplDecl: `impl Num[Int] { ... }` must register and dispatch).
      ? DONE (2026-08-08, commit b34ebaa4): `impl Trait[Args]` registers;
      `Trait[Arg].method()` static dispatch resolves to the impl's
      `Type.method` freestanding fn (expand_impl_blocks type-name fix +
      codegen impl-receiver resolution). Verified: `Num[Int].add`,
      `Num[Float64].add`, multi-type impls, direct `Int.add`.
   b. generic-operator monomorphization must NOT corrupt Float64
      (`add2[T](a+b)` correct for ALL widths incl. Float64/Float32).
      ? DONE: explicit type args `fn[T](args)` were DISCARDED by the parser
      (? wrong monomorphisation); now preserved through GenericCall and used
      for concrete-type mapping. Generic return-type substitution (was
      emitted as i64 ? garbage) fixed for scalar results. Verified:
      `add2[Int]/[Float64]/[Float32]` all correct.
   c. After (a)+(b): the generic numeric tower lands — `impl Num[Int]`,
      `impl Num[Int32]`, `impl Num[Float32]`, `impl Num[Float64]` … and ONE
      generic `sqrt[T: Num](x: T) -> T` serves all widths. Concrete fns stay
      as thin shims (freeze-gated).
      ? CORE DONE (2026-08-10, commit pending): `math/core.xi` folder module
      (D4 category) hosts the generic tower — `pub interface Num[T]` with
      `impl Num[Int/Int32/Int64/UInt64/Float64/Float32]` and ONE generic
      implementation per concept (`lerp`, `average`, `sum`, `product`,
      `negate`, `twice`) serving every width. Enabled by:
      - catalog `parse_file` expands impl blocks at parse time,
      - `collect_external_decls` injects catalog-loaded interfaces + impls
        (module-qualified keys `core.Float64.add`),
      - driver Stage 4.5 injects `TopDecl::Interface`,
      - codegen dispatches `Num[T].add` via `current_type_map` (T?concrete)
        with module-qualified impl-key search; C001 bound check accepts
        module-qualified/lazily-registered impl methods.
      Verified: smoke_math_core (lerp/average/sum/product/negate/twice over
      5 widths), smoke_generic_tower, missing-impl ? clean C001.
      ? COMPLETED (2026-08-10, commits f1cb3fef + cd48a8df):
      - `Real` interface (lt/gt/le/ge/is_negative) ? generic abs/clamp/min2/max2
      - `FromInt` interface (from_int/to_float) ? generic of_int
      - catalog impl-method injection: dedup on type-qualified names,
        interface collection in register_external_module, generic-bound
        reachability seeding (all interface methods survive the dead-code
        filter so C001 bound checks pass)
      - REMAINING (later): generic sqrt needs a Transcendental interface;
        stdlib adoption of the generic forms (math.xi stays frozen concrete).
   d. Full test pass on every step; no `#[ignore]`d shortcuts.
      ? checker 166, exec 67 (incl. hardening smoke), e2e 2231, all suites.
   e. ADDITIONAL fixes landed during hardening:
      - Str::from_utf8(Vec[UInt8]) NUL-termination (runtime
        `xiom_str_from_vec`) — was returning raw non-terminated Vec data ?
        intermittent garbage suffixes (ROOT CAUSE of the net_folder harness
        flake, ~1-in-5 processes; now 8/8 stable from Rust-spawn).
      - url_encode single-pass rewrite (two-pass count/write disagreement
        could leave uninitialized malloc bytes).
      - Test harness: compile retry + flush delay for the parallel-session
        binary race.
4. **Stdlib category expansion (D4) starts AFTER hardening** — agents write
   math/core, math/algebra, math/vectors, … as GENERIC libs over the real
   tower; flat aggregates become use-manifests (D4b). No per-width
   duplicated libs — one generic implementation per concept.
5. **BigFloat (D3)** — num/bigfloat.xi on bigint.xi.
6. **Backlog (next sessions):** see §14.

## 14. BACKLOG (owner-approved, next sessions)

### 14.1 Compiler hardening (continues after D2+D1)
- Interface `impl` dispatch (3a above) — parser handles ImplDecl today;
  checker+codegen ignore it. This is THE enabler for the generic stdlib.
- Generic-operator Float64 corruption (3b above).
- Result[Vec[T]].value corruption (SESSION.md bug 1).
- Chained .method on module-qualified Str-returning calls (bug 2) — already
  worked around in net/url.xi; fix at source.
- Bool?Int cast (bug 4).
- Option/Result match-arm mixing ? out-of-bounds GEP (bug 5).
- `&T` param semantics (address-as-i64, not value) — documented, keep.

### 14.2 Math family libs (category: math/, manifest math.xi)
Write AFTER hardening 3a+3b so they are generic (`[T: Num]`) not per-width:
- math/core — sqrt, pow, exp, ln, log10, log2, trig, hyperbolic, abs, min,
  max, clamp, floor/ceil/round/trunc/fract, remap, lerp — GENERIC over Num.
- math/primitives — number-theoretic primitives, divisibility, parity.
- math/algebra — linear algebra: vectors, matrices, determinants, inverses,
  solvers (Gaussian), eigenvalues (basic).
- math/vectors — geometric vectors (replaces flat geom.xi vec2/3/4 fns
  eventually; keep frozen flat fns).
- math/trig + math/transcendental — full trig, exp/log families, gamma,
  erf, zeta (basic), special functions.
- math/differential — numeric derivatives, gradients, ODE solvers
  (Euler, RK4), integration (trapezoid, Simpson, Gauss).
- math/integral — numeric quadrature.
- math/series — Taylor, Fourier (basic), polynomial ops.
- math/special — Bessel, Legendre, Chebyshev, factorial/gamma, binomial.

### 14.3 BigInt/BigFloat (category: num/, manifest num.xi)
- bigint.xi exists (frozen flat). Extend: bigint/ folder libs — karatsuba,
  toom-cook, montgomery, powmod, sqrt, gcd-extended, primality
  (Miller-Rabin), string base conversions.
- BigFloat (D3): num/bigfloat.xi — sign/exponent/significand on bigint,
  add/sub/mul/div, rounding modes, parse/format, sqrt, ln/exp (series),
  sin/cos (series). Separate from bigint.xi.

### 14.4 Remaining category gap libs (after hardening)
- hash: highway, spooky, metro, t1ha, farm, superfast (city/xxhash/murmur/
  jenkins/crc done).
- net: http (headers/cookies/mime/etag/sse), ip (v6/well-known ports),
  socket helpers.
- text: unicode (normalize, bidi), case, search, diff, transliterate.
- crypto: mac, kdf, cipher, aead, sign, keyx, curves (ECC already via
  runtime C; move to pure XIOM once i128 + hardening land).
- collect: list, map, set, trie, bloom, unionfind, kdtree, skiplist.
- os: mmap, ioctl, sync_io, win, unix.
- io: fs, buffer, console, pipe.
- ffi: dl (dlopen), c, errno.
- rand: splitmix, xoroshiro.
- time: chrono, calendar, iso8601 (Date done).
- stats: dist, test, regress, histogram, moments.
- geom: curves, polyhedra; vec/mat/quat/collision folders.
- sync: channel; thread: pool, park, local; async: io.
- serialize: varint, endian; encoding: ascii85, punycode, idna;
  compress: deflate-family detail; sort: intro/radix; search: kmp/boyer;
  iter: fold/chain detail; regex: engine detail; test: harness; log: sinks.
5. **Remaining gap libs** into their categories (hash: highway/spooky/metro/t1ha/farm/superfast; net: http/ip; text: unicode/bidi; etc.).





Function	Generic	Description
add(a, b)	?	Addition
sub(a, b)	?	Subtraction
mul(a, b)	?	Multiplication
div(a, b)	?	Division (requires b != 0)
mod(a, b)	?	Modulo/remainder
abs(x)	?	Absolute value
neg(x)	?	Negation
signum(x)	?	Sign (-1, 0, 1)
min(a, b)	?	Minimum of two values
max(a, b)	?	Maximum of two values
clamp(x, lo, hi)	?	Clamp value between bounds
lerp(a, b, t)	?	Linear interpolation
saturating_add(a, b)	?	Addition with saturation
saturating_sub(a, b)	?	Subtraction with saturation
saturating_mul(a, b)	?	Multiplication with saturation
checked_add(a, b)	?	Addition with overflow check
checked_sub(a, b)	?	Subtraction with overflow check
checked_mul(a, b)	?	Multiplication with overflow check
checked_div(a, b)	?	Division with zero check
wrapping_add(a, b)	?	Addition with wrap-around
wrapping_sub(a, b)	?	Subtraction with wrap-around
wrapping_mul(a, b)	?	Multiplication with wrap-around
overflowing_add(a, b)	?	Addition + overflow flag
overflowing_sub(a, b)	?	Subtraction + overflow flag
overflowing_mul(a, b)	?	Multiplication + overflow flag
abs_diff(a, b)	?	Absolute difference
math/constants — Fundamental Mathematical Constants
Description: Universal constants with type-specific precision. No functions, all constants. Constants are resolved at compile time.

Constant	Generic	Description
PI	?	p = 3.14159265358979323846
E	?	e = 2.71828182845904523536
TAU	?	t = 2p = 6.28318530717958647692
PHI	?	f = 1.61803398874989484820 (Golden ratio)
SQRT_2	?	v2 = 1.41421356237309504880
SQRT_3	?	v3 = 1.73205080756887729352
SQRT_5	?	v5 = 2.23606797749978969640
LN_2	?	ln 2 = 0.69314718055994530942
LN_10	?	ln 10 = 2.30258509299404568402
LOG2_E	?	log2 e = 1.44269504088896340736
LOG10_E	?	log10 e = 0.43429448190325182765
EULER_GAMMA	?	? = 0.57721566490153286060
CATALAN	?	G = 0.91596559417721901505
APERY	?	?(3) = 1.20205690315959428540
FLOAT_EPSILON	?	Machine epsilon (Float64)
FLOAT32_EPSILON	?	Machine epsilon (Float32)
FLOAT64_MAX	?	Maximum Float64
FLOAT64_MIN	?	Minimum Float64
FLOAT32_MAX	?	Maximum Float32
FLOAT32_MIN	?	Minimum Float32
INFINITY	?	Positive infinity
NEG_INFINITY	?	Negative infinity
NAN	?	Not-a-number
math/precision — Type-Specific Precision Information
Description: Compile-time information about numeric type precision, ranges, and characteristics.

Function	Generic	Description
min_value[T]()	?	Minimum representable value
max_value[T]()	?	Maximum representable value
epsilon[T]()	?	Machine epsilon
digits[T]()	?	Number of significant digits
mantissa_digits[T]()	?	Mantissa bits (floats)
exponent_bias[T]()	?	Exponent bias (floats)
min_exponent[T]()	?	Minimum exponent (floats)
max_exponent[T]()	?	Maximum exponent (floats)
is_signed[T]()	?	Whether type is signed
bit_width[T]()	?	Bit width of type
byte_width[T]()	?	Byte width of type
math/interfaces — Numeric Traits
Description: The foundational interfaces that enable generic mathematics. All numeric types implement these.

Interface	Description
Numeric	Add, sub, mul, div, abs, neg, signum, zero, one
Integer	Numeric + rem, shl, shr, bit_and, bit_or, bit_xor, bit_not
Signed	Numeric + is_negative, is_positive, abs
Unsigned	Numeric + wrapping_add, wrapping_sub, overflowing_add, overflowing_sub
Float	Numeric + sqrt, sin, cos, tan, exp, ln, log10, log2, pow, is_nan, is_inf, is_finite
Ord	Compare, lt, le, gt, ge, eq, ne, min, max, clamp
Bounded	min_value, max_value, epsilon
FromStr	Parse from string
Display	Format to string
ARITHMETIC & ALGEBRA
math/arithmetic — Arithmetic Operations
Description: Extended arithmetic operations beyond core. Generic over Integer and Float.

Function	Generic	Description
gcd(a, b)	?	Greatest common divisor
lcm(a, b)	?	Least common multiple
is_power_of_two(n)	?	Check if power of two
next_power_of_two(n)	?	Next power of two
prev_power_of_two(n)	?	Previous power of two
gcd_extended(a, b)	?	Extended Euclidean algorithm
mod_inverse(a, m)	?	Modular multiplicative inverse
pow_mod(base, exp, mod)	?	Modular exponentiation
is_odd(n)	?	Check if odd
is_even(n)	?	Check if even
div_ceil(a, b)	?	Integer division rounding up
div_floor(a, b)	?	Integer division rounding down
div_trunc(a, b)	?	Integer division truncating toward zero
mod_floor(a, b)	?	Modulo with floor division
mod_trunc(a, b)	?	Modulo with truncation
math/roots — Root Operations
Description: Square roots, cube roots, nth roots, and related operations. Float functions use hardware acceleration (where available). Integer functions use software fallback.

Function	Generic	Description
sqrt(x)	Partial	Square root (hardware for Float, software for Integer)
cbrt(x)	Partial	Cube root
nth_root(x, n)	Partial	Nth root
sqrt_pure(x)	?	Software-only sqrt (no hardware)
cbrt_pure(x)	?	Software-only cube root
is_square(n)	?	Check if perfect square
is_cube(n)	?	Check if perfect cube
integer_sqrt(n)	?	Integer square root (floor)
integer_cbrt(n)	?	Integer cube root (floor)
hypot(x, y)	?	Hypotenuse (sqrt(x² + y²))
hypot3(x, y, z)	?	Hypotenuse (sqrt(x² + y² + z²))
norm2(x, y)	?	Euclidean distance (2D)
norm3(x, y, z)	?	Euclidean distance (3D)
math/exponential — Exponential and Logarithmic Functions
Description: Exponential, logarithmic, power, and related functions. Float functions use libm (hardware accelerated). Integer functions use software fallback.

Function	Generic	Description
exp(x)	?	Exponential (e^x)
exp2(x)	?	Exponential base 2 (2^x)
exp10(x)	?	Exponential base 10 (10^x)
expm1(x)	?	e^x - 1 (accurate for small x)
ln(x)	?	Natural logarithm
log2(x)	?	Logarithm base 2
log10(x)	?	Logarithm base 10
log1p(x)	?	ln(1 + x) (accurate for small x)
ln_1_plus(x)	?	ln(1 + x)
pow(base, exp)	Partial	Power (hardware for Float, software for Integer)
pow_int(base, exp)	?	Integer power
pow_float(base, exp)	?	Float power (libm)
sqrt_power(base, exp)	?	Power with integer exponent
exp_pure(x)	?	Software-only exp
ln_pure(x)	?	Software-only ln
log2_pure(x)	?	Software-only log2
log10_pure(x)	?	Software-only log10
pow_pure(base, exp)	?	Software-only pow
math/rounding — Rounding Operations
Description: Floor, ceil, round, trunc, and fractional part operations.

Function	Generic	Description
floor(x)	?	Floor (largest integer = x)
ceil(x)	?	Ceiling (smallest integer = x)
round(x)	?	Round half to even
trunc(x)	?	Truncate (toward zero)
fract(x)	?	Fractional part
modf(x)	?	Split integer and fractional parts
floor_pure(x)	?	Software-only floor
ceil_pure(x)	?	Software-only ceil
round_pure(x)	?	Software-only round
trunc_pure(x)	?	Software-only trunc
fract_pure(x)	?	Software-only fract
integer_part(x)	?	Integer part (same as trunc)
frac_part(x)	?	Fractional part (same as fract)
round_to(x, decimals)	?	Round to n decimal places
round_nearest(x, multiple)	?	Round to nearest multiple
math/decompose — Number Decomposition
Description: Split numbers into components, extract mantissa/exponent, and related operations.

Function	Generic	Description
frexp(x)	?	Split into mantissa and exponent (Float)
ldexp(x, n)	?	Multiply by power of 2
ilogb(x)	?	Integer exponent (biased)
logb(x)	?	Unbiased exponent
scalbn(x, n)	?	Multiply by 2^n
scalbln(x, n)	?	Multiply by 2^n (long)
significand(x)	?	Extract significand
exponent(x)	?	Extract exponent
frexp_pure(x)	?	Software-only frexp
ldexp_pure(x, n)	?	Software-only ldexp
is_normal(x)	?	Check if normal float
is_subnormal(x)	?	Check if subnormal float
classify(x)	?	Classify floating-point value
nextafter(x, y)	?	Next representable float
nexttoward(x, y)	?	Next representable float (long double)
TRIGONOMETRY
math/trigonometry — Trigonometric Functions
Description: Sine, cosine, tangent, and related functions. Hardware accelerated via libm.

Function	Generic	Description
sin(x)	?	Sine (radians)
cos(x)	?	Cosine (radians)
tan(x)	?	Tangent (radians)
csc(x)	?	Cosecant (1/sin)
sec(x)	?	Secant (1/cos)
cot(x)	?	Cotangent (1/tan)
sincos(x)	?	Returns (sin, cos) pair (optimized)
sincospi(x)	?	Returns (sin(px), cos(px)) pair
sin_pure(x)	?	Software-only sin
cos_pure(x)	?	Software-only cos
tan_pure(x)	?	Software-only tan
sinpi(x)	?	sin(px)
cospi(x)	?	cos(px)
tanpi(x)	?	tan(px)
math/inverse_trig — Inverse Trigonometric Functions
Description: Arcsine, arccosine, arctangent, and related functions. Hardware accelerated via libm.

Function	Generic	Description
asin(x)	?	Arcsine
acos(x)	?	Arccosine
atan(x)	?	Arctangent
atan2(y, x)	?	Arctangent (two-argument)
atan2_pure(y, x)	?	Software-only atan2
asin_pure(x)	?	Software-only asin
acos_pure(x)	?	Software-only acos
atan_pure(x)	?	Software-only atan
atan2_radians(y, x)	?	atan2 in radians
atan2_degrees(y, x)	?	atan2 in degrees
arg(z)	?	Argument/phase of complex number
math/hyperbolic — Hyperbolic Functions
Description: Hyperbolic sine, cosine, tangent, and inverse functions. Hardware accelerated via libm.

Function	Generic	Description
sinh(x)	?	Hyperbolic sine
cosh(x)	?	Hyperbolic cosine
tanh(x)	?	Hyperbolic tangent
csch(x)	?	Hyperbolic cosecant
sech(x)	?	Hyperbolic secant
coth(x)	?	Hyperbolic cotangent
asinh(x)	?	Inverse hyperbolic sine
acosh(x)	?	Inverse hyperbolic cosine
atanh(x)	?	Inverse hyperbolic tangent
sinh_pure(x)	?	Software-only sinh
cosh_pure(x)	?	Software-only cosh
tanh_pure(x)	?	Software-only tanh
math/trigonometric_constants — Trigonometric Constants
Description: Constants related to trigonometry and angles.

Constant	Generic	Description
DEG_TO_RAD	?	p/180
RAD_TO_DEG	?	180/p
DEG_TO_RAD32	?	p/180 (Float32)
RAD_TO_DEG32	?	180/p (Float32)
PI_2	?	p/2
PI_4	?	p/4
PI_8	?	p/8
PI_3	?	p/3
PI_6	?	p/6
TAU_2	?	p
TAU_4	?	p/2
TAU_8	?	p/4
TAU_3	?	2p/3
TAU_6	?	p/3
TAU_12	?	p/6
math/angular — Angular Conversion
Description: Convert between radians, degrees, gradians, and other angular units.

Function	Generic	Description
to_radians(deg)	?	Degrees to radians
to_degrees(rad)	?	Radians to degrees
to_gradians(deg)	?	Degrees to gradians
from_gradians(grad)	?	Gradians to degrees
to_mils(deg)	?	Degrees to mils
from_mils(mils)	?	Mils to degrees
to_arcmin(deg)	?	Degrees to arcminutes
from_arcmin(arcmin)	?	Arcminutes to degrees
to_arcsec(deg)	?	Degrees to arcseconds
from_arcsec(arcsec)	?	Arcseconds to degrees
normalize_angle(rad)	?	Normalize angle to [0, 2p)
normalize_angle_deg(deg)	?	Normalize angle to [0, 360)
angle_diff(a, b)	?	Difference between angles
angle_lerp(a, b, t)	?	Angular interpolation
BITWISE & BINARY
math/bitwise — Bitwise Operations
Description: Bit manipulation operations on integer types. Hardware accelerated via LLVM intrinsics.

Function	Generic	Description
popcnt(x)	?	Count set bits (population count)
clz(x)	?	Count leading zeros
ctz(x)	?	Count trailing zeros
bit_reverse(x)	?	Reverse bit order
bit_reverse_byte(x)	?	Reverse bits within each byte
byte_swap(x)	?	Swap bytes (endian conversion)
rotate_left(x, n)	?	Rotate bits left
rotate_right(x, n)	?	Rotate bits right
bit_width(x)	?	Minimum bits to represent x
bit_length(x)	?	Number of bits needed to represent x
leading_ones(x)	?	Count leading ones
trailing_ones(x)	?	Count trailing ones
bit_parity(x)	?	Parity (odd/even number of bits)
bit_scan_forward(x)	?	Position of least significant set bit
bit_scan_reverse(x)	?	Position of most significant set bit
is_power_of_two_bit(x)	?	Check if power of two (bitwise)
math/rotation — Bit Rotation
Description: Advanced bit rotation and bitfield manipulation operations.

Function	Generic	Description
rotate_left(x, n)	?	Rotate left by n bits
rotate_right(x, n)	?	Rotate right by n bits
rotate_left_carry(x, n, carry)	?	Rotate left with carry bit
rotate_right_carry(x, n, carry)	?	Rotate right with carry bit
rol_imm(x, n)	?	Rotate left (constant)
ror_imm(x, n)	?	Rotate right (constant)
bit_rotate_left(x, n)	?	Alias for rotate_left
bit_rotate_right(x, n)	?	Alias for rotate_right
masked_rotate_left(x, mask, n)	?	Rotate only masked bits
masked_rotate_right(x, mask, n)	?	Rotate only masked bits
math/endianness — Endianness Operations
Description: Endian conversion and detection.

Function	Generic	Description
is_big_endian()	?	Check if system is big-endian
is_little_endian()	?	Check if system is little-endian
to_be(x)	?	Convert to big-endian
to_le(x)	?	Convert to little-endian
from_be(x)	?	Convert from big-endian
from_le(x)	?	Convert from little-endian
native_to_be(x)	?	Native to big-endian (no-op on BE)
native_to_le(x)	?	Native to little-endian (no-op on LE)
be_to_native(x)	?	Big-endian to native (no-op on BE)
le_to_native(x)	?	Little-endian to native (no-op on LE)
swap_endian(x)	?	Swap endianness (byte-swap)
bswap_16(x)	?	Swap 16-bit endianness
bswap_32(x)	?	Swap 32-bit endianness
bswap_64(x)	?	Swap 64-bit endianness
bswap_128(x)	?	Swap 128-bit endianness
bswap_256(x)	?	Swap 256-bit endianness
math/bitfield — Bitfield Operations
Description: Extract, insert, and manipulate bitfields.

Function	Generic	Description
bit_extract(x, pos, len)	?	Extract bits from position with length
bit_insert(x, value, pos, len)	?	Insert bits at position with length
bit_replace(x, mask, value)	?	Replace masked bits with value
bit_set(x, pos)	?	Set bit at position
bit_clear(x, pos)	?	Clear bit at position
bit_toggle(x, pos)	?	Toggle bit at position
bit_test(x, pos)	?	Test bit at position
bit_field_get(x, pos, len)	?	Get bitfield (extract)
bit_field_set(x, pos, len, value)	?	Set bitfield (insert)
bit_field_clear(x, pos, len)	?	Clear bitfield
bit_field_inc(x, pos, len)	?	Increment bitfield (saturating)
bit_field_dec(x, pos, len)	?	Decrement bitfield (saturating)
mask_low(len)	?	Create mask of len low bits
mask_high(len)	?	Create mask of len high bits
mask_range(pos, len)	?	Create mask for range of bits
sign_extend(x, width)	?	Sign extend from width to full
NUMBER THEORY
math/number_theory — Number Theory
Description: Prime numbers, factorization, and related number theory operations.

Function	Generic	Description
is_prime(n)	?	Primality test (Miller-Rabin)
is_prime_deterministic(n)	?	Deterministic primality test
next_prime(n)	?	Next prime number
prev_prime(n)	?	Previous prime number
factor(n)	?	Prime factorization (trial division)
pollard_rho(n)	?	Pollard's Rho factorization
p_1_factor(n)	?	Pollard's p-1 factorization
is_pseudoprime(n)	?	Fermat pseudoprime test
miller_rabin(n, k)	?	Miller-Rabin test with k iterations
fermat_test(n)	?	Fermat primality test
lucas_lehmer(p)	?	Lucas-Lehmer test for Mersenne primes
mersenne_prime_p(p)	?	Check if 2^p - 1 is prime
euler_phi(n)	?	Euler's totient function
mobius(n)	?	Möbius function
jordan_totient(n, k)	?	Jordan's totient function
carmichael(n)	?	Carmichael function
prime_pi(n)	?	Number of primes = n
nth_prime(n)	?	Nth prime number
primorial(n)	?	Primorial (product of primes = n)
is_composite(n)	?	Check if composite
is_semiprime(n)	?	Check if semiprime
is_power(n)	?	Check if perfect power
is_power_of(x, n)	?	Check if x is a power of n
radical(n)	?	Radical of n (product of distinct primes)
smooth(n, b)	?	B-smooth number check
rough(n, b)	?	B-rough number check
legendre_symbol(a, p)	?	Legendre symbol
jacobi_symbol(a, n)	?	Jacobi symbol
kronecker_symbol(a, n)	?	Kronecker symbol
divisor_sum(n)	?	Sum of divisors
divisor_count(n)	?	Number of divisors
proper_divisors(n)	?	All proper divisors
math/factorial — Factorial and Combinatorial Functions
Description: Factorial, binomial coefficients, and related combinatorial functions.

Function	Generic	Description
factorial(n)	?	Factorial (n!)
double_factorial(n)	?	Double factorial (n!!)
subfactorial(n)	?	Derangements (!n)
multifactorial(n, k)	?	Multifactorial
binomial(n, k)	?	Binomial coefficient (n choose k)
binomial_coeff(n, k)	?	Binomial coefficient (alias)
multinomial(n, ks)	?	Multinomial coefficient
falling_factorial(n, k)	?	Falling factorial
rising_factorial(n, k)	?	Rising factorial
stirling_first(n, k)	?	Stirling numbers of the first kind
stirling_second(n, k)	?	Stirling numbers of the second kind
bell(n)	?	Bell numbers
catalan(n)	?	Catalan numbers
eulerian(n, k)	?	Eulerian numbers
narayana(n, k)	?	Narayana numbers
lah(n, k)	?	Lah numbers
motzkin(n)	?	Motzkin numbers
schroeder(n)	?	Schröder numbers
partition_count(n)	?	Number of partitions (p(n))
integer_partitions(n)	?	Generate integer partitions
derangements(n)	?	Derangements (subfactorial)
bell_triangle(n)	?	Bell triangle
math/modular — Modular Arithmetic
Description: Modular arithmetic operations and algorithms.

Function	Generic	Description
mod_add(a, b, m)	?	Modular addition
mod_sub(a, b, m)	?	Modular subtraction
mod_mul(a, b, m)	?	Modular multiplication
mod_pow(a, e, m)	?	Modular exponentiation
mod_inverse(a, m)	?	Modular inverse
mod_sqrt(a, p)	?	Modular square root
mod_cbrt(a, p)	?	Modular cube root
mod_div(a, b, m)	?	Modular division
mod_lcm(a, b, m)	?	Modular LCM
crt(pairs)	?	Chinese Remainder Theorem
crt_solve(residues, moduli)	?	CRT solver
linear_congruence(a, b, m)	?	Linear congruence solver
quadratic_residue(a, p)	?	Check if quadratic residue
tonelli_shanks(a, p)	?	Tonelli-Shanks algorithm
cipolla(a, p)	?	Cipolla's algorithm
cornacchia(d, m)	?	Cornacchia's algorithm
hilbert_symbol(a, b, p)	?	Hilbert symbol
pow_mod_fast(a, e, m)	?	Fast modular exponentiation
COMPLEX NUMBERS
math/complex — Complex Numbers
Description: Operations on complex numbers. Generic over Float types.

Function	Generic	Description
Complex[T]	?	Complex number type
new(real, imag)	?	Create complex number
real(z)	?	Get real part
imag(z)	?	Get imaginary part
add(a, b)	?	Complex addition
sub(a, b)	?	Complex subtraction
mul(a, b)	?	Complex multiplication
div(a, b)	?	Complex division
neg(z)	?	Complex negation
conj(z)	?	Complex conjugate
abs(z)	?	Complex magnitude
abs_sq(z)	?	Squared magnitude
arg(z)	?	Argument/phase
sqrt(z)	?	Complex square root
cbrt(z)	?	Complex cube root
exp(z)	?	Complex exponential
ln(z)	?	Complex natural log
log(z, base)	?	Complex log with base
pow(z, n)	?	Complex power
sin(z)	?	Complex sine
cos(z)	?	Complex cosine
tan(z)	?	Complex tangent
sinh(z)	?	Complex hyperbolic sine
cosh(z)	?	Complex hyperbolic cosine
tanh(z)	?	Complex hyperbolic tangent
asin(z)	?	Complex arcsine
acos(z)	?	Complex arccosine
atan(z)	?	Complex arctangent
asinh(z)	?	Complex inverse hyperbolic sine
acosh(z)	?	Complex inverse hyperbolic cosine
atanh(z)	?	Complex inverse hyperbolic tangent
polar(r, theta)	?	Create from polar coordinates
to_polar(z)	?	Convert to polar coordinates
is_real(z)	?	Check if real
is_imag(z)	?	Check if imaginary
is_zero(z)	?	Check if zero
is_infinite(z)	?	Check if infinite
is_nan(z)	?	Check if NaN
LINEAR ALGEBRA
math/vector — Vector Operations
Description: Vector operations for 2D, 3D, 4D, and N-dimensional vectors.

Function	Generic	Description
Vec2[T]	?	2D vector
Vec3[T]	?	3D vector
Vec4[T]	?	4D vector
VecN[T]	?	N-dimensional vector
v2_new(x, y)	?	Create 2D vector
v3_new(x, y, z)	?	Create 3D vector
v4_new(x, y, z, w)	?	Create 4D vector
dot(a, b)	?	Dot product
cross(a, b)	?	Cross product (3D)
cross2(a, b)	?	Cross product (2D scalar)
outer(a, b)	?	Outer product
norm(v)	?	Euclidean norm
norm_sq(v)	?	Squared norm
normalize(v)	?	Normalized vector
unit(v)	?	Unit vector
distance(a, b)	?	Euclidean distance
distance_sq(a, b)	?	Squared distance
angle(a, b)	?	Angle between vectors
project(a, b)	?	Project a onto b
reject(a, b)	?	Reject a from b
lerp(a, b, t)	?	Linear interpolation
slerp(a, b, t)	?	Spherical interpolation
reflect(v, normal)	?	Reflect vector
refract(v, normal, eta)	?	Refract vector
clamp(v, min, max)	?	Clamp vector components
component_min(a, b)	?	Component-wise min
component_max(a, b)	?	Component-wise max
hadamard(a, b)	?	Component-wise product
math/matrix — Matrix Operations
Description: Matrix operations for 2x2, 3x3, 4x4, and MxN matrices.

Function	Generic	Description
Mat2[T]	?	2x2 matrix
Mat3[T]	?	3x3 matrix
Mat4[T]	?	4x4 matrix
MatMN[T]	?	MxN matrix
mat2_new(m00, m01, m10, m11)	?	Create 2x2
mat3_new(...)	?	Create 3x3
mat4_new(...)	?	Create 4x4
identity()	?	Identity matrix
zero()	?	Zero matrix
one()	?	Ones matrix
add(a, b)	?	Matrix addition
sub(a, b)	?	Matrix subtraction
mul(a, b)	?	Matrix multiplication
scalar_mul(a, s)	?	Scalar multiplication
transpose(m)	?	Transpose
det(m)	?	Determinant
inverse(m)	?	Inverse
adjugate(m)	?	Adjugate (classical adjoint)
cofactor(m, i, j)	?	Cofactor
minor(m, i, j)	?	Minor
trace(m)	?	Trace
rank(m)	?	Rank
nullity(m)	?	Nullity
eigenvalues(m)	?	Eigenvalues
eigenvectors(m)	?	Eigenvectors
diagonal(d)	?	Diagonal matrix
diag_mul(a, d)	?	Diagonal multiplication
hadamard(a, b)	?	Component-wise (Hadamard) product
kronecker(a, b)	?	Kronecker product
lu_decompose(m)	?	LU decomposition
qr_decompose(m)	?	QR decomposition
svd_decompose(m)	?	SVD decomposition
cholesky(m)	?	Cholesky decomposition
solve_linear(a, b)	?	Solve linear system
least_squares(a, b)	?	Least squares solution
condition_number(m)	?	Condition number
math/quaternion — Quaternion Operations
Description: Quaternion operations for 3D rotations.

Function	Generic	Description
Quat[T]	?	Quaternion type
quat_new(w, x, y, z)	?	Create quaternion
quat_identity()	?	Identity quaternion
quat_from_axis_angle(axis, angle)	?	Create from axis-angle
quat_from_euler(yaw, pitch, roll)	?	Create from Euler angles
quat_from_rotation_matrix(m)	?	Create from rotation matrix
quat_to_matrix(q)	?	Convert to rotation matrix
quat_to_euler(q)	?	Convert to Euler angles
quat_mul(a, b)	?	Quaternion multiplication
quat_conj(q)	?	Conjugate
quat_inv(q)	?	Inverse
quat_norm(q)	?	Norm
quat_normalize(q)	?	Normalize
quat_rotate(q, v)	?	Rotate vector by quaternion
quat_slerp(a, b, t)	?	Spherical interpolation
quat_nlerp(a, b, t)	?	Normalized linear interpolation
quat_angle(q)	?	Rotation angle
quat_axis(q)	?	Rotation axis
quat_look_at(direction, up)	?	Look at rotation
quat_between(from, to)	?	Quaternion between vectors
math/linear — Advanced Linear Algebra
Description: Advanced linear algebra operations.

Function	Generic	Description
gram_schmidt(vectors)	?	Gram-Schmidt orthogonalization
orthogonalize(vectors)	?	Orthogonalize vectors
normalize_columns(m)	?	Normalize columns
normalize_rows(m)	?	Normalize rows
is_orthogonal(m)	?	Check if orthogonal
is_symmetric(m)	?	Check if symmetric
is_skew_symmetric(m)	?	Check if skew-symmetric
is_positive_definite(m)	?	Check if positive definite
is_diagonal_dominant(m)	?	Check if diagonally dominant
matrix_exponential(m)	?	Matrix exponential
matrix_logarithm(m)	?	Matrix logarithm
matrix_sqrt(m)	?	Matrix square root
matrix_power(m, n)	?	Matrix power
vec_to_skew(v)	?	Convert vector to skew-symmetric matrix
skew_to_vec(m)	?	Convert skew-symmetric matrix to vector
GEOMETRY
math/geometry_2d — 2D Geometry
Description: 2D geometric shapes and operations.

Function	Generic	Description
Point2[T]	?	2D point
Line2[T]	?	2D line
Ray2[T]	?	2D ray
Segment2[T]	?	2D line segment
Circle[T]	?	Circle
Rect[T]	?	Rectangle
Triangle2[T]	?	Triangle
Polygon2[T]	?	Polygon
point_distance(a, b)	?	Distance between points
point_in_circle(p, circle)	?	Point in circle test
point_in_rect(p, rect)	?	Point in rectangle test
point_in_triangle(p, tri)	?	Point in triangle test
point_in_polygon(p, poly)	?	Point in polygon test
line_intersection(a, b)	?	Line intersection
segment_intersection(a, b)	?	Segment intersection
segment_point_distance(seg, p)	?	Distance from point to segment
line_point_distance(line, p)	?	Distance from point to line
circle_intersection(a, b)	?	Circle intersection
circle_line_intersection(circle, line)	?	Circle-line intersection
circle_circle_intersection(a, b)	?	Circle-circle intersection
area_triangle(a, b, c)	?	Triangle area
area_polygon(poly)	?	Polygon area
centroid(poly)	?	Polygon centroid
convex_hull(points)	?	Convex hull
is_convex(poly)	?	Check if convex
polygon_contains(poly, p)	?	Polygon contains point
polygon_intersection(a, b)	?	Polygon intersection
polygon_union(a, b)	?	Polygon union
polygon_difference(a, b)	?	Polygon difference
polygon_circumference(poly)	?	Polygon perimeter
math/geometry_3d — 3D Geometry
Description: 3D geometric shapes and operations.

Function	Generic	Description
Point3[T]	?	3D point
Line3[T]	?	3D line
Ray3[T]	?	3D ray
Segment3[T]	?	3D line segment
Plane[T]	?	Plane
Sphere[T]	?	Sphere
Capsule[T]	?	Capsule
Cylinder[T]	?	Cylinder
Cone[T]	?	Cone
Box[T]	?	Axis-aligned box (AABB)
OBB[T]	?	Oriented bounding box
Triangle3[T]	?	3D triangle
Polygon3[T]	?	3D polygon
Mesh[T]	?	Mesh
point_distance(a, b)	?	3D distance
point_sphere_distance(p, s)	?	Point-sphere distance
point_plane_distance(p, plane)	?	Point-plane distance
plane_point_distance(plane, p)	?	Plane-point distance
line_point_distance(line, p)	?	Line-point distance
segment_point_distance(seg, p)	?	Segment-point distance
ray_plane_intersection(ray, plane)	?	Ray-plane intersection
ray_triangle_intersection(ray, tri)	?	Ray-triangle intersection
ray_sphere_intersection(ray, sphere)	?	Ray-sphere intersection
ray_box_intersection(ray, box)	?	Ray-box intersection
plane_plane_intersection(a, b)	?	Plane-plane intersection
sphere_sphere_intersection(a, b)	?	Sphere-sphere intersection
aabb_intersection(a, b)	?	AABB intersection test
aabb_contains(box, point)	?	AABB contains point
closest_point_on_segment(p, seg)	?	Closest point on segment
closest_point_on_plane(p, plane)	?	Closest point on plane
triangle_normal(tri)	?	Triangle normal
mesh_volume(mesh)	?	Mesh volume
mesh_surface_area(mesh)	?	Mesh surface area
mesh_centroid(mesh)	?	Mesh centroid
convex_hull_3d(points)	?	3D convex hull
STATISTICS & PROBABILITY
math/statistics — Statistical Functions
Description: Descriptive statistics and data analysis.

Function	Generic	Description
mean(data)	?	Arithmetic mean
median(data)	?	Median
mode(data)	?	Mode
variance(data)	?	Variance (sample)
variance_pop(data)	?	Variance (population)
stddev(data)	?	Standard deviation (sample)
stddev_pop(data)	?	Standard deviation (population)
range(data)	?	Range (max - min)
iqr(data)	?	Interquartile range
quartiles(data)	?	Quartiles (Q1, Q2, Q3)
percentile(data, p)	?	Percentile
skewness(data)	?	Skewness
kurtosis(data)	?	Kurtosis
covariance(a, b)	?	Covariance
correlation(a, b)	?	Pearson correlation
spearman_correlation(a, b)	?	Spearman rank correlation
kendall_correlation(a, b)	?	Kendall tau correlation
rms(data)	?	Root mean square
geometric_mean(data)	?	Geometric mean
harmonic_mean(data)	?	Harmonic mean
weighted_mean(data, weights)	?	Weighted mean
trimmed_mean(data, p)	?	Trimmed mean
winsorized_mean(data, p)	?	Winsorized mean
mad(data)	?	Median absolute deviation
z_score(value, mean, stddev)	?	Z-score
math/probability — Probability Functions
Description: Probability distributions and related functions.

Function	Generic	Description
uniform_pdf(x, a, b)	?	Uniform PDF
uniform_cdf(x, a, b)	?	Uniform CDF
normal_pdf(x, mean, std)	?	Normal PDF
normal_cdf(x, mean, std)	?	Normal CDF
normal_quantile(p)	?	Normal quantile (inverse CDF)
exponential_pdf(x, lambda)	?	Exponential PDF
exponential_cdf(x, lambda)	?	Exponential CDF
gamma_pdf(x, shape, scale)	?	Gamma PDF
gamma_cdf(x, shape, scale)	?	Gamma CDF
beta_pdf(x, alpha, beta)	?	Beta PDF
beta_cdf(x, alpha, beta)	?	Beta CDF
chi2_pdf(x, df)	?	Chi-square PDF
chi2_cdf(x, df)	?	Chi-square CDF
t_pdf(x, df)	?	Student's t PDF
t_cdf(x, df)	?	Student's t CDF
f_pdf(x, df1, df2)	?	F-distribution PDF
f_cdf(x, df1, df2)	?	F-distribution CDF
weibull_pdf(x, shape, scale)	?	Weibull PDF
weibull_cdf(x, shape, scale)	?	Weibull CDF
lognormal_pdf(x, mean, std)	?	Log-normal PDF
lognormal_cdf(x, mean, std)	?	Log-normal CDF
pareto_pdf(x, alpha)	?	Pareto PDF
pareto_cdf(x, alpha)	?	Pareto CDF
poisson_pmf(k, lambda)	?	Poisson PMF
poisson_cdf(k, lambda)	?	Poisson CDF
binomial_pmf(k, n, p)	?	Binomial PMF
binomial_cdf(k, n, p)	?	Binomial CDF
geometric_pmf(k, p)	?	Geometric PMF
geometric_cdf(k, p)	?	Geometric CDF
negative_binomial_pmf(k, r, p)	?	Negative binomial PMF
negative_binomial_cdf(k, r, p)	?	Negative binomial CDF
hypergeometric_pmf(k, N, K, n)	?	Hypergeometric PMF
hypergeometric_cdf(k, N, K, n)	?	Hypergeometric CDF
CALCULUS & ANALYSIS
math/calculus — Calculus Operations
Description: Differentiation, integration, and related operations.

Function	Generic	Description
derivative(f, x, h)	?	Numerical derivative
derivative_2nd(f, x, h)	?	Second derivative
derivative_3rd(f, x, h)	?	Third derivative
integrate(f, a, b, n)	?	Numerical integration (Simpson)
integrate_trapezoid(f, a, b, n)	?	Trapezoidal integration
integrate_simpson(f, a, b, n)	?	Simpson's rule
integrate_romberg(f, a, b)	?	Romberg integration
integrate_gauss(f, a, b)	?	Gauss-Legendre quadrature
limit(f, x, direction)	?	Numerical limit
limit_left(f, x)	?	Left-hand limit
limit_right(f, x)	?	Right-hand limit
is_continuous(f, x)	?	Check continuity
gradient(f, x)	?	Gradient (multivariate)
partial_derivative(f, x, i, h)	?	Partial derivative
jacobian(f, x)	?	Jacobian matrix
hessian(f, x)	?	Hessian matrix
laplacian(f, x)	?	Laplacian
curl(f, x)	?	Curl
divergence(f, x)	?	Divergence
math/differential_equations — Differential Equations
Description: Numerical solvers for differential equations.

Function	Generic	Description
solve_ode_euler(f, y0, t0, t1, n)	?	Euler method
solve_ode_rk4(f, y0, t0, t1, n)	?	Runge-Kutta 4th order
solve_ode_rk45(f, y0, t0, t1)	?	Runge-Kutta-Fehlberg
solve_ode_adaptive(f, y0, t0, t1)	?	Adaptive step solver
solve_ode_bdf(f, y0, t0, t1, n)	?	Backward differentiation
solve_pde_fd(u0, bc, dx, dt)	?	Finite difference PDE
solve_pde_fem(u0, bc, mesh)	?	Finite element PDE
SPECIAL FUNCTIONS
math/special — Special Functions
Description: Advanced special functions from mathematics and physics.

Function	Generic	Description
gamma(x)	?	Gamma function G(x)
gamma_ln(x)	?	Log gamma ln(G(x))
digamma(x)	?	Digamma function ?(x)
trigamma(x)	?	Trigamma function ?1(x)
polygamma(n, x)	?	Polygamma function ?n(x)
beta(a, b)	?	Beta function B(a,b)
beta_ln(a, b)	?	Log beta ln(B(a,b))
incomplete_gamma(a, x)	?	Upper incomplete gamma
incomplete_gamma_low(a, x)	?	Lower incomplete gamma
incomplete_beta(a, b, x)	?	Incomplete beta
erf(x)	?	Error function
erfc(x)	?	Complementary error function
erfi(x)	?	Imaginary error function
erfinv(x)	?	Inverse error function
erfcinv(x)	?	Inverse complementary error function
bessel_j(n, x)	?	Bessel J (first kind)
bessel_y(n, x)	?	Bessel Y (second kind)
bessel_i(n, x)	?	Modified Bessel I
bessel_k(n, x)	?	Modified Bessel K
bessel_j0(x)	?	Bessel J0
bessel_j1(x)	?	Bessel J1
bessel_jn(n, x)	?	Bessel J_n
airy_ai(x)	?	Airy function Ai(x)
airy_bi(x)	?	Airy function Bi(x)
airy_aip(x)	?	Airy Ai'(x)
airy_bip(x)	?	Airy Bi'(x)
legendre_p(n, x)	?	Legendre polynomial P?(x)
legendre_q(n, x)	?	Legendre function Q?(x)
laguerre_l(n, x)	?	Laguerre polynomial L?(x)
hermite_h(n, x)	?	Hermite polynomial H?(x)
chebyshev_t(n, x)	?	Chebyshev T?(x)
chebyshev_u(n, x)	?	Chebyshev U?(x)
jacobi_p(n, a, b, x)	?	Jacobi polynomial P?^(a,b)(x)
gegenbauer_c(n, a, x)	?	Gegenbauer C?^(a)(x)
spherical_harmonic(l, m, theta, phi)	?	Spherical harmonic Y??
dawson(x)	?	Dawson's integral
fresnel_s(x)	?	Fresnel S(x)
fresnel_c(x)	?	Fresnel C(x)
exponential_integral(x)	?	Exponential integral E1(x)
li(x)	?	Logarithmic integral li(x)
li_offset(x)	?	Offset logarithmic integral Li(x)
sin_integral(x)	?	Sine integral Si(x)
cos_integral(x)	?	Cosine integral Ci(x)
hypergeometric_2f1(a, b, c, x)	?	Hypergeometric 2F1
hypergeometric_1f1(a, b, x)	?	Hypergeometric 1F1 (Kummer)
elliptic_k(k)	?	Complete elliptic integral K(k)
elliptic_e(k)	?	Complete elliptic integral E(k)
elliptic_pi(n, k)	?	Complete elliptic integral ?(n,k)
elliptic_f(phi, k)	?	Incomplete elliptic integral F(f,k)
elliptic_e_incomplete(phi, k)	?	Incomplete elliptic integral E(f,k)
elliptic_pi_incomplete(n, phi, k)	?	Incomplete elliptic integral ?(n,f,k)
theta_1(z, q)	?	Jacobi theta ?1
theta_2(z, q)	?	Jacobi theta ?2
theta_3(z, q)	?	Jacobi theta ?3
theta_4(z, q)	?	Jacobi theta ?4
riemann_zeta(x)	?	Riemann zeta function ?(x)
riemann_zeta_eta(x)	?	Dirichlet eta ?(x)
dirichlet_beta(x)	?	Dirichlet beta ß(x)
lerch_phi(z, s, a)	?	Lerch transcendent F(z,s,a)
polylog(s, z)	?	Polylogarithm Li?(z)
DISCRETE MATHEMATICS
math/combinatorics — Combinatorics
Description: Combinatorial structures and algorithms.

Function	Generic	Description
permutations(n, k)	?	Permutations P(n,k)
combinations(n, k)	?	Combinations C(n,k)
permutations_with_repetition(n, k)	?	Permutations with repetition
combinations_with_repetition(n, k)	?	Combinations with repetition
derangements(n)	?	Derangements !n
bell_numbers(n)	?	Bell numbers
catalan_numbers(n)	?	Catalan numbers
eulerian_numbers(n, k)	?	Eulerian numbers
stirling_numbers_1(n, k)	?	Stirling numbers (1st kind)
stirling_numbers_2(n, k)	?	Stirling numbers (2nd kind)
lah_numbers(n, k)	?	Lah numbers
narayana_numbers(n, k)	?	Narayana numbers
fibonacci(n)	?	Fibonacci number
fibonacci_start(a, b, n)	?	Generalized Fibonacci
lucas(n)	?	Lucas number
tribonacci(n)	?	Tribonacci number
tetranacci(n)	?	Tetranacci number
partitions(n)	?	Number of partitions p(n)
integer_partitions(n)	?	Generate integer partitions
compositions(n, k)	?	Compositions of n into k parts
compositions_all(n)	?	All compositions of n
surjections(n, k)	?	Surjections from n to k
involutions(n)	?	Involutions (self-inverse permutations)
derangements_enum(n)	?	Enumerate derangements
permutations_enum(n)	?	Enumerate permutations
combinations_enum(n, k)	?	Enumerate combinations
subsets_enum(n)	?	Enumerate subsets
powerset_enum(set)	?	Enumerate power set
math/graph_theory — Graph Theory
Description: Graph operations and algorithms.

Function	Generic	Description
Graph[T]	?	Graph type
graph_new()	?	Create empty graph
graph_add_vertex(g, v)	?	Add vertex
graph_add_edge(g, u, v)	?	Add edge
graph_add_weighted_edge(g, u, v, w)	?	Add weighted edge
graph_remove_vertex(g, v)	?	Remove vertex
graph_remove_edge(g, u, v)	?	Remove edge
graph_has_vertex(g, v)	?	Check vertex exists
graph_has_edge(g, u, v)	?	Check edge exists
graph_degree(g, v)	?	Degree of vertex
graph_vertices(g)	?	List vertices
graph_edges(g)	?	List edges
graph_adjacent(g, v)	?	Adjacent vertices
graph_dfs(g, start)	?	Depth-first search
graph_bfs(g, start)	?	Breadth-first search
graph_dijkstra(g, start)	?	Dijkstra's shortest path
graph_bellman_ford(g, start)	?	Bellman-Ford shortest path
graph_floyd_warshall(g)	?	Floyd-Warshall all-pairs
graph_astar(g, start, goal)	?	A* search
graph_prim(g)	?	Prim's MST
graph_kruskal(g)	?	Kruskal's MST
graph_tarjan_scc(g)	?	Tarjan's strongly connected components
graph_kosaraju_scc(g)	?	Kosaraju's SCC
graph_topological_sort(g)	?	Topological sort
graph_is_connected(g)	?	Check if connected
graph_is_cyclic(g)	?	Check if cyclic
graph_is_bipartite(g)	?	Check if bipartite
graph_isomorphic(g, h)	?	Check isomorphism
graph_color(g)	?	Graph coloring
graph_max_flow(g, s, t)	?	Max flow (Ford-Fulkerson)
graph_min_cut(g, s, t)	?	Min cut
graph_hamiltonian_path(g)	?	Hamiltonian path
graph_tsp(g)	?	Traveling salesman
ARBITRARY PRECISION
math/precision_integer — Arbitrary Precision Integers
Description: Big integers with arbitrary precision.

Function	Generic	Description
BigInt	?	Arbitrary precision integer
BigInt.new(value)	?	Create from integer
BigInt.from_str(s)	?	Parse from string
BigInt.to_str(n)	?	Convert to string
BigInt.to_hex(n)	?	Convert to hex
BigInt.to_bin(n)	?	Convert to binary
BigInt.to_oct(n)	?	Convert to octal
BigInt.add(a, b)	?	Addition
BigInt.sub(a, b)	?	Subtraction
BigInt.mul(a, b)	?	Multiplication
BigInt.div(a, b)	?	Division
BigInt.mod(a, b)	?	Modulo
BigInt.pow(a, b)	?	Power
BigInt.neg(a)	?	Negation
BigInt.abs(a)	?	Absolute value
BigInt.cmp(a, b)	?	Compare
BigInt.eq(a, b)	?	Equality
BigInt.lt(a, b)	?	Less than
BigInt.gt(a, b)	?	Greater than
BigInt.bit_and(a, b)	?	Bitwise AND
BigInt.bit_or(a, b)	?	Bitwise OR
BigInt.bit_xor(a, b)	?	Bitwise XOR
BigInt.bit_not(a)	?	Bitwise NOT
BigInt.shl(a, n)	?	Shift left
BigInt.shr(a, n)	?	Shift right
BigInt.is_prime(n)	?	Primality test
BigInt.gcd(a, b)	?	GCD
BigInt.lcm(a, b)	?	LCM
BigInt.mod_inverse(a, m)	?	Modular inverse
BigInt.mod_pow(a, e, m)	?	Modular exponentiation
BigInt.factorial(n)	?	Factorial
BigInt.binomial(n, k)	?	Binomial coefficient
math/precision_float — Arbitrary Precision Floats
Description: Big floats with arbitrary precision.

Function	Generic	Description
BigFloat	?	Arbitrary precision float
BigFloat.new(value)	?	Create from float
BigFloat.from_str(s)	?	Parse from string
BigFloat.to_str(f)	?	Convert to string
BigFloat.with_precision(prec)	?	Set precision (bits)
BigFloat.add(a, b)	?	Addition
BigFloat.sub(a, b)	?	Subtraction
BigFloat.mul(a, b)	?	Multiplication
BigFloat.div(a, b)	?	Division
BigFloat.neg(a)	?	Negation
BigFloat.abs(a)	?	Absolute value
BigFloat.sqrt(a)	?	Square root
BigFloat.cbrt(a)	?	Cube root
BigFloat.exp(a)	?	Exponential
BigFloat.ln(a)	?	Natural logarithm
BigFloat.log10(a)	?	Log base 10
BigFloat.log2(a)	?	Log base 2
BigFloat.pow(a, b)	?	Power
BigFloat.sin(a)	?	Sine
BigFloat.cos(a)	?	Cosine
BigFloat.tan(a)	?	Tangent
BigFloat.asin(a)	?	Arcsine
BigFloat.acos(a)	?	Arccosine
BigFloat.atan(a)	?	Arctangent
BigFloat.atan2(y, x)	?	Atan2
BigFloat.sinh(a)	?	Hyperbolic sine
BigFloat.cosh(a)	?	Hyperbolic cosine
BigFloat.tanh(a)	?	Hyperbolic tangent
BigFloat.pi(prec)	?	p with precision
BigFloat.e(prec)	?	e with precision
BigFloat.cmp(a, b)	?	Compare
BigFloat.eq(a, b)	?	Equality
math/precision_rational — Arbitrary Precision Rationals
Description: Big rational numbers with arbitrary precision.

Function	Generic	Description
BigRat	?	Arbitrary precision rational
BigRat.new(num, den)	?	Create rational
BigRat.from_int(n)	?	Create from integer
BigRat.from_str(s)	?	Parse from string
BigRat.to_str(r)	?	Convert to string
BigRat.numerator(r)	?	Get numerator
BigRat.denominator(r)	?	Get denominator
BigRat.add(a, b)	?	Addition
BigRat.sub(a, b)	?	Subtraction
BigRat.mul(a, b)	?	Multiplication
BigRat.div(a, b)	?	Division
BigRat.neg(a)	?	Negation
BigRat.abs(a)	?	Absolute value
BigRat.recip(a)	?	Reciprocal
BigRat.reduce(r)	?	Reduce to lowest terms
BigRat.is_reduced(r)	?	Check if reduced
BigRat.is_integer(r)	?	Check if integer
BigRat.is_zero(r)	?	Check if zero
BigRat.cmp(a, b)	?	Compare
BigRat.eq(a, b)	?	Equality
BigRat.to_float(r)	?	Convert to float
BigRat.to_integer(r)	?	Convert to integer
NUMERICAL METHODS
math/numerical — Numerical Methods
Description: Numerical algorithms for solving mathematical problems.

Function	Generic	Description
bisection(f, a, b)	?	Bisection method
newton(f, fprime, x0)	?	Newton-Raphson method
secant(f, x0, x1)	?	Secant method
falsi(f, a, b)	?	False position method
brent(f, a, b)	?	Brent's method
fixed_point(f, x0)	?	Fixed-point iteration
steffensen(f, x0)	?	Steffensen's method
newton_multi(f, jac, x0)	?	Multidimensional Newton
gauss_seidel(a, b, x0)	?	Gauss-Seidel method
jacobi_iterative(a, b, x0)	?	Jacobi iteration
conjugate_gradient(a, b, x0)	?	Conjugate gradient
gradient_descent(f, grad, x0)	?	Gradient descent
newton_raphson_multi(f, grad, hess, x0)	?	Newton-Raphson (multi)
bisection_root(f, a, b)	?	Bisection for root
newton_root(f, fp, x0)	?	Newton for root
broyden(f, x0)	?	Broyden's method
anderson(f, x0)	?	Anderson acceleration
interp_linear(x, y, xi)	?	Linear interpolation
interp_polynomial(x, y, xi)	?	Polynomial interpolation
interp_spline(x, y, xi)	?	Spline interpolation
interp_cubic(x, y, xi)	?	Cubic interpolation
interp_hermite(x, y, dy, xi)	?	Hermite interpolation
spline_linear(x, y)	?	Linear spline
spline_cubic(x, y)	?	Cubic spline
spline_b_spline(x, y, k)	?	B-spline
spline_nurbs(x, y, k, weights)	?	NURBS
quadrature_trapezoid(f, a, b, n)	?	Trapezoidal quadrature
quadrature_simpson(f, a, b, n)	?	Simpson's quadrature
quadrature_gauss(f, a, b, n)	?	Gauss-Legendre quadrature
quadrature_adaptive(f, a, b)	?	Adaptive quadrature
quadrature_monte_carlo(f, a, b, n)	?	Monte Carlo integration
optimize_golden(f, a, b)	?	Golden-section optimization
optimize_ternary(f, a, b)	?	Ternary search
optimize_bfgs(f, grad, x0)	?	BFGS optimization
optimize_lbfgs(f, grad, x0)	?	L-BFGS
optimize_simplex(f, x0)	?	Nelder-Mead simplex
optimize_powell(f, x0)	?	Powell's method
optimize_cg(f, grad, x0)	?	Conjugate gradient optimization
optimize_gradient(f, grad, x0)	?	Gradient descent optimization
optimize_newton(f, grad, hess, x0)	?	Newton optimization
optimize_least_squares(f, x0)	?	Nonlinear least squares
solver_single(f, x0)	?	Single equation solver
solver_system(f, x0)	?	System of equations solver
SIGNAL PROCESSING
math/signal — Signal Processing
Description: Signal processing and transform operations.

Function	Generic	Description
fft(data)	?	Fast Fourier Transform
ifft(data)	?	Inverse FFT
fft_real(data)	?	Real FFT
ifft_real(data)	?	Inverse real FFT
dft(data)	?	Discrete Fourier Transform
idft(data)	?	Inverse DFT
dct(data)	?	Discrete Cosine Transform
idct(data)	?	Inverse DCT
dct_type2(data)	?	DCT Type II
dct_type3(data)	?	DCT Type III
dst(data)	?	Discrete Sine Transform
idst(data)	?	Inverse DST
wavelet_dwt(data)	?	Discrete Wavelet Transform
wavelet_idwt(data)	?	Inverse DWT
wavelet_daubechies(data)	?	Daubechies wavelet
wavelet_haar(data)	?	Haar wavelet
filter_lowpass(data, cutoff)	?	Low-pass filter
filter_highpass(data, cutoff)	?	High-pass filter
filter_bandpass(data, lo, hi)	?	Band-pass filter
filter_bandstop(data, lo, hi)	?	Band-stop filter
filter_butterworth(data, cutoff, n)	?	Butterworth filter
filter_chebyshev(data, cutoff, n)	?	Chebyshev filter
filter_bessel(data, cutoff, n)	?	Bessel filter
filter_fir(data, taps)	?	FIR filter
filter_iir(data, a, b)	?	IIR filter
convolve(a, b)	?	Convolution
correlate(a, b)	?	Cross-correlation
autocorrelate(a)	?	Autocorrelation
window_hanning(n)	?	Hanning window
window_hamming(n)	?	Hamming window
window_blackman(n)	?	Blackman window
window_kaiser(n, beta)	?	Kaiser window
window_bartlett(n)	?	Bartlett window
window_gaussian(n, sigma)	?	Gaussian window
spectrum(data)	?	Power spectrum
psd(data)	?	Power spectral density
spectrogram(data, window, overlap)	?	Spectrogram
cepstrum(data)	?	Cepstrum
mel_filterbank(data)	?	Mel filterbank
mfcc(data)	?	Mel-frequency cepstral coefficients
OPTIMIZATION
math/optimization — Optimization Algorithms
Description: Mathematical optimization algorithms.

Function	Generic	Description
linear_programming(c, A, b)	?	Linear programming (simplex)
integer_programming(c, A, b)	?	Integer linear programming
mixed_integer_programming(c, A, b)	?	Mixed-integer programming
quadratic_programming(Q, c, A, b)	?	Quadratic programming
nonlinear_programming(f, constraints)	?	Nonlinear programming
lp_simplex(c, A, b)	?	Simplex algorithm
lp_interior_point(c, A, b)	?	Interior point method
branch_and_bound(f, constraints)	?	Branch and bound
cutting_plane(f, constraints)	?	Cutting plane method
sequential_quadratic(f, constraints)	?	Sequential quadratic programming
penalty_method(f, constraints)	?	Penalty method
barrier_method(f, constraints)	?	Barrier method
augmented_lagrangian(f, constraints)	?	Augmented Lagrangian
genetic_algorithm(f, population, generations)	?	Genetic algorithm
simulated_annealing(f, schedule)	?	Simulated annealing
particle_swarm(f, swarm_size, iterations)	?	Particle swarm optimization
ant_colony(f, ants, iterations)	?	Ant colony optimization
differential_evolution(f, population, generations)	?	Differential evolution
bayesian_optimization(f, bounds)	?	Bayesian optimization
grid_search(f, grid)	?	Grid search
random_search(f, distribution, iterations)	?	Random search
FINANCE
math/finance — Financial Mathematics
Description: Financial calculations and models.

Function	Generic	Description
pv(future_value, rate, periods)	?	Present value
fv(present_value, rate, periods)	?	Future value
npv(rate, cashflows)	?	Net present value
irr(cashflows)	?	Internal rate of return
mirr(cashflows, finance_rate, reinvest_rate)	?	Modified IRR
pmt(rate, periods, pv)	?	Payment amount
ipmt(rate, period, periods, pv)	?	Interest portion of payment
ppmt(rate, period, periods, pv)	?	Principal portion of payment
nper(rate, pmt, pv)	?	Number of periods
rate(nper, pmt, pv, fv)	?	Interest rate
annuity(rate, periods, pv)	?	Annuity calculation
perpetuity(cashflow, rate)	?	Perpetuity calculation
bond_price(face_value, coupon, maturity, rate)	?	Bond price
bond_yield(price, face_value, coupon, maturity)	?	Bond yield to maturity
duration(price, face_value, coupon, maturity, rate)	?	Macaulay duration
convexity(price, face_value, coupon, maturity, rate)	?	Convexity
option_call(s, k, t, r, sigma)	?	Call option price (Black-Scholes)
option_put(s, k, t, r, sigma)	?	Put option price (Black-Scholes)
option_call_delta(s, k, t, r, sigma)	?	Call option delta
option_put_delta(s, k, t, r, sigma)	?	Put option delta
option_gamma(s, k, t, r, sigma)	?	Option gamma
option_theta(s, k, t, r, sigma)	?	Option theta
option_vega(s, k, t, r, sigma)	?	Option vega
option_rho(s, k, t, r, sigma)	?	Option rho
implied_volatility(price, s, k, t, r)	?	Implied volatility
cagr(start_value, end_value, periods)	?	Compound annual growth rate
sharpe_ratio(returns, risk_free_rate)	?	Sharpe ratio
sortino_ratio(returns, risk_free_rate)	?	Sortino ratio
calmar_ratio(returns)	?	Calmar ratio
var(returns, confidence_level)	?	Value at Risk
cvar(returns, confidence_level)	?	Conditional VaR
drawdown(returns)	?	Maximum drawdown
beta(returns, market_returns)	?	Beta coefficient
alpha(returns, market_returns, risk_free_rate)	?	Alpha coefficient
treynor_ratio(returns, market_returns, risk_free_rate)	?	Treynor ratio
Complete Module Summary
Module	Category	Functions
math/core	Foundation	25
math/constants	Foundation	24
math/precision	Foundation	10
math/interfaces	Foundation	10
math/arithmetic	Arithmetic	20
math/roots	Arithmetic	12
math/exponential	Arithmetic	22
math/rounding	Arithmetic	14
math/decompose	Arithmetic	14
math/trigonometry	Trigonometry	12
math/inverse_trig	Trigonometry	10
math/hyperbolic	Trigonometry	12
math/trigonometric_constants	Trigonometry	12
math/angular	Trigonometry	12
math/bitwise	Bitwise	18
math/rotation	Bitwise	10
math/endianness	Bitwise	16
math/bitfield	Bitwise	16
math/number_theory	Number Theory	38
math/factorial	Number Theory	22
math/modular	Number Theory	18
math/complex	Complex	36
math/vector	Linear Algebra	30
math/matrix	Linear Algebra	34
math/quaternion	Linear Algebra	18
math/linear	Linear Algebra	16
math/geometry_2d	Geometry	28
math/geometry_3d	Geometry	30
math/statistics	Statistics	28
math/probability	Probability	30
math/calculus	Calculus	18
math/differential_equations	Calculus	8
math/special	Special	58
math/combinatorics	Discrete	32
math/graph_theory	Discrete	38
math/precision_integer	Precision	34
math/precision_float	Precision	28
math/precision_rational	Precision	20
math/numerical	Numerical	44
math/signal	Signal	38
math/optimization	Optimization	24
math/finance	Finance	36
TOTAL	42 Modules	~980 Functions
Next Steps
Implement math/core first (most used, simplest)

Add math/constants (compile-time only)

Implement math/trigonometry (libm bindings)

Add math/vector (game/3D operations)

Expand incrementally based on demand

Would you like me to write the full implementation for any specific module?

do we include stuff like min max lerp vector length etc ? are we left any math
Complete Math Coverage Audit
Let me do a full audit to make sure we haven't missed anything. I'll check every branch of mathematics and identify gaps.

? WHAT WE HAVE (Covered)
Category	Modules	Status
Foundations	core, constants, precision, interfaces	? Complete
Arithmetic	arithmetic, roots, exponential, rounding, decompose	? Complete
Trigonometry	trigonometry, inverse_trig, hyperbolic, angular, trig_constants	? Complete
Bitwise	bitwise, rotation, endianness, bitfield	? Complete
Number Theory	number_theory, factorial, modular	? Complete
Complex	complex	? Complete
Linear Algebra	vector, matrix, quaternion, linear	? Complete
Geometry	geometry_2d, geometry_3d	? Complete
Statistics	statistics, probability	? Complete
Calculus	calculus, differential_equations	? Complete
Special Functions	special	? Complete
Discrete Math	combinatorics, graph_theory	? Complete
Precision	precision_integer, precision_float, precision_rational	? Complete
Numerical Methods	numerical	? Complete
Signal Processing	signal	? Complete
Optimization	optimization	? Complete
Finance	finance	? Complete
? WHAT WE MISSED (Gaps)
1. MIN/MAX/LERP/VECTOR LENGTH — These are actually covered!
Function	Where it lives
min, max	math/core (generic over Ord)
clamp	math/core (generic over Ord)
lerp	math/core (generic over Numeric)
norm, norm_sq, normalize	math/vector
length, length_sq	math/vector (aliases for norm)
distance	math/vector
So these ARE included. Good.

2. MISSING: Set Theory
text
math/set_theory
+-- Set[T] - Set operations
+-- union, intersection, difference, symmetric_difference
+-- subset, superset, proper_subset
+-- power_set, cartesian_product
+-- cardinality, complement
+-- disjoint, partition
+-- set_comprehension
3. MISSING: Logic & Boolean Algebra
text
math/logic
+-- truth_table - Generate truth table
+-- boolean_expression - Evaluate boolean expressions
+-- simplify - Boolean algebra simplification
+-- normal_forms - DNF, CNF conversion
+-- iff, implies, xor, nand, nor
+-- quantifiers - ?, ?
+-- satisfiability - SAT solver (basic)
+-- tautology_check - Check if expression is tautology
4. MISSING: Information Theory
text
math/information_theory
+-- entropy - Shannon entropy
+-- joint_entropy - H(X,Y)
+-- conditional_entropy - H(X|Y)
+-- mutual_information - I(X;Y)
+-- kl_divergence - KL divergence
+-- js_divergence - Jensen-Shannon divergence
+-- cross_entropy - Cross entropy
+-- perplexity - Perplexity
+-- self_information - log(1/p)
+-- entropy_rate - Entropy rate
+-- channel_capacity - Shannon-Hartley
+-- data_compression - Information theoretic bounds
+-- huffman_coding - Huffman encoding/decoding
+-- arithmetic_coding - Arithmetic encoding/decoding
5. MISSING: Cryptography (but you have crypto/ module already)
text
(Already in crypto/ - skip)
6. MISSING: Chaos Theory
text
math/chaos
+-- logistic_map - x??1 = r*x?*(1-x?)
+-- lorenz_system - Lorenz attractor
+-- rossler_system - Rössler attractor
+-- henon_map - Hénon map
+-- bifurcation_diagram - Bifurcation diagram
+-- lyapunov_exponent - Lyapunov exponent
+-- strange_attractor - Strange attractor detection
+-- fractal_dimension - Hausdorff dimension
+-- mandelbrot_set - Mandelbrot set
+-- julia_set - Julia set
+-- burning_ship - Burning Ship fractal
+-- newton_fractal - Newton fractal
+-- tent_map - Tent map
7. MISSING: Game Theory
text
math/game_theory
+-- NormalFormGame - Matrix game
+-- ExtensiveFormGame - Tree game
+-- nash_equilibrium - Nash equilibrium solver
+-- minimax - Minimax algorithm
+-- alpha_beta - Alpha-beta pruning
+-- dominant_strategy - Dominant strategy detection
+-- pareto_optimal - Pareto optimality
+-- cooperative_game - Coalition games
+-- shapley_value - Shapley value
+-- core - Core of cooperative game
+-- auction - Auction theory
+-- mechanism_design - Mechanism design
+-- evolutionary_game - Evolutionary game theory
+-- replicator_dynamics - Replicator dynamics
+-- prisoner_dilemma - Classic game theory examples
8. MISSING: Queueing Theory
text
math/queueing
+-- m_m_1 - M/M/1 queue (arrival/service rates)
+-- m_m_c - M/M/c queue
+-- m_g_1 - M/G/1 queue
+-- g_g_1 - G/G/1 queue
+-- erlang_b - Erlang B formula
+-- erlang_c - Erlang C formula
+-- little_law - Little's Law (L = ?W)
+-- utilization - Server utilization
+-- queue_length - Expected queue length
+-- waiting_time - Expected waiting time
+-- loss_probability - Loss probability
+-- blocking_probability - Blocking probability
+-- heavy_traffic - Heavy traffic approximation
+-- diffusion_approx - Diffusion approximation
9. MISSING: Control Theory
text
math/control_theory
+-- pid_controller - PID controller
+-- transfer_function - Transfer function
+-- state_space - State-space representation
+-- observability - Observability check
+-- controllability - Controllability check
+-- stability - Stability analysis (Routh-Hurwitz)
+-- nyquist_plot - Nyquist plot
+-- bode_plot - Bode plot
+-- root_locus - Root locus
+-- pole_placement - Pole placement
+-- lqr - Linear Quadratic Regulator
+-- lqg - Linear Quadratic Gaussian
+-- kalman_filter - Kalman filter
+-- h_infinity - H-infinity control
+-- robust_control - Robust control
10. MISSING: Machine Learning Primitives
text
math/machine_learning
+-- activation - Activation functions (sigmoid, tanh, relu, gelu, swish)
+-- loss - Loss functions (MSE, MAE, Huber, CrossEntropy, Hinge)
+-- metrics - Metrics (accuracy, precision, recall, f1, auc)
+-- regularization - L1, L2, ElasticNet
+-- normalization - BatchNorm, LayerNorm, GroupNorm
+-- dropout - Dropout
+-- kernel - Kernel functions (RBF, polynomial, sigmoid)
+-- distance - Distance metrics (Euclidean, Manhattan, Cosine, Minkowski)
+-- similarity - Similarity metrics (Cosine, Jaccard, Dice)
+-- embedding - Embedding operations
11. MISSING: Topology
text
math/topology
+-- open_set - Open set operations
+-- closed_set - Closed set operations
+-- compactness - Compactness check
+-- connectedness - Connectedness check
+-- continuity - Continuity check
+-- homeomorphism - Homeomorphism check
+-- topological_space - Topological space operations
+-- metric_space - Metric space operations
+-- ball - Open/closed ball
+-- interior - Interior of set
+-- closure - Closure of set
+-- boundary - Boundary of set
+-- limit_point - Limit points
+-- neighborhood - Neighborhood operations
12. MISSING: Number Systems
text
math/number_systems
+-- binary - Binary operations
+-- octal - Octal operations
+-- decimal - Decimal operations
+-- hexadecimal - Hex operations
+-- base_n - Base-N conversion
+-- roman - Roman numerals
+-- mayan - Mayan numerals
+-- chinese - Chinese numerals
+-- japanese - Japanese numerals
+-- egyptian - Egyptian fractions
+-- babylonian - Babylonian numerals
+-- greek - Greek numerals
+-- fraction - Fractions (proper, improper, mixed)
+-- continued_fraction - Continued fractions
+-- surds - Surds (v2, v3, etc.)
+-- complex - Complex numbers (already have)
+-- quaternion - Quaternions (already have)
+-- octonion - Octonions
+-- sedenion - Sedenions
13. MISSING: Mathematical Logic
text
math/mathematical_logic
+-- propositional - Propositional logic
+-- predicate - Predicate logic
+-- first_order - First-order logic
+-- modal - Modal logic
+-- temporal - Temporal logic
+-- fuzzy - Fuzzy logic
+-- intuitionistic - Intuitionistic logic
+-- linear - Linear logic
+-- relevance - Relevance logic
+-- provability - Provability logic
+-- model_theory - Model theory
+-- proof_theory - Proof theory
+-- set_theory - Axiomatic set theory
+-- type_theory - Type theory
+-- category_theory - Category theory
14. MISSING: Approximation Theory
text
math/approximation
+-- interpolation - Interpolation methods
+-- extrapolation - Extrapolation methods
+-- polynomial_approx - Polynomial approximation
+-- rational_approx - Rational approximation
+-- trigonometric_approx - Trigonometric approximation
+-- exponential_approx - Exponential approximation
+-- chebyshev_approx - Chebyshev approximation
+-- least_squares - Least squares approximation
+-- minimax - Minimax approximation
+-- pade_approx - Padé approximation
+-- remez - Remez algorithm
+-- spline_approx - Spline approximation
+-- best_approx - Best approximation
15. MISSING: Fuzzy Mathematics
text
math/fuzzy
+-- fuzzy_set - Fuzzy set operations
+-- membership - Membership functions
+-- fuzzy_logic - Fuzzy logic operations
+-- fuzzy_intersection - Fuzzy intersection
+-- fuzzy_union - Fuzzy union
+-- fuzzy_complement - Fuzzy complement
+-- fuzzy_relation - Fuzzy relations
+-- fuzzy_composition - Fuzzy composition
+-- defuzzification - Defuzzification methods
+-- fuzzy_inference - Fuzzy inference
+-- mamdani - Mamdani inference
+-- sugeno - Sugeno inference
+-- fuzzy_control - Fuzzy control
+-- fuzzy_decision - Fuzzy decision making
16. MISSING: Mathematical Physics
text
math/mathematical_physics
+-- hamiltonian - Hamiltonian mechanics
+-- lagrangian - Lagrangian mechanics
+-- quantum_operators - Quantum operators
+-- pauli_matrices - Pauli matrices
+-- gamma_matrices - Dirac gamma matrices
+-- tensor_calculus - Tensor calculus
+-- differential_geometry - Differential geometry
+-- riemannian - Riemannian geometry
+-- symplectic - Symplectic geometry
+-- lie_algebra - Lie algebra
+-- lie_group - Lie groups
+-- representation - Representation theory
+-- greens_function - Green's functions
+-- propagator - Quantum propagators
+-- path_integral - Path integrals
17. MISSING: Operations Research
text
math/operations_research
+-- linear_programming - LP (already have)
+-- integer_programming - ILP (already have)
+-- dynamic_programming - Dynamic programming
+-- inventory - Inventory management
+-- queuing - Queuing theory (above)
+-- scheduling - Job scheduling
+-- routing - Vehicle routing
+-- assignment - Assignment problem
+-- transportation - Transportation problem
+-- transshipment - Transshipment problem
+-- network_flow - Network flow (already in graph)
+-- facility_location - Facility location
+-- supply_chain - Supply chain optimization
+-- revenue_management - Revenue management
+-- stochastic_optimization - Stochastic optimization
18. MISSING: Mathematical Biology
text
math/mathematical_biology
+-- population_growth - Population growth models
+-- logistic_growth - Logistic growth
+-- lotka_volterra - Predator-prey model
+-- epidemiological - SIR, SEIR models
+-- chemotherapy - Chemotherapy models
+-- genetics - Genetic algorithms
+-- neural_networks - Neural network math
+-- ecology - Ecological models
+-- epidemiology - Disease spread
+-- immunology - Immune system models
+-- neuroscience - Neuron models
+-- evolution - Evolutionary dynamics
19. MISSING: Mathematical Economics
text
math/mathematical_economics
+-- utility - Utility functions
+-- production - Production functions (Cobb-Douglas)
+-- demand - Demand functions
+-- supply - Supply functions
+-- equilibrium - Market equilibrium
+-- elasticity - Elasticity calculations
+-- marginal - Marginal analysis
+-- consumer_theory - Consumer theory
+-- producer_theory - Producer theory
+-- general_equilibrium - General equilibrium
+-- game_theory - Game theory (above)
+-- auction_theory - Auction theory
+-- mechanism_design - Mechanism design
20. MISSING: Geometry (Extended)
text
math/geometry_extended
+-- projective_geometry - Projective geometry
+-- hyperbolic_geometry - Hyperbolic geometry
+-- elliptic_geometry - Elliptic geometry
+-- non_euclidean - Non-Euclidean geometry
+-- inversive_geometry - Inversive geometry
+-- incidence_geometry - Incidence geometry
+-- finite_geometry - Finite geometries
+-- algebraic_geometry - Algebraic geometry
+-- differential_geometry - Differential geometry
+-- riemannian_geometry - Riemannian geometry
+-- convex_geometry - Convex geometry
+-- discrete_geometry - Discrete geometry
+-- computational_geometry - Computational geometry
+-- voronoi - Voronoi diagrams
+-- delaunay - Delaunay triangulation
+-- bezier - Bézier curves
+-- b_spline - B-splines
+-- nurbs - NURBS
+-- subdivision - Subdivision surfaces
+-- mesh_processing - Mesh processing
21. MISSING: Algebra (Extended)
text
math/algebra_extended
+-- group_theory - Group theory
+-- ring_theory - Ring theory
+-- field_theory - Field theory
+-- module_theory - Module theory
+-- vector_spaces - Vector spaces (already have)
+-- linear_algebra - Linear algebra (already have)
+-- galois_theory - Galois theory
+-- algebraic_number - Algebraic number theory
+-- algebraic_geometry - Algebraic geometry
+-- commutative_algebra - Commutative algebra
+-- homological_algebra - Homological algebra
+-- category_theory - Category theory
+-- universal_algebra - Universal algebra
+-- representation_theory - Representation theory
+-- lie_algebra - Lie algebra
+-- clifford_algebra - Clifford algebra
?? SUMMARY: What We Have vs What We're Missing
Category	Status	Modules
Basic Math	? Complete	core, constants, arithmetic, roots, exponential, rounding, decompose
Trigonometry	? Complete	trigonometry, inverse_trig, hyperbolic, angular
Bitwise	? Complete	bitwise, rotation, endianness, bitfield
Number Theory	? Complete	number_theory, factorial, modular
Complex Numbers	? Complete	complex
Linear Algebra	? Complete	vector, matrix, quaternion, linear
Geometry	?? Partial	geometry_2d, geometry_3d (missing extended geometry)
Statistics	? Complete	statistics, probability
Calculus	? Complete	calculus, differential_equations
Special Functions	? Complete	special
Discrete Math	? Complete	combinatorics, graph_theory
Precision	? Complete	precision_integer, precision_float, precision_rational
Numerical Methods	? Complete	numerical
Signal Processing	? Complete	signal
Optimization	? Complete	optimization
Finance	? Complete	finance
Missing:
Category	Priority	Modules Needed
Set Theory	Medium	math/set_theory
Logic	Medium	math/logic
Information Theory	High	math/information_theory
Chaos Theory	Low	math/chaos
Game Theory	Medium	math/game_theory
Queueing Theory	Medium	math/queueing
Control Theory	High	math/control_theory
ML Primitives	High	math/machine_learning
Topology	Low	math/topology
Number Systems	Low	math/number_systems
Mathematical Logic	Low	math/mathematical_logic
Approximation	Medium	math/approximation
Fuzzy Math	Low	math/fuzzy
Math Physics	Low	math/mathematical_physics
Operations Research	Medium	math/operations_research
Math Biology	Low	math/mathematical_biology
Math Economics	Low	math/mathematical_economics
Extended Geometry	Medium	math/geometry_extended
Extended Algebra	Low	math/algebra_extended
?? RECOMMENDATION: What to Add Next
Priority 1 (Add Now - Most Used)
text
math/information_theory - Entropy, KL divergence, mutual information
math/machine_learning - Activation, loss, metrics, normalization
math/control_theory - PID, transfer functions, stability
math/set_theory - Set operations
math/approximation - Interpolation, approximation methods
Priority 2 (Add Soon)
text
math/game_theory - Nash, minimax, Shapley value
math/queueing - M/M/1, Erlang, Little's Law
math/operations_research - Dynamic programming, scheduling
math/geometry_extended - Voronoi, Delaunay, Bézier curves
Priority 3 (Add Later - Niche)
text
math/chaos - Fractals, attractors, Lyapunov
math/topology - Open/closed sets, continuity
math/number_systems - Roman, Mayan, base conversion
math/mathematical_logic - Propositional, predicate logic
math/fuzzy - Fuzzy sets, fuzzy logic
math/mathematical_physics - Hamiltonian, quantum operators
math/mathematical_biology - Population models, SIR
math/mathematical_economics - Utility, production functions
math/algebra_extended - Group theory, ring theory
?? Updated Module List
text
math/
+-- core/                      ? Foundation
+-- constants/                 ? Constants
+-- precision/                 ? Type precision
+-- interfaces/                ? Traits
+-- arithmetic/                ? Arithmetic
+-- roots/                     ? Roots
+-- exponential/               ? Exponential
+-- rounding/                  ? Rounding
+-- decompose/                 ? Decompose
+-- trigonometry/              ? Trig
+-- inverse_trig/              ? Inverse trig
+-- hyperbolic/                ? Hyperbolic
+-- angular/                   ? Angular conversion
+-- trig_constants/            ? Trig constants
+-- bitwise/                   ? Bitwise
+-- rotation/                  ? Rotation
+-- endianness/                ? Endianness
+-- bitfield/                  ? Bitfield
+-- number_theory/             ? Number theory
+-- factorial/                 ? Factorial
+-- modular/                   ? Modular
+-- complex/                   ? Complex
+-- vector/                    ? Vector
+-- matrix/                    ? Matrix
+-- quaternion/                ? Quaternion
+-- linear/                    ? Linear algebra
+-- geometry_2d/               ? 2D geometry
+-- geometry_3d/               ? 3D geometry
+-- statistics/                ? Statistics
+-- probability/               ? Probability
+-- calculus/                  ? Calculus
+-- differential_equations/    ? ODE/PDE
+-- special/                   ? Special functions
+-- combinatorics/             ? Combinatorics
+-- graph_theory/              ? Graph theory
+-- precision_integer/         ? BigInt
+-- precision_float/           ? BigFloat
+-- precision_rational/        ? BigRat
+-- numerical/                 ? Numerical methods
+-- signal/                    ? Signal processing
+-- optimization/              ? Optimization
+-- finance/                   ? Finance
¦
+-- set_theory/                ?? Add
+-- logic/                     ?? Add
+-- information_theory/        ?? Add
+-- chaos/                     ?? Add
+-- game_theory/               ?? Add
+-- queueing/                  ?? Add
+-- control_theory/            ?? Add
+-- machine_learning/          ?? Add
+-- topology/                  ?? Add
+-- number_systems/            ?? Add
+-- mathematical_logic/        ?? Add
+-- approximation/             ?? Add
+-- fuzzy/                     ?? Add
+-- mathematical_physics/      ?? Add
+-- operations_research/       ?? Add
+-- mathematical_biology/      ?? Add
+-- mathematical_economics/    ?? Add
+-- geometry_extended/         ?? Add
+-- algebra_extended/          ?? Add
Final Answer: Are We Missing Anything?
Yes, about 19 modules. But the core that 95% of developers need is already covered. The missing modules are for specialized domains:

Domain	Users
Information Theory	Data scientists, ML engineers
Machine Learning	AI/ML developers
Control Theory	Robotics, aerospace, engineers
Game Theory	Economists, AI researchers
Queueing Theory	Network engineers, operations
Recommendation: Keep the core as is. Add the missing modules as packages (@xiom/math-*) rather than bloating the stdlib. This keeps stdlib lean while supporting specialized needs.

---

## 13. WISH-LIST AUDIT (2026-08-11) — HAVE / GAP-stdlib / GAP-package

> Full pass over the flat wish-list (HASHING / COLLECTIONS / STRING / CONVERSION /
> NETWORK / FILE FORMATS / OS INTERACTION). Rules: **STDLIB** = zero external deps
> (pure XIOM; SIMD/C-FFI/ASM only for perf with pure fallback + runtime dispatch);
> **PACKAGE** = needs an external library/protocol peer; dedupe aggressively.
> Verified against the live tree on 2026-08-11 (64+ modules, ~2,215 pub fns).
> GAP-stdlib items marked **(P0/P1/P2)** are queued implementation work; P0 items
> landed in the same session (see §10 status + docs/stdlib_session.md).

### 13.1 HASHING (16 wish-items ? 13 HAVE, 3 GAP-stdlib)

| Wish item | Status | Home (module.fn) / note |
|-----------|--------|--------------------------|
| hash/fnv (32/64/128) | **HAVE** (128 GAP P2) | `hash.fnv1a32`, `fnv1a64`, `fnv1_64`, `fnv1_32`; fnv1a_128/fnv1_128 ? GAP |
| hash/murmur (2, 3: 32/128) | **HAVE** | `hash.murmur3_32`, `hash.murmur.murmur3_128`, `hash.murmur.murmur2_64` |
| hash/city (64/128) | **HAVE** | `hash.city.city64`, `city64_with_seed`, `city128` (CityHash v1.1; 256-bit does not exist upstream) |
| hash/xxhash (32/64/128, XXH3) | **GAP-stdlib P0** | `hash.xxhash32/64`, `hash.xxhash.xxh32/xxh64`; **XXH3-64 + XXH128 missing ? landed this session** |
| hash/siphash (2-4, 1-3) | **GAP-stdlib P0** | `hash.sip_hash` is a misnamed DJB2 wrapper — **real SipHash-2-4/1-3 landed this session** (hash/siphash.xi) |
| hash/highway (64/128/256) | **GAP-stdlib P1** | pure XIOM port; large |
| hash/spooky (128) | **GAP-stdlib P1** | pure XIOM port; large |
| hash/t1ha | **GAP-stdlib P2** | fast non-crypto; pure |
| hash/metro (64/128) | **GAP-stdlib P2** | pure |
| hash/farm | **GAP-stdlib P2** | city-derived; pure |
| hash/jenkins (lookup3) | **HAVE** | `hash.jenkins.jenkins_lookup3` |
| hash/superfast | **GAP-stdlib P0** | trivial Paul Hsieh — **landed this session** (hash/superfast.xi) |
| hash/crc (32/64 hw-accel) | **HAVE** | `hash.crc32_ieee`, `hash.crc.crc32c`, `crc64_ecma`, `crc64_we`, `crc16_ccitt`; hw-accel = §7 asm track |
| hash/adler (32) | **GAP-stdlib P0** | **landed this session** (hash/crc.xi) |
| hash/checksum (BSD/SysV/Internet) | **HAVE** | `hash.crc.checksum_bsd/sysv/internet` |

### 13.2 COLLECTIONS (56 wish-items ? 30 HAVE, 26 GAP-stdlib, 0 PACKAGE)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| list / vector / stack / queue | **HAVE** | `collections.LinkedList/Vec/Stack/Queue` |
| ring (circular) | **GAP-stdlib P0** | spsc ring **landed this session** (collect/queue.xi `SpscRing`) |
| map (open addressing) | **HAVE** | `collections.Map` |
| mapch (chaining) | **HAVE** | `collections.HashMap` |
| treemap / treeset | **HAVE** | `collections.BTreeMap/BTreeSet` |
| tree / avl | **HAVE** | `collect.tree.Bst/Avl` |
| rbtree | **GAP-stdlib P1** | pure; AVL covers balanced needs (dedupe candidate) |
| bheap / fheap / priority | **HAVE** | `collect.heap.PHeap`, `FibHeap` |
| pairing heap | **GAP-stdlib P2** | pure; dedupe with PHeap |
| deque | **HAVE** | `collect.queue.Deque` + `collections.VecDeque` |
| skiplist | **GAP-stdlib P0** | **landed this session** (collect/skiplist.xi) |
| trie / radix | **GAP-stdlib P0** | **trie landed this session** (collect/trie.xi); radix = trie variant, dedupe |
| bitmap | **HAVE** | `bits.bit_*`, `num` bit ops |
| bloom | **HAVE** | `collect.hash.BloomFilter` |
| cuckoo | **GAP-stdlib P0** | **landed this session** (collect/cuckoo.xi) |
| hashset | **HAVE** | `collections.Set` |
| linkedhash | **HAVE** | `collect.hash.LhMap` |
| lru / lfu | **HAVE** | `collect.cache.LruCache/LfuCache` |
| tinylfu | **GAP-stdlib P2** | count-min sketch + LFU; pure |
| arc (Adaptive Replacement) | **GAP-stdlib P0** | **landed this session** (collect/cache.xi `ArcCache`) |
| btree / btreeplus | **HAVE** (B+Tree GAP P2) | `collections.BTreeMap/BTreeSet` |
| segment tree | **GAP-stdlib P2** | pure; fenwick covers prefix sums |
| fenwick | **GAP-stdlib P0** | **landed this session** (collect/fenwick.xi) |
| sparse / dense sets | **GAP-stdlib P2** | pure; dedupe with Set |
| hasharray (HAMT) | **GAP-stdlib P2** | pure; low |
| immutable / persistent | **GAP-stdlib P2** | pure (persistent via copy-on-write); low |
| concurrent collections | **GAP-stdlib P0** | **spsc lock-free ring landed this session**; mpmc/mpsc need atomic-CAS ring or a Mutex setter (see note) |
| interval / range trees | **GAP-stdlib P2** | pure; med |
| kdtree / octree / quadtree / spatial | **GAP-stdlib P1** | pure; geom-adjacent |
| graph / dag | **HAVE** | `collect.graph.Graph` (adjacency, BFS/DFS/cycles) |
| unionfind | **HAVE** | `collect.graph.uf_*` |
| intmap / stringmap | **GAP-stdlib P2** | LhMap covers insertion-order needs; perf variants low |
| objectpool | **GAP-stdlib P0** | **landed this session** (collect/objectpool.xi) |
| threadpool | **GAP-stdlib P1** | `thread`+`sync` exist; needs a work-queue executor |
| workqueue | **HAVE** | `collect.queue.WorkQueue` |
| blocking queue | **GAP-stdlib P1** | `sync.Semaphore`/`Condvar` + WorkQueue |
| mpmc / mpsc / spmc / spsc | **HAVE-partial** | mpsc cooperative: `async.Channel`; **spsc lock-free: landed this session**; mpmc: needs Mutex mutation API (documented limitation, see module comment) |

### 13.3 STRING (72 wish-items ? 47 HAVE, 25 GAP-stdlib, 0 PACKAGE)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| compare / search / replace / trim / split / join / case / strip / repeat / pad / slice | **HAVE** | `string.*` + `cmp.*` (dedupe: compare?cmp, search?index_of, strip?trim) |
| escape / unescape | **HAVE** | `string.str_escape/unescape` (URL variants in `encoding.url_encode/percent_encode`) |
| format (sprintf-style) | **GAP-stdlib P0** | `fmt.format1..9` positional; **printf-style `fmt.sprintf` landed this session** |
| printf / scanf | **GAP-stdlib P0** | **landed this session**: `fmt.sprintf1..3`, `fmt.sscanf` + typed wrappers |
| template | **GAP-stdlib P2** | format1..9 cover positional; named-placeholder templates low |
| glob / regex | **HAVE** | `misc.glob_match`, `regex.*` |
| levenshtein / damerau / jaro(-winkler) / soundex / metaphone / ngram / ngram_similarity / cosine / lcs / editdistance / hamming | **HAVE** | `text.similarity.*` + `misc.*` |
| jaccard | **GAP-stdlib P0** | **landed this session** (`text.similarity.jaccard_similarity`) |
| lcp / lcsuffix | **GAP-stdlib P0** | **landed this session** (`text.similarity.longest_common_prefix/suffix`) |
| tr / rot / caesar / atbash | **GAP-stdlib P0** | **landed this session** (`string.str_translate/rot13/rot47/caesar/atbash`) |
| shuffle / rotate / permute / combine / interleave / chunk | **GAP-stdlib P2** | pure; shuffle needs rand; low-med |
| reverse | **HAVE** | `string.str_reverse`, `misc.reverse_str` |
| wrap / indent / align / truncate | **HAVE** | `fmt.format_wrap/indent/align_left/align_right`, `string.str_center`, `misc.truncate` |
| abbreviate / obfuscate | **GAP-stdlib P0** | **landed this session** (`string.str_abbreviate/obfuscate`) |
| Unicode (normalize/collate/casefold/titlecase/segment/wordbreak/ea_width/emoji/script/block/category/bidi/mirror/nfc/nfd/nfkc/nfkd/maps) | **GAP-stdlib P1** | pure but table-heavy (utf8 module is the foundation); ICU-class collation = **PACKAGE** (xiom-icu placeholder) |

### 13.4 CONVERSION (82 wish-items ? 55 HAVE, 22 GAP-stdlib, 5 GAP-package)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| int/float/toint/tofloat/tostring/parse/itos/ftos/atoi/itoa | **HAVE** | `convert.*`, `num.parse_int(_radix)/parse_float`, `string.str_to_int/float` |
| fromstr/tryfrom/into/asref/asmut/from (traits) | **HAVE** (N/A) | language traits — dedupe to `convert.*` + `core` helpers |
| bytes / endian / network order / swap | **HAVE** | `bits.pack_*/unpack_*`, `num.to_be/to_le/from_be/from_le`, `bits.byte_swap*` |
| saturating / wrapping / overflow / checked / exact / lossy / roundtrip | **HAVE** | `num.saturating_*/wrapping_*/checked_*`; roundtrip = to_str/parse pairs |
| cstring / wstring / utf8 / utf16 / utf32 | **HAVE** (utf16/32 GAP P2) | `ffi.Str.from_cstring`, `mem`, `utf8.*`, `encoding.utf8_*` |
| base64 / base32 / base16 / base64url | **HAVE** | `encoding.*` |
| base58 / base62 / ascii85 | **HAVE** | `num.convert.to_base58/from_base58/to_base62/from_base62/to_ascii85/from_ascii85` |
| uuencode / xxencode / quoted-printable | **GAP-stdlib P2** | trivial pure encodings |
| punycode / idna | **GAP-stdlib P1** | pure but fiddly (IDNA tables) |
| percent | **HAVE** | `encoding.url_encode/percent_encode/url_decode/percent_decode` |
| html / xml escaping | **GAP-stdlib P2** | entity tables; low (str_escape is C-style) |
| json escaping | **HAVE** | `serialize` (JSON internal escaping) |
| csv / tsv escaping | **GAP-stdlib P2** | trivial |
| yaml / toml escaping | **GAP-package** | xiom-yaml/xiom-toml placeholders |
| regex / glob escaping | **GAP-stdlib P2** | low |
| shell / cmd escaping | **GAP-stdlib P2** | pure; med |
| printf escaping (%% etc.) | **HAVE** | **fmt.sprintf landed this session** |
| strftime / strptime | **GAP-stdlib P0** | **landed this session** (`time.strftime/strptime`) |
| duration / date / datetime / timestamp | **HAVE** | `time.*` (Duration/Date/DateTime/ISO 8601) |
| uuid / mac / ip / url / uri | **HAVE** | `rand.uuid_v4`, `net.is_valid_ipv4`, `net.parse_url/url_parse` |
| email / phone / creditcard / iban / swift validation | **GAP-stdlib P1** | pure validation (email/iban useful); phone/creditcard P2 |

### 13.5 NETWORK (307 wish-items ? ~25 HAVE, ~10 GAP-stdlib, ~272 GAP-package)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| socket / tcp / udp / address | **HAVE** | `net.tcp_connect/tcp_listen/udp_bind`, `TcpStream/TcpListener/UdpSocket` |
| dns / host / ip / port / protocol | **HAVE** | `net.dns_*`, `resolve_host`, `dns_well_known_port`, `is_valid_ipv4` |
| url / uri / query / header / basic/bearer auth / http_status_text | **HAVE** | `net.url_parse/url_query_*/http_header_*/basic_auth_header/bearer_auth_header` |
| http (get/post) | **HAVE** | `net.http_get/http_post/http_status` |
| sse | **HAVE-partial** | `net.sse_format_*` (wire formatting); full SSE client P2 |
| websocket / jsonrpc / rest | **HAVE-partial** | jsonrpc_request/success/error builders exist; websocket framing GAP-stdlib P1; rest = http + json |
| cookie / multipart / mime / charset / etag / accept-* / link | **GAP-stdlib P2** | pure parsing; low-med |
| jwt | **GAP-stdlib P1** | pure composition over crypto (HMAC/SHA) |
| ntp / sntp | **GAP-stdlib P2** | UDP datagram client; pure-ish |
| icmp (ping) / traceroute | **GAP-stdlib P2** | raw sockets via FFI; low |
| unix sockets / pipe | **HAVE-partial** | `os.create_pipe/Pipe`; AF_UNIX GAP-stdlib P2 |
| everything else (tls/ssl/ssh/ftp/smtp/pop3/imap/irc/xmpp/mqtt/amqp/kafka/redis/mongo/postgres/mysql/sqlite/grpc/graphql/soap/thrift/zeromq/dbus/ldap/kerberos/ntp/dhcp/dns-sd/cloud SDKs/VPN/kernel networking/hardware protocols) | **GAP-package** | external protocol peers / C libs; placeholders exist (xiom-ftp, xiom-smtp, xiom-mqtt, xiom-tls, xiom-ldap, ...) |

### 13.6 FILE FORMATS (~1,700 wish-items ? ~20 HAVE, ~25 GAP-stdlib, ~30 GAP-package, ~1,600 noise/dedupe)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| hex / octal / binary dump, hexdump | **HAVE** | `format.dump.hexdump/octal_dump/binary_dump`, `fmt.format_hexdump` |
| bytes human-readable | **HAVE** | `format.number.fmt_bytes`, `misc.human_size` |
| table / columns / wrap / indent / align / join / repeat / line | **HAVE** | `fmt.format_table/columns/wrap/indent/align_left/align_right/join/repeat/line` |
| number formatting (fixed/percent/separators/duration/ordinal) | **HAVE** | `format.number.fmt_float_fixed/fmt_percent/fmt_int_with_separators/fmt_duration_ms/fmt_ordinal` |
| json formatting | **HAVE** | `serialize` |
| progress / spinner / ansi / colors / box / border / list / toc | **GAP-stdlib P2** | pure text; terminal control via `os` later |
| markdown / html / textile / rtf / latex / troff / man | **GAP-package** | xiom-markdown/xiom-html placeholders |
| xml / yaml / toml / csv / tsv | **GAP-package** | xiom-xml/yaml/toml/csv placeholders |
| diagrams (flowchart/uml/mermaid/gantt/...) | **GAP-package** | rendering/DSL tools |
| geo formats (geojson/kml/gpx/wkt/wkb/geohash/utm/...) | **GAP-package** | xiom-geo placeholders (mostly) |
| statistics/regression/metrics/ML formatting (~900 items) | **GAP-stdlib P2** | dedupe ? `stats.*` + `format.number.*`; most are number-formatting variants |
| typography (fonts/kerning/hyphenation/bidi/CJK) | **GAP-package** | ICU-class |
| audio/video metadata (id3/mp4/exif/...) | **GAP-package** | binary container parsers |
| everything else | **noise** | dedupe into the rows above |

### 13.7 OS INTERACTION (~310 wish-items ? ~60 HAVE, ~40 GAP-stdlib, ~210 GAP-package)

| Wish item | Status | Home / note |
|-----------|--------|-------------|
| pipe / fd / stat / perm / rename / remove / temp / cwd / chdir / mkdir / walk / realpath | **HAVE** | `os.*` (create_pipe/Pipe, walk_dir, env, disk_*), `io.*` (file ops), `path.*` |
| process (spawn/exec/wait/exit/signal) | **HAVE** | `process.spawn_command/wait/kill/is_running/exit`, `os.on_signal/raise_signal/ChildProcess` |
| watch (files/dirs) | **HAVE** | `os.FileWatcher/watch_file/watch_dir` |
| symlink / link / readlink / owner (chown) / mmap / dup / select | **GAP-stdlib P2** | FFI syscalls; med-low |
| eol / bom / utf8bom / binary-text detection / magic / mime | **GAP-stdlib P2** | pure + FFI; low-med |
| truncate / fallocate / seek / tell / read_at / write_at / pread / pwrite / readv / writev / sendfile / splice | **GAP-stdlib P2** | FFI; io.xi covers the basic read/write/seek set |
| epoll / kqueue / iocp / io_uring / eventfd / timerfd / signalfd / poll / select | **GAP-stdlib P2** | FFI; async executor domain (compiler session) |
| fork / waitpid / popen / posix_spawn | **GAP-stdlib P2** | FFI |
| tty / pty / termios / terminal control | **GAP-stdlib P2** | FFI |
| errno / strerror / backtrace / demangle | **GAP-stdlib P2** | FFI; `debug` module is the home |
| dlopen / dlsym / dlclose | **HAVE** | `ffi.*` |
| libm / libc | **HAVE** | `math.*` (libm), `mem.*`, `string.*`, `ffi.*` |
| openssl / libssl / zlib / bz2 / lzma / zstd / lz4 / snappy / iconv / xml2 / curl / git2 / ssh2 / pcap | **GAP-package** | external C libs (xiom-openssl, xiom-zstd, ...) |
| graphics (vulkan/dx/metal/gl), media frameworks, ML frameworks, cloud SDKs, VPN/wireless vendors, registry/plist | **GAP-package** | external deps; xiom-vulkan etc. placeholders |

### 13.8 Dedup map (aggressive, per session rules)

`str/compare`?`cmp` · `str/search`?`string.index_of` · `str/strip`?`str_trim` · `conv/base64`?`encoding` ·
`conv/base16`?`encoding.hex_*` · `collect/vector`?`collections.Vec` · `collect/stack/queue/ring`?`collections.Stack/Queue`+`collect.queue` ·
`hash/crc`?`hash.crc32_ieee`+`hash.crc` · `str/regex`?`regex` · `conv/uuid`?`rand.uuid_v4` ·
`conv/endian`?`bits.pack/unpack`+`num.to_be/to_le` · `conv/swap`?`bits.byte_swap*` · `conv/saturating|wrapping|checked`?`num.*` ·
`conv/strftime`?`time.strftime` (landed) · `format/indent|wrap|align`?`fmt.*` · `format/hex`?`format.dump` ·
`os/memcpy|memcmp`?`mem` · `os/str*`?`string` · `collect/radix`?`collect/trie` · `collect/sparse|dense`?`collections.Set` ·
`format/*stat*`?`stats` · `net/jsonrpc`?`net.jsonrpc_*` · `str/metaphone|soundex|jaro|ngram|cosine`?`text.similarity`

### 13.9 Generics policy (audited 2026-08-11 — math family, num, bits, geom, complex)

Verified against the live tree. The policy is **specialize-by-default, generic-where-semantic**:

| Area | Pattern | Verdict |
|------|---------|---------|
| `math` flat (52 fns: sqrt/trig/exp/log/…) | Float64-specialized | **KEEP** — native f64 ABI, no boxing, libm FFI (BUG 11 fixed) |
| `math.tower` (folder, 11 fns; renamed from math.core 2026-08-11) | generic `[T: Num]` / `[T: Real]` tower (lerp/average/sum/product/abs/clamp/min2/max2/negate/twice) | **KEEP** — the one place width-generic math lives |
| `num` (243 fns) | mixed: generic `min_value/max_value/epsilon[T: Bounded]`, `saturating_*/wrapping_*/checked_*[T: Bounded+Ord+Add…]` + Float64/Int specializations (f64_floor, parse_int…) | **KEEP** — generics exactly where widths matter; specializations where ABI/perf does |
| `geom` (186 fns) | Vec2/3/4, Quat, Matrix, transforms — Float64-specialized | **KEEP** — graphics math is f64 by contract; the §5.1 “generic geom” idea was dropped in practice and that is correct |
| `complex` (20 fns) | `Complex = { re: Float64; im: Float64; }` — NOT `Complex[T]` (the §5.1 plan) | **KEEP** — f64 specialization is the shipped reality; no callers need Complex[Float32] |
| `bits` (28 fns) | Int-specialized | **KEEP** — bit ops on i64 only |
| `stats` (23 fns) | Int-specialized (Vec[Int]) | **KEEP** — note: the compiler's Vec[Float64] element reads are broken (BUG 12), so float stats must use scaled-Int or fixed slots until fixed |
| `bigint`/`bigfloat` | arbitrary precision, concrete types | **KEEP** — no generics needed |

Rationale (documented for future contributors): (1) native scalar ABI (f64/i64) is
the compiler's fastest and most reliable path — generic containers of floats are
currently broken (BUG 12); (2) generic code is mono-instantiated per module, so
generics pay off only when multiple widths are actually instantiated (num's
checked/saturating/wrapping families are the canonical example); (3) new math
functions must be added Float64-specialized to `math` unless they are
width-agnostic numeric helpers, which go to `math.tower` with `[T: Num]`.


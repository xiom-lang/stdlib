# XIOM Standard Library & Package Architecture Plan

> **Status: PLANNING (v0.56.0, 2026-08-06)**
> **Owner:** Compiler team — `feat/architect`
> **Scope:** Categorize the 500-module proposal into **stdlib / packages / external projects**, document the current inventory, define the **non-breaking migration strategy** (CRITICAL: thousands of tests + 66-package ecosystem must not break).
> **Constraint:** This document only POINTS at locations — no folders are created here. Stdlib lives in `stdlib/`, packages in `packages/`, external projects at repo top level.

---

## 1. Rules & Principles (CRITICAL)

1. **Stdlib has NO external dependencies.** It may only use:
   - The language itself (pure XIOM), and
   - OS syscalls / C runtime via minimal FFI (`extern "C"`), plus the compiler substrate (LLVM/clang, NASM) which the language is built on — these are NOT counted as dependencies.
2. **Packages are built ON TOP of stdlib** and may depend on third-party C libraries (FFI bindings: OpenSSL, SQLite, SDL3, …) and on other packages.
3. **External projects are standalone products** (frameworks, engines, applications). They live at the **repo top level** (like `xiom-playground/`, `xiom-db/`, `xiom-benchmark-chaos/`) or as separate GitHub repos. They are NOT packages:
   - `xiom-pulse` → Node.js-like web application framework (external project)
   - `xiom-game-engine` → game engine bundling graphics/physics/audio bindings (external project)
4. **`xiom.*` namespace reservation:** stdlib owns the core `xiom.<name>` names. A package may claim `xiom.<name>` **only if** stdlib does not reserve it (see §4 reserved list). If a package module collides with a reserved name, it must move to `xiom.<package>.<feature>`.
5. **Nothing that ships today may break** — additive-only evolution, alias/shim deprecation windows, and an API-freeze test gate (§7.2).

---

## 2. Current State Inventory (scanned 2026-08-06 — read-only, nothing modified)

### 2.1 Stdlib — 51 modules in `stdlib/xiom/*.xi` (~1,300 public fns)

| Module | fns | Notes |
|--------|----:|-------|
| core | 72 | panic/assert, conversions, slice helpers (is_sorted/all/none/contains) |
| collections | 93 | Vec (+14 ops), Map, Set, VecDeque, BinaryHeap, LinkedList |
| math | 61 | sqrt/pow/abs/minmax, trig (Taylor), ln, log/exp, floor/ceil |
| io | 38 | print/println, read_line, read/write/append file, dir ops |
| os | 49 | cstr, platform, cpu_count, memory, env_set, cwd, perms, read_link |
| net | 18 | TCP/UDP sockets, http_get/post, parse_http_response, resolve_host |
| sync | 46 | Mutex, RwLock, guards, Condvar, AtomicInt, Once |
| thread | 17 | spawn, JoinHandle, Thread, sleep, yield, scope |
| async | 20 | Executor, spawn/at/step/run/block_on |
| crypto | 80 | SHA-256 internals + high-level hashes, AES, HMAC, entropy |
| sha | 38 | SHA-1/256/512 implementations |
| md5 | 11 | MD5 |
| aes | 28 | AES-128/256 block cipher |
| ed25519 | 3 | keygen/sign/verify |
| pbkdf | 2 | PBKDF2-HMAC-SHA256, HKDF |
| compress | 29 | gzip/deflate, RLE, crc32, adler32 |
| encoding | 27 | base64/base64url, hex (byte-level) |
| b64 | 4 | base64 (legacy thin wrapper, superset in `encoding`) |
| hex | 3 | hex encode/decode (legacy thin wrapper, superset in `encoding`) |
| serialize | 29 | JSON detect/validate/build, to_json/from_json, binary |
| string | 25 | str_len/concat/slice/contains/split/trim/upper/lower, format |
| char | 16 | is_*/to_* Unicode categories |
| convert | 8 | int/float/string/bool/char conversions |
| fmt | 15 | Formatter, to_str for Int/Float64/Bool/Str, format1-3 |
| num | 43 | min/max_value, gcd/lcm, bit ops (count_ones/zeros, rotate, reverse_bits), power-of-two |
| iter | 42 | range, Iterator[T] map/filter/enumerate/take/skip/chain |
| cmp | 15 | Ordering, min/max/clamp, min_by/max_by |
| hash | 11 | DefaultHasher, hash_value/hash, sip_hash, Int/Bool.hash |
| rand | 29 | StdRng (LCG), random(), distributions (uniform/normal/exponential) |
| random | 1 | thin alias (`random()` → rand) — consolidation candidate |
| time | 44 | Duration (full), now, sleep, timestamps |
| env | 19 | var/var_opt/set/remove, args/args_os, cwd, dirs |
| path | 27 | Path/PathBuf, parent/file_name/ext/stem, join, components |
| ffi | 32 | alloc/free/memcpy, SafePtr, extern helpers |
| ptr | 19 | null/null_mut/dangling, read/write (volatile) |
| alloc | 15 | Layout, GlobalAlloc, allocate/deallocate/grow |
| mem | 14 | swap/replace/take/drop, size_of/align_of |
| cell | 16 | Cell, RefCell, Ref/RefMut |
| rc | 17 | Rc, strong/weak counts, ptr_eq |
| regex | 23 | Regex, is_match/find/find_all/captures |
| reflect | 13 | TypeId, type_name/size/align, field count |
| contracts | 39 | contract registry, verify_invariants, check_invariant |
| error | 6 | Error chain, wrap_error, capture_backtrace |
| log | 25 | LogLevel, entry format (text/json), trace..error |
| simd | 26 | feature detect (SSE/AVX/NEON), Vec4f |
| stats | 8 | mean/median/stddev/percentile (Int) |
| bench | 5 | run_bench(_n), compare, black_box |
| runner | 8 | bench_run/report suite (benchmark reporting) |
| types | 2 | BenchConfig/BenchSuite (benchmark types) |
| test | 17 | assert/assert_eq/assert_ok/… test harness helpers |
| demo | 10 | example/demo helpers (not library-critical) |

**Consolidation candidates (internal duplicates — safe to merge with shims, §7.2):** `b64`+`hex` → `encoding`; `random` → `rand`; `bench`+`runner`+`types` → single `bench`; `md5`/`aes`/`ed25519`/`pbkdf`/`sha` → `crypto` (or stay as aliasing wrappers).

### 2.2 Packages — 66 dirs in `packages/` (all `deps: xiom-std`)

- **Pure-XIOM packages (no C dep):** xiom-json, xiom-http, xiom-net, xiom-rest, xiom-graphql, xiom-websocket, xiom-micro, xiom-realtime, xiom-algo, xiom-math, xiom-core, xiom-ffi, xiom-log, xiom-test, xiom-arrow
- **FFI-bound packages (wrap a C/3rd-party lib):** the rest — xiom-openssl, xiom-libsodium, xiom-sqlite, xiom-postgres/xiom-libpq, xiom-redis, xiom-kafka, xiom-zeromq, xiom-grpc, xiom-protobuf, xiom-wasmtime, xiom-libuv, xiom-zstd, xiom-lzfse, xiom-tensorflow, xiom-libtorch/xiom-torch, xiom-onnx, xiom-numpy, xiom-pandas, xiom-scipy, xiom-blas, xiom-openblas, xiom-cuda, xiom-eigen, xiom-opencv, xiom-ffmpeg, xiom-sql, xiom-dxc, xiom-moveit, xiom-ros2, xiom-gazebo, xiom-sensor, xiom-control, xiom-bullet, xiom-jolt, xiom-box2d, xiom-ozz, xiom-meshopt, xiom-assimp, xiom-raylib, xiom-glfw, xiom-sdl3, xiom-imgui, xiom-ui, xiom-miniaudio, xiom-openal, xiom-portaudio, xiom-phonon, xiom-vulkan, xiom-opengl, xiom-directx11, xiom-directx12, xiom-vma, xiom-stb

**Namespace reality (important):** packages currently declare `module xiom.json`, `module xiom.algo`, `module xiom.http.client`, `module xiom.net.demo` — they share the `xiom.*` namespace. This is fine **today** because stdlib does not ship `json.xi`, `algo.xi`, `http.xi`, `graphql.xi`, … but the reserved-name list (§4) must prevent future stdlib growth from colliding with these packages.

### 2.3 Test/ecosystem dependency surface (the no-break constraint)

- `tests/regression/` — **2,090** `.xi` files, **467** use `use` imports
- `examples/stdlib_smoke/` — **687** smoke files
- `tests/ecosystem/` — internal E2E fixtures (t1-t8, test_algo, eco_* suites)
- Stdlib modules imported by tests today: alloc, array, async, bench, cell, char, cmp, collections, compress, contracts, convert, core, crypto, encoding, env, error, ffi, fmt, hash, io, iter, log, math, mem, net, num, os, path, ptr, rand, rc, reflect, regex, serialize, simd, string, sync, test, thread, time
- Import forms in the wild: `use xiom.string;` (majority) and `use stdlib.xiom.string;` (35 files) — **both must keep working forever**.
- 66 packages in `packages/` all declare `deps: { "xiom-std": "0.1.0" }` and import `xiom.*` stdlib modules.

**Conclusion: stdlib module NAMES and PUBLIC FN SIGNATURES are frozen as a compatibility contract.** Any reorganization must be additive + shimmed.

---

## 3. Namespace & Naming Policy

| Scope | Namespace | Rule |
|-------|-----------|------|
| Stdlib | `xiom.<name>` (`stdlib/xiom/<name>.xi`) | Reserves §4 list. No external deps. |
| Package | `xiom.<name>` **or** `xiom.<pkg>.<feature>` (`packages/<pkg>/src/*.xi`) | May use `xiom.<name>` only if NOT in §4 reserved list. On collision → rename to `xiom.<pkg>.<feature>` + shim. |
| External project | own repo top-level (e.g. `xiom-pulse/`, `xiom-game-engine/`) | Depends on stdlib + packages like any user project. |

## 4. Stdlib Reserved Names (draft — extend as stdlib grows)

The following names are RESERVED by stdlib — a package may NOT ship a `module xiom.<name>` for any of them without prior coordination (rename to `xiom.<pkg>.<feature>` + shim instead):

`core, io, os, sys, env, args, path, file, dir, time, date, duration, thread, sync, mutex, atomic, condvar, rwlock, semaphore, once, process, signal, memory, alloc, mem, ptr, ffi, string, str, utf8, utf16, char, array, slice, range, iter, vector, list, stack, queue, ring, deque, priority, map, set, tree, btree, rbtree, avl, heap, bheap, fheap, filter, num, math, int, uint, float, const, abs, minmax, clamp, sqrt, pow, log, exp, trig, atrig, hyper, floor, modf, ldexp, bit, bits, rotate, endian, crc, adler, checksum, bitarray, hash, fnv, murmur, city, xxhash, siphash, highway, composite, rand, random, mt, pcg, xorshift, chacha, dist, seed, source, crypto, sha, sha1, sha256, sha512, md5, blake2, keccak, aes, des, poly1305, curve25519, ed25519, rsa, dh, otp, entropy, kdf, hmac, padding, mode, compress, deflate, inflate, zlib, gzip, lz4, snappy, huffman, lz, rle, serial, binary, varint, fixed, zero, buffer, stream, sort, quick, merge, heap, insert, bubble, select, radix, count, tim, stable, search, binary, linear, interp, exponential, jump, ternary, concurrent, channel, select, spawn, join, future, promise, yield, convert, conv, parse, atoi, itoa, tostring, toint, tofloat, compare, replace, trim, split, join, case, strip, repeat, pad, slice, escape, printf, scanf, format, fmt, regex, reflect, typeid, align, offset, unsafe, builtin, callconv, platform, linux, windows, darwin, bsd, unix, posix, debug, trace, symbol, break, print, assert, source, perf, counter, cycle, bench, prof, test, misc, uuid, guid, version, semver, glob, diff, patch, natural, levenshtein, soundex, error, option, result, panic, defer, log, stats, simd, async, cell, rc, contracts, serialize, net, socket, tcp, udp, dns, ip, port, url, host, protocol, icmp, mac, websocket, sse, sql, sqlite, postgres, mysql, mongo, redis, oauth, jwt, tls, ssl, cert, x509, ldap, saml, bcrypt, argon2, password, sanitize, escape, audit, encrypt, decrypt, key, secret, vault, i18n, locale, translate, plural, collation, transliteration, unicode, icu, unit, currency, timezone, qrcode, slug, emoji, phone, email, geo, calendar, holiday, units, license, notice, legal, game, engine, physics, collision, particle, scene, entity, ai, pathfinding, steering, state, save, achievement, leaderboard, multiplayer, input, audio, ui, level, event, web, server, router, middleware, auth, session, cookie, cache, static, template, form, validation, csrf, xss, rate, cors, docs, ml, tensor, neural, deep, training, inference, optimizer, layers, activation, loss, metrics, dataset, preprocess, feature, selection, ensemble, boosting, randomforest, svm, clustering, dimensionality, media, image, png, jpeg, gif, bmp, webp, svg, mp3, wav, ogg, flac, aac, video, mp4, avi, mkv, codec, subtitle, embedded, gpio, i2c, spi, uart, adc, dac, pwm, interrupt, timer, rtc, eeprom, flash, sd, ble, zigbee, blockchain, ethereum, bitcoin, smartcontract, wallet, transaction, consensus, merkle, hashchain, nft, defi, web3, oracle, bridge, cloud, aws, azure, gcp, docker, k8s, terraform, ansible, puppet, chef, salt, helm, serverless, cfn, monitoring, tracing, metrics, alerting, scaling, util, logger, config, flag, option, retry, cache, pool, worker, lru, ttl, backoff, timeout, context, cancel, benchmark, profiling, fuzz, mock, stub, coverage, property, golden, snapshot, performance, security, compliance, report, compiler, parser, lexer, ast, codegen, optimizer, linter, formatter, analyzer, refactor, plugin, macro, inline, jit, wasm, llvm`

> Package maintainers MUST consult this list before shipping a new `module xiom.X`. The list grows monotonically.

---

## 5. Categorization of the 500-Module Proposal

Legend: **[STDLIB]** = belongs in `stdlib/xiom/` (pure, no deps) · **[PKG]** = package in `packages/` (may wrap C) · **[EXT]** = external top-level project · **[OUT]** = not now (needs ecosystem/community).

### 5.1 — STDLIB (core building blocks, zero external deps)

**System foundation (mostly present — extend):**
| Proposed | Status | Home |
|----------|--------|------|
| sys/io, sys/file, sys/dir, sys/path, sys/env, sys/args, sys/time, sys/process, sys/signal, sys/memory, sys/alloc, sys/exit, sys/host, sys/thread, sys/mutex, sys/atomic, sys/semaphore, sys/condvar, sys/once, sys/rwlock | ✅ HAVE | io, os, env, path, time, thread, sync, alloc, mem, ptr |
| sys/exit | ⚠️ GAP | add to `os` or new `process` |

**Core language (mostly present):**
| core/panic, core/assert, core/defer, core/error, core/option, core/result, core/string, core/utf8, core/utf16, core/char, core/array, core/slice, core/range, core/iter, core/typeid, core/align, core/offset, core/unsafe, core/builtin, core/callconv | ✅/⚠️ | core, string, char, array, iter, reflect, ptr, mem — **GAP: utf8/utf16 module, callconv** |

**Primitive math (present):** math/int, math/uint, math/float, math/const, math/abs, math/minmax, math/clamp, math/sqrt, math/pow, math/log, math/exp, math/trig, math/atrig, math/hyper, math/floor, math/modf, math/ldexp, math/bit, math/rotate, math/endian → `math` + `num` ✅ (bit ops exist in `num`; endianness conversion GAP → `num`)

**Bits & bytes (PARTIAL):** bits/read, bits/write, bits/swap, bits/bytes, bits/binary, bits/hex, bits/base64, bits/base32, bits/base16, bits/crc, bits/adler, bits/checksum, bits/bitarray → `encoding` (b64/hex ✅), `compress` (crc32/adler32 ✅) — **GAP: bit read/write, byte swap, base32, bitarray → new `bits` module or extend `num`**

**Hashing (PARTIAL):** hash/fnv, hash/murmur, hash/city, hash/xxhash, hash/siphash (✅), hash/highway, hash/composite → **GAP: fnv, murmur, city, xxhash, highway → extend `hash`**

**Collections (PARTIAL):** collect/list, collect/vector (✅ Vec), collect/stack, collect/queue, collect/ring, collect/map (✅), collect/mapch, collect/tree, collect/avl, collect/rbtree, collect/bheap, collect/fheap, collect/filter (map/filter/reduce via iter), collect/deque (✅ VecDeque), collect/priority (✅ BinaryHeap) — **GAP: linked list, chained map, tree/avl/rbtree, fheap → extend `collections`**

**String ops (mostly present):** str/compare, str/search, str/replace, str/trim, str/split, str/join, str/case, str/strip, str/repeat, str/pad, str/slice, str/escape, str/printf, str/scanf, str/format → `string` + `fmt` — **GAP: printf/scanf, escape → `string`**

**Conversion (present):** conv/int, conv/float, conv/toint, conv/tofloat, conv/tostring, conv/parse, conv/itos, conv/ftos, conv/atoi, conv/itoa → `convert` + `core` ✅

**Networking basic (present):** net/socket, net/address, net/tcp, net/udp, net/dns, net/host, net/ip, net/port, net/protocol, net/url → `net` ✅ — **GAP: IPv6 helpers, URL parse → `net`**

**File formats basic (PARTIAL):** format/hex, format/bytes, format/dump, format/pretty, format/table, format/indent, format/wrap, format/column → `fmt` — **GAP: table/column/wrap → `fmt`**

**OS interaction (mostly present):** os/pipe, os/fd, os/dup, os/select, os/event, os/ioctl, os/mmap, os/stat, os/perm, os/owner, os/link, os/rename, os/remove, os/symlink, os/readlink, os/realpath, os/temp, os/cwd, os/chdir, os/mkdir, os/rmdir, os/walk → `os` ✅ — **GAP: mmap, walk, pipe → `os`**

**Random (present):** rand/mt, rand/pcg, rand/xorshift, rand/chacha, rand/dist, rand/seed, rand/source → `rand` (LCG-based) — **GAP: PCG/MT/xorshift generators → `rand`**

**Crypto basic, no deps (present):** crypto/sha256, sha512, sha1, md5, blake2, keccak, aes, des, chacha, poly1305, curve25519, ed25519, rsa, dh, otp, entropy, kdf, hmac, padding, mode, crypto/rand → `crypto`, `sha`, `md5`, `aes`, `ed25519`, `pbkdf` ✅ — **GAP: chacha20, poly1305, keccak, curve25519, DES → extend `crypto`**

**Compression basic (PARTIAL):** compress/deflate ✅, inflate ✅, zlib, gzip ✅, lz4, snappy, huffman, lz, rle ✅ → **GAP: lz4, snappy, huffman, lz77 → extend `compress`** (pure implementations)

**Serialization binary (present):** serial/binary, serial/varint, serial/fixed, serial/zero, serial/buffer, serial/stream → `serialize` ✅ (varint GAP → `serialize`)

**Sorting (GAP — top priority):** sort/quick, sort/merge, sort/heap, sort/insert, sort/bubble, sort/select, sort/radix, sort/count, sort/tim, sort/stable → **NEW `sort` module or extend `collections`** (must not clash with package `xiom-algo`)

**Searching (GAP):** search/binary, search/linear, search/interp, search/exponential, search/jump, search/ternary → **extend `array`/`collections` or NEW `search`** (fixtures `test_algo.xi` already prove the algorithms)

**Concurrency core (present):** concurrent/channel ✅ (Channel[T]), concurrent/select, concurrent/spawn ✅, concurrent/join ✅, concurrent/future, concurrent/promise, concurrent/yield ✅ → `sync`, `thread`, `async` — **GAP: select, future/promise → `sync`/`async`**

**Time (PARTIAL):** time/duration ✅, time/tick, time/date, time/iso, time/parse, time/format → `time` (Duration ✅) — **GAP: Date struct, ISO 8601 parse/format → `time`**

**Advanced pure math (PARTIAL):** math/modular, math/prime, math/gcd ✅ (num), math/factor, math/combin, math/factorial, math/bigint, math/bigrat, math/bigfloat, math/matrix, math/vector, math/quaternion, math/complex → `math`/`num` — **GAP: bigint, matrix, complex, prime/factor → extend `num` (pure) or NEW `bigint`**

**Platform abstraction (GAP):** platform/linux, platform/windows, platform/darwin, platform/bsd, platform/unix, platform/posix → **NEW `platform` module** (os.platform() exists; per-OS constants + cfg helpers)

**FFI (present):** ffi/cdecl, ffi/stdcall, ffi/fastcall, ffi/pointer, ffi/export, ffi/import, ffi/struct, ffi/string → `ffi` ✅ (calling-convention helpers GAP → `ffi`)

**Debugging (GAP):** debug/trace, debug/symbol, debug/break, debug/print, debug/assert, debug/source → **NEW `debug` module** (error.capture_backtrace exists; stack-trace + source-location helpers)

**Performance (PARTIAL):** perf/counter, perf/cycle, perf/bench ✅ (bench/runner), perf/prof, perf/alloc → **GAP: counters/cycle → extend `bench`**

**Misc core (GAP):** misc/uuid, misc/guid, misc/version, misc/semver, misc/glob, misc/diff, misc/patch, misc/sort (natural), misc/levenshtein, misc/soundex → **NEW `misc` module** (pure algorithms)

### 5.2 — PACKAGES (build on stdlib; may wrap C)

**Data formats:** data/json ✅ (xiom-json), data/xml, data/yaml, data/toml, data/csv, data/tsv, data/binary (serialize ✅), data/msgpack, data/protobuf ✅ (xiom-protobuf), data/thrift, data/bson, data/avro, data/parquet, data/arrow ✅ (xiom-arrow), data/orc, data/xls, data/xlsx, data/pdf, data/docx, data/pptx → **PKG** (xml/yaml/toml/csv/msgpack/… = new packages)

**Databases:** db/sql ✅ (xiom-sql), db/postgres ✅ (xiom-postgres/xiom-libpq), db/mysql, db/sqlite ✅ (xiom-sqlite), db/mongo, db/redis ✅ (xiom-redis), db/cassandra, db/elastic, db/oracle, db/mssql, db/db2, db/firebird, db/leveldb, db/rocksdb, db/badger, db/bolt, db/etcd, db/consul, db/zookeeper, db/dynamo → **PKG** (FFI-bound or pure wire protocols)

**Networking protocols:** net/http ✅ (xiom-http), net/https, net/websocket ✅ (xiom-websocket), net/ftp, net/smtp, net/pop3, net/imap, net/dns (stdlib ✅ base), net/dhcp, net/telnet, net/ssh, net/irc, net/mqtt, net/amqp, net/zmq ✅ (xiom-zeromq), net/grpc ✅ (xiom-grpc), net/rpc, net/proxy, net/ntp, net/snmp, net/tftp, net/upnp, net/bonjour, net/multicast, net/icmp, net/ip (stdlib ✅ base), net/mac → **PKG** (protocol clients on top of stdlib net)

**Crypto/security (FFI or pure):** crypto/tls, crypto/ssh, crypto/pgp, crypto/jwt ✅ (xiom-json + crypto), crypto/oauth, crypto/otp (stdlib ✅ base), crypto/zero; security/auth, security/authorization, security/password (bcrypt/argon2 — pure GAP → PKG or stdlib? **PKG**: argon2/bcrypt are heavy → package), security/sanitize, security/escape, security/audit, security/encrypt, security/decrypt, security/key, security/cert, security/secret, security/vault, security/saml, security/ldap → **PKG** (openssl/libsodium wrappers exist: xiom-openssl, xiom-libsodium)

**Text/NLP:** text/regex ✅ (stdlib regex), text/parsing, text/lexing, text/template, text/markdown, text/html, text/diff, text/patch, text/stemming, text/lemmatization, text/nlp, text/tokenizer, text/ngram, text/sentiment, text/summary, text/translation, text/spell, text/unicode (stdlib ✅ base) → **PKG** (heavy algorithms; pure but ecosystem-level)

**Multimedia:** media/image, png, jpeg, gif, bmp, webp, svg, audio, mp3, wav, ogg, flac, aac, video, mp4, avi, mkv, codec, stream, subtitle → **PKG** (FFI: xiom-ffmpeg, xiom-miniaudio, xiom-openal, xiom-portaudio, xiom-phonon, xiom-stb)

**Graphics/UI bindings:** ui/terminal, ui/console, ui/window, ui/gui, ui/widget, ui/event, ui/canvas, ui/3d, ui/opengl ✅, ui/vulkan ✅, ui/directx ✅, ui/shader, ui/texture, ui/font, ui/color, ui/animation, ui/dialog, ui/menu, ui/toolbar, ui/theme → **PKG** as raw bindings (xiom-opengl, xiom-vulkan, xiom-directx11/12, xiom-sdl3, xiom-raylib, xiom-imgui, xiom-ui) — BUT see §5.3: a *framework* built on them is **EXT** (xiom-game-engine).

**Science/engineering:** sci/physics, chemistry, biology, astronomy, geology, weather, climate, environment, materials, mechanics, thermo, quantum, nuclear, particle, relativity, electronics, robotics, control ✅ (xiom-control), signal, imaging, spectroscopy, chromatography, microscopy, geography, meteorology → **PKG** (domain libs)

**ML/AI:** ml/tensor, neural, deep, training, inference, optimizer, layers, activation, loss, metrics, data, preprocess, feature, selection, ensemble, boosting, randomforest, svm, clustering, dimensionality → **PKG** (xiom-tensorflow, xiom-libtorch/xiom-torch, xiom-onnx, xiom-numpy, xiom-pandas, xiom-scipy, xiom-blas, xiom-openblas, xiom-cuda, xiom-eigen)

**Cloud/DevOps:** cloud/aws, azure, gcp, docker, k8s, terraform, ansible, puppet, chef, salt, helm, serverless, cfn, monitoring, logging, tracing, metrics, alerting, scaling → **PKG**

**Embedded/IoT:** embedded/gpio, i2c, spi, uart, adc, dac, pwm, interrupt, timer, rtc, eeprom, flash, sd, ble, zigbee → **PKG** (hardware FFI)

**Blockchain/Web3:** blockchain/core, ethereum, bitcoin, smartcontract, wallet, transaction, consensus, crypto, merkle, hashchain, nft, defi, web3, oracle, bridge → **PKG**

**i18n:** i18n/locale, translate, plural, date, time, number, currency, name, address, phonenumber, unit, collation, unicode, transliteration, icu → **PKG** (icu FFI)

**Concurrency advanced:** concurrent/forkjoin, actor, stm, lockfree, barrier, countdown, exchanger, phaser, executor, scheduler → **PKG** (or stdlib if pure — decision: executor/scheduler belong in stdlib `async` eventually; actor/stm = PKG)

**Utility (mixed):** util/logger ✅ (stdlib log; xiom-log), util/config, util/flag, util/option, util/retry, util/cache, util/pool, util/worker, util/queue, util/stack, util/lru, util/ttl, util/semaphore, util/backoff, util/timeout, util/context, util/cancel, util/benchmark ✅ (stdlib bench), util/profiling, util/tracing → **PKG** (small pure libs — candidates to fold into stdlib `util` later, but keep as packages now to avoid churn)

**Testing/quality:** test/unit ✅ (stdlib test), test/integration, test/benchmark, test/fuzzing, test/mock, test/stub, test/assert ✅, test/coverage, test/property, test/golden, test/snapshot, test/performance, test/security, test/compliance, test/report → **PKG** (xiom-test exists; extend there)

**Compiler/language tools:** compiler/parser, lexer, ast, codegen, optimizer, linter, formatter, analyzer, refactor, plugin, macro, inline, jit, wasm, llvm → **PKG/OUT** (tooling; xiom-wasmtime exists; compiler internals stay in `crates/`)

### 5.3 — EXTERNAL PROJECTS (top-level repos — NOT packages)

| Project | Proposal mapping | Status |
|---------|------------------|--------|
| **xiom-pulse** | web/server, web/router, web/middleware, web/auth, web/session, web/cookie, web/cache, web/static, web/template, web/form, web/validation, web/csrf, web/xss, web/rate, web/cors, web/sse, web/rest, web/graphql, web/documentation — the **Node.js-like application framework** | 🔲 NEW — depends on xiom-http, xiom-json, xiom-websocket, xiom-graphql, xiom-rest |
| **xiom-game-engine** | game/* (engine, math, physics, collision, particle, scene, entity/ECS, ai, pathfinding, steering, state, save, achievement, leaderboard, multiplayer, input, audio, ui, level, event) + the graphics/audio binding packages (xiom-raylib, xiom-sdl3, xiom-glfw, xiom-imgui, xiom-vulkan, xiom-opengl, xiom-directx11/12, xiom-miniaudio, xiom-openal, xiom-portaudio, xiom-phonon, xiom-jolt, xiom-bullet, xiom-box2d, xiom-ozz, xiom-meshopt, xiom-assimp, xiom-stb, xiom-vma, xiom-dxc) | 🔲 NEW — the bindings remain packages; the ENGINE is the external project consuming them |
| xiom-db | db/* database server product | ✅ EXISTS (top-level `xiom-db/`) |
| xiom-vector | vector database product | ✅ EXISTS (top-level `xiom-vector/`) |
| xiom-debugger-pro | debugger product | ✅ EXISTS (top-level `xiom-debugger-pro/`) |
| xiom-playground | WASM playground | ✅ EXISTS (top-level `xiom-playground/`) |
| xiom-website | website | ✅ EXISTS (top-level `xiom-website/`) |
| xiom-Book | language book | ✅ EXISTS (top-level `xiom-Book/`) |
| xiom-benchmark-chaos | benchmark harness | ✅ EXISTS (top-level, other owner) |
| xiom-research_paper | research | ✅ EXISTS (top-level) |

---

## 6. Stdlib Gap Analysis (what's missing, prioritized)

| # | Gap | Where | Priority |
|---|-----|-------|----------|
| G1 | **Sorting algorithms** (quick/merge/heap/radix/tim/stable) | NEW `sort` (or `collections`) — algo proven in `test_algo.xi` fixtures | P0 |
| G2 | **Searching algorithms** (binary/linear/interp/jump/ternary) | `array` + `collections` | P0 |
| G3 | **Date + ISO 8601** (Date struct, parse/format, tick/timer) | `time` | P0 |
| G4 | **Non-crypto hashes** (fnv-1a, murmur3, xxhash, city) | `hash` | P1 |
| G5 | **Bit manipulation** (bit read/write, byte swap, bitarray) | `num` + NEW `bits` | P1 |
| G6 | **More data structures** (linked list, tree/avl/rbtree, chained map) | `collections` | P1 |
| G7 | **Pure compression** (lz4, snappy, huffman, lz77) | `compress` | P1 |
| G8 | **BigInt / rational / complex / matrix** (pure) | NEW `bigint` + `num`/`math` | P1 |
| G9 | **Platform abstraction** (per-OS cfg helpers, endianness) | NEW `platform` | P1 |
| G10 | **Debug utilities** (stack trace, source location, symbol name) | NEW `debug` | P2 |
| G11 | **Perf counters** (cycle counting, allocation tracking) | `bench` | P2 |
| G12 | **Misc pure algos** (uuid v4, semver, glob, diff (Myers), levenshtein, soundex, natural sort) | NEW `misc` | P2 |
| G13 | **printf/scanf, escape** | `string`/`fmt` | P2 |
| G14 | **UTF-8/16 module, calling-convention helpers** | NEW `utf8` + `ffi` | P2 |
| G15 | **Async future/promise, select** | `async`/`sync` | P2 |
| G16 | **PCG/MT/xorshift PRNGs, chacha20/poly1305/keccak/curve25519** | `rand`/`crypto` | P2 |

**Not stdlib (stay packages):** JSON/XML/YAML/TOML/CSV (data formats), all DB drivers, TLS/SSH/PGP, HTTP framework pieces, media codecs, GPU/ML bindings, embedded HAL, blockchain, cloud SDKs, i18n, NLP. These build ON stdlib.

---

## 7. Migration Strategy (production-grade, NON-BREAKING)

### 7.1 Hard constraints (from §2.3)

- `use xiom.<name>` AND `use stdlib.xiom.<name>` must both keep resolving.
- All existing pub fn names + signatures in the 51 stdlib modules are a **frozen contract** (2,090 regression files, 687 smokes, 66 packages, E2E eco_* suites depend on them).
- Packages must not be forced to republish simultaneously with stdlib changes (separate repos/owners).

### 7.2 Strategy — "Additive Growth, Shimmed Consolidation"

1. **Additive-only for existing modules.** New functions are APPENDED to existing modules (`collections.sort_quick`, `time.Date`, `hash.fnv1a`, `num.byte_swap`, …). Never rename/remove/resignature an existing pub fn. This alone closes G1–G16 with zero breakage.
2. **New modules are additive too.** `sort`, `search`, `bits`, `platform`, `debug`, `misc`, `bigint`, `utf8` as NEW `stdlib/xiom/*.xi` files — they cannot collide because their names are newly reserved (§4) and no test/package imports them yet. Packages already using those names (none today for these) would be audited first.
3. **Consolidation only via alias shims.** For internal duplicates (`b64`/`hex` → `encoding`, `random` → `rand`, `bench`+`runner`+`types` → `bench`, `md5`/`aes`/`sha`/`ed25519`/`pbkdf` → `crypto`):
   - Phase A: add the canonical implementation to the target module; rewrite the duplicate as a **thin re-export** (`pub fn hex_encode(...) { return encoding.hex_encode(...); }`).
   - Phase B: mark deprecated in docs (still fully working).
   - Phase C: after ≥2 minor releases with 0 warnings in the deprecation scan, remove the shim. **No test breaks at any phase** because behavior is identical.
4. **Packages keep `xiom.<name>` unless reserved.** New stdlib growth must NOT claim names already shipped by packages (`json`, `http`, `graphql`, `rest`, `websocket`, `algo`, `arrow`, `protobuf`, `net`, `sql`, `sqlite`, `redis`, `kafka`, `zeromq`, `grpc`, `micro`, `realtime`, `openssl`, `libsodium`, `tensorflow`, `torch`, `onnx`, `numpy`, `pandas`, `scipy`, `blas`, `openblas`, `cuda`, `eigen`, `opencv`, `ffmpeg`, `raylib`, `sdl3`, `glfw`, `imgui`, `ui`, `vulkan`, `opengl`, `directx11`, `directx12`, `miniaudio`, `openal`, `portaudio`, `phonon`, `jolt`, `bullet`, `box2d`, `ozz`, `meshopt`, `assimp`, `stb`, `vma`, `dxc`, `wasmtime`, `libuv`, `zstd`, `lzfse`, `moveit`, `ros2`, `gazebo`, `sensor`, `control`, `cuda`). The §4 reserved list is the guardrail; if stdlib later NEEDS one of those names, the package is renamed to `xiom.<pkg>.<feature>` with a shim first.
5. **API-freeze test gate.** Add a new test (e.g. `stdlib_api_freeze_tests`) that snapshot-checks every pub fn signature of the 51 stdlib modules. Any rename/removal/resignature FAILS CI immediately. This is the mechanical enforcement of "don't break the ecosystem."
6. **Import-alias test gate.** Extend a regression test that compiles one fixture per import form: `use xiom.string;` and `use stdlib.xiom.string;` — both must compile forever.
7. **Phased rollout:**
   - **Phase 0 (this doc):** inventory + categorization + reserved names. DONE.
   - **Phase 1 (P0 gaps, additive):** `sort`, `search`, `time.Date`/ISO8601. Land as new fns/modules; run full suite (2,231 E2E + 1,284 unit) green.
   - **Phase 2 (P1 gaps):** hashes, bits, structures, compression, bigint, platform.
   - **Phase 3 (P2 gaps + consolidation shims):** debug, perf, misc, utf8, callconv + the `b64`/`hex`/`random`/`bench` shims.
   - **Phase 4 (package/namespace hygiene):** audit package modules against §4; rename colliding ones with shims; publish new packages (yaml, toml, csv, mqtt, …).
   - **Phase 5 (external projects):** scaffold `xiom-pulse` and `xiom-game-engine` as top-level repos consuming stdlib + packages.
8. **Every phase ships with:** full `cargo test` (all suites) green, `stdlib_execution_tests` green, E2E 2,230/2,231 green, and the API-freeze gate green. No phase may require a coordinated republish of the 66 packages.

---

## 8. Decision Log

| Date | Decision |
|------|----------|
| 2026-08-06 | Stdlib = zero external deps (except C runtime/LLVM/NASM substrate); packages build on stdlib and may wrap C; frameworks/engines = top-level external projects (xiom-pulse, xiom-game-engine). |
| 2026-08-06 | `xiom.*` namespace shared by stdlib + packages; stdlib maintains a monotonic reserved-name list (§4) as the collision guardrail. |
| 2026-08-06 | Evolution policy: additive-only + alias-shim consolidation + API-freeze test gate + import-alias test gate. 2,090 regression files / 687 smokes / 66 packages / 2,231 E2E are the no-break contract. |
| 2026-08-06 | JSON/XML/YAML/TOML/CSV, DB drivers, TLS/SSH, HTTP framework, codecs, GPU/ML, embedded, blockchain, cloud, i18n, NLP → packages. Sorting/searching/date/hashes/bits/structures/compression/bigint/platform/debug/perf/misc → stdlib. |

---

## Appendix A — Original 500-module proposal (reference)

The full 500-module list from the original proposal is preserved as reference in
`docs/STDLIB_EXTENSION.md` revision history (git). Its categorization is resolved
above: §5.1 (stdlib), §5.2 (packages), §5.3 (external projects).

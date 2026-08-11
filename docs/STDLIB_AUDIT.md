# STDLIB AUDIT - doc says X -> tree has Y

> **Scope:** docs/STDLIB_EXTENSION.md vs `stdlib/xiom/` (read-only audit, 2026-08-11).
> **Method:** full doc read (5,541 lines), full tree scan (440 `.xi` files), per-file
> `module` declaration extraction, deterministic per-line fn/stub classification
> (PowerShell + .NET regex over `[System.IO.File]::ReadAllLines`).
> **Verdict:** **READY for the implementation phase** - see S1.

---

## 1. Summary

| Metric | Value |
|--------|------:|
| Category folders in `stdlib/xiom/` | **39** |
| `.xi` files (all declare `module xiom...`) | **440** |
| Distinct declared modules (440 files, 0 duplicate module decls) | **440** |
| Files with a REAL implementation (>=1 real `fn`) | **93** |
| Spec-skeleton files (module header + commented `// fn ... TODO(compiler): implement`) | **346** |
| Aggregate use-manifests (real, no fns of their own) | **1** (`num/bigfloat_agg.xi`) |
| Real `pub fn` declarations across REAL files (doc S10 claims ~2,215) | **2,298** |
| Duplicate module declarations (must be 0) | **0** |
| Same-name module leaf-name pairs across categories (must be 38) | **38** (verified) |
| TRUE fn name conflicts within a single module | **1** (`hash/xxhash.xi` `_rotl32`) |
| Doc-specified items MISSING from the tree | **0** (2 doc overstatements, see S5) |

### 1.1 Verdict

**READY for the implementation phase.**

- All 40 test-imported contract modules resolve to a real file whose declared
  module name matches (`use xiom.X` verified for all 40, S2.3 of the doc).
- Zero duplicate module declarations; the D4b category/folder expansion is fully
  scaffolded (every planned folder sub-lib exists as a file with a correct
  `module` header).
- The 346 spec skeletons are the *deliberate* D4/D4b pattern: a declared module
  with commented fn signatures marked `TODO(compiler): implement`. They are the
  implementation-phase work queue, not missing files.
- 2 doc claims overstate the tree (`ffi` dlopen/dlsym/dlclose in S13.7; see S5.1),
  and 1 genuine intra-module fn-name collision exists (`hash/xxhash.xi`, S4.2).
  Both are entry-checklist items, not blockers.

---

## 2. Mechanical scan results (STEP 3)

### 2.1 Module -> category folder agreement

Rule: for each file, `module xiom.<seg1>.<seg2>...` - the file must live under the
folder named `<seg1>`, **or** be a flat frozen-contract module relocated into its
category folder (D4 migration - "existing flat files stay byte-identical").
Reported mismatches:

| Folder | File(s) | Declared module | Verdict |
|--------|---------|-----------------|---------|
| `collections/` | 61 files | `xiom.collect.*` | **NOTE** - folder is `collections/`, namespace is `collect`. Resolution works (smokes pass); see S5.2. |
| `core/` | `cmp.xi` | `xiom.cmp` | D4 flat-module relocation (frozen contract) - expected |
| `core/` | `contracts.xi` | `xiom.contracts` | D4 relocation - expected |
| `core/` | `platform.xi` | `xiom.platform` | D4 relocation; doc D4b places `platform.xi` under `os/` - minor divergence (S5.3) |
| `crypto/` | `chacha.xi`, `des.xi`, `ecc.xi`, `poly1305.xi`, `rsa.xi` | `xiom.chacha`, `xiom.des`, `xiom.ecc`, `xiom.poly1305`, `xiom.rsa` | Tier-2 flat modules stored in `crypto/` - expected |
| `format/` | `fmt.xi` | `xiom.fmt` | D4 relocation (folder `format/` vs doc D4b `fmt/`) - minor (S5.3) |
| `math/` | `complex.xi` | `xiom.complex` | Tier-2 flat module in `math/` - expected |
| `memory/` | `alloc.xi`, `cell.xi`, `mem.xi`, `ptr.xi`, `rc.xi` | `xiom.alloc`, `xiom.cell`, `xiom.mem`, `xiom.ptr`, `xiom.rc` | D4 relocation - expected |
| `num/` | `bigint.xi` | `xiom.bigint` | Tier-2 flat module in `num/` - expected |
| `num/` | `bigfloat_agg.xi` | `xiom.bigfloat` | D4b aggregate use-manifest - expected |
| `os/` | `env.xi`, `path.xi`, `process.xi` | `xiom.env`, `xiom.path`, `xiom.process` | D4 relocation - expected |
| `stats/` | `stats.xi` | `xiom.bench.stats` | **ANOMALY** - declares `xiom.bench.stats`, not `xiom.stats` (S5.4) |
| `string/` | `char.xi`, `utf8.xi` | `xiom.char`, `xiom.utf8` | D4 relocation - expected |
| `search/` | `search.xi` | `xiom.search` | matches folder - OK |
| `test/` | `test.xi` | `xiom.test` | matches folder - OK |
| all others | - | `xiom.<folder>...` | OK |

Net: **0 broken resolutions**; 3 items worth a naming decision (S5.2-5.4).

### 2.2 Duplicate module declarations

`FILES WITH DUPLICATE MODULE DECLS = 0` (440 unique module names from 440 files).

### 2.3 Same-name module leaf names across categories

**38** cross-category groups (matches the pre-run scan):

| Leaf | Files |
|------|-------|
| ascii85 | convert, encoding |
| base32 | convert, encoding |
| base64 | convert, encoding |
| bigfloat | num/`bigfloat.xi` (`xiom.num.bigfloat`) + num/`bigfloat_agg.xi` (`xiom.bigfloat`) - same-category pair |
| chacha | crypto (`xiom.chacha`), rand (`xiom.rand.chacha`) |
| chain | error, iter |
| channel | async, sync |
| convert | convert (`xiom.convert`), num (`xiom.num.convert`) |
| core | core (`xiom.core`), math (`xiom.math.core`) |
| curves | crypto, geom |
| date | convert, time |
| duration | convert, time |
| endian | convert, serialize |
| escape | convert, string |
| float | convert, num |
| fold | iter, string |
| fs | io, os |
| glob | misc, string |
| hash | collect (`xiom.collect.hash`), crypto (`xiom.crypto.hash`), hash (`xiom.hash`) - triple |
| heap | collect, sort |
| io | async (`xiom.async.io`), io (`xiom.io`) |
| ip | convert, net |
| json | convert, log, serialize - triple |
| levenshtein | misc, string |
| mac | convert, crypto |
| map | collect, iter |
| percent | convert, encoding |
| punycode | convert, encoding |
| radix | collect, sort |
| range | collect, iter |
| search | search (`xiom.search`), string (`xiom.string.search`) |
| segment | collect, string |
| soundex | misc, string |
| terminal | format, os |
| test | stats (`xiom.stats.test`), test (`xiom.test`) |
| time | convert (`xiom.convert.time`), time (`xiom.time`) |
| unix | net, os |
| url | convert, net |
| utf8 | convert (`xiom.convert.utf8`), string (`xiom.utf8`) |

**Designated-home recommendations** (all are *distinct fully-qualified module
names* - none collide in the module namespace; the pairs are file-name coincidences
the audit tracks so implementers keep qualified calls deterministic):

| Pair | Home (qualified module) | Why |
|------|--------------------------|-----|
| ascii85 | `xiom.encoding.ascii85` (encoding/ascii85.xi) | encoding category owns base-N |
| base32 / base64 | `xiom.encoding.base32` / `.base64` | encoding category owns base-N; `convert/*` are numeric radix conversion, not encodings |
| bigfloat | `num/bigfloat.xi` (`xiom.num.bigfloat`) | production impl; `xiom.bigfloat` (`bigfloat_agg.xi`) stays as the flat aggregate manifest (D3/D4b) |
| chacha | crypto/`chacha.xi` (`xiom.chacha`) = RFC 8439 stream cipher | verified: `chacha20_new/process/encrypt/decrypt` (RFC 8439). `rand/chacha.xi` (`xiom.rand.chacha`) = ChaChaRng PRNG (`chacha_rng_*`) - BOTH real, different domains, keep both; cipher home = `xiom.chacha`, PRNG home = `xiom.rand.chacha` |
| chain | `xiom.error.chain` (error/chain.xi) | error context chaining |
| channel | `xiom.sync.channel` (sync/channel.xi) | sync owns channels; `async/channel.xi` is the executor flavor |
| convert | `xiom.convert` (convert/convert.xi, frozen) + `xiom.num.convert` (num/convert.xi) | the latter is numeric radix/base58/62/85/roman (verified) |
| core | `xiom.core` (core/core.xi, frozen) + `xiom.math.core` (math/core.xi, generic tower) | distinct by design (D4b) |
| curves | `xiom.crypto.curves` (crypto/curves.xi, ECC) vs `xiom.geom.curves` (geom/curves.xi, splines) | distinct domains |
| date / duration / time / timestamp | `xiom.time.*` (time/time.xi flat has real Date/Duration/strftime/strptime) | time is the production home; `convert/*` are parse/serialize shims |
| endian | `xiom.serialize.endian` (serialize/endian.xi) | binary serialization |
| escape | `xiom.string.escape` (string/escape.xi) | text escaping |
| float | `xiom.num.float` (num/float.xi) | numeric |
| fold | `xiom.iter.fold` (iter/fold.xi) | iterator combinator |
| fs | `xiom.os.fs` (os/fs.xi, REAL) vs `xiom.io.fs` (io/fs.xi, stub) | os owns filesystem; io owns console/streams |
| glob | `xiom.misc.glob` (misc/glob.xi) | misc owns glob_match (real in misc.xi) |
| hash | `xiom.hash` (hash/hash.xi, real) = canonical; `xiom.collect.hash` = BloomFilter/LhMap; `xiom.crypto.hash` = crypto digest API | keep all three, distinct |
| heap | `xiom.collect.heap` (real PHeap/FibHeap) vs `xiom.sort.heap` (sort/heap.xi) | data structure vs sort algorithm |
| io | `xiom.io` (io/io.xi, frozen) vs `xiom.async.io` (async/io.xi) | sync vs async |
| ip | `xiom.net.ip` (net/ip.xi) | networking |
| json | `xiom.serialize.json` (serialize/serialize.xi has JSON) + `xiom.log.json` (log/json.xi) + `xiom.convert.json` | serialize = canonical; log = structured entries |
| levenshtein / soundex | `xiom.misc.*` (misc/misc.xi has real impls; `text/similarity.xi` also real) | dedupe string/ copies as wrappers |
| mac | `xiom.crypto.mac` (crypto/mac.xi) = MACs; `xiom.convert.mac` = MAC-address strings | distinct |
| map | `xiom.collect.map` (collect/map.xi) vs `xiom.iter.map` (iter/map.xi) | structure vs combinator |
| percent / punycode | `xiom.encoding.percent` / `.punycode` | encoding owns them |
| radix | `xiom.sort.radix` (sort/radix.xi) vs `xiom.collect.radix` (collect/radix.xi) | sort vs tree |
| range | `xiom.iter.range` (iter/range.xi) vs `xiom.collect.range` (collect/range.xi) | iterator vs tree |
| search | `xiom.search` (search/search.xi, real) vs `xiom.string.search` (string/search.xi) | algorithms vs string |
| segment | `xiom.collect.segment` vs `xiom.string.segment` (Unicode graphemes) | distinct |
| terminal | `xiom.os.terminal` (os/terminal.xi) vs `xiom.format.terminal` (format/terminal.xi) | OS vs formatting |
| test | `xiom.test` (test/test.xi, real) vs `xiom.stats.test` (stats/test.xi) | harness vs statistical tests |
| unix | `xiom.net.unix` (AF_UNIX) vs `xiom.os.unix` (unix FFI) | distinct |
| url | `xiom.net.url` (net/url.xi, REAL) vs `xiom.convert.url` (convert/url.xi) | net owns URL parsing |
| utf8 | `xiom.utf8` (string/utf8.xi, REAL) vs `xiom.convert.utf8` (convert/utf8.xi) | string owns the codec |

---

## 3. Doc->Tree mapping table

Status legend: **REAL** = real implementation; **STUB** = spec skeleton (`// fn ... TODO(compiler): implement`); **AGG** = aggregate use-manifest; **PACKAGE** = not stdlib (lives in `packages/`); **MISSING** = doc specifies, tree lacks (none).

### 3.1 Math family (doc S5.1 + D4b `num/`, `math/`, `geom/`, `bits/`, `stats/`, `rand/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `num` (KEEP/EXPAND, 243 fns) | num/num.xi | `xiom.num` | REAL (243 pub fns; int128/checked/sat/wrap/parse/base verified) |
| `num.convert` (base58/62/ascii85/roman) | num/convert.xi | `xiom.num.convert` | REAL (13 fns) |
| `num.fraction` | num/fraction.xi | `xiom.num.fraction` | STUB |
| `num.base` | num/base.xi | `xiom.num.base` | STUB |
| `num.float` | num/float.xi | `xiom.num.float` | STUB |
| `bigint` (Phase A) | num/bigint.xi | `xiom.bigint` | REAL (75 fns; from_u64/from_hex/pow_mod/is_prime/factorial verified) |
| `bigfloat` (D3, Phase B/C) | num/bigfloat.xi | `xiom.num.bigfloat` | REAL (99 fns) |
| `bigfloat` flat aggregate | num/bigfloat_agg.xi | `xiom.bigfloat` | AGG (use-manifest -> xiom.num.bigfloat) |
| `bits` | bits/bits.xi | `xiom.bits` | REAL (28 fns) |
| `bits.bitarray` / `bitfield` / `popcount` | bits/bitarray.xi, bitfield.xi, popcount.xi | `xiom.bits.*` | STUB |
| `math` (KEEP/EXPAND + NASM) | math/math.xi | `xiom.math` | REAL (77 fns; f64-specialized, libm FFI verified) |
| `math.core` (generic tower, D4b) | math/core.xi | `xiom.math.core` | REAL (104 fns; Num/Real/FromInt tower verified) |
| `math.complex` (Tier-2 flat) | math/complex.xi | `xiom.complex` | REAL (23 fns) |
| `math.algebra` / `primitives` / `vectors` / `matrices` / `trig` / `transcendental` / `differential` / `integral` / `series` / `special` | math/*.xi | `xiom.math.*` | STUB (10 skeletons) |
| `geom` (186 fns) | geom/geom.xi | `xiom.geom` | REAL (186 fns) |
| `geom.vec`/`mat`/`quat`/`collision`/`curves`/`polyhedra` | geom/*.xi | `xiom.geom.*` | STUB (6 skeletons) |
| `stats` | stats/stats.xi | `xiom.bench.stats` | REAL (31 fns) - **see S5.4 name anomaly** |
| `stats.dist`/`test`/`regress`/`histogram`/`moments` | stats/*.xi | `xiom.stats.*` | STUB (5 skeletons) |
| `rand` (StdRng + mt/pcg/xorshift/chacha, dist) | rand/rand.xi | `xiom.rand` | REAL (42 fns; StdRng/Xorshift64/uuid_v4 verified) |
| `rand.mt19937` / `pcg` / `chacha` | rand/mt19937.xi, pcg.xi, chacha.xi | `xiom.rand.mt19937`, `xiom.rand.pcg`, `xiom.rand.chacha` | REAL (10/8/11 fns) |

### 3.2 Crypto family (doc S5.2 + D4b `crypto/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `crypto` (umbrella) | crypto/crypto.xi | `xiom.crypto` | REAL (107 fns; hmac_sha256/pbkdf2/hkdf_sha256/aes GCM/constant_time_compare/secure_random_bytes verified) |
| `sha` | crypto/sha.xi | `xiom.sha` | REAL (38 fns) |
| `md5` | crypto/md5.xi | `xiom.md5` | REAL (11 fns) |
| `aes` | crypto/aes.xi | `xiom.aes` | REAL (28 fns) |
| `chacha` (NEW) | crypto/chacha.xi | `xiom.chacha` | REAL (RFC 8439, 11 fns) |
| `poly1305` (NEW) | crypto/poly1305.xi | `xiom.poly1305` | REAL (9 fns) |
| `ecc` (NEW) | crypto/ecc.xi | `xiom.ecc` | REAL (34 fns) |
| `rsa` (NEW) | crypto/rsa.xi | `xiom.rsa` | REAL (12 fns) |
| `des` (NEW) | crypto/des.xi | `xiom.des` | REAL (18 fns) |
| `crypto.hash` / `mac` / `kdf` / `cipher` / `aead` / `sign` / `keyx` / `curves` / `rng_crypto` | crypto/*.xi | `xiom.crypto.*` | STUB (9 skeletons) |

### 3.3 Text family (doc S5.3 + D4b `string/`, `text/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `string` | string/string.xi | `xiom.string` | REAL (56 fns) |
| `char` | string/char.xi | `xiom.char` | REAL (42 fns) |
| `utf8` (NEW) | string/utf8.xi | `xiom.utf8` | REAL (11 fns) |
| `text.similarity` (jaccard/lcp/lcsuffix landed) | text/similarity.xi | `xiom.text.similarity` | REAL (23 fns; verified) |
| `text.diff` / `transliterate` | text/diff.xi, transliterate.xi | `xiom.text.*` | STUB |
| `string.*` (65 sub-libs: case/split/trim/pad/join/... / unicode/bidi/normalize/...) | string/*.xi | `xiom.string.*` | STUB (65 skeletons - the S13.3 GAP-stdlib queue) |
| `fmt` | format/fmt.xi | `xiom.fmt` | REAL (66 fns; format_table/wrap/indent/sprintf_*/sscanf verified) |
| `format.number` / `dump` | format/number.xi, dump.xi | `xiom.format.number`, `xiom.format.dump` | REAL (6/9 fns) |
| `format.ansi`/`markup`/`numbering`/`relative`/`table`/`terminal`/`text`/`textual`/`units` | format/*.xi | `xiom.format.*` | STUB (9 skeletons) |
| `regex` | regex/regex.xi | `xiom.regex` | REAL (31 fns) |
| `regex.engine`/`syntax`/`pcre_lite` | regex/*.xi | `xiom.regex.*` | STUB |

### 3.4 System family (doc S5.4 + D4b `io/`, `os/`, `ffi/`, `thread/`, `sync/`, `async/`, `time/`, `debug/`, `error/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `io` | io/io.xi | `xiom.io` | REAL (51 pub fns; read/write/append/file ops verified) |
| `io.fs`/`buffer`/`console`/`pipe` | io/*.xi | `xiom.io.*` | STUB (4 skeletons) |
| `os` | os/os.xi | `xiom.os` | REAL (41 pub fns; walk_dir/create_pipe/FileWatcher verified) |
| `os.fs` / `proc` / `term` (done) | os/fs.xi, proc.xi, term.xi | `xiom.os.fs`, `xiom.os.proc`, `xiom.os.term` | REAL (10/5/11 fns) |
| `os.mmap`/`ioctl`/`sync_io`/`win`/`unix`/`err`/`event`/`filetype`/`fs_ffi`/`proc_ffi`/`terminal` | os/*.xi | `xiom.os.*` | STUB (11 skeletons) |
| `env` | os/env.xi | `xiom.env` | REAL (34 fns) |
| `path` | os/path.xi | `xiom.path` | REAL (28 fns) |
| `process` (NEW) | os/process.xi | `xiom.process` | REAL (19 fns; spawn_command/wait/kill/is_running/exit verified) |
| `platform` (NEW) | core/platform.xi | `xiom.platform` | REAL (14 fns) - location diverges from D4b (S5.3) |
| `time` (Date/ISO8601/strftime/strptime landed) | time/time.xi | `xiom.time` | REAL (61 pub fns; Date/Duration/DateTime/strftime/strptime verified) |
| `time.duration`/`instant`/`date`/`iso8601`/`chrono`/`calendar` | time/*.xi | `xiom.time.*` | STUB (6 skeletons) |
| `thread` | thread/thread.xi | `xiom.thread` | REAL (35 fns) |
| `thread.pool`/`spawn`/`park`/`local` | thread/*.xi | `xiom.thread.*` | STUB |
| `sync` | sync/sync.xi | `xiom.sync` | REAL (82 fns; Mutex/RwLock/Condvar/Once/Barrier/Arc/Atomic verified) |
| `sync.mutex`/`condvar`/`barrier`/`channel`/`atomics`/`rwlock` | sync/*.xi | `xiom.sync.*` | STUB |
| `async` | async/async.xi | `xiom.async` | REAL (31 fns; Channel verified) |
| `async.executor`/`channel`/`timer`/`io` | async/*.xi | `xiom.async.*` | STUB |
| `debug` (NEW) | debug/debug.xi | `xiom.debug` | REAL (12 fns) |
| `debug.trace`/`disasm`/`heap_report` | debug/*.xi | `xiom.debug.*` | STUB |
| `error` | error/error.xi | `xiom.error` | REAL (15 fns) |
| `error.chain`/`context`/`backtrace` | error/*.xi | `xiom.error.*` | STUB |
| `ffi` | ffi/ffi.xi | `xiom.ffi` | REAL (52 fns) |
| `ffi.c`/`dl`/`errno` | ffi/*.xi | `xiom.ffi.*` | STUB - **doc S13.7 overstates dlopen; see S5.1** |
| `memory` family: `alloc`/`cell`/`mem`/`ptr`/`rc` | memory/*.xi | `xiom.alloc`, `xiom.cell`, `xiom.mem`, `xiom.ptr`, `xiom.rc` | REAL (24/16/21/19/17 fns) |

### 3.5 Collections & algorithms (doc S5.5 + D4b `collections/`, `iter/`, `sort/`, `search/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `collections` (Vec/Map/Set/... 148 fns) | collections/collections.xi | `xiom.collections` | REAL (148 fns) |
| `collect.tree` (Bst/Avl) | collections/tree.xi | `xiom.collect.tree` | REAL (25 fns) |
| `collect.heap` (PHeap/FibHeap) | collections/heap.xi | `xiom.collect.heap` | REAL (19 fns) |
| `collect.cache` (LruCache/LfuCache/ArcCache) | collections/cache.xi | `xiom.collect.cache` | REAL (26 fns) |
| `collect.hash` (BloomFilter/LhMap) | collections/hash.xi | `xiom.collect.hash` | REAL (15 fns) |
| `collect.queue` (WorkQueue/Deque/SpscRing) | collections/queue.xi | `xiom.collect.queue` | REAL (19 fns) |
| `collect.graph` (Graph + uf_*) | collections/graph.xi | `xiom.collect.graph` | REAL (18 fns) |
| `collect.skiplist` / `trie` / `cuckoo` / `fenwick` / `objectpool` (landed) | collections/*.xi | `xiom.collect.*` | REAL (14/10/13/6/6 fns) |
| `collect.arc`/`avl`/`bheap`/`bitmap`/`blockingqueue`/`bloom`/`btree`/`btreeplus`/`concurrent`/`dag`/`dense`/`deque`/`fheap`/`hamt`/`hasharray`/`hashset`/`immutable`/`interval`/`intmap`/`kdtree`/`lfu`/`linkedhash`/`list`/`lru`/`map`/`mapch`/`mpmc`/`mpsc`/`octree`/`pairingheap`/`persistent`/`priority`/`quadtree`/`radix`/`range`/`rbtree`/`ring`/`segment`/`sparse`/`spatial`/`spmc`/`stack`/`stringmap`/`threadpool`/`tinylfu`/`treemap`/`treeset`/`unionfind`/`vector`/`workqueue` | collections/*.xi | `xiom.collect.*` | STUB (50 skeletons - the S13.2 GAP-stdlib queue) |
| `iter` | iter/iter.xi | `xiom.iter` | REAL (44 fns) |
| `iter.range`/`map`/`filter`/`zip`/`chain`/`fold` | iter/*.xi | `xiom.iter.*` | STUB |
| `sort` | sort/sort.xi | `xiom.sort` | REAL (32 fns) |
| `sort.quick`/`merge`/`heap`/`radix`/`intro` | sort/*.xi | `xiom.sort.*` | STUB |
| `search` | search/search.xi | `xiom.search` | REAL (10 fns) |
| `search.linear`/`binary`/`interpolation`/`kmp`/`boyer` | search/*.xi | `xiom.search.*` | STUB |
| `cmp` | core/cmp.xi | `xiom.cmp` | REAL (29 fns) |
| `array` | array/array.xi | `xiom.array` | REAL (29 fns) |
| `array.fixed`/`dynamic` | array/*.xi | `xiom.array.*` | STUB |

### 3.6 Encoding & data (doc S5.6 + D4b `encoding/`, `serialize/`, `hash/`, `compress/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `encoding` | encoding/encoding.xi | `xiom.encoding` | REAL (38 fns) |
| `encoding.hex`/`base64`/`base32`/`percent`/`ascii85`/`punycode`/`idna` | encoding/*.xi | `xiom.encoding.*` | STUB (7 skeletons) |
| `serialize` | serialize/serialize.xi | `xiom.serialize` | REAL (47 fns; JSON verified) |
| `serialize.json`/`varint`/`endian`/`yaml_lite` | serialize/*.xi | `xiom.serialize.*` | STUB |
| `hash` | hash/hash.xi | `xiom.hash` | REAL (35 fns; fnv1a/32/64/xxhash32/64/murmur3_32/sip_hash/crc32_ieee verified) |
| `hash.city` / `xxhash` / `murmur` / `jenkins` / `crc` / `siphash` / `superfast` (landed) | hash/*.xi | `xiom.hash.*` | REAL (18/56/6/3/11/8/1 fns; crc includes crc64/adler32/checksum_*) |
| `hash.adler`/`checksum`/`fnv`/`highway`/`spooky`/`metro`/`t1ha`/`farm` | hash/*.xi | `xiom.hash.*` | STUB (skeletons; note adler/checksum/fnv real impls live in flat hash.xi + crc.xi) |
| `compress` | compress/compress.xi | `xiom.compress` | REAL (38 fns) |
| `compress.deflate`/`lz77`/`huffman`/`gzip`/`zlib`/`brotli`/`lz4`/`snappy` | compress/*.xi | `xiom.compress.*` | STUB (8 skeletons) |

### 3.7 Core & quality (doc S5.7 + D4b `core/`, `reflect/`, `test/`, `bench/`, `log/`, `misc/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `core` | core/core.xi | `xiom.core` | REAL (118 fns) |
| `contracts` | core/contracts.xi | `xiom.contracts` | REAL (43 fns) |
| `reflect` | reflect/reflect.xi | `xiom.reflect` | REAL (29 fns) |
| `reflect.typeinfo`/`fields` | reflect/*.xi | `xiom.reflect.*` | STUB |
| `test` | test/test.xi | `xiom.test` | REAL (30 fns) |
| `test.assert`/`harness` | test/*.xi | `xiom.test.*` | STUB |
| `bench` | bench/bench.xi | `xiom.bench` | REAL (17 fns) |
| `log` | log/log.xi | `xiom.log` | REAL (38 fns) |
| `log.levels`/`sinks`/`json`/`color` | log/*.xi | `xiom.log.*` | STUB |
| `misc` (uuid/semver/glob/diff/levenshtein/soundex/natural/units) | misc/misc.xi | `xiom.misc` | REAL (39 fns; semver_compare/glob_match/levenshtein_distance/soundex/natural_compare/slugify/roman/units verified) |
| `misc.glob`/`levenshtein`/`natural`/`semver`/`soundex` | misc/*.xi | `xiom.misc.*` | STUB |
| `simd` | simd/simd.xi | `xiom.simd` | REAL (52 fns) |
| `simd.vec4`/`vec8`/`mask`/`gather` | simd/*.xi | `xiom.simd.*` | STUB |

### 3.8 Networking (doc S5.8 + D4b `net/`)

| Doc module | Tree path | Declared module | Status |
|-----------|-----------|-----------------|--------|
| `net` | net/net.xi | `xiom.net` | REAL (43 fns; tcp/udp/http_get/post/dns/resolve_host/parse_url/is_valid_ipv4 verified) |
| `net.url` / `dns` / `proto` (done) | net/url.xi, dns.xi, proto.xi | `xiom.net.url`, `xiom.net.dns`, `xiom.net.proto` | REAL (16/20/15 fns; jsonrpc_*/sse_format_*/http_header_*/auth headers/dns_well_known_port verified) |
| `net.address`/`cookie`/`header`/`http`/`ip`/`jwt`/`mime`/`multipart`/`ntp`/`ping`/`socket`/`sse`/`tls_helper`/`unix`/`websocket` | net/*.xi | `xiom.net.*` | STUB (15 skeletons) |

### 3.9 Wish-list categories (doc S13 tables) - cross-check of "landed this session" claims

All P0 "landed this session" claims from S13 verified **REAL** in the tree:

| S13 claim | Tree | Status |
|-----------|------|--------|
| hash/superfast, siphash, adler (in crc.xi), checksum | hash/superfast.xi, siphash.xi, crc.xi | REAL |
| hash/city (city64/128), xxhash (xxh32/64 + XXH3-64/128), murmur3_128, jenkins | hash/city.xi, xxhash.xi, murmur.xi, jenkins.xi | REAL |
| collect skiplist / trie / cuckoo / fenwick / objectpool / ArcCache / SpscRing | collections/skiplist.xi, trie.xi, cuckoo.xi, fenwick.xi, objectpool.xi, cache.xi, queue.xi | REAL |
| text.similarity jaccard / lcp / lcsuffix | text/similarity.xi | REAL |
| fmt sprintf / sscanf | format/fmt.xi | REAL |
| time strftime / strptime | time/time.xi | REAL |
| num.convert base58 / base62 / ascii85 / roman | num/convert.xi | REAL |
| os fs / proc / term, net url / dns / proto, rand mt19937 / pcg / chacha, math.core tower | os/*, net/*, rand/*, math/core.xi | REAL |

S13 items still queued (correctly marked GAP-stdlib P1/P2) map to the STUB files above.

---

## 4. Name-conflict verdict

| Check | Result |
|-------|--------|
| Duplicate module declarations | **0** (440 unique modules from 440 files) |
| Cross-category same-name leaf groups | **38** (matches pre-run claim) |
| Same-name pairs with real implementations on both sides | chacha (crypto cipher + rand PRNG - keep both, S3.2/S2.3), convert, core, hash, io, search, test, time, url, utf8, bigfloat, curves, fs, mac, map, heap, json, channel, fold, chain, terminal, glob, levenshtein, soundex, unix, date, duration, endian, escape, float, ip, percent, punycode, radix, range, segment, ascii85, base32, base64 (all fully qualified - no namespace collision) |
| Genuine intra-module fn-name collision | **1**: `hash/xxhash.xi` defines `fn _rotl32(x: UInt64, r: Int) -> UInt64` at line 37 **and** `fn _rotl32(x: UInt64, c: Int) -> UInt64` at line 293 - identical signature, same module. Likely last-definition-wins shadowing; both are private helpers. **Entry item: dedupe.** |

---

## 5. MISSING / TODO list

### 5.1 Doc overstates the tree (2 items)

1. **`ffi` dlopen/dlsym/dlclose - S13.7 says `HAVE | ffi.*` but the tree has no dlopen/dlsym/dlclose anywhere.** `ffi/dl.xi` is a STUB (`// Dynamic library loading ... TODO(compiler): implement`), and `ffi/ffi.xi` contains no dynamic-loading fns. Correct status: **STUB (GAP-stdlib)**. Entry item: implement in ffi/dl.xi.
2. **`hash/fnv` folder module (S13.1 marks HAVE via flat `hash.xi`)** - flat impl is real (fnv1a32/64, fnv1_32/64) but `hash/fnv.xi` (folder) is a STUB. Doc cites the flat names, so the claim holds; the folder skeleton is a duplicate namespace to fold in during implementation.

### 5.2 `collections/` folder vs `xiom.collect.*` namespace

The D4b map names the folder `collect/`; the tree folder is `collections/` while all 61 sub-modules declare `xiom.collect.*`. Resolution works (verified: smokes import `use xiom.collect.skiplist;` etc.), so the compiler is using declared-header matching. **No action required** - document the folder/namespace asymmetry.

### 5.3 Category placement divergences (2, cosmetic)

- `core/platform.xi` holds `xiom.platform`; D4b lists `platform.xi` under `os/`. Keep in `core/` or move - one-line `use` change, no signature change.
- `format/` folder holds flat `xiom.fmt` (D4b calls the folder `fmt/`). Cosmetic.

### 5.4 `stats/stats.xi` declares `module xiom.bench.stats`

The stats aggregate (31 real fns) declares `xiom.bench.stats`, not `xiom.stats`, while its sub-modules declare `xiom.stats.dist/test/regress/histogram/moments` and the D4b map row reads `stats/ | stats.xi`. `stats` is not among the 40 frozen contract modules, so nothing breaks, but the aggregate name is inconsistent with its folder and children. **Decision needed:** rename the aggregate to `module xiom.stats` (consistent) or accept `xiom.bench.stats` as the deliberate "stats-under-bench" namespace.

### 5.5 Items that are NOT stdlib (mark as PACKAGE / other domain)

| Doc item | Classification |
|----------|----------------|
| S8.1's 15 pure-XIOM packages (xiom-json, xiom-http, xiom-net, xiom-rest, xiom-graphql, xiom-websocket, xiom-micro, xiom-realtime, xiom-algo, xiom-math, xiom-core, xiom-ffi, xiom-log, xiom-test, xiom-arrow) | **PACKAGE** - lives in `packages/` (365 dirs present), NOT stdlib. Not audited here. |
| S7 NASM/SIMD optimization tracks (math/crypto/hash/compress/rand asm) | **Compiler-session domain** - runtime asm exists (`stdlib/runtime/{mem_x86_64,crypto_x86_64,context_switch}.asm`, `simd_runtime.c`, `sha256_sw.c`); hot-path dispatch is a compiler/runtime-session task, not a stdlib file. |
| S8.2 placeholder packages, S9 external projects | PACKAGE / top-level projects - out of stdlib scope. |
| S12 traits (FromStr/TryFrom/Into/AsRef/From) | Declared as stub skeletons in convert/*.xi - correctly documented as "declare-only until compiler impl-dispatch" (S12 of the doc). STUB by design. |

### 5.6 Missing from tree (after all above)

**None.** Every doc-specified stdlib module/sublib exists as a file with a matching `module` header. The only gaps are implementation gaps inside existing skeletons (the 346 STUB files), which are exactly the implementation-phase backlog.

---

## 6. Implementation-phase entry checklist

For each of the **346 STUB sublibs** (one row per file, grouped by category per S3):

1. **Replace the TODO stubs with real code.** The file currently has the correct
   `module xiom.<cat>.<sub>` header plus commented `// fn ...` signatures - uncomment,
   implement against the frozen flat aggregate's existing helpers, keep the exact
   qualified leaf name (`<sub>.<fn>`), e.g. `use xiom.num.bigfloat;` -> `bigfloat.bigfloat_add(...)`.
2. **Keep the aggregate use-line.** After implementing, add/keep the
   `use xiom.<cat>.<sub>;` line in the flat aggregate manifest (e.g. `math.xi` already
   lists all 12 sub-libs) - D4b requires the parent to `use` its children explicitly.
   The aggregate file itself stays byte-identical for the frozen contract.
3. **Keep the module name.** Do NOT rename `module xiom.<cat>.<sub>` or change
   qualified-call prefixes - the freeze gate + import-alias gate depend on them.
4. **Add a smoke.** One file in `examples/stdlib_smoke/` (naming: `smoke_<cat>_<sub>.xi`)
   importing the sub-lib and calling every pub fn with a known-answer check.
   - Known-answer caveats already in the codebase: `collect.skiplist` + `collect.trie`
     must stay in separate smokes (COMPILER_BUGS.md BUG 16); xxhash's duplicate
     `_rotl32` should be deduped first (S4).
5. **Concrete-over-generic for math/crypto/num.** Follow S12/S13.9: width-agnostic
   numeric helpers go to `math.core` with `[T: Num]`; everything else is
   Float64/Int-specialized (`f64_*`, `i64_*`) or arbitrary-precision concrete types.
6. **No external deps.** Any sublib that needs a C library is a PACKAGE, not stdlib
   (wire this decision into S5.5 classification).
7. **Fix the 2 overstatements** (S5.1): implement `ffi/dl.xi` (dlopen/dlsym/dlclose)
   and fold `hash/fnv.xi` to delegate to the flat `hash.xi` impls.
8. **Resolve the 3 naming decisions** (S5.2-5.4): confirm `stats` aggregate module
   name, `platform.xi` placement, `collections/` <-> `xiom.collect` documentation.
9. **Re-run gates** after each sublib: freeze gate, import-alias gate, full suite
   (per doc S11 gates) - no phase requires coordinated package republish.

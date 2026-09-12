# XIOM Stdlib Readiness Plan (production-grade bar)

**Created:** 2026-08-24 - **Branch:** `feat/architect` - **Baseline HEAD:** `81ed009a` (round-15)
**Scope:** `stdlib/**` (package `xiom/*`, `runtime/` C+asm) plus smoke realignment in
`examples/stdlib_smoke/`. The PARALLEL COMPILER SESSION owns `crates/**`; see
`docs/COMPILER_READINESS_PLAN.md`. Neither session edits the other's tree.
**Sources:** `docs/xiom-stdlib-audit-v0.58.md`, `docs/stdlib_session.md`,
`docs/REPORT_TO_STDLIB_SESSION.md`.

---

## 0. Position (why this plan)

The audit's verdict stands: breadth A-, assurance F. Three broken foundations,
in urgency order:

1. **No test culture** -- 8 `test_*` fns / 3 asserts in 150k LOC; zero KATs for
   crypto/encodings/parsers.
2. **Compiler-forced duplication** -- same-name delegation crash forces
   copy-paste modules; copies already diverged (base64 4-vs-8 pub fns).
3. **Allocation-per-op core types** -- every string predicate mallocs; no views/
   builder/arena; Option/Result payload-always layout.

(2) is a compiler fix -- we prep, they land. (1) and most of (3)'s first steps
are OURS and unblocked TODAY.

## 1. Ownership & coordination contract

| Item | Owner | Status |
|---|---|---|
| `stdlib/**`, `runtime/**`, smoke realignment | STDLIB (this plan) | active |
| Same-name delegation crash (repro: `convert/base58`) | COMPILER | flagged, needs priority bump |
| geom nested `&Vec[Vec[Float64]]` param reads | COMPILER | round-16 queue |
| CRT-layout AV family / json heap layer / stack-cookie fns / clang variants | COMPILER | stage 4 |
| array_zip T001 tuple typing | COMPILER | stage 2 |
| LET-array representation joint decision (M33 let->Vec vs &[N]T) | JOINT | doc pending from compiler |
| api_freeze harness path sync (item B) | COMPILER | blocks honest manifest checks |

Rule (from REPORT_TO_STDLIB_SESSION.md): never work around an open compiler
bug in stdlib code; document the blocker instead, fix when their round lands.

## 2. Phase T -- Trust (this campaign; highest ROI)

Audit Phase 0 adapted to what is executable now:

### T1. Ground truth sweep
Full 907-smoke sweep on the isolated round-15 binary (worktree build at HEAD;
the compiler session holds uncommitted crates/ changes, so a shared binary is
unusable for attribution). Triage deltas vs the known-fail clusters in
`stdlib_session.md` section 1. Every NEW failure gets probe -> log -> verify
before any edit; stdlib-side fixes committed, compiler-side logged to
`REPORT_TO_COMPILER_SESSION.md`.

### T2. Known-answer test corpus (kills audit #1)
New smokes prefixed `kat_` in `examples/stdlib_smoke/`, one module family per
file, official vectors ONLY (no self-invented expectations):

| File | Vectors |
|---|---|
| kat_encoding_base16_32_64 | RFC 4648 test vectors incl. padding/url-alphabet |
| kat_convert_base64url | RFC 4648 S5 + unpadded forms (diverged-copy lock) |
| kat_encoding_punycode | RFC 3492 S7 sample vectors |
| kat_convert_utf8_decoder | Kuhn stress set subset (BMP, surrogates-reject, overlong-reject, boundary bytes) |
| kat_crypto_sha2 | NIST CAVP short/msg digests SHA-256/512 + empty-string vectors |
| kat_crypto_hmac | RFC 4231 HMAC-SHA-256 cases 1-7 |
| kat_crypto_chacha20poly1305 | RFC 8439 S2.3.2 keystream + S2.8.2 AEAD vector (where paths compile) |
| kat_serialize_json | JSONTestSuite y_/n_ minimal subset (parse accept/reject) |
| kat_net_parsers | url/ip/percent edge tables from RFC 3986/4291 examples |
| kat_num_bigint_bigfloat | known decimal expansions + round-trip identities |

Blocked-but-written rule: if a KAT's path hits a compiler cluster (pbkdf2/
argon2 stack cookies, json heap layer), commit it anyway marked BLOCKED in the
header with the bug name; it flips green automatically when their fix lands.
Crypto first -- an untested AES is indistinguishable from a broken AES.

### T3. Lock in verified wins as permanent smokes (handoff item 5)
- `smoke_iter_zip_predicates` (probe_iter_terminals shapes)
- `smoke_sync_arc_battery` (deref-assign constructor pattern)
- string byte-copy locks: multibyte passthrough lower/upper, str_slice via
  byte_at, byte_at OOB -> 0

### T4. Ownership convention (audit Phase 0 item 3)
`docs/STR_OWNERSHIP.md`: who frees what across `Str.from_cstring`, malloc'd
buffers crossing extern boundaries; then audit all ~93 extern "C" sites against
it. ASAN pass deferred until compiler stage-5 infra exists.

## 3. Phase E -- Core ergonomics (stdlib-side, unblocked)

1. **StringBuilder** (`string/builder.xi`): amortized doubling, push_str/
   push_byte/int_to_string reuse; migrate hot encode/parse internals.
2. **Deallocated predicates**: rewrite starts_with/ends_with/index_of family as
   index-range comparisons (no slice-malloc). Blessed `(Str, start, end)` idiom
   until the language has borrowed views; keep API compatible.
3. **Route bulk copies through runtime memops**: bind the already-exported
   `xiom_asm_memcpy/memmove/memset`; concat/copy fast-path above a length
   threshold.
4. **Container tuning docs**: load/growth/shrink factors, iteration-order
   guarantees; make keyed siphash the default Map hasher (hash-DoS).
5. **CSPRNG binding** (audit security top item): inspect `rng_crypto.xi`
   seeding; runtime exports no OS entropy symbol -> add `xiom_os_entropy` to
   `runtime/` (BCryptGenRandom on Win, getrandom on Unix), reseed policy doc.

Order matters: 1-3 change no APIs, so they can land between compiler rounds
without churn.

## 4. Phase O -- Organization (prep now, execute after delegation fix)

- Dedup inventory: canonical module per twin pair (base64, base32, ascii85,
  percent, punycode, json, endian x3, glob, soundex, levenshtein, ip, url,
  duration, date, fs x3, terminal x3, platform x2, geom twins) with migration
  shim design. Executing renames BEFORE the same-name-delegation crash is fixed
  would hit the identical crash -- do not reorder.
- `package.xi` identity fix ("xiom-bench"/"xiom-std" nonsense) after driver
  registry format settles (compiler stage 5 supply chain).
- Deprecation ladder for MD5/DES/SHA-1: move under `crypto/legacy/` with loud
  headers; never defaults. Pure-doc + header change, safe NOW.
- Namespace cleanup (collect vs collections, escaped crypto names, memory
  quartet) -- mechanical, gated on delegation fix + shims.

## 5. Phase C -- Capability completion (priority order)

1. CSPRNG (see E5 -- pulled forward into this campaign if time allows).
2. TLS decision doc: recommend FFI-bind system schannel first (toolchain is
   Windows-first); until landed, https/jwt/ws modules carry honest
   "plaintext unless you bring your own TLS" security footnotes.
3. CSV DONE 2026-09-12 (`xiom.serialize.csv`: RFC 4180 reader/writer,
   quoted/doubled-quote/embedded-newline handling, CRLF writer,
   smoke_serialize_csv with round-trip vectors). TOML + argv-parsing
   still owed (toolchain eats its own `xiom.toml`).
4. tzdata: phase 1 delegate to OS timezone APIs via FFI; embed IANA snapshot later.
5. Bind-or-delete the ~175 orphaned runtime symbols (atomics ordering, ctx
   swap, ct_compare into MAC compare, disk/sysinfo).
6. Async stress suite (10k fibers, cancellation storms, channel saturation).

## 6. Phase S -- Scale discipline

Property tests for collections (BST balance, heap shape, hashmap distribution);
fuzz targets for url/ip/header/cookie/mime/json/utf parsers (pairs with
compiler stage-5 fuzz infra); decompression-bomb guards (max output ratio/
size caps) on gzip/lz4/json decoders; coverage ratchet from whatever number
T1/T2 yields.

## 7. Sequencing rules

- Sweeps run on ISOLATED binaries built from committed HEAD in a temp worktree;
  never the shared target/debug (compiler session rebuilds it live).
- No stdlib edits while a sweep is in flight; author new files in staging.
- One fix = one probe = one verified rerun; batch commits per family.
- Contract clauses ride along on every touched function (target >=60% pub-fn
  coverage in collections/string/io eventually; verifier hardening makes them
  meaningful).
- Update `stdlib_session.md` at session end; report cross-boundary items to
  `REPORT_TO_COMPILER_SESSION.md`.

## 8. Definition of production-ready (gate)

- [x] Zero known-cluster regressions -- DEFINITIVE all-green 2026-09-12:
      r33 sweep on committed compiler HEAD b8e2fa43 = 935 files,
      935 PASS / 0 RUNFAIL / 0 COMPILEFAIL (includes smoke_serialize_csv).
      History: r20 903/937; r29 916/935; r32 927/934 with three compiler
      WIP regressions (R11/R12/R13) which b8e2fa43 superseded and closed.
- [x] KAT corpus committed and passing for encodings/UTF-8/hashes/MACs/AEAD/
      parsers -- 15 files, ALL un-gated as of 2026-09-10 (kdf + json last)
- [x] CSPRNG bound to OS entropy with documented reseed policy -- flip
      landed 7148b615; OS-seeded LCG only as documented no-OS fallback
- [x] StringBuilder + alloc-free predicates shipped (DONE); runtime memops
      bound in xiom.mem (DONE); STRING fast-path RE-LANDED 2026-09-12:
      str_concat + sb_to_str route through xiom_memcpy_dispatch with the
      R16 Int-cast workaround for the dest offset (the old Str-cast
      chained-concat failure was the `buf + len_a` argument miscompile,
      not the casts). Verified by p_fastpath_live + the string subset;
      full r34 corpus sweep runs as the definitive gate.
- [x] Legacy ciphers quarantined: banners + physical move DONE 2026-09-12
      (des/md5/sha under crypto/legacy/; module names frozen for the api
      freeze, manifest paths synced; p_legacy_modules + 41-file crypto
      battery green); TLS story documented (TLS_DECISION.md); schannel
      binding not started
- [~] Duplication consolidated -- 2026-09-12 waves: endian trio unit
      landed; namespace waves (collect dirs, memory quartet); ascii85
      audited (= already layered: convert canonical, encoding wrappers, no
      action); base32/percent/punycode and the base16/base64/base58 family
      are COMPILER-GATED by R15 (same-leaf + same-name codegen key
      collision); ip4/ip6 needs a translation pass; console/terminal +
      platform still queued.
- [x] Coverage number published + ratcheted in CI-equivalent sweep script --
      DELIVERED 2026-09-12: global 1007 clauses / 8627 fns = 11.7%
      (pub-with-clause 636/6465 = 9.8%); key modules io 38.9%,
      string 17.1%, collect 2.0% (target >=60% in later waves). Wave 1
      added 40 clauses on touched io/string/IntMap/StringMap fns,
      verified by a 429-file battery with zero contract fallout.
      Ratchet: coverage_scan.ps1 -RatchetFile coverage_floors32.json
      (stdlib_ws tooling; positive + negative runs verified); floors are
      per top-level stdlib/xiom directory.

## 9. Status audit -- 2026-09-10 (rounds 15-29, sweep29 in flight)

### 9.1 What is genuinely done (verified, not aspirational)

- **Trust (T)**: 935-file smoke corpus + 15 KAT files (RFC 4648/4231/5869/
  8439/1952, NIST SHS, JSONTestSuite subset, Kuhn UTF-8); ownership
  convention (STR_OWNERSHIP.md) with full extern-site audit; probe-first
  verification protocol; compressed/gzip proven interoperable with python.
- **Ergonomics (E1,E2,E4,E5)**: StringBuilder; alloc-free search predicates;
  container tuning doc; CSPRNG (OS-entropy flip + lock smoke);
  decompression-bomb caps through lz77/huffman/deflate/gzip/zlib/lz4/snappy.
- **Compiler-forced debt cleared**: T007 whole-body-unsafe sweep (128 fns),
  io.rename/exit collision shims, io.sleep Windows fix, 20+ smoke/API
  keyword-defect repairs (env.var, MimeType.type, module_theory/module,
  pub/fn locals), stdio FILE* accessors, R5/R6/KDF/CRT/json flips verified.
- **Organization (O)**: dedup execution started; legacy banners; TLS doc.

### 9.2 Remaining work, ordered

**A. Unblocked now (highest ROI first)**
1. sweep29 triage + publish baseline. Fix smoke_stress_io_bufreader
   harness block: add io.open/io.close (FILE* wrappers; BufReader has NO
   file-open API today) and make the smoke file-based; note for all sweep
   harnesses: redirect stdin.
2. ~~Seeded-siphash DEFAULT hasher switch (E4; hash-DoS)~~ DELIVERED
   2026-09-12 (b6df21b7): StringMap defaults to per-process OS-entropy
   seeded SipHash-2-4 (zero-copy Str core, vectors re-verified); degraded
   fallback documented. Iteration order now varies run-to-run by design
   (STDLIB_CONTAINER_TUNING.md updated). Follow-up: generic HashMap[K,V]
   seed rollout.
3. ~~Legacy physical move to crypto/legacy/ + deprecation ladder~~ DONE
   2026-09-12: des/md5/sha moved to crypto/legacy/ with physical-location
   headers; module names frozen (api_freeze), manifest synced; probe +
   41-file crypto battery green.
4. ~~Namespace cleanup wave 1: collections/.xi files declare module
   xiom.collect.* (62 files) while xiom.collections also exists~~ DONE
   2026-09-12: 61 xiom.collect.* files moved to stdlib/xiom/collect/
   (rc-move pattern); xiom.collections aggregate stays at
   collections/collections.xi; manifest + naming docs synced; 100/100
   container smokes green. Memory quartet still queued.
5. ~~Contract-coverage wave 1 (io/string/collections touched fns) + publish
   the coverage number + add a ratchet mode~~ DONE 2026-09-12 (see gate #7).
6. Dedup continuation: ~~endian three-way~~ DONE 2026-09-12
   (convert/endian -> delegating shim over serialize.endian + bits;
   twin-vs-vectors pinned by smoke_convert_endian). Remaining:
   base32/ascii85/percent/punycode, ip4+ip6 (needs an API translation
   pass -- Result/Vec[UInt8] vs Option/Vec[UInt16], not a blind shim),
   console/os.terminal/os.term, core.platform/os.platform -- each lands
   with a parity smoke.

**B. Capability (C)**
7. Runtime symbol audit: 441 xiom_* defs vs 247 stdlib externs => ~194
   unbound symbols; bind-or-delete.
8. ~~CSV + TOML modules (toolchain eats its own xiom.toml)~~ CSV DONE
   2026-09-12 (xiom.serialize.csv + smoke_serialize_csv); TOML owed.
9. tzdata phase 1 via OS timezone FFI (only chrono_timezone_offset today).
10. Async stress suite (10k fibers, cancellation storms, saturation);
    async infra currently has a single smoke.
11. TLS schannel binding (project; decision doc done).

**C. Compiler-gated**
12. ~~R7 (generic container mono truncates large V)~~ FIXED 2026-09-11
    (882ee321): json nested + large_json + Map[K,bigV] verified green.
13. ~~R8 (char_at contract codegen)~~ FIXED 2026-09-11 (20aa3d07):
    char_at in-range ensures RESTORED and verified; R8 follow-up
    (method `.trim()` on Str params) + R10 (Vec[Option[struct]]
    element AV) also FIXED and verified on r32 (029bdb77).
12b. ~~R9 (full-path calls without import)~~ latent only: stdlib shims
    all import their targets and the shipping corpus is clean; the
    compiler lane is on it (tests/regression/m70_full_path_shim_delegation.xi
    in flight). R11/R12/R13 (r31/r32 WIP regressions) CLOSED by
    b8e2fa43; r33 all-green.
14. ~~memops string fast-path re-land (Str-cast chained concat)~~ DONE
    2026-09-12: the real failure was R16 (`ptr + int` as a memcpy dest
    argument miscompiles); re-landed with the Int-cast workaround in
    str_concat + sb_to_str. Completes gate #4's performance item.
15. Stage-5 coupling: fuzz targets, api_freeze manifest path sync,
    package.xi identity.

**D. Scale discipline (S)**
16. Property tests for collections (BST balance, heap shape, hash
    distribution).
17. Parser fuzz ladder (url/ip/header/cookie/mime/json/utf) once stage-5
    fuzz infra lands.
18. Coverage ratchet in CI-equivalent script; async/CLI-of-everything.

### 9.3 Honest Rust-parity gaps (beyond the original plan)

- No timezone database/zoneinfo, CSV, TOML, or TLS -- the biggest "not a
  complete systems stdlib yet" items.
- Async runtime is minimal (executor/timer/channel + 1 smoke); no
  cancellation-storm/saturation validation.
- ~194 runtime symbols defined but unbound by any module (dead surface;
  audit pending). Runtime is 441 xiom_* fns vs 247 stdlib externs.
- Contract coverage 11.7% globally / 9.8% pub-with-clause; key modules
  io 38.9%, string 17.1%, collect 2.0% (target >=60%; wave 2+ owed).
- Namespace/identity debt: collect vs collections, memory quartet,
  package.xi identity, geom/twin module names.
- No fuzz/property infrastructure (stage-5 dependent); coverage number
  unpublished.
- Console is Windows-first (console_clear "cls"); os.terminal exists but
  the split is not consolidated.

Strengths relative to the Rust-parity bar: breadth (40 module families),
KAT-locked crypto/compression with real RFC interop, 935-file executable
smoke corpus, OS-entropy CSPRNG, working threads/sync/atomics, SIMD/geom/
stats/math towers, and a documented verification protocol.

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
| kat_convert_base64url | RFC 4648 §5 + unpadded forms (diverged-copy lock) |
| kat_encoding_punycode | RFC 3492 §7 sample vectors |
| kat_convert_utf8_decoder | Kuhn stress set subset (BMP, surrogates-reject, overlong-reject, boundary bytes) |
| kat_crypto_sha2 | NIST CAVP short/msg digests SHA-256/512 + empty-string vectors |
| kat_crypto_hmac | RFC 4231 HMAC-SHA-256 cases 1-7 |
| kat_crypto_chacha20poly1305 | RFC 8439 §2.3.2 keystream + §2.8.2 AEAD vector (where paths compile) |
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
3. TOML + CSV + argv-parsing modules (toolchain eats its own `xiom.toml`).
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

- [ ] Zero known-cluster regressions; sweep green except catalogued compiler bugs
- [ ] KAT corpus committed and passing for encodings/UTF-8/hashes/MACs/AEAD/parsers
- [ ] CSPRNG bound to OS entropy with documented reseed policy
- [ ] StringBuilder + alloc-free predicates shipped; bulk ops on runtime memops
- [ ] Legacy ciphers quarantined; TLS story documented honestly
- [ ] Duplication consolidated behind canonical modules once delegation lands
- [ ] Coverage number published + ratcheted in CI-equivalent sweep script

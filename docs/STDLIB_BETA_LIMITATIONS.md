<!--
Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
SPDX-License-Identifier: MIT OR Apache-2.0
-->
# XIOM Stdlib -- Beta Known Limitations (2026-09-16, v0.60-pre-split)

Audience: release/infra lane (public known-limitations page), beta users.
Source of truth for status/next work: `docs/stdlib_session.md` (section 0)
and `docs/STDLIB_READINESS_PLAN.md`. Verification baselines: strict
flip ON, freeze sweep on compiler tag v0.60.0 = 947/947 + module check
509/509 + bare-name 0 hits + coverage ratchet OK (floors47),
`docs/VERIFICATION_BASELINE.md`, 15 KAT files, corpus gate clean.

## Shipped and verified

- Core containers (Vec/StringMap/hash/AVL/RB/BTree/trees/hamt/deque/
  fenwick/LRU/LFU/bloom/cuckoo/persistent/...), string/unicode/text,
  encoding (base16/32/64/64url/percent/ascii85/punycode/idna), convert,
  net (http/url/dns/ip4/ip6/tls-helper stubs), crypto (hashes/macs/kdf/
  AEAD ciphers/sign/keyx/curves with KATs), compress (lz77/huffman/
  deflate/zlib/gzip/snappy/lz4), serialize (json/csv/toml reader+writer),
  time/date, io/fs/os/args, format (ANSI/progress/dump), random,
  regex, math family, async (executor/channels/timers), sync
  (mutex/rwlock/barrier/channel/atomics), thread/threadpool, test.
- CSPRNG on OS entropy (`xiom_os_entropy`: ProcessPrng/RtlGenRandom +
  /dev/urandom; zero new link deps). Legacy ciphers (DES/MD5/SHA-1)
  physically quarantined under `crypto/legacy/` with frozen module names.
- Dedup waves: endian trio, base16/32/64/64url/percent, base58
  `to_base58`, ip family (convert.ip / net.dns / net.ip v6 / net.net),
  os.term; punycode audited as intentionally divergent (see below).
- Contract coverage published + ratcheted (gate #7): 16.6% of functions
  carry >=1 clause; 16.0% of pub fns (wave 10, 2026-09-17); floors
  `coverage_floors47.json`.
  Growth target: >=60% on key modules (io/string/collect) in later waves.

## Excluded from beta (tracked for v1.0)

- **TLS / HTTPS**: no TLS ships. `https`/`jwt` modules carry explicit
  plaintext-on-the-wire warnings. Decision recorded in
  `docs/TLS_DECISION.md` (bind schannel/OpenSSL first, never homegrown);
  blocked on the compiler's stage-5 FFI hardening. Do not claim HTTPS
  semantics until interop passes.
- **Full tzdata**: phase 1 only -- runtime-backed local offset/DST for the
  current machine (`xiom.time.tz`: `tz_offset_secs_at`,
  `tz_local_offset_secs`, `tz_is_dst`, `tz_local_epoch_secs`,
  `tz_local_now`). No bundled historical/global transition tables.
- **Stdlib parser fuzzing**: a deterministic mutation harness now runs in
  the corpus (`smoke_stress_fuzz_parsers.xi`: 600 generated/mutated inputs
  across json/toml/csv/url plus http header totalness, with writer
  round-trip stability). The Stage-5 coverage-guided workspace (compiler
  lane, `fuzz/`) remains the deeper fuzzing home.
- **Untested public surface**: updated scan 2026-09-21 -- **1,113 of 6,103**
  pub functions are never referenced by any smoke or module. Covered by
  generated probes (`tools/gen_call_probes.ps1`, compile-only by design):
  75 zero-arg (`tools/probes/p_never_called_zeroarg.xi`, which surfaced the
  `x25519_keypair` codegen break fixed in compiler R43), the scalar
  single-param and multi-param tranches (239 + 179 calls, all clean on
  R53/R54), and the `-IncludeRefs` tranche (112 modules / 602 calls covering
  `&T`/`&mut T` scalar and `Vec[E]` parameters) -- 110/112 clean, the two
  failures filed as compiler findings (`tools/known_failures/
  p_result_tuple_vec_loop.xi`, `p_ref_tuple_mangle.xi`); the combined
  `-IncludeStructs` tranche covers struct-typed params through same-module
  public constructors (123 modules / 734 calls, 121/123 clean -- the same two
  findings). Remaining classes: struct params without a usable constructor
  (44 fns), fn-typed params (45), generic fns (83), plus the un-targeted
  remainder.
- **Single-param untested surface**: RESOLVED 2026-09-21 on compiler main
  `7837b194` (R54: large fixed arrays emit memset + address access instead
  of the crashing aggregate loads). The raw call set compiles+links again and
  is locked by `tools/probes/p_sweep_single_param.xi`, a runtime-guarded
  compile lock (the calls sit behind an `XIOM_SWEEP_RUN` env guard); the raw
  call set and crash header are archived in `tools/probes/evidence/`. See
  `docs/VERIFICATION_BASELINE.md` R54 section.
- **Same-leaf public type collisions (R44 class)**: 40 non-generic
  same-leaf pub-type groups exist stdlib-wide (e.g. `collect.Avl`,
  `geom.Vec2`, `regex.Regex`, `sync.AtomicInt`). One pair
  (`net.net.HttpResponse` vs `net.http.HttpResponse`) actually clobbered
  fields; it is fixed by renaming the legacy net.net type to
  `NetHttpResponse` (2026-09-17). The rest need a compiler+stdlib
  qualification slice (compiler `docs/COMPILER_BUGS.md` R44); worklist and
  dispositions: `docs/SAME_LEAF_TYPE_CONFLICTS.md` (16 conflicting leaves,
  24 shape-identical duplicate leaves).

## Intentional design divergences (not bugs)

- **`convert.punycode` vs `encoding.punycode`**: same leaf/names but
  different conventions (ACE label + ASCII passthrough vs RFC 3492 raw
  payload). Both stay; each convention is locked by
  `smoke_convert_punycode` / `kat_encoding_punycode`. Probes:
  `p_puny_parity`.
- **`io.console` vs `os.terminal`**: I/O surface vs termios/pty surface --
  not duplicates; documented after audit. `os.term` delegates its
  implementable parts (stubs -> `os.terminal`, styles ->
  `format.terminal`).
- **`net.address`**: address-with-port semantics differ from ip4/ip6
  literals; left local by design.

## Compiler issues that affected stdlib users (now FIXED, kept for history)

- **R28**: reading `.value` off a **temporary** aggregate Option/Result
  call result (e.g. `let v = f().value;`) silently yielded zeroed element
  data. FIXED (90261793); re-verified by the stdlib lane on r47
  (`p_payload_read.xi` correct, full sweep 947/947). The named-local/
  `match` patterns in the ip/dns shims remain as harmless explicitness.
- **R29**: building a Vec inside a `match` arm over a `Result[Vec[...]]`
  payload failed clang codegen. FIXED (bf627c2e); re-verified on r47
  (`p_match_vec_codegen.xi` green, m83 lock compiler-side, full sweep
  947/947).
- Both fixes are in the r47 baseline; keep `docs/COMPILER_BUGS.md` as the
  live status source before repeating any warning in a release.

## Operational notes

- **Runtime symbol audit**: 192 unbound runtime symbols classified
  (83 codegen-referenced keep, 83 runtime-internal keep, 20
  definition-only delete candidates awaiting compiler-lane confirmation;
  no user-visible impact). `docs/RUNTIME_SYMBOL_AUDIT.md`.
- **Async cancellation**: validated 2026-09-16 by `smoke_async_cancel`
  (executor shutdown drops pending tasks; timer-wheel cancel-all /
  selective / unknown-id no-op; channel close drain + Err/false
  semantics). No preemptive cancellation API exists (cooperative model).
- **R16 workaround** remains in the string fast path
  (`(ptr as Int + n) as *UInt8`) until the compiler cleans up
  ptr+int arguments; R16 is otherwise FIXED.

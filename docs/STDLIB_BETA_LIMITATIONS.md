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
  findings). The final `-IncludeFns` addition covers simple `fn(...)` params
  (scalar-or-empty inner params, scalar/Unit return; +4 calls). Remaining
  classes: struct params without a usable constructor (44 fns), fn-typed
  params with non-scalar/other shapes, generic fns (83), plus the
  un-targeted remainder.
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

## Package-relay close-outs (2026-09-23)

Findings relayed from the package-porting session, with the stdlib-side
resolution:

- **Aggregate-module visibility (two traps, both closed).** `str_compare`
  lives in `xiom.string.compare` and `to_string` in
  `xiom.convert.tostring`; porters who wrote `use xiom.string;` /
  `use xiom.convert;` and called the bare name hit
  `error[T001]: undefined variable`. The canonical implementations now sit
  on the parent aggregates (`xiom.string.str_compare`,
  `xiom.convert.to_string` -- the latter is INT_MIN-exact) and the
  submodules delegate to them, so both import styles resolve. Locked by
  `tools/probes/p_relay_visibility.xi`. Rule of thumb for future
  additions: the public idiom of a family belongs on its aggregate
  module; submodules may delegate.
- **Monotonic millisecond clock: EXISTS** (`xiom.time.monotonic_ms()` now
  added as the domain-owner entry point; `xiom.async.async_now_ms()` and
  `xiom.async.timer.Stopwatch` predate it). The runtime source
  (`xiom_async_now_ms`) is QueryPerformanceCounter on Windows and
  CLOCK_MONOTONIC on POSIX and is guaranteed non-decreasing. The
  package-doc claim "no monotonic ms clock exists" is stale; note that
  `xiom.time.Instant.now()` is the wall-clock `time(0)` path and is NOT
  monotonic.
- **Cross-type generic callback returns (compiler v0.61.3, OPEN)**: a
  `[T, U]` generic whose callback changes type (`fn(&T) -> U` or
  `fn(T) -> U`) returns a WRONG value when `U` differs in runtime type from
  `T` (silent, no diagnostic; some pairs crash). Verified on v0.61.3:
  Int->Str wrong (by-ref run 23, by-value run 41), Int->Float64 wrong,
  Int->Int correct, Str->Int correct, concrete callbacks correct. Corpus
  impact: the smokes only exercise same-type maps
  (`smoke_core_option_map`/`smoke_core_result_map` map Int -> Int) and
  `sort_by_key` had no smoke, so the gate is green while these shapes are
  silently wrong. Stdlib surface to avoid until fixed:
  `xiom.sort.sort_by_key[Int, Str]` (mis-sorts; `[Str, Int]` and `[Int, Int]`
  are correct), `xiom.array.map[T,U]` with cross-type `U`,
  `xiom.iter` `Range.map[U]`/`MapIter.map[V]` with cross-type `U`, and core
  `Option[T].map[U]`/`Result[T,E].map[U]` with cross-type `U`. Minimal
  reproductions: `tools/known_failures/p_generic_typechanging_*.xi`
  (4 files, with the observed exit codes). Packages: keep concrete shims
  for type-changing maps until the compiler lane fixes the callback ABI;
  single-type-parameter generic APIs are safe.
- **Checker E001 conservatism (compiler lane, warning-only)**: the borrow
  checker warns "cannot borrow as mutable while immutably borrowed" for
  sequential `&local` then `&mut local` calls (no overlap in time).
  Warning-only; the stdlib smoke corpus compiles with it and runs green
  (949/949). Deterministic reproduction on v0.61.3: `run_smokes.ps1
  -Filter smoke_collect_sparse` emits 7 E001 lines (lines 22/24/28/31/33/
  50/52); also smoke_collect2a:63 and smoke_collect_threadpool:28. Minimal
  pattern kept at `tools/probes/evidence/p_e001_borrow_conservatism.xi`.
  No stdlib change; relayed to the compiler lane.
- **`xiom.flags` env thread-safety**: environment mutation
  (`xiom.os.env_set` / `xiom.env.set_var`) writes process-global state
  through the runtime shims and is not internally synchronized. Callers
  that mutate env from several threads must serialize; a stdlib lock
  cannot cover external C writers. Documented rather than "fixed".
- **Registry compiler-pin correlation (relayed 2026-09-24)**: the registry
  wants the toolchain pin published as `compiler` per xiom-std version.
  Dependency: the `xiom pkg` client must emit the field (verified absent in
  the compiler repo's `crates/xiom-pkg/src/main.rs` by the registry lane).
  Once it ships, add `compiler: "<pin>"` to the stdlib package manifest (or
  pass the flag) at publish time -- no registry change needed. Nothing to
  correlate until then (`xiom-std@0.61.3` has no compiler value).
- **Clause-parsing precedence trap (stdlib, fixed 2026-09-24)**: in a
  clause expression, `A == B > C` parses LEFT-ASSOCIATIVELY as
  `(A == B) > C`; the compiler silently coerces the Bool/Int mix instead of
  rejecting it, so the clause only holds when B happens to equal the Bool's
  numeric value. Two new clauses hit this (`lhmap_first/last`:
  `result.is_some == lhmap_size(m) > 0`); fixed with explicit parentheses
  and the repo was audited -- every pre-existing clause of this shape
  already parenthesizes (`result.is_some == (size(m) > 0)` etc.). Compiler
  lane: consider rejecting mixed Bool/Int comparisons in clause position.

## Deferred-stub re-triage (2026-09-24)

The 82 files with `TODO(compiler)` / `NOT IMPLEMENTABLE` markers were
re-classified against the pin (compiler v0.61.3). The old N-class wording
("nested Vec element reads return garbage") is too absolute: direct
`m[i][j]` on a by-ref parameter is broken, but the **row-local copy** shape
works and is proven in two gate-green modules (`geom/matrix.xi`,
`iter/zip.xi`). Closed this round (all verified on the pin):

- `xiom.math.trig.sinh/cosh/tanh/atanh`: delegate to the gate-green
  `xiom.math.hyperbolic` (the old BUG-20 inline-arithmetic claim is stale);
  `smoke_math_trig` now asserts values.
- `xiom.num.float.float_next_up/float_next_down/float_ulp`: exact via
  `xiom.math.primitives.nextafter` (no bitcast intrinsic needed);
  `smoke_num_float` asserts them. `float_bits`/`bits_to_float` still need
  the bitcast intrinsic.
- `xiom.math.set_theory.set_partition`: implemented with the row-local
  nested-Vec read; new `smoke_math_set_partition` covers good/overlap/
  missing/outside/empty cases.
- `xiom.async.timer.timer_interval`: was returning an unarmed timer. Root
  cause: the same-leaf type collision `xiom.async.Timer` vs
  `xiom.async.timer.Timer` (the private aggregate twin won the leaf and
  `armed` read the wrong layout). Fixed by renaming the private aggregate
  type to `AsyncTimerTask`; `smoke_async` now asserts armed + timer_next.
  Compiler lane: same-leaf *private* types still collide with another
  module's type of the same leaf name (R44 class).

Still open (own units): the remaining pin-viable rewrites from the
re-triage (gradients via push-only perturbations, `least_squares` row-copy,
`integrate_gauss` re-probe, `series.convergence_rate`, `lp_simplex`,
`control_theory` observability/controllability) and the genuinely
compiler-gated classes (recursive evaluator returning non-Int, Bool/aggregate
tuples, `&Vec[fn]` reads, bitcast, fp128, lazy `Iter`). The full ranked list
is in the session handoff (`docs/stdlib_session.md`, PART 9).

## Operational notes

- **Runtime symbol audit** (closed stdlib-side 2026-09-17; re-verified
  2026-09-23): of the 20 definition-only candidates, 9 non-hot entries
  were DELETED (0 references in `runtime/**` on the v0.61.3 tree) and the
  11 `xiom_hot_*` entries are kept + annotated as intentional hot-reload
  ABI in `runtime/xiom_hot_reload.c` (AUDIT block; dynamic `GetProcAddress`
  reach via `tools/xiom_hot_host.c`). No user-visible impact; the remaining
  compiler-lane confirmation applies only to the kept ABI set.
  `docs/RUNTIME_SYMBOL_AUDIT.md`.
- **Async cancellation**: validated 2026-09-16 by `smoke_async_cancel`
  (executor shutdown drops pending tasks; timer-wheel cancel-all /
  selective / unknown-id no-op; channel close drain + Err/false
  semantics). No preemptive cancellation API exists (cooperative model).
- **R16 workaround** remains in the string fast path
  (`(ptr as Int + n) as *UInt8`) until the compiler cleans up
  ptr+int arguments; R16 is otherwise FIXED.

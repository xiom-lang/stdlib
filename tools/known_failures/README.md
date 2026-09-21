# Known-failing reproductions (not part of the probe corpus)

Files here are **expected to fail** on the pinned compiler and are excluded
from `tools/probes/` so the probe runner and CI stay green. Each file is a
minimal-or-not-yet-minimized reproduction of an OPEN compiler-lane finding,
kept so the compiler session can iterate without regenerating inputs.

Run one manually with:

```powershell
xiom --force -o out.exe tools/known_failures/<file>.xi
```

## Current

- `q1_verify_all.xi` -- **RESOLVED 2026-09-21** on compiler main R58
  (`5bdffaad`; the R55-R58 batches): the 36-import T007 verification graph
  now compiles within the default 300s watchdog (`compile=0 run=0` in the
  re-triage run), so the probe is **moved to `tools/probes/`** as a green
  compile-graph lock. History: it exceeded the watchdog on R52-R54 and was
  kept here as a performance/watchdog item (it compiled with `--timeout 0`).

- `p_result_tuple_vec_loop.xi` (2026-09-21, from the `-IncludeRefs` generated
  tranche): OPEN. A `Result[(Vec[Int], Int), Str]` whose match arm builds a
  Vec inside a while loop (loop-local accumulation) emits the Result payload
  slot as two scalars, so the Vec is stored into a scalar-sized slot:
  `%tmp334` defined with type `%struct.Vec ...` but expected
  `%struct.Result = type { i64, i64, i64 }`. Breaks
  `xiom.net.tls_helper.cert_public_key_info` and `cert_is_self_signed`
  (through `asn1_read_oid`). Minimal shape verified on R53/R54; nested simple
  loops and loop-free arms compile fine, so the trigger is the
  loop-local-to-Vec dataflow inside a tuple-payload Result arm.

- `p_ref_tuple_mangle.xi` (2026-09-21, from the `-IncludeRefs` generated
  tranche): OPEN. A tuple built from a reference parameter mangles the
  reference type into the struct NAME:
  `%struct.Tuple__&Vec__Int = type { i64, i64 }` -- invalid LLVM identifier
  (`expected '=' after name`), plus `warning: unknown type '&Vec' --
  defaulting to i64`. Breaks the `xiom.crypto.sign` Ed25519/ECDSA/DSA family
  (`ed25519_keypair_from_seed` returns `(seed, Vec[UInt8].new())`), whose
  module header already stubs those functions for this class.

- `q1_verify_all.xi` (moved from `tools/probes/`, 2026-09-21): OPEN --
  performance/watchdog, NOT a correctness failure. The 36-import T007
  verification graph compiles clean with `--timeout 0` (378,368-byte exe on
  compiler R52) but exceeds the compiler's default 300s compile watchdog,
  which aborts it. Same class as the heavy generator groups (see
  `tools/README.md`, `-Timeout`). Kept here so the probe runner stays green;
  the per-module intent is covered by `check_modules` 509/509.

- `p_hash_probe.xi` (moved from `tools/probes/`, 2026-09-21): OPEN. The
  hasher-interface path (`impl H2[Int]` in a probe) is unimplemented:
  `error[T001]: 15:36: argument 1 type mismatch: expected Int, found Self`.
  `xiom/hash.xi` documents the interface as having no concrete impls yet and
  a historical pointer-to-i64 IR defect; this is the only repro of the
  `Self`-typed impl-argument path. Needs compiler-lane triage.

- `p_async_read_line_codegen.xi` (moved from `tools/probes/`, 2026-09-21):
  OPEN. `xiom.async.io.async_read_line(0)` compiles but dies with 0xC0000409
  (stack cookie) when stdin is at EOF -- the shape run_smokes feeds every
  probe (empty stdin). The body reads through
  `fread(&byte_buf[0], 1, 1, fd as *UInt8)` (an fd cast to FILE*), so the
  crash is either the cast path or the stack buffer under it. The only probe
  covering async_read_line; keep until the compiler lane rules.

- `p_generic_push.xi`, `p_gp_b.xi`, `p_gp_c.xi` (moved from `tools/probes/`,
  2026-09-21): OPEN. The R7 generic-constructor residual (compiler
  COMPILER_BUGS.md): `Vec[V].new()` inside a generic constructor yields a
  corrupt vector and a later push AVs with 0xC0000005. `p_gp_a.xi`
  (constructor only) is green; these are the push legs. `p_generic_push` is
  the combined repro, `p_gp_b`/`p_gp_c` the minimized variants (generic
  push, concrete push).

- `p_fnref.xi` (moved from `tools/probes/`, 2026-09-21): OPEN, needs a
  compiler-lane ruling. Two distinct function values (`io.read_int` and
  `io.read_float`) compare equal: the probe's `if f == g { return 1; }`
  fires. No spec or test covers module-qualified function-value identity;
  classify as bug or unsupported feature before closing.

- `p_pre_capture_callee.xi` -- **RESOLVED 2026-09-20** on compiler main
  R52 (R51 `c235b3fe`: the `@pre` walkers descend through Imply/Is so
  implication-wrapped clauses emit entry snapshots), **moved to
  `tools/probes/`**: `--run` exits 0. IMPACT history: the R49 residual
  aliased ref-param entry snapshots when a CALLEE mutated scalar fields /
  computed-index Vec loops, which kept `tools/probes/p_wave8_shapes.xi` red
  and forced `@pre`-free clauses in nine `collect/*` modules; the strong
  size relations are restored and the targeted smoke families (20/20) pass
  on R52. Compiler-side lock: e2e_m104.

- `p_module_path_alias.xi` -- **RESOLVED 2026-09-19** on compiler main
  `306073ba` (R49-1), **moved to `tools/probes/`**: the catalog keys modules
  by their declared header, `process_use` rewrites non-declared paths
  up-front, and the freeze resolver gained a declared-header index. Path
  imports of the 19 mismatched modules (`crypto/legacy/*`,
  `core/{cmp,contracts,platform}`, `os/*`, ...) are `--check` clean and
  `stdlib_api_freeze_tests` is 2/2 (0 missing).

- `p_pre_call_capture.xi` (2026-09-18) -- **RESOLVED 2026-09-19** on compiler
  main `306073ba` (R49, `0f2213bc`), **moved to `tools/probes/`**: `--run`
  exits 0, no contract violation. IMPACT history: after fixing the
  run_smokes runtime-detection bug, 11 corpus smokes were aborting on these
  clauses; every call-`@pre` clause in the stdlib was replaced with an
  `@pre`-free equivalent. The direct shape is fixed, so the restored
  clauses are verified in `collections.xi` (method receivers) and
  `rc`/`sync` clone counters; the callee-mutation residual above still
  blocks scalar-field shapes.

- `p_os_env_set_link.xi` -- **RESOLVED 2026-09-19**, moved to
  `tools/probes/p_os_env_set_link.xi`. `runtime/xiom_runtime.c` now exports
  `xiom_env_set` / `xiom_env_unset` (`_putenv_s` on Windows,
  `setenv`/`unsetenv` elsewhere) and `xiom.os` / `xiom.env` call those, so
  the former Windows link failure (`undefined symbol: setenv`) is gone and
  the probe round-trips set/get/remove on every platform.

- `p_result_payload_contract.xi` -- **RESOLVED 2026-09-19** on compiler main
  `306073ba` (R49-3), **moved to `tools/probes/`**. History: one module with
  two Result-returning functions whose `ensures` clauses read the payload
  (`result.value`) -- a scalar payload (Int) plus a Vec payload -- broke
  clang (`'%tmp46' defined with type '%struct.Vec' but expected 'ptr'`); the
  `is Err` payload form failed the same way combined with a Vec-payload Ok
  contract. Impact: wave-13 kept payload-reading clauses out of io/fs;
  R49-3 unblocked them, and wave 17 (2026-09-21) applies them across
  io/fs, io/console and io/pipe, pre-validated by
  `tools/probes/p_wave17_shapes.xi`.

- `p_sweep_single_param.xi` -- **RESOLVED 2026-09-21** on compiler main
  `7837b194` (R54: large fixed arrays emit memset + address access instead of
  the crashing aggregate zeroinit/whole-array loads). History: the raw
  generated single-param call set failed codegen from v0.60.0 through R52
  (R43 tuple mismatch, then a clang ISel `0xC0000005` on
  `@__unsafe_block_77`; IR deterministic; crash header
  `p_sweep_single_param.clang-crash.txt`). The raw file compiles+links in
  ~51s on the R53/R54 binary. It is unsafe to execute (null-FFI arguments
  fast-fail in the CRT; `async_read_line` at EOF is the separately tracked
  crash), so the promoted regression lock is the runtime-guarded
  `tools/probes/p_sweep_single_param.xi` (the calls sit behind an
  `XIOM_SWEEP_RUN` env guard: type-check and codegen always happen, the
  calls never run) and the raw call set is archived at
  `tools/probes/evidence/p_sweep_single_param_raw.xi`. Regenerate the
  surface with `tools/gen_call_probes.ps1 -MinParams 1 -MaxParams 1
  -Timeout 0` (60 modules / 239 calls as of R53).

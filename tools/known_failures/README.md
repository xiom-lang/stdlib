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

- `p_result_payload_contract.xi` (2026-09-18): MINIMAL codegen repro found
  while pre-validating wave-13 contract shapes on main R46b (`504fcc1e`).
  One module with TWO Result-returning functions whose `ensures` clauses
  read the payload (`result.value`): a scalar payload (Int) plus a Vec
  payload breaks clang:
  `'%tmp46' defined with type '%struct.Vec' but expected 'ptr'` at
  `call i64 @xiom_str_len(i8* %tmp46)`. Either function compiles alone; the
  pair is the trigger. The `is Err` payload form
  (`ensures: result is Err => result.value.len() > 0`) fails the same way
  when combined with a Vec-payload Ok contract. Bare `result is Ok` across
  Str/Vec/Unit payloads, and scalar+Str payload contracts, are clean.
  Impact: wave-13 stdlib contracts use only the clean forms; payload-reading
  Result clauses stay out of io/fs.xi until the compiler lane fixes this.

- `p_sweep_single_param.xi` (2026-09-17): 139 calls to single-parameter
  public functions that no smoke/module references, across 54 imported
  modules. Fails codegen on v0.60.0 and on main R43 (`274184be`) with:
  `'%tmp15' defined with type '%struct.Tuple__Int__Int' but expected
  '%struct.Tuple__Int__Bool'` (clang rejects the IR). The failure is an
  interaction of the import set: most calls compile in isolation (e.g.
  `xiom.async.io.async_read_line(0)` alone compiles fine), so this needs
  compiler-side triage before minimization.
  **Status on main R45 (`483f283e`, 2026-09-17): NOT fixed.**
  **Status on main R46 (`12148d43`) and R46b (`504fcc1e`, 2026-09-18):
  NOT fixed; NO HANG; the failure is now a clang crash.** Fresh `git archive`
  builds (`cargo build --locked -p xiom`, debug) finish compiler-side in
  256.8s (R46) / 147.7s (R46b) and emit byte-identical IR
  (`p_sweep1.exe.ll`, 4,596,577 bytes,
  sha256 `949d633a...c9e3d1` on both). clang 22.1.8 then dies with
  `Exception Code: 0xC0000005` in `X86 DAG->DAG Instruction Selection` on
  function `@__unsafe_block_77` (xiom.net TcpStream block; contains a
  `[65536 x i8]` stack alloca). Crash header:
  `p_sweep_single_param.clang-crash.txt`. The earlier R45 "hang" was the
  compiler debug driver being slow, not a hang: a run now completes
  end-to-end attempt in under 5 minutes. The failure mode moved on from the
  R43 tuple mismatch, so the compiler lane should minimize from
  `@__unsafe_block_77` rather than the old tuple evidence.
  Regenerate the call list with the reference scan described in
  `docs/stdlib_session.md` (2.21, untested-surface sweep).

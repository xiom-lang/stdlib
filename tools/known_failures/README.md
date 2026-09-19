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

- `p_pre_call_capture.xi` (2026-09-18): a call expression with `@pre` in an
  `ensures` clause reads the POST-state instead of the pre-state, so
  `f(x) == f(x)@pre + delta` always violates at runtime. Minimal repro is
  13 lines; field `@pre` (`b.v[0] == b.v[0]@pre`) works. Reproduced on
  compiler main R46 (`12148d43`) and R46b (`504fcc1e`); it makes
  `tools/probes/p_wave8_shapes.xi` line 75 red
  (`int_map_size(m) == int_map_size(m)@pre - 1`). Wave-14 contracts avoid
  the shape; any contract of this form must stay out of the stdlib until
  fixed.

- `p_os_env_set_link.xi` (2026-09-18): Windows link failure found by the new
  `tools/gen_call_probes.ps1` sweep (never-referenced multi-param surface).
  `xiom.os.env_set` (and `xiom.env.set_var` / `set_var_if_absent` /
  `remove_var`) declares and calls the C `setenv`/`unsetenv`
  (`xiom/os/os.xi:26-27,312,320`; `xiom/os/env.xi:12-13,80,88`), which do
  not exist in MSVC. Any Windows program referencing them fails at link:
  `lld-link: error: undefined symbol: setenv` (undefined symbol: unsetenv
  for the remove path). `xiom.os.win.win_set_environment_var` already
  documents the gap and returns Err. Fix needs a runtime shim
  (`_putenv_s` on Windows) or compiler FFI hardening; until then these
  public functions are unusable on Windows. No smoke calls them, so the
  corpus does not cover the gap.

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

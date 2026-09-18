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

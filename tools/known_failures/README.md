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
  compiler-side triage before minimization. Regenerate the call list with
  the reference scan described in `docs/stdlib_session.md` (2.21,
  untested-surface sweep).

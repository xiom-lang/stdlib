// p_os_env_set_link.xi -- locks the portable env shims.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// HISTORY: found 2026-09-18 by tools/gen_call_probes.ps1. xiom.os.env_set /
// xiom.env.set_var called the C setenv/unsetenv directly, which MSVC does
// not provide, so any Windows program referencing them failed at LINK:
//   lld-link: error: undefined symbol: setenv
// FIXED 2026-09-19 stdlib-side: runtime/xiom_runtime.c now exports
// xiom_env_set / xiom_env_unset (_putenv_s on Windows, setenv/unsetenv
// elsewhere) and the os/env modules call those. This probe links and
// round-trips on every platform.
module p_os_env_set_link

use xiom.env;
use xiom.io;

fn main() -> Int {
  env.set_var("XIOM_PROBE_ENV", "42");
  var v = env.get_var("XIOM_PROBE_ENV");
  match v {
    Ok(s) => { if s != "42" { io.println("env:get"); return 1; } },
    Err(e) => { io.println("env:get-missing"); return 2; },
  };
  env.remove_var("XIOM_PROBE_ENV");
  var v2 = env.var_opt("XIOM_PROBE_ENV");
  if v2.is_some { io.println("env:still-present"); return 3; }
  io.println("P_OS_ENV_SET_LINK OK");
  return 0;
}

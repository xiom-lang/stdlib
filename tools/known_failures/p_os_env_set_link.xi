// p_os_env_set_link.xi -- Windows link-failure repro (compiler main R46b 504fcc1e).
//
// xiom.os.env_set calls the C `setenv` directly (xiom/os/os.xi:26,312); MSVC
// has no setenv, so any Windows program that references the function fails at
// link time with:
//   lld-link: error: undefined symbol: setenv
//   >>> referenced by <...>:(__unsafe_block_0)
// xiom.env.set_var / set_var_if_absent / remove_var have the same extern
// declarations (xiom/os/env.xi:12-13,80,88) and the same caveat, and
// xiom.os.win.win_set_environment_var documents the gap and returns Err.
// Found by tools/gen_call_probes.ps1 (never-referenced multi-param surface):
// no smoke/module calls these functions, which is why the corpus stays green
// on Windows.
module p_os_env_set_link

use xiom.os;

fn main() -> Int {
  xiom.os.env_set("", "");
  return 0;
}

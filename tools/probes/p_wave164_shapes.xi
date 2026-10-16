// p_wave164_shapes.xi -- wave 164 lock: the runtime host-platform branches
// (REL-20261015-2202-pulse follow-up; the wave-160 Linux finding).
//
// Root cause (compiler-side, filed): a BARE in-module reference to a module's
// own compile-time platform constant keeps the literal initializer, while
// qualified cross-module refs (env.FAMILY) are rewritten to the target --
// verified on the official v0.64.5 pin: on Linux `env.FAMILY` reads "unix"
// from outside while xiom.os.env's own bare check still matched "windows".
// Consequence pre-fix on Linux: path_separator() "\\", join_paths "a\\b",
// data_dir/cache_dir/config_dir pointing at AppData\... under a unix home.
// Fix: xiom.os.env branches on the RUNTIME probe env.host_is_windows().
// Rows (0 = all hold; 20+ = setup):
//  1 -- separator is "/" exactly when the runtime host is not Windows
//  2 -- separator is "\\" exactly when the runtime host is Windows
//  3 -- join_paths uses the platform separator and no foreign one
//  4 -- env.host_is_windows() agrees with xiom.os.platform predicates
//  5 -- data_dir marker (.local/share vs AppData/Roaming) + separator-clean
//  6 -- cache_dir marker (.cache vs AppData/Local) + separator-clean
//  7 -- config_dir marker (.config vs AppData/Roaming) + separator-clean
//  8 -- os.raise_signal honors the runtime platform (Linux: delivered to the
//       signal_install handler; Windows: documented no-op)
//
// RED-BEFORE evidence (official pin, WSL Ubuntu): this file run against the
// pre-fix env.xi fails rows 1/3/5/6/7 (path_sep "\\", join "a\\b", AppData
// dirs); rows 2/4/8 pass. Post-fix: green on Windows and WSL.

module p_wave164_shapes

use xiom.os.env as env;
use xiom.os.platform as plat;
use xiom.os.signal as sig;
use xiom.os as osm;
use xiom.string;

fn main() -> Int {
  let is_win = env.host_is_windows();

  // Row 1: unix -> "/".
  if (env.path_separator() == "/") != (is_win == false) { return 1; }

  // Row 2: windows -> "\\".
  if (env.path_separator() == "\\") != is_win { return 2; }

  // Row 3: join uses the platform separator, never the foreign one.
  let joined = env.join_paths("a", "b");
  if joined != "a" + env.path_separator() + "b" { return 3; }
  if is_win {
    if string.str_contains(joined, "/") { return 3; }
  } else {
    if string.str_contains(joined, "\\") { return 3; }
  };

  // Row 4: the two runtime probes agree.
  if is_win != plat.platform_is_windows() { return 4; }
  if plat.platform_family() != (if is_win { "windows" } else { "unix" }) { return 4; }

  // Rows 5-7: dir markers + separator cleanliness (skipped when an XDG
  // override answers; markers checked only when the home-derived join runs).
  let xdg_data = env.var_opt("XDG_DATA_HOME");
  match env.data_dir() {
    Some(p) => {
      if !is_win && string.str_contains(p, "\\") { return 5; }
      if xdg_data.is_none {
        if is_win {
          if !string.str_contains(p, "AppData") { return 5; }
        } else {
          if !string.str_contains(p, ".local/share") { return 5; }
        };
      };
    },
    None => {},
  };
  let xdg_cache = env.var_opt("XDG_CACHE_HOME");
  match env.cache_dir() {
    Some(p) => {
      if !is_win && string.str_contains(p, "\\") { return 6; }
      if xdg_cache.is_none {
        if is_win {
          if !string.str_contains(p, "AppData") { return 6; }
        } else {
          if !string.str_contains(p, ".cache") { return 6; }
        };
      };
    },
    None => {},
  };
  let xdg_config = env.var_opt("XDG_CONFIG_HOME");
  match env.config_dir() {
    Some(p) => {
      if !is_win && string.str_contains(p, "\\") { return 7; }
      if xdg_config.is_none {
        if is_win {
          if !string.str_contains(p, "AppData") { return 7; }
        } else {
          if !string.str_contains(p, ".config") { return 7; }
        };
      };
    },
    None => {},
  };

  // Row 8: raise_signal honors the runtime platform.
  match sig.signal_install() {
    Ok(_) => {},
    Err(_) => { return 20; },
  };
  if is_win {
    // Documented no-op on Windows (the CRT raise() fail-fasts on values
    // outside the CRT's table) -- nothing pending afterwards.
    osm.raise_signal(osm.SIGTERM);
    match sig.signal_pending() {
      Ok(n) => { if n != 0 { return 8; } },
      Err(_) => { return 8; },
    };
  } else {
    // Linux: CRT raise() delivers to the installed handler -> pending 15.
    osm.raise_signal(osm.SIGTERM);
    match sig.signal_pending() {
      Ok(n) => { if n != 15 { return 8; } },
      Err(_) => { return 8; },
    };
  };

  return 0;
}

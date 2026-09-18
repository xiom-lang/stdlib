// XIOM -- Platform Info (xiom.os.platform)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Platform identification helpers built on the compile-time xiom.env
// constants. The module deliberately does NOT import the flat xiom.os
// module: flat os exposes a function named `platform`, and importing
// both would make the `platform` module prefix ambiguous (compiler
// module/function name collision).

module xiom.os.platform

use xiom.env;

// platform_name returns the OS name ("windows", "linux", "macos", ...).
// Complexity: O(1). Pure.
/// platform_name returns the OS name ("windows", "linux", "macos", ...).
/// Complexity: O(1). Pure.
pub fn platform_name() -> Str {
  env.OS
}

// platform_arch returns the target architecture ("x86_64", ...).
// Complexity: O(1). Pure.
/// platform_arch returns the target architecture ("x86_64", ...).
/// Complexity: O(1). Pure.
pub fn platform_arch() -> Str {
  env.ARCH
}

// platform_family returns "unix" or "windows".
// Complexity: O(1). Pure.
/// platform_family returns "unix" or "windows".
/// Complexity: O(1). Pure.
pub fn platform_family() -> Str {
  env.FAMILY
}

// platform_is_windows returns true on Windows.
// Complexity: O(1). Pure.
/// platform_is_windows returns true on Windows.
/// Complexity: O(1). Pure.
pub fn platform_is_windows() -> Bool {
  env.FAMILY == "windows"
}

// platform_is_linux returns true on Linux.
// Complexity: O(1). Pure.
/// platform_is_linux returns true on Linux.
/// Complexity: O(1). Pure.
pub fn platform_is_linux() -> Bool {
  env.OS == "linux"
}

// platform_is_macos returns true on macOS.
// Complexity: O(1). Pure.
/// platform_is_macos returns true on macOS.
/// Complexity: O(1). Pure.
pub fn platform_is_macos() -> Bool {
  env.OS == "macos"
}

// platform_is_unix returns true on Linux or macOS.
// Complexity: O(1). Pure.
/// platform_is_unix returns true on Linux or macOS.
/// Complexity: O(1). Pure.
pub fn platform_is_unix() -> Bool {
  env.FAMILY == "unix"
}

// platform_hostname returns the system hostname. Implemented locally
// via the env.TEMP-free C getenv-free approach: reads the COMPUTERNAME
// variable (Windows) or HOSTNAME (Unix) as a best effort. Complexity:
// O(1).
/// platform_hostname returns the system hostname. Implemented locally
/// via the env.TEMP-free C getenv-free approach: reads the COMPUTERNAME
/// variable (Windows) or HOSTNAME (Unix) as a best effort. Complexity:
/// O(1).
pub fn platform_hostname() -> Result[Str, Str] {
  let cn = env.var_opt("COMPUTERNAME");
  match cn {
    Some(v) => {
      if v.len() > 0 {
        return Ok(v);
      }
      None
    }
    None => {}
  }
  let hn = env.var_opt("HOSTNAME");
  match hn {
    Some(v) => {
      if v.len() > 0 {
        return Ok(v);
      }
      None
    }
    None => {}
  }
  Err("platform_hostname: no hostname variable available")
}

// platform_os_version returns a best-effort OS version string derived
// from environment constants. Complexity: O(1). Pure.
/// platform_os_version returns a best-effort OS version string derived
/// from environment constants. Complexity: O(1). Pure.
pub fn platform_os_version() -> Str {
  env.OS
}

// platform_user_name returns the current user name from the USERNAME
// (Windows) or USER (Unix) environment variable. Complexity: O(1).
/// platform_user_name returns the current user name from the USERNAME
/// (Windows) or USER (Unix) environment variable. Complexity: O(1).
pub fn platform_user_name() -> Option[Str] {
  let un = env.var_opt("USERNAME");
  match un {
    Some(v) => {
      if v.len() > 0 {
        return Some(v);
      }
      None
    }
    None => {}
  }
  env.var_opt("USER")
}

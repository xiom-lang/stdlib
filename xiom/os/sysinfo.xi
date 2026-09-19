// XIOM -- System Info (xiom.os.sysinfo)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// System information helpers. The module deliberately does NOT import
// the flat xiom.os module: flat os exposes externs and functions named
// `signal`, `platform`, `hostname`, etc., and importing it from a
// sibling submodule leaks those symbols into the importing smoke's
// namespace, shadowing sibling submodule prefixes. Values that need a
// runtime syscall not exposed here use documented defaults.

module xiom.os.sysinfo

use xiom.env;

extern "C" {
  fn xiom_cpu_count() -> Int32;
  fn xiom_total_memory() -> UInt64;
  fn xiom_free_memory() -> UInt64;
  fn xiom_getpid() -> Int64;
}

/// sysinfo_cpu_count returns the number of logical CPUs.
/// Complexity: O(1) syscall.
pub fn sysinfo_cpu_count() -> Int {
  let count = unsafe { xiom_cpu_count() };
  if count < 1 {
    return 1;
  }
  count as Int
}

/// sysinfo_total_memory returns total system memory in bytes.
/// Complexity: O(1) syscall.
pub fn sysinfo_total_memory() -> Int {
  let m = unsafe { xiom_total_memory() };
  m as Int
}

/// sysinfo_free_memory returns free system memory in bytes.
/// Complexity: O(1) syscall.
pub fn sysinfo_free_memory() -> Int {
  let m = unsafe { xiom_free_memory() };
  m as Int
}

/// sysinfo_total_memory_mb returns total system memory in MiB.
/// Complexity: O(1).
pub fn sysinfo_total_memory_mb() -> Int {
  let total = sysinfo_total_memory();
  total / (1024 * 1024)
}

/// sysinfo_free_memory_mb returns free system memory in MiB.
/// Complexity: O(1).
pub fn sysinfo_free_memory_mb() -> Int {
  let free = sysinfo_free_memory();
  free / (1024 * 1024)
}

/// sysinfo_page_size returns the system page size in bytes (4096 on the
/// supported runtimes). Complexity: O(1).
pub fn sysinfo_page_size() -> Int {
  4096
}

/// sysinfo_hostname returns the system hostname from the COMPUTERNAME
/// (Windows) or HOSTNAME (Unix) environment variable. Complexity: O(1).
pub fn sysinfo_hostname() -> Result[Str, Str] {
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
  Err("sysinfo_hostname: no hostname variable available")
}

/// sysinfo_os_name returns the OS name.
/// Complexity: O(1). Pure.
pub fn sysinfo_os_name() -> Str {
  env.OS
}

/// sysinfo_os_version returns a best-effort OS version string derived
/// from environment constants. Complexity: O(1). Pure.
pub fn sysinfo_os_version() -> Str {
  env.OS
}

/// sysinfo_process_id returns the current process ID.
/// Complexity: O(1) syscall.
pub fn sysinfo_process_id() -> Int {
  let pid = unsafe { xiom_getpid() };
  pid as Int
}

/// sysinfo_user_name returns the current user name from the USERNAME
/// (Windows) or USER (Unix) environment variable. Complexity: O(1).
pub fn sysinfo_user_name() -> Option[Str] {
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

/// sysinfo_cpu_model returns a CPU model string. The runtime does not
/// expose CPUID; always returns "unknown". Complexity: O(1).
pub fn sysinfo_cpu_model() -> Str {
  "unknown"
}

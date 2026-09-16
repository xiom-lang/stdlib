// XIOM - OS: Unix-specific Utilities
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.unix

// Depends on: xiom.ffi

// ============================================================================
// Unix-only helpers: umask, uid/gid, user/group names, load average, sysconf,
// rlimits, utime, chroot and nice. Home-directory lookup delegates to
// xiom.env (different name -- safe); the remaining functions require POSIX
// syscalls the pure stdlib does not expose -- documented stubs returning
// documented defaults.
// ============================================================================

use xiom.env;

/// Set the file mode creation mask; returns the previous mask.
/// NOT IMPLEMENTED: requires the umask syscall. Returns 0.
pub fn unix_umask(mask: Int) -> Int {
  let _ = mask;
  0
}

/// The real user id of the process.
/// NOT IMPLEMENTED: requires the getuid syscall. Returns 0.
pub fn unix_uid() -> Int {
  0
}

/// The real group id of the process.
/// NOT IMPLEMENTED: requires the getgid syscall. Returns 0.
pub fn unix_gid() -> Int {
  0
}

/// Resolve a uid to a user name.
/// NOT IMPLEMENTED: requires getpwuid.
/// Returns: Err("unix_username: getpwuid not available in the pure stdlib").
pub fn unix_username(uid: Int) -> Result[Str, Str] {
  let _ = uid;
  Err("unix_username: getpwuid not available in the pure stdlib")
}

/// Resolve a gid to a group name.
/// NOT IMPLEMENTED: requires getgrgid.
/// Returns: Err("unix_groupname: getgrgid not available in the pure stdlib").
pub fn unix_groupname(gid: Int) -> Result[Str, Str] {
  let _ = gid;
  Err("unix_groupname: getgrgid not available in the pure stdlib")
}

/// The current user's home directory.
/// Reads HOME via xiom.env (falls back to "").
/// Complexity: O(1). Pure (OS call).
pub fn unix_home_dir() -> Str {
  let v = env.home_dir();
  match v {
    Some(h) => h;
    None => "";
  }
}

/// The system hostname.
/// NOT IMPLEMENTED: requires the gethostname syscall. Returns "".
pub fn unix_hostname() -> Str {
  ""
}

/// The system NIS/domain name.
/// NOT IMPLEMENTED: requires getdomainname. Returns "".
pub fn unix_domainname() -> Str {
  ""
}

/// System uptime in seconds.
/// NOT IMPLEMENTED: requires sysinfo/getboottime. Returns 0.
pub fn unix_uptime() -> Int {
  0
}

/// Load averages; the tuple is (1min, 5min, 15min).
/// NOT IMPLEMENTED: requires getloadavg. Returns (0.0, 0.0, 0.0).
pub fn unix_loadavg() -> (Float64, Float64, Float64) {
  (0.0, 0.0, 0.0)
}

/// Query a system configuration value by name.
/// NOT IMPLEMENTED: requires the sysconf syscall. Returns 0.
pub fn unix_sysconf(name: Int) -> Int {
  let _ = name;
  0
}

/// Query a per-path configuration value.
/// NOT IMPLEMENTED: requires the pathconf syscall. Returns 0.
pub fn unix_pathconf(path: Str, name: Int) -> Int {
  let _ = path;
  let _ = name;
  0
}

/// Resource limits; the tuple is (soft, hard).
/// NOT IMPLEMENTED: requires getrlimit. Returns (0, 0).
pub fn unix_getrlimit(resource: Int) -> (Int, Int) {
  let _ = resource;
  (0, 0)
}

/// Set resource limits.
/// NOT IMPLEMENTED: requires setrlimit.
/// Returns: Err("unix_setrlimit: setrlimit not available in the pure stdlib").
pub fn unix_setrlimit(resource: Int, soft: Int, hard: Int) -> Result[Unit, Str] {
  let _ = resource;
  let _ = soft;
  let _ = hard;
  Err("unix_setrlimit: setrlimit not available in the pure stdlib")
}

/// Set a file's access and modification times.
/// NOT IMPLEMENTED: requires the utime syscall.
/// Returns: Err("unix_utime: utime not available in the pure stdlib").
pub fn unix_utime(path: Str, atime: Int, mtime: Int) -> Result[Unit, Str] {
  let _ = path;
  let _ = atime;
  let _ = mtime;
  Err("unix_utime: utime not available in the pure stdlib")
}

/// Change the process root directory.
/// NOT IMPLEMENTED: requires the chroot syscall.
/// Returns: Err("unix_chroot: chroot not available in the pure stdlib").
pub fn unix_chroot(path: Str) -> Result[Unit, Str] {
  let _ = path;
  Err("unix_chroot: chroot not available in the pure stdlib")
}

/// Adjust process priority; returns the new nice value.
/// NOT IMPLEMENTED: requires the nice syscall.
/// Returns: Err("unix_nice: nice not available in the pure stdlib").
pub fn unix_nice(inc: Int) -> Result[Int, Str] {
  let _ = inc;
  Err("unix_nice: nice not available in the pure stdlib")
}

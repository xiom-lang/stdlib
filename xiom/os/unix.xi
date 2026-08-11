// XIOM - OS: Unix-specific Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.unix

// Depends on: xiom.ffi

// ============================================================================
// Unix-only helpers: umask, uid/gid, user/group names, load average, sysconf,
// rlimits, utime, chroot and nice. NOTE: current implementation lives in
// os.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn unix_umask(mask: Int) -> Int - set the file mode creation mask; returns the previous mask. TODO(compiler): implement.
// fn unix_uid() -> Int - the real user id of the process. TODO(compiler): implement.
// fn unix_gid() -> Int - the real group id of the process. TODO(compiler): implement.
// fn unix_username(uid: Int) -> Result[Str, Str] - resolve a uid to a user name. TODO(compiler): implement.
// fn unix_groupname(gid: Int) -> Result[Str, Str] - resolve a gid to a group name. TODO(compiler): implement.
// fn unix_home_dir() -> Str - the current user's home directory. TODO(compiler): implement.
// fn unix_hostname() -> Str - the system hostname. TODO(compiler): implement.
// fn unix_domainname() -> Str - the system NIS/domain name. TODO(compiler): implement.
// fn unix_uptime() -> Int - system uptime in seconds. TODO(compiler): implement.
// fn unix_loadavg() -> (Float64, Float64, Float64) - load averages; the tuple is (1min, 5min, 15min). TODO(compiler): implement.
// fn unix_sysconf(name: Int) -> Int - query a system configuration value by name. TODO(compiler): implement.
// fn unix_pathconf(path: Str, name: Int) -> Int - query a per-path configuration value. TODO(compiler): implement.
// fn unix_getrlimit(resource: Int) -> (Int, Int) - resource limits; the tuple is (soft, hard). TODO(compiler): implement.
// fn unix_setrlimit(resource, soft, hard) -> Result[Unit, Str] - set resource limits. TODO(compiler): implement.
// fn unix_utime(path: Str, atime: Int, mtime: Int) -> Result[Unit, Str] - set a file's access and modification times. TODO(compiler): implement.
// fn unix_chroot(path: Str) -> Result[Unit, Str] - change the process root directory. TODO(compiler): implement.
// fn unix_nice(inc: Int) -> Result[Int, Str] - adjust process priority; returns the new nice value. TODO(compiler): implement.

// XIOM - OS: Windows-specific Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.win

// Depends on: xiom.ffi

// ============================================================================
// Windows-only helpers: registry, environment variables, services, shell
// execute and identity queries. Environment-variable access delegates to
// xiom.env (different names -- safe); the registry/service/shell functions
// require the Win32 API, which the pure stdlib does not expose -- documented
// stubs.
// ============================================================================

use xiom.env;

/// Read a registry value as a string.
/// NOT IMPLEMENTED: requires the Win32 registry API.
/// Returns: Err("win_registry_read: Win32 registry not available in the pure stdlib").
pub fn win_registry_read(hive: Int, path: Str, name: Str) -> Result[Str, Str] {
  let _ = hive;
  let _ = path;
  let _ = name;
  Err("win_registry_read: Win32 registry not available in the pure stdlib")
}

/// Write a string registry value.
/// NOT IMPLEMENTED: requires the Win32 registry API.
/// Returns: Err("win_registry_write: Win32 registry not available in the pure stdlib").
pub fn win_registry_write(hive: Int, path: Str, name: Str, value: Str) -> Result[Unit, Str] {
  let _ = hive;
  let _ = path;
  let _ = name;
  let _ = value;
  Err("win_registry_write: Win32 registry not available in the pure stdlib")
}

/// Delete a registry value.
/// NOT IMPLEMENTED: requires the Win32 registry API.
/// Returns: Err("win_registry_delete: Win32 registry not available in the pure stdlib").
pub fn win_registry_delete(hive: Int, path: Str, name: Str) -> Result[Unit, Str] {
  let _ = hive;
  let _ = path;
  let _ = name;
  Err("win_registry_delete: Win32 registry not available in the pure stdlib")
}

/// Read a Windows environment variable.
/// Delegates to xiom.env.var_opt.
/// Parameters: name -- the variable name.
/// Returns: Some(value) when set, None otherwise.
/// Complexity: O(1). Pure (OS call).
pub fn win_environment_var(name: Str) -> Option[Str] {
  let v = env.var_opt(name);
  v
}

/// Set a Windows environment variable.
/// NOT IMPLEMENTED: the portable setenv path does not link on Windows MSVC,
/// and the Win32 _putenv_s API is not exposed by the pure stdlib. Returns Err.
/// Complexity: O(1).
pub fn win_set_environment_var(name: Str, value: Str) -> Result[Unit, Str] {
  let _ = name;
  let _ = value;
  Err("win_set_environment_var: environment write is not available in the pure stdlib")
}

/// The current status of a named Windows service.
/// NOT IMPLEMENTED: requires the Win32 service API. Returns "unknown".
pub fn win_service_status(name: Str) -> Str {
  let _ = name;
  "unknown"
}

/// Start a named Windows service.
/// NOT IMPLEMENTED: requires the Win32 service API.
/// Returns: Err("win_service_start: Win32 service API not available in the pure stdlib").
pub fn win_service_start(name: Str) -> Result[Unit, Str] {
  let _ = name;
  Err("win_service_start: Win32 service API not available in the pure stdlib")
}

/// Stop a named Windows service.
/// NOT IMPLEMENTED: requires the Win32 service API.
/// Returns: Err("win_service_stop: Win32 service API not available in the pure stdlib").
pub fn win_service_stop(name: Str) -> Result[Unit, Str] {
  let _ = name;
  Err("win_service_stop: Win32 service API not available in the pure stdlib")
}

/// ShellExecute a file with a verb (open, runas, edit).
/// NOT IMPLEMENTED: requires the Win32 ShellExecute API.
/// Returns: Err("win_shell_execute: Win32 ShellExecute not available in the pure stdlib").
pub fn win_shell_execute(verb: Str, file: Str, args: Str) -> Result[Int, Str] {
  let _ = verb;
  let _ = file;
  let _ = args;
  Err("win_shell_execute: Win32 ShellExecute not available in the pure stdlib")
}

/// The Windows version string.
/// Returns the compile-time target OS name (the runtime does not expose
/// GetVersionEx in the pure stdlib).
/// Complexity: O(1).
pub fn win_version() -> Str {
  env.OS
}

/// True when the process runs elevated.
/// NOT IMPLEMENTED: requires the Win32 token API. Returns false.
pub fn win_is_admin() -> Bool {
  false
}

/// The current Windows user name.
/// Reads the USERNAME environment variable, or "" when unset.
/// Complexity: O(1). Pure (OS call).
pub fn win_username() -> Str {
  let v = env.var_opt("USERNAME");
  match v {
    Some(u) => u;
    None => "";
  }
}

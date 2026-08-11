// XIOM - OS: Windows-specific Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.os.win

// Depends on: xiom.ffi

// ============================================================================
// Windows-only helpers: registry, environment variables, services, shell
// execute and identity queries. NOTE: current implementation lives in os.xi -
// move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn win_registry_read(hive: Int, path: Str, name: Str) -> Result[Str, Str] - read a registry value as a string. TODO(compiler): implement.
// fn win_registry_write(hive, path, name, value) -> Result[Unit, Str] - write a string registry value. TODO(compiler): implement.
// fn win_registry_delete(hive, path, name) -> Result[Unit, Str] - delete a registry value. TODO(compiler): implement.
// fn win_environment_var(name: Str) -> Option[Str] - read a Windows environment variable. TODO(compiler): implement.
// fn win_set_environment_var(name, value) -> Result[Unit, Str] - set a Windows environment variable. TODO(compiler): implement.
// fn win_service_status(name: Str) -> Str - the current status of a named Windows service. TODO(compiler): implement.
// fn win_service_start(name) -> Result[Unit, Str] - start a named Windows service. TODO(compiler): implement.
// fn win_service_stop(name) -> Result[Unit, Str] - stop a named Windows service. TODO(compiler): implement.
// fn win_shell_execute(verb: Str, file: Str, args: Str) -> Result[Int, Str] - ShellExecute a file with a verb (open, runas, edit). TODO(compiler): implement.
// fn win_version() -> Str - the Windows version string. TODO(compiler): implement.
// fn win_is_admin() -> Bool - true when the process runs elevated. TODO(compiler): implement.
// fn win_username() -> Str - the current Windows user name. TODO(compiler): implement.

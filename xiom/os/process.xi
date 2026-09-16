// XIOM -- Process Management (exit, spawn, env, PID)
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
//
// Provides a cross-platform process management interface.
// Delegates to xiom.os, xiom.io, xiom.env, and xiom.thread where possible.
// Implements missing functionality via direct FFI using the same extern
// patterns established in xiom.os and xiom.net.

module xiom.process

use xiom.io;
use xiom.env;
use xiom.os;
use xiom.thread;
use xiom.string;

extern "C" {
    fn system(command: *UInt8) -> Int32;
    fn xiom_getpid() -> Int64;
    // v0.56: Production process operations
    fn xiom_process_spawn(cmd: *UInt8) -> Int64;
    fn xiom_process_kill(pid: Int64) -> Int32;
    fn xiom_process_wait(pid: Int64) -> Int64;
    fn xiom_process_running(pid: Int64) -> Int32;
}

// -- Helper: C string conversion (mirrors os.xi/cstr pattern) -----------------

// Convert an XIOM Str to a null-terminated C string pointer.
// WARNING: The pointer is only valid as long as the original Str is alive.
fn cstr(s: Str) -> *UInt8
    requires: s.len() > 0
    ensures:  result != null
{
    unsafe {
        return s as *UInt8;
    }
}

// -- Exit ---------------------------------------------------------------------

/// Terminate the current process with the given exit code.
/// Delegates to xiom.io.exit (which calls the C exit() function).
/// 0 indicates success, non-zero indicates failure.
pub fn exit(code: Int)
    requires: code >= 0
{
    xiom.io.exit(code);
}

// -- Get PID ------------------------------------------------------------------
//
// PID retrieval requires a platform-specific FFI call. The XIOM runtime does
// not currently expose a xiom_getpid() intrinsic. On Windows, _getpid() from
// ucrt or GetCurrentProcessId() from kernel32 would be used; on Unix, getpid()
// from unistd.h.
//
// Until the runtime adds this intrinsic, get_pid() returns -1 as a sentinel
// indicating "not implemented". Programs should check for this value.

  /// Return the current process ID (via the xiom_getpid runtime intrinsic).
  pub fn get_pid() -> Int
    requires: true  // extern getpid call below (T002 confinement)
  {
      xiom_getpid()
  }

// -- Sleep --------------------------------------------------------------------

/// Sleep (block) the current thread for the specified number of milliseconds.
/// Delegates to xiom.thread.sleep_ms which calls xiom_thread_sleep_ms.
pub fn sleep_ms(ms: Int)
    requires: ms >= 0
{
    xiom.thread.sleep_ms(ms);
}

// -- Environment variable -----------------------------------------------------

/// Get the value of an environment variable.
/// Returns Some(value) if the variable exists, None otherwise.
/// Delegates to xiom.env.var_opt.
pub fn env_var(name: Str) -> Option[Str]
    requires: name.len() > 0
{
    xiom.env.var_opt(name)
}

// -- Current executable path --------------------------------------------------

/// Get the full path of the currently running executable.
/// Delegates to xiom.env.current_exe() which reads argv[0].
/// Returns Some(path) on success, None if the path cannot be determined.
pub fn current_exe_path() -> Option[Str] {
    let result = xiom.env.current_exe();
    match result {
        Ok(path) => Some(path);
        Err(_) => None;
    }
}

// -- Spawn command ------------------------------------------------------------
//
/// Execute an external command with arguments and wait for it to complete.
/// Uses the C system() function (the same backend as xiom.os.spawn).
/// Returns the exit code on success.
/// WARNING: system() passes the command through the shell (cmd.exe on Windows,
/// /bin/sh on Unix). This is subject to command injection if user input is
/// interpolated into the command string. For serious use, prefer a real
/// CreateProcess/fork+exec wrapper (future extension).
///
/// Complexity: delegates to OS process creation.

// Join CLI arguments into a single command string joined by spaces.
// Mirrors the private build_command_string in xiom.os.
fn build_command_string(command: Str, args: &Vec[Str]) -> Str {
    var cmd = command;
    var i: Int = 0;
    let alen = args.len();
    while i < alen {
        cmd = cmd + " " + args[i];
        i = i + 1;
    };
    cmd
}

pub fn spawn_command(cmd: Str, args: &Vec[Str]) -> Result[Int, Str]
    requires: cmd.len() > 0
    ensures:  result is Ok => result >= 0
{
    let cmd_str = build_command_string(cmd, args);
    // Use the system() extern; same as os.xi's private spawn function.
    let rc: Int32;
    unsafe {
        rc = system(cstr(cmd_str));
    }
    if rc == -1 {
        return Err("spawn_command: failed to execute: " + cmd);
    };
    Ok(rc as Int)
}

// -- Command existence check --------------------------------------------------
//
/// Check whether a command/program exists on the system PATH.
/// Uses platform-specific lookup:
///   Windows: "where <name> > nul 2>&1"
///   Unix:    "which <name> > /dev/null 2>&1"
/// WARNING: This spawns a shell subprocess and is relatively slow.
/// Suitable for one-shot checks, not hot-path lookups.
///
/// Complexity: O(1) API + cost of spawning a shell process.

/// Returns true if the named command can be found via the system PATH.
/// On Windows: runs "where <name> > nul 2>&1".
/// On Unix: runs "which <name> > /dev/null 2>&1".
pub fn command_exists(name: Str) -> Bool
    requires: name.len() > 0
{
    // Build the platform-appropriate check command.
    var check_cmd: Str;
    if xiom.env.OS == "windows" {
        check_cmd = "where " + name + " > nul 2>&1";
    } else {
        check_cmd = "which " + name + " > /dev/null 2>&1";
    };
    let rc: Int32;
    unsafe {
        rc = system(cstr(check_cmd));
    }
    rc == 0
}

// -- v0.56: Production process management -------------------------------------
//
// These functions delegate to the xiom_runtime.c OS process
// primitives (CreateProcessA on Windows, fork+exec on POSIX).
// Unlike the system()-based spawn_command(), these provide:
//   - Exit-code capture (spawn_blocking)
//   - Process kill (kill)
//   - Process wait (wait)
//   - Liveliness check (is_running)
//
// All spawn operations are BLOCKING -- the caller is suspended until
// the child process completes.  For asynchronous use, spawn in a
// separate thread via thread.spawn.

/// Spawn a command via the OS shell and wait for completion.
/// Returns Ok(exit_code) on success, Err on spawn failure.
/// BLOCKING: the calling thread blocks until the child exits.
/// On Windows: uses cmd.exe /c internally.
/// On POSIX:   uses /bin/sh -c internally.
pub fn spawn_blocking(command: Str) -> Result[Int, Str]
    requires: command.len() > 0
    ensures:  result is Ok => result >= 0
{
    let rc: Int64;
    unsafe {
        rc = xiom_process_spawn(cstr(command));
    }
    if rc < 0 {
        return Err("spawn_blocking: failed to spawn process");
    };
    Ok(rc as Int)
}

/// Terminate a process by PID.  Returns true on success, false
/// if the process could not be killed (doesn't exist, access denied).
pub fn kill(pid: Int) -> Bool
    requires: pid > 0
{
    let rc: Int32;
    unsafe {
        rc = xiom_process_kill(pid as Int64);
    }
    rc == 0
}

/// Wait for a process to exit and return its exit code.
/// Returns Ok(exit_code) on success, Err if the process doesn't exist
/// or the wait failed.
/// BLOCKING: blocks until the target process terminates.
pub fn wait(pid: Int) -> Result[Int, Str]
    requires: pid > 0
{
    let rc: Int64;
    unsafe {
        rc = xiom_process_wait(pid as Int64);
    }
    if rc < 0 {
        return Err("wait: process not found or wait error");
    };
    Ok(rc as Int)
}

/// Check whether a process is still running.
/// Returns true if the process exists and is running, false otherwise.
/// May return false for processes owned by other users (access denied).
pub fn is_running(pid: Int) -> Bool
    requires: pid > 0
{
    let rc: Int32;
    unsafe {
        rc = xiom_process_running(pid as Int64);
    }
    rc == 1
}

// XIOM - OS: proc_ffi (process control via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.proc_ffi

// Depends on: xiom.ffi

// ============================================================================
// Low-level process control beyond process.xi: fork/wait, popen pipes,
// posix_spawn/exec, process identity and signal delivery. getpid delegates to
// xiom.os.process_id (different name -- safe); the wait-status decoders
// (exit_code / exit_signal) are pure bit math; the remaining functions need
// POSIX syscalls the pure stdlib does not expose -- documented stubs.
// ============================================================================

use xiom.os;

/// Fork the current process (child gets 0).
/// NOT IMPLEMENTED: requires the fork syscall.
/// Returns: Err("fork: fork syscall not available in the pure stdlib").
pub fn fork() -> Result[Int, Str] {
  Err("fork: fork syscall not available in the pure stdlib")
}

/// Wait for a child.
/// NOT IMPLEMENTED: requires the waitpid syscall.
/// Returns: Err("waitpid: waitpid syscall not available in the pure stdlib").
pub fn waitpid(pid: Int, options: Int) -> Result[Int, Str] {
  let _ = pid;
  let _ = options;
  Err("waitpid: waitpid syscall not available in the pure stdlib")
}

/// Wait for any child.
/// NOT IMPLEMENTED: requires the wait syscall.
/// Returns: Err("wait: wait syscall not available in the pure stdlib").
pub fn wait() -> Result[Int, Str] {
  Err("wait: wait syscall not available in the pure stdlib")
}

/// Open a pipe to/from a command.
/// NOT IMPLEMENTED: requires the popen libc call.
/// Returns: Err("popen: popen not available in the pure stdlib").
pub fn popen(cmd: Str, mode: Str) -> Result[Int, Str] {
  let _ = cmd;
  let _ = mode;
  Err("popen: popen not available in the pure stdlib")
}

/// Close a popen pipe and get the status.
/// NOT IMPLEMENTED: requires the pclose libc call.
/// Returns: Err("pclose: pclose not available in the pure stdlib").
pub fn pclose(pipe: Int) -> Result[Int, Str] {
  let _ = pipe;
  Err("pclose: pclose not available in the pure stdlib")
}

/// Spawn a process by path.
/// NOT IMPLEMENTED: requires posix_spawn.
/// Returns: Err("posix_spawn: posix_spawn not available in the pure stdlib").
pub fn posix_spawn(path: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = path;
  let _ = args;
  Err("posix_spawn: posix_spawn not available in the pure stdlib")
}

/// Spawn searching PATH.
/// NOT IMPLEMENTED: requires posix_spawnp.
/// Returns: Err("posix_spawnp: posix_spawnp not available in the pure stdlib").
pub fn posix_spawnp(file: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = file;
  let _ = args;
  Err("posix_spawnp: posix_spawnp not available in the pure stdlib")
}

/// Replace the process image.
/// NOT IMPLEMENTED: requires the execv syscall.
/// Returns: Err("execv: execv syscall not available in the pure stdlib").
pub fn execv(path: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = path;
  let _ = args;
  Err("execv: execv syscall not available in the pure stdlib")
}

/// Exec searching PATH.
/// NOT IMPLEMENTED: requires the execvp syscall.
/// Returns: Err("execvp: execvp syscall not available in the pure stdlib").
pub fn execvp(file: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = file;
  let _ = args;
  Err("execvp: execvp syscall not available in the pure stdlib")
}

/// Current process id.
/// Delegates to xiom.os.process_id.
/// Complexity: O(1).
pub fn getpid() -> Int {
  let pid = os.process_id();
  pid
}

/// Parent process id.
/// NOT IMPLEMENTED: requires the getppid syscall. Returns 0.
pub fn getppid() -> Int {
  0
}

/// Session id.
/// NOT IMPLEMENTED: requires the getsid syscall. Returns 0.
pub fn getsid(pid: Int) -> Int {
  let _ = pid;
  0
}

/// Send a signal.
/// NOT IMPLEMENTED: requires the kill syscall.
/// Returns: Err("kill: kill syscall not available in the pure stdlib").
pub fn kill(pid: Int, sig: Int) -> Result[Unit, Str] {
  let _ = pid;
  let _ = sig;
  Err("kill: kill syscall not available in the pure stdlib")
}

/// Send a signal to the current process.
/// NOT IMPLEMENTED: requires the raise libc call.
/// Returns: Err("raise: raise not available in the pure stdlib").
pub fn raise(sig: Int) -> Result[Unit, Str] {
  let _ = sig;
  Err("raise: raise not available in the pure stdlib")
}

/// Extract the exit code from a wait status.
/// Parameters: status -- a wait()/waitpid() status word.
/// Returns: the low 8 bits of the shifted status.
/// Complexity: O(1). Pure.
pub fn exit_code(status: Int) -> Int {
  let shifted = status >> 8;
  shifted & 0xFF
}

/// Extract the terminating signal from a wait status.
/// Parameters: status -- a wait()/waitpid() status word.
/// Returns: the low 7 bits of the status.
/// Complexity: O(1). Pure.
pub fn exit_signal(status: Int) -> Int {
  status & 0x7F
}

/// Poll a process (None if still running).
/// NOT IMPLEMENTED: requires waitpid(WNOHANG). Returns None.
pub fn process_status(pid: Int) -> Option[Int] {
  let _ = pid;
  None
}

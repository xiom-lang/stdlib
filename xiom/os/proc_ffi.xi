// XIOM - OS: proc_ffi (process control via FFI syscalls)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.os.proc_ffi

// Depends on: xiom.ffi, xiom.env, xiom.io.pipe

// ============================================================================
// Low-level process control beyond process.xi: fork/wait, popen pipes,
// posix_spawn/exec, process identity and signal delivery. getpid delegates to
// xiom.os.process_id (different name -- safe); the wait-status decoders
// (exit_code / exit_signal) are pure bit math.
//
// Wave 160 landed the popen-class, non-blocking spawn surface
// (REL-20261015-2202-pulse item 3; the multi-worker supervisor / drain-safe
// reload shape):
//   - spawn_with_pipes(cmd, dir) -- shell-string child with three pipes; the
//     parent returns immediately and drains through the existing fd read
//     helpers (pipe.pipe_read / pipe.pipe_read_line) or drain_fd below.
//   - PipedChild.wait / .kill / .close_pipes / .is_running -- child control.
//   - popen(cmd, mode) / pclose(child) -- the libc-class pair over the same
//     runtime primitive ("r" reads out_fd, "w" writes in_fd; both
//     directions of a child are patched at once).
//   - posix_spawn / posix_spawnp -- argv-based (no shell) spawn on POSIX
//     (fork + execv/execvp); on Windows both map to CreateProcessA.
//   - wait_status(pid) -- the raw waitpid status word on POSIX (feed it to
//     exit_code / exit_signal); on Windows there is no signal status, so it
//     reports the child's exit code as an unsigned 32-bit value.
// fork/waitpid/wait/execv/execvp/raise remain honest Err stubs: the XIOM
// process model is spawn-based (fork would duplicate the managed runtime
// state, exec would replace the running program image).
//
// Wait-result convention (PipedChild.wait / pclose): Ok(exit_code) for a
// normal exit; Ok(128 + signal) when the child was terminated by a signal
// (POSIX; e.g. kill -> SIGKILL -> 137). On Windows the terminator's exit
// code is reported as-is (PipedChild.kill terminates with code 1).
// ============================================================================

use xiom.os;
use xiom.env;
use xiom.io.pipe;

extern "C" {
  // Wave 160: non-blocking pipe/argv spawns + raw wait status
  // (runtime/xiom_runtime.c). 64-bit returns: -1 is a real failure value.
  fn xiom_process_spawn_pipes(cmd: *UInt8, dir: *UInt8, fds: *Int32) -> Int64;
  fn xiom_process_spawn_args(file: *UInt8, args_blob: *UInt8, dir: *UInt8, search_path: Int32) -> Int64;
  fn xiom_process_wait_status(pid: Int64) -> Int64;
  fn xiom_process_kill(pid: Int64) -> Int32;
  fn xiom_process_running(pid: Int64) -> Int32;
}

// -- Helpers ------------------------------------------------------------------

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

// Directory pointer for the spawns: an empty dir maps to "." (same working
// directory), so the runtime never needs a null pointer from XIOM.
fn cstr_dir(dir: Str) -> *UInt8
  requires: true
{
  unsafe {
    if dir.len() == 0 {
      return cstr(".");
    }
    return cstr(dir);
  }
}

// Raw byte at `i` over a cached pointer (wave 133): Str.byte_at strnlens the
// whole string per call, so per-byte loops are quadratic otherwise.
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Serialize argv as a NUL-separated blob (each entry NUL-terminated, one
// extra NUL terminates the list) for xiom_process_spawn_args. Entries cannot
// contain NUL bytes and must be non-empty -- the same restrictions as POSIX
// argv (an empty entry terminates the list early).
fn args_blob(args: &Vec[Str]) -> Vec[UInt8] {
  var blob: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < args.len() {
    let a = args[i];
    let alen = a.len();
    let abase: *UInt8 = a.c_str();
    var j: Int = 0;
    while j < alen {
      blob.push(_raw_byte(abase, j));
      j = j + 1;
    }
    blob.push(0 as UInt8);
    i = i + 1;
  }
  blob.push(0 as UInt8);
  blob
}

// -- Popen-class non-blocking spawn (wave 160) --------------------------------

/// PipedChild is a non-blocking spawned child plus its three parent-side
/// pipe descriptors. The parent keeps the fds: write the child's stdin on
/// in_fd, read stdout/stderr from out_fd / err_fd through the xiom.io.pipe
/// helpers (pipe_read / pipe_read_line) or drain_fd. The child runs
/// independently of the parent (spawn never waits); reap it with wait()
/// after draining, and kill() first when needed.
pub type PipedChild = {
  pid: Int;
  in_fd: Int;
  out_fd: Int;
  err_fd: Int;
}

/// spawn_with_pipes starts `cmd` through the OS shell (cmd.exe /c on
/// Windows, /bin/sh -c on POSIX) with fresh pipes on all three standard
/// streams and returns immediately with the child pid and the parent-side
/// fds (in_fd: write the child's stdin; out_fd / err_fd: read stdout /
/// stderr). `dir` is the child's working directory; "" inherits the
/// parent's. Reads/writes use the xiom.io.pipe surface; drain_fd reads
/// until EOF (i.e. until the child and every holder of the write end
/// closes it).
/// Returns: Ok(PipedChild); Err on spawn failure.
/// Complexity: O(1) OS calls.
pub fn spawn_with_pipes(cmd: Str, dir: Str) -> Result[PipedChild, Str]
  ensures: cmd.len() == 0 => result.is_err == true
{
  if cmd.len() == 0 {
    return Err("spawn_with_pipes: empty command");
  }
  var fds: [3]Int32;
  fds[0] = -1;
  fds[1] = -1;
  fds[2] = -1;
  let pid64: Int64;
  unsafe {
    pid64 = xiom_process_spawn_pipes(cstr(cmd), cstr_dir(dir), &fds[0]);
  }
  if pid64 < 0 {
    return Err("spawn_with_pipes: failed to spawn: " + cmd);
  }
  return Ok(PipedChild{
    pid: pid64 as Int;
    in_fd: fds[0] as Int;
    out_fd: fds[1] as Int;
    err_fd: fds[2] as Int;
  });
}

/// Drain all bytes from `fd` until EOF, appending them to `buf`.
/// Blocks until the writer closes its end -- for a child's stdout that
/// happens when the child (and every process holding the write end)
/// exits/closes it.
/// Returns: Ok(total bytes appended); Err when a read fails.
/// Complexity: O(bytes) in 256-byte chunks.
pub fn drain_fd(fd: Int, buf: &mut Vec[UInt8]) -> Result[Int, Str]
  requires: fd >= 0
{
  var total: Int = 0;
  var done = false;
  while !done {
    let r = pipe.pipe_read(fd, buf);
    match r {
      Ok(n) => {
        if n <= 0 {
          done = true;
        } else {
          total = total + n;
        }
      }
      Err(_) => {
        return Err("drain_fd: pipe read failed");
      }
    }
  }
  return Ok(total);
}

/// Wait for the child and report its status: Ok(exit_code) for a normal
/// exit, or Ok(128 + signal) when it was terminated by a signal (POSIX);
/// on Windows the child's exit code as-is (PipedChild.kill reports 1).
/// Err when the wait itself fails (unknown pid / wait error).
/// BLOCKING: blocks until the child terminates.
/// Complexity: one waitpid / WaitForSingleObject.
pub fn PipedChild.wait(self) -> Result[Int, Str]
  requires: self.pid > 0
{
  let st: Int64;
  unsafe {
    st = xiom_process_wait_status(self.pid as Int64);
  }
  if st < 0 {
    return Err("wait: process not found or wait error");
  }
  let s = st as Int;
  if env.OS == "windows" {
    return Ok(s);
  }
  let sig = exit_signal(s);
  if sig != 0 {
    return Ok(128 + sig);
  }
  return Ok(exit_code(s));
}

/// Terminate a process (TerminateProcess on Windows, SIGKILL on POSIX).
/// Only SIGKILL (9) is available: the runtime's spawn/terminate model is
/// cross-platform, and other signals need a POSIX-only delivery path.
/// Err when the signal is not 9 or the process cannot be terminated.
pub fn kill(pid: Int, sig: Int) -> Result[Unit, Str]
  requires: pid > 0
  ensures: sig != 9 => result.is_err == true
{
  if sig != 9 {
    return Err("kill: only SIGKILL (9) is available in the spawn-based model");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_process_kill(pid as Int64);
  }
  if rc != 0 {
    return Err("kill: process not found or access denied");
  }
  return Ok(());
}

/// Terminate the child (SIGKILL / TerminateProcess). The pipes stay open;
/// close_pipes + wait after it to reap. Err when the kill fails (e.g. the
/// child already exited and its handle is gone).
pub fn PipedChild.kill(self) -> Result[Unit, Str]
  requires: self.pid > 0
{
  return kill(self.pid, 9);
}

/// Close the three parent-side pipe descriptors.
pub fn PipedChild.close_pipes(self)
  requires: true  // fds may already be closed by the caller
{
  if self.in_fd >= 0 {
    pipe.pipe_close(self.in_fd);
  }
  if self.out_fd >= 0 {
    pipe.pipe_close(self.out_fd);
  }
  if self.err_fd >= 0 {
    pipe.pipe_close(self.err_fd);
  }
}

/// Whether the child process is still alive (best effort: may report false
/// for processes owned by other users; a reaped child is never running).
pub fn PipedChild.is_running(self) -> Bool
  requires: self.pid > 0
{
  let rc: Int32;
  unsafe {
    rc = xiom_process_running(self.pid as Int64);
  }
  return rc == 1;
}

/// popen opens a pipe to/from a shell command -- the libc-class pair with
/// pclose, backed by spawn_with_pipes. `mode` selects the documented
/// primary direction: "r" reads the child's stdout on out_fd, "w" writes
/// the child's stdin on in_fd. Both directions are patched at once (and
/// err_fd always carries the child's stderr); the mode only names the
/// intended use. The child is not reaped until pclose / wait.
/// Returns: Ok(PipedChild); Err on spawn failure or a mode other than
/// "r"/"w".
/// Complexity: O(1) OS calls.
pub fn popen(cmd: Str, mode: Str) -> Result[PipedChild, Str]
  ensures: cmd.len() == 0 => result.is_err == true
  ensures: (mode != "r" && mode != "w") => result.is_err == true
{
  if cmd.len() == 0 {
    return Err("popen: empty command");
  }
  if mode != "r" && mode != "w" {
    return Err("popen: mode must be r or w");
  }
  return spawn_with_pipes(cmd, "");
}

/// pclose closes the parent-side fds and waits for the child, with the
/// same status convention as PipedChild.wait (Ok(exit_code), or
/// Ok(128 + signal) on POSIX signal death). Call it once per PipedChild.
/// BLOCKING: waits for the child after closing the pipes.
pub fn pclose(child: PipedChild) -> Result[Int, Str]
  requires: child.pid > 0
{
  child.close_pipes();
  return child.wait();
}

// -- posix_spawn / posix_spawnp (wave 160) ------------------------------------

// Shared argv spawn: `search_path` selects execvp vs execv (POSIX);
// on Windows the runtime maps both to CreateProcessA (posix_spawnp
// resolves the image from argv[0], which conventionally names the program).
fn spawn_exec(file: Str, args: &Vec[Str], search_path: Bool) -> Result[Int, Str]
  ensures: file.len() == 0 => result.is_err == true
{
  if file.len() == 0 {
    return Err("posix_spawn: empty file");
  }
  let blob = args_blob(args);
  var sp: Int32 = 0;
  if search_path {
    sp = 1;
  }
  let pid64: Int64;
  unsafe {
    pid64 = xiom_process_spawn_args(cstr(file), blob.as_ptr(), cstr_dir(""), sp);
  }
  if pid64 < 0 {
    return Err("posix_spawn: failed to spawn: " + file);
  }
  return Ok(pid64 as Int);
}

/// posix_spawn starts `path` with `args` and no shell (fork + execv on
/// POSIX). `args` are passed verbatim as argv[0..]; when empty, `path`
/// itself is argv[0]. The child inherits the parent's standard handles
/// (no pipes -- use spawn_with_pipes for those); reap it with wait /
/// wait_status / PipedChild-style helpers. Windows maps to CreateProcessA
/// with lpApplicationName = path (argv[0] stays whatever the caller
/// passed).
/// Returns: Ok(pid) -- the parent is NOT blocked; Err on spawn failure.
/// Complexity: O(1) OS calls.
pub fn posix_spawn(path: Str, args: &Vec[Str]) -> Result[Int, Str]
  ensures: path.len() == 0 => result.is_err == true
{
  return spawn_exec(path, args, false);
}

/// posix_spawnp searches PATH for `file` (fork + execvp on POSIX;
/// CreateProcessA image resolution from argv[0] on Windows -- argv[0]
/// should name the program). Same handle-inheritance and reaping rules as
/// posix_spawn.
/// Returns: Ok(pid); Err on spawn failure.
/// Complexity: O(1) OS calls.
pub fn posix_spawnp(file: Str, args: &Vec[Str]) -> Result[Int, Str]
  ensures: file.len() == 0 => result.is_err == true
{
  return spawn_exec(file, args, true);
}

/// wait_status waits for a child and returns the raw status word: on POSIX
/// the waitpid status (decode with exit_code / exit_signal; WIFEXITED is
/// (status & 0x7F) == 0); on Windows the exit code as an unsigned 32-bit
/// value (no signal status exists there). Pairs with posix_spawn /
/// posix_spawnp, which return bare pids.
/// Returns: Ok(status); Err when the wait fails.
/// BLOCKING: blocks until the target process terminates.
pub fn wait_status(pid: Int) -> Result[Int, Str]
  requires: pid > 0
{
  let st: Int64;
  unsafe {
    st = xiom_process_wait_status(pid as Int64);
  }
  if st < 0 {
    return Err("wait_status: process not found or wait error");
  }
  return Ok(st as Int);
}

// -- Unimplemented (honest stubs) ---------------------------------------------

/// Fork the current process (child gets 0).
/// NOT IMPLEMENTED: fork would duplicate the managed XIOM runtime state
/// (heap, GC, threads) without a consistent reload; the spawn-based model
/// (spawn_with_pipes / posix_spawn) is the supported route.
/// Returns: Err("fork: ...").
pub fn fork() -> Result[Int, Str] {
  Err("fork: not available -- fork would duplicate the managed runtime state; use spawn_with_pipes or posix_spawn")
}

/// Wait for a child.
/// NOT IMPLEMENTED: requires the waitpid syscall. Use wait_status(pid),
/// which returns the raw waitpid status.
/// Returns: Err("waitpid: ...").
pub fn waitpid(pid: Int, options: Int) -> Result[Int, Str] {
  let _ = pid;
  let _ = options;
  Err("waitpid: not available -- use wait_status(pid) for a raw status")
}

/// Wait for any child.
/// NOT IMPLEMENTED: requires the wait syscall. Use wait_status(pid).
/// Returns: Err("wait: ...").
pub fn wait() -> Result[Int, Str] {
  Err("wait: not available -- use wait_status(pid)")
}

/// Replace the process image.
/// NOT IMPLEMENTED: exec replaces the running program image, which the
/// managed runtime cannot survive (live heap, GC, threads); spawn a child
/// instead (posix_spawn / spawn_with_pipes).
/// Returns: Err("execv: ...").
pub fn execv(path: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = path;
  let _ = args;
  Err("execv: not available -- exec cannot replace the managed runtime; spawn a child instead")
}

/// Exec searching PATH.
/// NOT IMPLEMENTED: see execv.
/// Returns: Err("execvp: ...").
pub fn execvp(file: Str, args: &Vec[Str]) -> Result[Int, Str] {
  let _ = file;
  let _ = args;
  Err("execvp: not available -- exec cannot replace the managed runtime; spawn a child instead")
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

/// Send a signal to the current process.
/// NOT IMPLEMENTED: requires the raise libc call; the spawn-based model
/// terminates children via kill(pid, 9).
/// Returns: Err("raise: ...").
pub fn raise(sig: Int) -> Result[Unit, Str] {
  let _ = sig;
  Err("raise: not available in the spawn-based model")
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

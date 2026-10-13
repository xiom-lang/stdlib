// XIOM -- Signal Info (xiom.os.signal)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Signal name/code mapping and classification helpers (pure) plus real
// delivery since wave 123: signal_install / signal_wait / signal_pending
// (sigaction + self-pipe on POSIX, console control events on Windows;
// REL-20261012-1946-pulse ask 1 -- graceful drain). The module
// deliberately does NOT import the flat xiom.os module: flat os declares
// an extern named `signal` and functions `on_signal`/`raise_signal`, and
// importing both would make the `signal` module prefix ambiguous
// (compiler module/function name collision).

module xiom.os.signal

use xiom.string;

extern "C" {
  fn xiom_signal_install() -> Int32;
  fn xiom_signal_installed() -> Int32;
  fn xiom_signal_wait(timeout_ms: Int) -> Int;
  fn xiom_signal_raise(sig: Int32) -> Int32;
}

/// signal_name returns the canonical name for a signal number, or
/// "unknown" for numbers outside the table. Complexity: O(1). Pure.
pub fn signal_name(num: Int) -> Str
  ensures: result.len() > 0
{
  if num == 1 { return "HUP"; }
  if num == 2 { return "INT"; }
  if num == 3 { return "QUIT"; }
  if num == 4 { return "ILL"; }
  if num == 5 { return "TRAP"; }
  if num == 6 { return "ABRT"; }
  if num == 7 { return "BUS"; }
  if num == 8 { return "FPE"; }
  if num == 9 { return "KILL"; }
  if num == 10 { return "USR1"; }
  if num == 11 { return "SEGV"; }
  if num == 12 { return "USR2"; }
  if num == 13 { return "PIPE"; }
  if num == 14 { return "ALRM"; }
  if num == 15 { return "TERM"; }
  if num == 16 { return "STKFLT"; }
  if num == 17 { return "CHLD"; }
  if num == 18 { return "CONT"; }
  if num == 19 { return "STOP"; }
  if num == 20 { return "TSTP"; }
  if num == 21 { return "TTIN"; }
  if num == 22 { return "TTOU"; }
  if num == 23 { return "URG"; }
  if num == 24 { return "XCPU"; }
  if num == 25 { return "XFSZ"; }
  if num == 26 { return "VTALRM"; }
  if num == 27 { return "PROF"; }
  if num == 28 { return "WINCH"; }
  if num == 29 { return "IO"; }
  if num == 30 { return "PWR"; }
  if num == 31 { return "SYS"; }
  "unknown"
}

/// signal_code returns the signal number for a canonical name, or None.
/// Matching is case-insensitive on the letters (wave-123 fix: the body
/// now upper-cases first, matching this contract). Complexity: O(n). Pure.
pub fn signal_code(name: Str) -> Option[Int]
  ensures: (result.is_some == true) => (name.len() >= 2)
{
  let n = string.str_upper(name);
  if n == "HUP" || n == "SIGHUP" { return Some(1); }
  if n == "INT" || n == "SIGINT" { return Some(2); }
  if n == "QUIT" || n == "SIGQUIT" { return Some(3); }
  if n == "ILL" || n == "SIGILL" { return Some(4); }
  if n == "TRAP" || n == "SIGTRAP" { return Some(5); }
  if n == "ABRT" || n == "SIGABRT" { return Some(6); }
  if n == "BUS" || n == "SIGBUS" { return Some(7); }
  if n == "FPE" || n == "SIGFPE" { return Some(8); }
  if n == "KILL" || n == "SIGKILL" { return Some(9); }
  if n == "USR1" || n == "SIGUSR1" { return Some(10); }
  if n == "SEGV" || n == "SIGSEGV" { return Some(11); }
  if n == "USR2" || n == "SIGUSR2" { return Some(12); }
  if n == "PIPE" || n == "SIGPIPE" { return Some(13); }
  if n == "ALRM" || n == "SIGALRM" { return Some(14); }
  if n == "TERM" || n == "SIGTERM" { return Some(15); }
  if n == "CHLD" || n == "SIGCHLD" { return Some(17); }
  if n == "CONT" || n == "SIGCONT" { return Some(18); }
  if n == "STOP" || n == "SIGSTOP" { return Some(19); }
  if n == "TSTP" || n == "SIGTSTP" { return Some(20); }
  if n == "TTIN" || n == "SIGTTIN" { return Some(21); }
  if n == "TTOU" || n == "SIGTTOU" { return Some(22); }
  if n == "URG" || n == "SIGURG" { return Some(23); }
  if n == "XCPU" || n == "SIGXCPU" { return Some(24); }
  if n == "XFSZ" || n == "SIGXFSZ" { return Some(25); }
  if n == "VTALRM" || n == "SIGVTALRM" { return Some(26); }
  if n == "PROF" || n == "SIGPROF" { return Some(27); }
  if n == "WINCH" || n == "SIGWINCH" { return Some(28); }
  if n == "IO" || n == "SIGIO" { return Some(29); }
  if n == "PWR" || n == "SIGPWR" { return Some(30); }
  if n == "SYS" || n == "SIGSYS" { return Some(31); }
  None
}

/// signal_is_ignorable returns true for signals that can be ignored
/// (not SIGKILL or SIGSTOP). Complexity: O(1). Pure.
pub fn signal_is_ignorable(num: Int) -> Bool
  ensures: result == (num != 9 && num != 19 && num > 0)
{
  num != 9 && num != 19 && num > 0
}

/// signal_is_catchable returns true for signals a process can install a
/// handler for (not SIGKILL or SIGSTOP). Complexity: O(1). Pure.
pub fn signal_is_catchable(num: Int) -> Bool
  ensures: result == (num != 9 && num != 19 && num > 0)
{
  num != 9 && num != 19 && num > 0
}

/// signal_default_action returns the default disposition ("term", "core",
/// "stop", "cont", "ignore", or "unknown"). Complexity: O(1). Pure.
pub fn signal_default_action(num: Int) -> Str
  ensures: result.len() > 0
{
  if num == 18 { return "cont"; }
  if num == 19 || num == 20 || num == 21 || num == 22 { return "stop"; }
  if num == 1 || num == 2 || num == 3 || num == 15 { return "term"; }
  if num == 4 || num == 6 || num == 7 || num == 8 || num == 11 { return "core"; }
  if num == 17 || num == 23 || num == 28 { return "ignore"; }
  if num == 9 { return "term"; }
  if num == 13 { return "term"; }
  "unknown"
}

/// signal_raise delivers `num` to the current process. Real implementation
/// (wave 123): POSIX uses the libc raise() (the handlers must be installed
/// first -- signal_install -- or the default action terminates the
/// process); Windows latches the number and wakes a signal_wait as
/// self-delivery (there is no OS signal for SIGTERM on Windows; the
/// console-event mapping is CTRL_C -> 2, CTRL_BREAK -> 3, close/logoff/
/// shutdown -> 15). Complexity: O(1) syscall.
/// Returns: Ok(()) once delivered; Err before signal_install, for invalid
/// numbers, and for uncatchable signals.
pub fn signal_raise(num: Int) -> Result[Unit, Str]
  ensures: (num <= 0) => (result.is_err == true)
{
  if num <= 0 {
    return Err("signal_raise: invalid signal number");
  }
  if !signal_is_catchable(num) {
    return Err("signal_raise: signal is not catchable");
  }
  let st: Int32;
  unsafe {
    st = xiom_signal_installed();
  }
  if st != 1 {
    return Err("signal_raise: install the handlers first (signal_install)");
  }
  let rc: Int32;
  unsafe {
    rc = xiom_signal_raise(num as Int32);
  }
  if rc != 0 {
    return Err("signal_raise: raise failed");
  }
  Ok(())
}

/// signal_install installs the delivery handlers: SIGINT/SIGTERM via
/// sigaction with a self-pipe waker on POSIX; console control events
/// (CTRL_C -> 2, CTRL_BREAK -> 3, close/logoff/shutdown -> 15) via
/// SetConsoleCtrlHandler on Windows. Idempotent; call once before
/// signal_wait / signal_raise.
/// Returns: Ok(()) once installed; Err on failure.
/// Complexity: O(1).
pub fn signal_install() -> Result[Unit, Str]
  ensures: result is Ok => signal_installed_marker()
{
  let rc: Int32;
  unsafe {
    rc = xiom_signal_install();
  }
  if rc != 0 {
    return Err("signal_install: install failed");
  }
  Ok(())
}

// signal_installed_marker re-reads the runtime install flag; the
// signal_install Ok-side clause proves the install landed.
fn signal_installed_marker() -> Bool
{
  let st: Int32;
  unsafe {
    st = xiom_signal_installed();
  }
  st == 1
}

/// signal_wait waits up to timeout_ms for a delivered signal and returns
/// its number (2 = INT, 15 = TERM, 3 = BREAK/QUIT; 0 on timeout).
/// Coalesced delivery: when several signals arrive between waits, the
/// last one wins. Bounded timeouts only (negative is Err; no unbounded
/// wait). Real implementation (wave 123) -- the graceful-drain primitive:
/// install once, then loop { s = signal_wait(ms); if s == 15 || s == 2 {
/// stop accepting; flush; exit 0 } }.
/// Returns: Ok(signal number or 0); Err on bad arguments or failure.
/// Complexity: blocking wait.
pub fn signal_wait(timeout_ms: Int) -> Result[Int, Str]
  ensures: result is Ok => result >= 0
  ensures: result is Ok => timeout_ms >= 0
{
  if timeout_ms < 0 {
    return Err("signal_wait: negative timeout");
  }
  let rc: Int;
  unsafe {
    rc = xiom_signal_wait(timeout_ms);
  }
  if rc < 0 {
    return Err("signal_wait: wait failed (install the handlers first)");
  }
  Ok(rc)
}

/// signal_handle installs a handler callback for `num`. NOT AVAILABLE:
/// callbacks from signal context need a compiler-side trampoline; use the
/// poll API instead (signal_install + signal_wait / signal_pending).
/// Currently a documented Err stub so callers can compile against the
/// surface and degrade to no-handler behavior.
/// Complexity: O(1).
pub fn signal_handle(num: Int, cb: fn(Int) -> Unit) -> Result[Unit, Str]
  ensures: result.is_err == true  // always Err while runtime-backed
{
  if !signal_is_catchable(num) {
    return Err("signal_handle: signal is not catchable");
  }
  Err("signal_handle: callback mode not available (use signal_install + signal_wait)")
}

/// signal_pending is the non-blocking check: signal_wait(0) under the
/// hood. Returns the pending signal number (0 when none); reading clears
/// it. Real implementation (wave 123).
/// Returns: Ok(signal number or 0); Err on failure.
pub fn signal_pending() -> Result[Int, Str]
  ensures: result is Ok => result >= 0
{
  return signal_wait(0);
}

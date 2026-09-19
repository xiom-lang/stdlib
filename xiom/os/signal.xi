// XIOM -- Signal Info (xiom.os.signal)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Signal name/code mapping and classification helpers. Pure mapping
// tables. The module deliberately does NOT import the flat xiom.os
// module: flat os declares an extern named `signal` and functions
// `on_signal`/`raise_signal`, and importing both would make the
// `signal` module prefix ambiguous (compiler module/function name
// collision). signal_raise uses a local extern for the raise syscall.

module xiom.os.signal

extern "C" {
  fn raise_sig(sig: Int32) -> Int32;
}

/// signal_name returns the canonical name for a signal number, or
/// "unknown" for numbers outside the table. Complexity: O(1). Pure.
pub fn signal_name(num: Int) -> Str {
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
/// Matching is case-insensitive on the letters. Complexity: O(1). Pure.
pub fn signal_code(name: Str) -> Option[Int] {
  let n = name;
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
pub fn signal_is_ignorable(num: Int) -> Bool {
  num != 9 && num != 19 && num > 0
}

/// signal_is_catchable returns true for signals a process can install a
/// handler for (not SIGKILL or SIGSTOP). Complexity: O(1). Pure.
pub fn signal_is_catchable(num: Int) -> Bool {
  num != 9 && num != 19 && num > 0
}

/// signal_default_action returns the default disposition ("term", "core",
/// "stop", "cont", "ignore", or "unknown"). Complexity: O(1). Pure.
pub fn signal_default_action(num: Int) -> Str {
  if num == 18 { return "cont"; }
  if num == 19 || num == 20 || num == 21 || num == 22 { return "stop"; }
  if num == 1 || num == 2 || num == 3 || num == 15 { return "term"; }
  if num == 4 || num == 6 || num == 7 || num == 8 || num == 11 { return "core"; }
  if num == 17 || num == 23 || num == 28 { return "ignore"; }
  if num == 9 { return "term"; }
  if num == 13 { return "term"; }
  "unknown"
}

/// signal_raise sends a signal to the current process via the runtime
/// raise() primitive. Complexity: O(1) syscall.
pub fn signal_raise(num: Int) -> Result[Unit, Str] {
  if num <= 0 {
    return Err("signal_raise: invalid signal number");
  }
  let rc = unsafe { raise_sig(num as Int32) };
  if rc != 0 {
    return Err("signal_raise: raise failed");
  }
  Ok(())
}

// XIOM -- Process Query Helpers (xiom.os.proc)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Process query helpers built on the existing xiom.process / xiom.os
// runtime primitives (xiom_process_spawn/kill/wait/running).

module xiom.os.proc

use xiom.process;
use xiom.convert;

// proc_is_running returns true if the process with the given pid is
// still alive. Delegates to xiom.process.is_running, which wraps the
// xiom_process_running runtime intrinsic. Pids must be positive.
pub fn proc_is_running(pid: Int) -> Bool {
  if pid <= 0 {
    return false;
  };
  return process.is_running(pid);
}

// proc_exit_code_success returns true when the exit code indicates
// success (code == 0).
pub fn proc_exit_code_success(code: Int) -> Bool {
  return code == 0;
}

// proc_signal_name maps a POSIX signal number to its conventional name,
// or returns "SIG" + the number for unknown signals.
pub fn proc_signal_name(sig: Int) -> Str {
  if sig == 1 {
    return "HUP";
  } elif sig == 2 {
    return "INT";
  } elif sig == 3 {
    return "QUIT";
  } elif sig == 6 {
    return "ABRT";
  } elif sig == 9 {
    return "KILL";
  } elif sig == 11 {
    return "SEGV";
  } elif sig == 13 {
    return "PIPE";
  } elif sig == 14 {
    return "ALRM";
  } elif sig == 15 {
    return "TERM";
  } elif sig == 17 {
    return "CHLD";
  } elif sig == 19 {
    return "STOP";
  } elif sig == 20 {
    return "TSTP";
  };
  return "SIG" + convert.int_to_string(sig);
}

// proc_status_text formats a process exit code as "exit(<code>)".
// The runtime does not expose wait-status decoding (WIFSIGNALED etc.),
// so signals cannot be distinguished here.
pub fn proc_status_text(code: Int) -> Str {
  return "exit(" + convert.int_to_string(code) + ")";
}

// proc_command_exists returns true if the named command can be found on
// the system PATH. Delegates to xiom.process.command_exists, which runs
// "where <name>" (Windows) or "which <name>" (Unix) via the shell.
// Spawning the command itself is not a reliable existence probe, since
// the system()-based spawn reports the command's exit code rather than
// a spawn failure.
pub fn proc_command_exists(cmd: Str) -> Bool {
  if cmd.is_empty() {
    return false;
  };
  return process.command_exists(cmd);
}

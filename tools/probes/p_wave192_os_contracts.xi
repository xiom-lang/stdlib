// p_wave192_os_contracts.xi -- wave 192: os contract-clause locks.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the wave-192 runtime clauses (a violation aborts
// the probe). Cases:
// 1. terminal_title length relation: ESC]0; + title + BEL == title.len() + 5;
//    terminal_bell is the one-byte BEL payload.
// 2. errno_message is never empty (errno() reports 0 => "unknown error").
// 3. exit_code stays in [0,255] and exit_signal in [0,127], including
//    sign-extended status words; the documented decodes still hold.
// 4. getpid is a positive process id.
// 5. win_version is non-empty; unix_home_dir is non-empty only when
//    env.home_dir() resolves; win_environment_var/win_username keep their
//    env-var relation on Windows.
// 6. fsync/fdatasync accept a real fd (fd >= 0 precondition) and chmod_path
//    accepts a non-empty path with non-negative mode.
// Returns 0 when every case holds.

module p_wave192_os_contracts

use xiom.os.terminal;
use xiom.os.proc_ffi;
use xiom.os.err;
use xiom.os.fs_ffi;
use xiom.os.sync_io;
use xiom.os.win;
use xiom.os.unix;
use xiom.env;
use xiom.io;

fn main() -> Int {
  // 1: terminal escape-sequence payloads.
  let t = terminal.terminal_title("xiom");
  if t.len() != 9 { return 1; }
  if t != "\x1b]0;xiom\x07" { return 2; }
  if terminal.terminal_title("").len() != 5 { return 3; }
  let b = terminal.terminal_bell();
  if b.len() != 1 { return 4; }
  if b != "\x07" { return 5; }

  // 2: errno messages are never empty.
  if err.errno_message().len() == 0 { return 6; }

  // 3: wait-status decoder masks.
  if proc_ffi.exit_code(0) < 0 || proc_ffi.exit_code(0) > 255 { return 7; }
  if proc_ffi.exit_code(-1) < 0 || proc_ffi.exit_code(-1) > 255 { return 8; }
  if proc_ffi.exit_code(256) != 1 { return 9; }
  if proc_ffi.exit_code(65280) != 255 { return 10; }
  if proc_ffi.exit_signal(-1) < 0 || proc_ffi.exit_signal(-1) > 127 { return 11; }
  if proc_ffi.exit_signal(11) != 11 { return 12; }
  if proc_ffi.exit_signal(127) != 127 { return 13; }

  // 4: process id positivity.
  if proc_ffi.getpid() <= 0 { return 14; }

  // 5: platform/env identity clauses.
  if win.win_version().len() == 0 { return 15; }
  let uh = unix.unix_home_dir();
  if uh.len() > 0 {
    if env.home_dir().is_none { return 16; }
  }
  if xiom.os.platform.platform_is_windows() {
    let wv = win.win_environment_var("USERNAME");
    if wv.is_none { return 17; }
    if win.win_username().len() == 0 { return 18; }
  }

  // 6: fd/path domain preconditions on the real durability primitives.
  let path = "p_wave192_os_contracts_tmp.txt";
  let w = io.write_file(path, "wave192");
  if w.is_err { return 19; }
  let cr = fs_ffi.chmod_path(path, 644);
  if cr.is_err { return 20; }
  let h = sync_io.open_append(path);
  match h {
    Ok(fd) => {
      let r = fs_ffi.fsync(fd);
      if r.is_err { return 21; }
      let r2 = fs_ffi.fdatasync(fd);
      if r2.is_err { return 22; }
      let c = sync_io.close_fd(fd);
      if c.is_err { return 23; }
    },
    Err(_) => {
      return 24;
    },
  };
  let _ = io.remove_file(path);

  io.println("p_wave192_os_contracts: OK");
  return 0;
}

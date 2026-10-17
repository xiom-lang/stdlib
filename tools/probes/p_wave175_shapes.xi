// p_wave175_shapes.xi -- wave 175 lock: systemd socket activation
// (LISTEN_PID/LISTEN_FDS -> fds 3..3+N-1) in xiom.net.socket, plus the
// POSIX-only and malformed-input rejection paths. On Windows the probe
// asserts the documented Err; on Linux/WSL it exercises the real adoption
// path, the env consumption, LISTEN_FDNAMES preservation, and the second-call
// guard.
// Returns 0 when all rows hold; a nonzero return names the first failing row.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave175_shapes

use xiom.net.socket;
use xiom.env;
use xiom.os;
use xiom.convert;

fn main() -> Int {
  env.remove_var("LISTEN_PID");
  env.remove_var("LISTEN_FDS");
  env.remove_var("LISTEN_FDNAMES");

  // --- row 1: missing activation variables ---
  let missing = socket.socket_listen_fds();
  if !missing.is_err { return 1; }

  let pid = os.process_id();
  let pid_text = convert.int_to_string(pid);

  if env.host_is_windows() {
    // --- row 2: POSIX-only Err even with a matching PID ---
    env.set_var("LISTEN_PID", pid_text);
    env.set_var("LISTEN_FDS", "2");
    let win = socket.socket_listen_fds();
    if !win.is_err { return 2; }
    env.remove_var("LISTEN_PID");
    env.remove_var("LISTEN_FDS");
    return 0;
  };

  // --- row 3: PID mismatch ---
  env.set_var("LISTEN_PID", "1");
  env.set_var("LISTEN_FDS", "2");
  let mismatch = socket.socket_listen_fds();
  if !mismatch.is_err { return 3; }

  // --- row 4: missing LISTEN_FDS ---
  env.set_var("LISTEN_PID", pid_text);
  env.remove_var("LISTEN_FDS");
  let no_count = socket.socket_listen_fds();
  if !no_count.is_err { return 4; }

  // --- row 5: malformed counts ---
  env.set_var("LISTEN_FDS", "abc");
  if !socket.socket_listen_fds().is_err { return 5; }
  env.set_var("LISTEN_FDS", "0-1");
  if !socket.socket_listen_fds().is_err { return 5; }
  env.set_var("LISTEN_FDS", "1025");
  if !socket.socket_listen_fds().is_err { return 5; }

  // --- row 6: zero fds is a successful empty adoption ---
  env.set_var("LISTEN_FDS", "0");
  let zero = socket.socket_listen_fds();
  match zero {
    Ok(v) => { if v.len() != 0 { return 6; } },
    Err(_) => { return 6; },
  };
  let zero_again = socket.socket_listen_fds();
  if !zero_again.is_err { return 6; }

  // --- row 7: three inherited fds, env consumed, names preserved ---
  env.set_var("LISTEN_PID", pid_text);
  env.set_var("LISTEN_FDS", "3");
  env.set_var("LISTEN_FDNAMES", "http:https:admin");
  let adopted = socket.socket_listen_fds();
  match adopted {
    Ok(v) => {
      if v.len() != 3 { return 7; }
      if v[0] != 3 || v[1] != 4 || v[2] != 5 { return 7; }
    },
    Err(_) => { return 7; },
  };
  if env.get_var("LISTEN_PID").is_ok { return 7; }
  if env.get_var("LISTEN_FDS").is_ok { return 7; }
  let names = env.get_var("LISTEN_FDNAMES");
  match names {
    Ok(n) => { if n != "http:https:admin" { return 7; } },
    Err(_) => { return 7; },
  };

  // --- row 8: a second adoption fails (variables consumed) ---
  let second = socket.socket_listen_fds();
  if !second.is_err { return 8; }
  env.remove_var("LISTEN_FDNAMES");
  return 0;
}

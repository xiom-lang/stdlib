// p_socket_recv_into.xi -- REL-20261022-2049-pulse: reusable receive buffers
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the recv-into pair on a loopback TCP pair (127.0.0.1:39743):
//   * socket_recv_into clears buf, returns the byte count, and fills the
//     caller's Vec with the received bytes (0 = clean EOF);
//   * a second, same-size receive reuses the buffer capacity (no growth);
//   * a larger receive grows once and the following one reuses it;
//   * socket_recv_timeout_into returns Err when the deadline expires with
//     no data and leaves buf empty (the 408 path);
//   * a peer shutdown surfaces as Ok(0), not Err;
//   * invalid fd / non-positive max are Err.
// Returns 0 when every case holds.

module p_socket_recv_into

use xiom.net.socket;

fn main() -> Int {
  // Contracts before any network setup.
  var tmp = Vec[UInt8].new();
  match socket.socket_recv_into(-1, &mut tmp, 16) {
    Ok(_) => { return 1; },
    Err(_) => {},
  };
  match socket.socket_recv_into(0, &mut tmp, 0) {
    Ok(_) => { return 2; },
    Err(_) => {},
  };
  match socket.socket_recv_timeout_into(0, &mut tmp, 16, -1) {
    Ok(_) => { return 3; },
    Err(_) => {},
  };

  let srv = socket.socket_tcp();
  let sfd: Int;
  match srv {
    Ok(f) => { sfd = f; },
    Err(_) => { return 4; },
  };
  let bd = socket.socket_bind(sfd, "127.0.0.1", 39743);
  match bd {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  let ls = socket.socket_listen(sfd, 4);
  match ls {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  let cli = socket.socket_tcp();
  let cfd: Int;
  match cli {
    Ok(f) => { cfd = f; },
    Err(_) => { return 4; },
  };
  let cn = socket.socket_connect(cfd, "127.0.0.1", 39743);
  match cn {
    Ok(_) => {},
    Err(_) => { return 5; },
  };
  let ap = socket.socket_accept(sfd);
  let afd: Int;
  match ap {
    Ok(f) => { afd = f; },
    Err(_) => { return 5; },
  };

  var buf = Vec[UInt8].new();

  // 1) "hello" -> Ok(5), exact bytes, len 5.
  var hello = Vec[UInt8].new();
  hello.push(104);
  hello.push(101);
  hello.push(108);
  hello.push(108);
  hello.push(111);
  let s1 = socket.socket_send_all(cfd, &hello);
  match s1 {
    Ok(_) => {},
    Err(_) => { return 6; },
  };
  let r1 = socket.socket_recv_into(afd, &mut buf, 64);
  match r1 {
    Ok(n) => {
      if n != 5 { return 7; }
      if buf.len() != 5 { return 8; }
      if buf[0] != 104 { return 8; }
      if buf[4] != 111 { return 8; }
    },
    Err(_) => { return 9; },
  };
  let cap1 = buf.cap;
  if cap1 < 5 { return 10; }

  // 2) same size again: capacity is reused, content replaced.
  var world = Vec[UInt8].new();
  world.push(119);
  world.push(111);
  world.push(114);
  world.push(108);
  world.push(100);
  let s2 = socket.socket_send_all(cfd, &world);
  match s2 {
    Ok(_) => {},
    Err(_) => { return 11; },
  };
  let r2 = socket.socket_recv_into(afd, &mut buf, 64);
  match r2 {
    Ok(n) => {
      if n != 5 { return 12; }
      if buf.len() != 5 { return 13; }
      if buf[0] != 119 { return 13; }
      if buf[4] != 100 { return 13; }
    },
    Err(_) => { return 14; },
  };
  if buf.cap != cap1 { return 15; }

  // 3) a larger payload grows once; the next same-size call reuses it.
  var big = Vec[UInt8].new();
  var i = 0;
  while i < 16 {
    big.push(i as UInt8);
    i = i + 1;
  }
  let s3 = socket.socket_send_all(cfd, &big);
  match s3 {
    Ok(_) => {},
    Err(_) => { return 16; },
  };
  let r3 = socket.socket_recv_into(afd, &mut buf, 64);
  match r3 {
    Ok(n) => {
      if n != 16 { return 17; }
      if buf.len() != 16 { return 18; }
      if buf[15] != 15 as UInt8 { return 18; }
    },
    Err(_) => { return 19; },
  };
  let cap2 = buf.cap;
  let s4 = socket.socket_send_all(cfd, &big);
  match s4 {
    Ok(_) => {},
    Err(_) => { return 20; },
  };
  let r4 = socket.socket_recv_into(afd, &mut buf, 64);
  match r4 {
    Ok(n) => {
      if n != 16 { return 21; }
    },
    Err(_) => { return 22; },
  };
  if buf.cap != cap2 { return 23; }

  // 4) deadline with no data: Err (not Ok(0)), buffer empty.
  let rt = socket.socket_recv_timeout_into(afd, &mut buf, 64, 250);
  match rt {
    Ok(n) => {
      if n != 0 { return 24; }
      return 25;
    },
    Err(_) => {},
  };
  if buf.len() != 0 { return 26; }

  // 5) peer shutdown surfaces as a clean Ok(0).
  let sd = socket.socket_shutdown(cfd, 2);
  match sd {
    Ok(_) => {},
    Err(_) => { return 27; },
  };
  let re = socket.socket_recv_into(afd, &mut buf, 64);
  match re {
    Ok(n) => {
      if n != 0 { return 28; }
    },
    Err(_) => { return 29; },
  };
  if buf.len() != 0 { return 30; }

  socket.socket_close(afd);
  socket.socket_close(cfd);
  socket.socket_close(sfd);
  return 0;
}

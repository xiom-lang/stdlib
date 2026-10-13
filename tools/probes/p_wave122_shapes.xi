// p_wave122_shapes.xi -- wave 122 lock: poll/select with timeout
// (socket_poll_read / socket_poll_write) and SO_REUSEPORT
// (socket_set_reuseport), the remaining high-severity pulse runtime rows
// (REL-20261012-1946-pulse asks 2 and 3).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// reuseport: POSIX asserts Ok plus a real double-bind of the same port by
// two listeners (SO_REUSEPORT semantics); Windows asserts the documented
// Err (no equivalent).
// poll: a loopback pair locks the timeout-empty case, listener-readable on
// a pending connection, the idle-empty case, immediate write readiness,
// multi-fd compaction order, and the post-send readable/recv roundtrip;
// Err rows: negative timeout, over-1024 list, and the empty input no-op.
// Single thread (the wave-119/121 loopback sequencing pattern; no threads).
// Returns 0 when all cases hold. Red pre-fix (the helpers do not exist),
// green post.

module p_wave122_shapes

use xiom.net.socket;
use xiom.env;
use xiom.io;

fn main() -> Int {
  // --- reuseport ---
  let s1r = socket.socket_tcp();
  let s1: Int;
  match s1r {
    Ok(f) => { s1 = f; },
    Err(_) => { return 1; },
  };
  let rp = socket.socket_set_reuseport(s1, true);
  if env.FAMILY == "windows" {
    match rp {
      Ok(_) => { return 2; },
      Err(_) => {},
    };
    socket.socket_close(s1);
  } else {
    match rp {
      Ok(_) => {},
      Err(_) => { return 2; },
    };
    let b1 = socket.socket_bind(s1, "127.0.0.1", 39612);
    match b1 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let l1 = socket.socket_listen(s1, 4);
    match l1 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let s2r = socket.socket_tcp();
    let s2: Int;
    match s2r {
      Ok(f) => { s2 = f; },
      Err(_) => { return 3; },
    };
    let rp2 = socket.socket_set_reuseport(s2, true);
    match rp2 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let b2 = socket.socket_bind(s2, "127.0.0.1", 39612);
    match b2 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    let l2 = socket.socket_listen(s2, 4);
    match l2 {
      Ok(_) => {},
      Err(_) => { return 3; },
    };
    socket.socket_close(s1);
    socket.socket_close(s2);
  };

  // --- poll: loopback pair ---
  let srvr = socket.socket_tcp();
  let srv: Int;
  match srvr {
    Ok(f) => { srv = f; },
    Err(_) => { return 4; },
  };
  let bb = socket.socket_bind(srv, "127.0.0.1", 39613);
  match bb {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  let ll = socket.socket_listen(srv, 4);
  match ll {
    Ok(_) => {},
    Err(_) => { return 4; },
  };
  var one = Vec[Int].new();
  one.push(srv);
  let p0 = socket.socket_poll_read(&one, 50);
  match p0 {
    Ok(v) => {
      let n0 = v.len();
      if n0 != 0 { return 5; }
    },
    Err(_) => { return 5; },
  };
  let clir = socket.socket_tcp();
  let cli: Int;
  match clir {
    Ok(f) => { cli = f; },
    Err(_) => { return 6; },
  };
  let cc = socket.socket_connect(cli, "127.0.0.1", 39613);
  match cc {
    Ok(_) => {},
    Err(_) => { return 6; },
  };
  let p1 = socket.socket_poll_read(&one, 2000);
  match p1 {
    Ok(v) => {
      let n1 = v.len();
      if n1 != 1 { return 7; }
      let g1 = v[0];
      if g1 != srv { return 7; }
    },
    Err(_) => { return 7; },
  };
  let ar = socket.socket_accept(srv);
  let cfd: Int;
  match ar {
    Ok(f) => { cfd = f; },
    Err(_) => { return 6; },
  };
  var two = Vec[Int].new();
  two.push(cfd);
  let p2 = socket.socket_poll_read(&two, 50);
  match p2 {
    Ok(v) => {
      let n2 = v.len();
      if n2 != 0 { return 8; }
    },
    Err(_) => { return 8; },
  };
  let pw = socket.socket_poll_write(&two, 50);
  match pw {
    Ok(v) => {
      let nw = v.len();
      if nw != 1 { return 9; }
      let gw = v[0];
      if gw != cfd { return 9; }
    },
    Err(_) => { return 9; },
  };
  var msg = to_bytes("poll!");
  let snd = socket.socket_send_all(cli, &msg);
  match snd {
    Ok(_) => {},
    Err(_) => { return 10; },
  };
  var both = Vec[Int].new();
  both.push(cfd);
  both.push(srv);
  let p3 = socket.socket_poll_read(&both, 2000);
  match p3 {
    Ok(v) => {
      let n3 = v.len();
      if n3 != 1 { return 11; }
      let g3 = v[0];
      if g3 != cfd { return 11; }
    },
    Err(_) => { return 11; },
  };
  let rr = socket.socket_recv(cfd, 16);
  match rr {
    Ok(v) => {
      let nr = v.len();
      if nr != 5 { return 12; }
      let b0 = v[0];
      if b0 != 112 { return 12; }
    },
    Err(_) => { return 12; },
  };
  var none: Vec[Int] = Vec[Int].new();
  let p4 = socket.socket_poll_read(&none, 0);
  match p4 {
    Ok(v) => {
      let n4 = v.len();
      if n4 != 0 { return 13; }
    },
    Err(_) => { return 13; },
  };
  let p5 = socket.socket_poll_read(&one, -5);
  match p5 {
    Ok(_) => { return 14; },
    Err(_) => {},
  };
  var big: Vec[Int] = Vec[Int].new();
  var bi = 0;
  while bi < 1025 {
    big.push(srv);
    bi = bi + 1;
  }
  let p6 = socket.socket_poll_read(&big, 0);
  match p6 {
    Ok(_) => { return 15; },
    Err(_) => {},
  };
  socket.socket_close(cli);
  socket.socket_close(cfd);
  socket.socket_close(srv);
  return 0;
}

// to_bytes copies a string's bytes into a Vec.
fn to_bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(s.byte_at(i));
    i = i + 1;
  }
  v
}

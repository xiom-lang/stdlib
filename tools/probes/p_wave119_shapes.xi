// p_wave119_shapes.xi -- wave 119 lock: socket options + shutdown real
// (socket_set_timeout / socket_set_nonblocking / socket_reuse_addr /
// socket_shutdown).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the landed semantics on a loopback TCP pair (127.0.0.1:39473):
//   * set_timeout(250) and set_nonblocking(true/false) return Ok;
//   * a non-blocking recv with no data returns Err immediately;
//   * a blocked recv with the 250 ms receive timeout returns Err (the
//     slowloris guard: no unbounded wait);
//   * reuse_addr returns Ok on the listener;
//   * shutdown(both) returns Ok and the peer sees EOF (an empty Ok recv).
// Cross-fd contention and exact timing are not asserted. Every returned
// value is bound before comparing. Returns 0 when all cases hold. Red
// pre-fix (the stubs return Err), green post.

module p_wave119_shapes

use xiom.net.socket;

fn main() -> Int {
  let srvr = socket.socket_tcp();
  match srvr {
    Ok(sfd) => {
      let b = socket.socket_bind(sfd, "127.0.0.1", 39473);
      match b {
        Ok(_) => {},
        Err(_) => { return 1; },
      };
      let l = socket.socket_listen(sfd, 4);
      match l {
        Ok(_) => {},
        Err(_) => { return 1; },
      };
      let ra0 = socket.socket_reuse_addr(sfd, true); // listener option
      match ra0 {
        Ok(_) => {},
        Err(_) => { return 8; },
      };
      let cli = socket.socket_tcp();
      match cli {
        Ok(cfd) => {
          let c = socket.socket_connect(cfd, "127.0.0.1", 39473);
          match c {
            Ok(_) => {},
            Err(_) => { return 2; },
          };
          let a = socket.socket_accept(sfd);
          match a {
            Ok(afd) => {
              // 1) set_timeout valid
              let t1 = socket.socket_set_timeout(afd, 250);
              match t1 {
                Ok(_) => {},
                Err(_) => { return 3; },
              };
              // 2) non-blocking on: empty recv returns Err fast
              let nb = socket.socket_set_nonblocking(afd, true);
              match nb {
                Ok(_) => {},
                Err(_) => { return 4; },
              };
              let r1 = socket.socket_recv(afd, 16);
              match r1 {
                Ok(v) => {
                  let n = v.len();
                  if n > 0 { return 5; }
                },
                Err(_) => {},
              };
              // 3) non-blocking off: the 250 ms receive timeout fires
              let nb2 = socket.socket_set_nonblocking(afd, false);
              match nb2 {
                Ok(_) => {},
                Err(_) => { return 6; },
              };
              let r2 = socket.socket_recv(afd, 16);
              match r2 {
                Ok(v) => {
                  let n = v.len();
                  if n > 0 { return 7; }
                },
                Err(_) => {},
              };
              // 4) deadline wrapper: no data -> Err within the deadline
              let r4 = socket.socket_recv_timeout(afd, 16, 250);
              match r4 {
                Ok(v) => {
                  let n = v.len();
                  if n > 0 { return 11; }
                },
                Err(_) => {},
              };
              // 5) shutdown both: Ok; the peer sees EOF (empty Ok recv)
              let sd = socket.socket_shutdown(afd, 2);
              match sd {
                Ok(_) => {},
                Err(_) => { return 9; },
              };
              let r3 = socket.socket_recv(cfd, 16);
              match r3 {
                Ok(v) => {
                  let n = v.len();
                  if n != 0 { return 10; }
                },
                Err(_) => { return 10; },
              };
              socket.socket_close(afd);
            },
            Err(_) => { return 2; },
          };
          socket.socket_close(cfd);
        },
        Err(_) => { return 2; },
      };
      socket.socket_close(sfd);
    },
    Err(_) => { return 1; },
  };
  return 0;
}

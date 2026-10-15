// p_wave143_shapes.xi -- socket semantics locks, wave 143
// (REL-20261015-1948 refused-connect + REL-20261015-2202-pulse item 2)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Rows (returns 0 when all hold):
//  1 -- socket_connect to a CLOSED loopback port must be Err (it returned
//       Ok on Windows: the stack accepted the call and deferred the
//       refusal to the first send; the runtime now checks SO_ERROR
//       synchronously after connect)
//  2 -- tcp_listen's default path listens and accepts a connect
//  3 -- socket_set_nodelay: Ok on a live socket, Err on fd -1
//  4 -- socket_set_keepalive: Ok on a live socket, Err on fd -1
//  5 -- tcp_listen_with_backlog(port, 16) listens and accepts a connect
// Distinct setup-failure codes are 10+ (never a silent pass).

module p_wave143_shapes

use xiom.net.socket;
use xiom.net;

fn main() -> Int {
  // 1: refused connect -- nothing listens on 45911
  let t1 = socket_tcp();
  match t1 {
    Ok(fd) => {
      let c = socket_connect(fd, "127.0.0.1", 45911);
      match c {
        Ok(_) => { return 1; }
        Err(_) => {}
      };
      socket_close(fd);
    }
    Err(_) => { return 10; }
  };

  // 2: default tcp_listen accepts a connect (backlog 128 path)
  let l2 = tcp_listen("127.0.0.1", 45913);
  match l2 {
    Ok(listener2) => {
      let t3 = socket_tcp();
      match t3 {
        Ok(fd3) => {
          let c3 = socket_connect(fd3, "127.0.0.1", 45913);
          match c3 {
            Ok(_) => {}
            Err(_) => { return 2; }
          };
          socket_close(fd3);
        }
        Err(_) => { return 13; }
      };
      socket_close(listener2.fd);
    }
    Err(_) => { return 14; }
  };

  // 5: explicit backlog listener accepts a connect
  let l1 = tcp_listen_with_backlog("127.0.0.1", 45912, 16);
  match l1 {
    Ok(listener) => {
      let t2 = socket_tcp();
      match t2 {
        Ok(fd2) => {
          let c2 = socket_connect(fd2, "127.0.0.1", 45912);
          match c2 {
            Ok(_) => {}
            Err(_) => { return 5; }
          };
          socket_close(fd2);
        }
        Err(_) => { return 11; }
      };
      socket_close(listener.fd);
    }
    Err(_) => { return 12; }
  };

  // 3 + 4: nodelay and keepalive on a live socket; Err on invalid fds
  let t4 = socket_tcp();
  match t4 {
    Ok(fd4) => {
      match socket_set_nodelay(fd4, true) {
        Ok(_) => {}
        Err(_) => { return 3; }
      };
      match socket_set_nodelay(-1, true) {
        Ok(_) => { return 30; }
        Err(_) => {}
      };
      match socket_set_keepalive(fd4, true) {
        Ok(_) => {}
        Err(_) => { return 4; }
      };
      match socket_set_keepalive(-1, false) {
        Ok(_) => { return 40; }
        Err(_) => {}
      };
      socket_close(fd4);
    }
    Err(_) => { return 15; }
  };

  return 0;
}

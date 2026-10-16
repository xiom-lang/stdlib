// p_wave155_bind.xi -- wave 155 lock (REL-20261016-1404): socket_bind
// honors the address (inet_pton path) and socket_local_addr is real via
// getsockname. Pre-wave: bind ignored the address (INADDR_ANY) and
// local_addr was an Err stub. Returns 0 when every row holds.

module p_wave155_bind

use xiom.net.socket;

fn main() -> Int {
  // 127.0.0.1 bind + listen + getsockname roundtrip
  let s1 = socket.socket_tcp();
  var fd1: Int = 0;
  match s1 {
    Ok(v) => { fd1 = v; },
    Err(_) => { return 1; },
  }
  let b1 = socket.socket_bind(fd1, "127.0.0.1", 45731);
  if b1.is_err { return 2; }
  let l1 = socket.socket_listen(fd1, 4);
  if l1.is_err { return 3; }
  let la1 = socket.socket_local_addr(fd1);
  match la1 {
    Ok(pair) => {
      if pair.0 != "127.0.0.1" { return 4; }
      if pair.1 != 45731 { return 5; }
    },
    Err(_) => { return 6; },
  }

  // wildcard bind reports 0.0.0.0
  let s2 = socket.socket_tcp();
  var fd2: Int = 0;
  match s2 {
    Ok(v) => { fd2 = v; },
    Err(_) => { return 7; },
  }
  let b2 = socket.socket_bind(fd2, "0.0.0.0", 45732);
  if b2.is_err { return 8; }
  let la2 = socket.socket_local_addr(fd2);
  match la2 {
    Ok(pair) => {
      if pair.0 != "0.0.0.0" { return 9; }
      if pair.1 != 45732 { return 10; }
    },
    Err(_) => { return 11; },
  }

  // an unparsable address is a typed Err (parse failure path)
  let s3 = socket.socket_tcp();
  var fd3: Int = 0;
  match s3 {
    Ok(v) => { fd3 = v; },
    Err(_) => { return 12; },
  }
  let b3 = socket.socket_bind(fd3, "not.an.ip", 45733);
  if b3.is_ok { return 13; }

  // binding a non-local address fails (EADDRNOTAVAIL class)
  let b4 = socket.socket_bind(fd3, "203.0.113.1", 45734);
  if b4.is_ok { return 14; }

  // unbound-but-open fd: local_addr may succeed with port 0 or Err, but
  // must never report a bound port
  let s4 = socket.socket_tcp();
  var fd4: Int = 0;
  match s4 {
    Ok(v) => { fd4 = v; },
    Err(_) => { return 15; },
  }
  let la4 = socket.socket_local_addr(fd4);
  match la4 {
    Ok(pair) => {
      if pair.1 != 0 { return 16; }
    },
    Err(_) => {},
  }

  // end-to-end loopback: connect to the 127.0.0.1 listener; the client's
  // own local address must be loopback (proves the bind really was)
  let c = socket.socket_tcp();
  var cfd: Int = 0;
  match c {
    Ok(v) => { cfd = v; },
    Err(_) => { return 17; },
  }
  let conn = socket.socket_connect(cfd, "127.0.0.1", 45731);
  if conn.is_err { return 18; }
  let ca = socket.socket_local_addr(cfd);
  match ca {
    Ok(pair) => {
      if pair.0 != "127.0.0.1" { return 19; }
    },
    Err(_) => { return 20; },
  }
  let _ = socket.socket_close(cfd);
  let _ = socket.socket_close(fd1);
  let _ = socket.socket_close(fd2);
  let _ = socket.socket_close(fd3);
  let _ = socket.socket_close(fd4);
  return 0
}

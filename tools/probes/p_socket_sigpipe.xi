// REL-20261030-1645: a client that connects then closes must not kill the
// server process with SIGPIPE when the server writes afterwards. Without
// MSG_NOSIGNAL/SIG_IGN this exits 141 on Linux; Windows is unaffected and
// the write simply returns an error.
module p_socket_sigpipe

use xiom.io;
use xiom.net;
use xiom.net.socket;
use xiom.thread;
use xiom.thread.spawn;

fn _serve() -> Int {
  let l = net.tcp_listen("127.0.0.1", 46751);
  match l {
    Ok(listener) => {
      match listener.accept() {
        Ok(pair) => {
          let st = pair.0;
          // Let the client close before the server writes.
          thread.sleep_ms(300);
          var b: Vec[UInt8] = Vec[UInt8].new();
          var i = 0;
          while i < 4096 {
            b.push(65);
            i = i + 1;
          }
          let w1 = st.write_all(&b);
          let w2 = st.write_all(&b);
          let _ = st.close();
          socket.socket_close(listener.fd);
          if w1.is_err || w2.is_err {
            return 1;
          }
          return 0;
        },
        Err(_) => {
          socket.socket_close(listener.fd);
          return 2;
        },
      }
    },
    Err(_) => { return 3; },
  }
}

fn _connect_retry(port: Int, tries: Int) -> Result[TcpStream, Str] {
  var i = 0;
  while i < tries {
    match net.tcp_connect("127.0.0.1", port) {
      Ok(s) => { return Ok(s); },
      Err(_) => {},
    };
    thread.sleep_ms(50);
    i = i + 1;
  };
  Err("connect failed")
}

fn main() -> Int {
  let t = spawn.spawn(_serve);
  let cr = _connect_retry(46751, 60);
  if cr.is_err { return 10; }
  var c = cr.value;
  var b: Vec[UInt8] = Vec[UInt8].new();
  b.push(71);
  let _ = c.write_all(&b);
  let _ = c.close();
  let _ = spawn.join(t);
  io.println("socket sigpipe survived");
  return 0;
}

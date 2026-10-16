// p_wave159_shapes.xi -- wave 159 zero-copy send lock
// (REL-20261015-2202-pulse item 6): fs_ffi.writev + fs_ffi.sendfile real
// (POSIX writev(2)/sendfile(2); Windows WSASend + sequential _write
// fallback / TransmitFile) and the thin net wrapper TcpStream.send_file.
// Rows (0 = all hold; setup failures 20+):
//  1 -- writev, 3 segments on a file fd -> byte-exact read-back (300 B)
//  2 -- empty iov -> Ok(0)
//  3 -- bad fd (negative) -> clean Err
//  4 -- closed fd -> Err (POSIX only: the Windows UCRT fast-fails on
//       _write of a closed fd -- the documented trap; skipped there)
//  5 -- sendfile(local file -> loopback TCP pair, offset -1, full) ->
//       byte-exact receive (300 B, NUL/0xFF-heavy body)
//  6 -- sendfile count < file -> exact 100-byte prefix
//  7 -- sendfile offset semantics: offset 5, count 50 -> slice [5, 55)
//  8 -- sendfile argument validation (negative fd/count/offset) + Ok(0)
//  9 -- Windows: non-socket out fd -> Err (TransmitFile needs a socket;
//       POSIX allows file->file, so the row is Windows-gated)
// 10 -- net wrapper TcpStream.send_file on a live loopback pair
// 11 -- writev on a socket fd -> byte-exact receive (Windows WSASend
//       branch; POSIX writev-on-socket)
// The offset != -1 slice row and the loopback rows cover the Linux
// sendfile path on the WSL leg; the Windows leg exercises TransmitFile.

module p_wave159_shapes

use xiom.io;
use xiom.net;
use xiom.net.socket;
use xiom.os.fs_ffi;
use xiom.os.platform;
use xiom.os.sync_io;

fn body_slice(src: &Vec[UInt8], start: Int, len: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = 0;
  while i < len {
    out.push(src[start + i]);
    i = i + 1;
  };
  out
}

fn bytes_eq(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() {
    return false;
  }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] {
      return false;
    }
    i = i + 1;
  };
  true
}

// recv_exact drains `want` bytes from a socket in bounded chunks.
fn recv_exact(fd: Int, want: Int) -> Result[Vec[UInt8], Str] {
  var out = Vec[UInt8].new();
  while out.len() < want {
    let r = socket.socket_recv(fd, want - out.len());
    match r {
      Ok(chunk) => {
        let cn = chunk.len();
        if cn == 0 {
          return Err("recv_exact: unexpected EOF");
        }
        var j = 0;
        while j < cn {
          out.push(chunk[j]);
          j = j + 1;
        }
      },
      Err(e) => { return Err(e); },
    };
  };
  Ok(out)
}

fn main() -> Int {
  // ---- fixture: 300-byte NUL/0xFF-heavy body ----------------------------
  let bodyfile = "p_wave159_body.bin";
  let outfile = "p_wave159_out.bin";
  var body = Vec[UInt8].new();
  var i = 0;
  while i < 300 {
    var b = ((i * 5 + 11) % 256) as UInt8;
    if i % 13 == 0 {
      b = 0 as UInt8;
    }
    if i % 17 == 0 {
      b = 255 as UInt8;
    }
    body.push(b);
    i = i + 1;
  };
  match io.write_file_bytes(bodyfile, &body) {
    Ok(_) => {},
    Err(_) => { return 20; },
  };
  var seg1 = body_slice(&body, 0, 80);
  var seg2 = body_slice(&body, 80, 120);
  var seg3 = body_slice(&body, 200, 100);
  var segs: Vec[Vec[UInt8]] = Vec[Vec[UInt8]].new();
  segs.push(seg1);
  segs.push(seg2);
  segs.push(seg3);

  // ---- 1-4: writev ------------------------------------------------------
  var closed_fd = -1;
  let hw = sync_io.open_rw(outfile);
  match hw {
    Ok(fdw) => {
      let w = fs_ffi.writev(fdw, &segs);
      match w {
        Ok(n) => {
          if n != 300 {
            let _ = sync_io.close_fd(fdw);
            return 1;
          }
        },
        Err(_) => {
          let _ = sync_io.close_fd(fdw);
          return 1;
        },
      };
      // 2: empty iov is Ok(0)
      var none: Vec[Vec[UInt8]] = Vec[Vec[UInt8]].new();
      match fs_ffi.writev(fdw, &none) {
        Ok(z) => {
          if z != 0 {
            let _ = sync_io.close_fd(fdw);
            return 2;
          }
        },
        Err(_) => {
          let _ = sync_io.close_fd(fdw);
          return 2;
        },
      };
      // 3: negative fd is a clean Err (no syscall)
      match fs_ffi.writev(-1, &segs) {
        Ok(_) => {
          let _ = sync_io.close_fd(fdw);
          return 3;
        },
        Err(_) => {},
      };
      closed_fd = fdw;
      let _ = sync_io.close_fd(fdw);
    },
    Err(_) => { return 20; },
  };
  // 1 (continued): byte-exact read-back of the 3-segment write
  match io.read_file_bytes(outfile) {
    Ok(v) => {
      if v.len() != 300 {
        return 1;
      }
      if !bytes_eq(&v, &body) {
        return 1;
      }
    },
    Err(_) => { return 1; },
  };
  // 4: closed fd -> Err on POSIX; Windows is skipped (UCRT fast-fail trap)
  if !platform.platform_is_windows() {
    match fs_ffi.writev(closed_fd, &segs) {
      Ok(_) => { return 4; },
      Err(_) => {},
    };
  }

  // ---- loopback TCP pair (raw socket face) ------------------------------
  var port = 45858;
  var lfd = -1;
  var tries = 0;
  while tries < 3 && lfd < 0 {
    match socket.socket_tcp() {
      Ok(fd) => {
        let b = socket.socket_bind(fd, "127.0.0.1", port);
        match b {
          Ok(_) => {
            let l = socket.socket_listen(fd, 4);
            match l {
              Ok(_) => { lfd = fd; },
              Err(_) => { let _ = socket.socket_close(fd); },
            };
          },
          Err(_) => { let _ = socket.socket_close(fd); },
        };
      },
      Err(_) => { return 21; },
    };
    if lfd < 0 {
      port = port + 1;
      tries = tries + 1;
    }
  };
  if lfd < 0 {
    return 21;
  }
  var cfd = -1;
  match socket.socket_tcp() {
    Ok(fd) => {
      let c = socket.socket_connect(fd, "127.0.0.1", port);
      match c {
        Ok(_) => { cfd = fd; },
        Err(_) => { let _ = socket.socket_close(fd); return 21; },
      };
    },
    Err(_) => { let _ = socket.socket_close(lfd); return 21; },
  };
  var sfd = -1;
  match socket.socket_accept(lfd) {
    Ok(fd) => { sfd = fd; },
    Err(_) => {
      let _ = socket.socket_close(cfd);
      let _ = socket.socket_close(lfd);
      return 21;
    },
  };

  // ---- 5: sendfile full file -> byte-exact receive ----------------------
  let h1 = sync_io.open_read(bodyfile);
  match h1 {
    Ok(fin1) => {
      let sf1 = fs_ffi.sendfile(sfd, fin1, -1, 300);
      match sf1 {
        Ok(n) => {
          if n != 300 {
            let _ = sync_io.close_fd(fin1);
            let _ = socket.socket_close(cfd);
            let _ = socket.socket_close(sfd);
            let _ = socket.socket_close(lfd);
            return 5;
          }
        },
        Err(_) => {
          let _ = sync_io.close_fd(fin1);
          let _ = socket.socket_close(cfd);
          let _ = socket.socket_close(sfd);
          let _ = socket.socket_close(lfd);
          return 5;
        },
      };
      let _ = sync_io.close_fd(fin1);
    },
    Err(_) => {
      let _ = socket.socket_close(cfd);
      let _ = socket.socket_close(sfd);
      let _ = socket.socket_close(lfd);
      return 22;
    },
  };
  match recv_exact(cfd, 300) {
    Ok(got) => {
      if !bytes_eq(&got, &body) {
        return 5;
      }
    },
    Err(_) => { return 5; },
  };

  // ---- 6 + 7: prefix count, then explicit offset slice ------------------
  let h2 = sync_io.open_read(bodyfile);
  match h2 {
    Ok(fin2) => {
      // 6: count 100 < file 300 -> exact 100-byte prefix (offset -1: pos 0)
      let sf2 = fs_ffi.sendfile(sfd, fin2, -1, 100);
      match sf2 {
        Ok(n) => {
          if n != 100 {
            let _ = sync_io.close_fd(fin2);
            return 6;
          }
        },
        Err(_) => {
          let _ = sync_io.close_fd(fin2);
          return 6;
        },
      };
      match recv_exact(cfd, 100) {
        Ok(got) => {
          let want = body_slice(&body, 0, 100);
          if !bytes_eq(&got, &want) {
            return 6;
          }
        },
        Err(_) => { return 6; },
      };
      // 7: explicit offset 5, count 50 -> slice [5, 55)
      let sf3 = fs_ffi.sendfile(sfd, fin2, 5, 50);
      match sf3 {
        Ok(n) => {
          if n != 50 {
            let _ = sync_io.close_fd(fin2);
            return 7;
          }
        },
        Err(_) => {
          let _ = sync_io.close_fd(fin2);
          return 7;
        },
      };
      match recv_exact(cfd, 50) {
        Ok(got) => {
          let want = body_slice(&body, 5, 50);
          if !bytes_eq(&got, &want) {
            return 7;
          }
        },
        Err(_) => { return 7; },
      };

      // ---- 8: argument validation ---------------------------------------
      match fs_ffi.sendfile(-1, fin2, 0, 10) {
        Ok(_) => { return 8; },
        Err(_) => {},
      };
      match fs_ffi.sendfile(sfd, -1, 0, 10) {
        Ok(_) => { return 8; },
        Err(_) => {},
      };
      match fs_ffi.sendfile(sfd, fin2, -2, 10) {
        Ok(_) => { return 8; },
        Err(_) => {},
      };
      match fs_ffi.sendfile(sfd, fin2, 0, -1) {
        Ok(_) => { return 8; },
        Err(_) => {},
      };
      match fs_ffi.sendfile(sfd, fin2, 0, 0) {
        Ok(z) => {
          if z != 0 {
            return 8;
          }
        },
        Err(_) => { return 8; },
      };

      // ---- 9: Windows non-socket out fd -> Err (TransmitFile needs a
      // socket; POSIX file->file would be legal, so the row is gated) ----
      if platform.platform_is_windows() {
        match fs_ffi.sendfile(fin2, fin2, 0, 10) {
          Ok(_) => { return 9; },
          Err(_) => {},
        };
      }
      let _ = sync_io.close_fd(fin2);
    },
    Err(_) => { return 22; },
  };

  // ---- 11: writev on a socket fd (Windows WSASend branch; POSIX
  // writev-on-socket) -> byte-exact receive --------------------------------
  let wv = fs_ffi.writev(sfd, &segs);
  match wv {
    Ok(n) => {
      if n != 300 {
        return 11;
      }
    },
    Err(_) => { return 11; },
  };
  match recv_exact(cfd, 300) {
    Ok(got) => {
      if !bytes_eq(&got, &body) {
        return 11;
      }
    },
    Err(_) => { return 11; },
  };

  // ---- 10: thin net wrapper on a live loopback pair ---------------------
  var port2 = 45871;
  var l2 = tcp_listen("127.0.0.1", port2);
  match l2 {
    Ok(listener) => {
      let t2 = tcp_connect("127.0.0.1", port2);
      match t2 {
        Ok(stream) => {
          let acc = listener.accept();
          match acc {
            Ok(pair) => {
              let srv = pair.0;
              let wr = srv.send_file(bodyfile, -1, 300);
              match wr {
                Ok(n) => {
                  if n != 300 {
                    let _ = socket.socket_close(cfd);
                    let _ = socket.socket_close(sfd);
                    let _ = socket.socket_close(lfd);
                    let _ = socket.socket_close(listener.fd);
                    let _ = stream.close();
                    let _ = srv.close();
                    return 10;
                  }
                },
                Err(_) => {
                  let _ = socket.socket_close(cfd);
                  let _ = socket.socket_close(sfd);
                  let _ = socket.socket_close(lfd);
                  let _ = socket.socket_close(listener.fd);
                  let _ = stream.close();
                  let _ = srv.close();
                  return 10;
                },
              };
              match recv_exact(stream.fd, 300) {
                Ok(got) => {
                  if !bytes_eq(&got, &body) {
                    return 10;
                  }
                },
                Err(_) => { return 10; },
              };
              let _ = srv.close();
            },
            Err(_) => {
              let _ = socket.socket_close(listener.fd);
              let _ = stream.close();
              return 23;
            },
          };
          let _ = stream.close();
        },
        Err(_) => {
          let _ = socket.socket_close(listener.fd);
          return 23;
        },
      };
      let _ = socket.socket_close(listener.fd);
    },
    Err(_) => { return 23; },
  };

  // ---- cleanup ----------------------------------------------------------
  let _ = socket.socket_close(cfd);
  let _ = socket.socket_close(sfd);
  let _ = socket.socket_close(lfd);
  let _ = io.remove_file(bodyfile);
  let _ = io.remove_file(outfile);
  return 0;
}

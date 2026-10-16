// p_wave156_shapes.xi -- wave 156 station-surface lock (REL-20261016-1128-orbitdb
// asks 3-5): CSPRNG + KDF known-answers, the monotonic clock contract, and the
// TCP session ergonomics the Station consumes. Rows (0 = all hold):
//  1 -- HKDF-SHA-256 RFC 5869 TC1 vector
//  2 -- PBKDF2-HMAC-SHA-256 ("password","salt",1,32) known answer
//  3 -- argon2 deterministic over equal inputs, 32 bytes
//  4 -- secure_random_bytes(32): length, nonzero, two draws differ
//  5 -- monotonic clock: two reads non-decreasing; Instant.elapsed() >= 0
//  6 -- session ergonomics: SO_REUSEADDR + SO_RCVTIMEO + shutdown + local_addr
//       on a live loopback socket
// Setup failures use 10+.

module p_wave156_shapes

use xiom.crypto;
use xiom.encoding.hex;
use xiom.io;
use xiom.net.socket;
use xiom.net;
use xiom.time;

fn hx(s: Str) -> Vec[UInt8] {
  match hex.hex_decode(s) {
    Ok(v) => { return v; },
    Err(_) => { return Vec[UInt8].new(); },
  }
}

fn main() -> Int {
  // 1: HKDF RFC 5869 TC1
  var ikm = hx("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b");
  var salt = hx("000102030405060708090a0b0c");
  var info = hx("f0f1f2f3f4f5f6f7f8f9");
  match crypto.hkdf_sha256(&ikm, &salt, &info, 42) {
    Ok(okm) => {
      let got = hex.hex_encode(&okm);
      if got != "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865" {
        return 1;
      }
    },
    Err(_) => { return 10; },
  };

  // 2: PBKDF2-HMAC-SHA-256 known answer (c=1)
  var psalt = hx("73616c74"); // "salt"
  let pk = crypto.pbkdf2(&"password", &psalt, 1, 32);
  if hex.hex_encode(&pk) != "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b" {
    return 2;
  }

  // 3: argon2 determinism
  var asalt = hx("000102030405060708090a0b0c0d0e0f");
  let a1 = crypto.argon2(&"station-pw", &asalt, 64, 1, 1);
  let a2 = crypto.argon2(&"station-pw", &asalt, 64, 1, 1);
  if a1.len() != 32 || a2.len() != 32 { return 3; }
  if hex.hex_encode(&a1) != hex.hex_encode(&a2) { return 4; }

  // 4: CSPRNG
  let r1 = crypto.secure_random_bytes(32);
  let r2 = crypto.secure_random_bytes(32);
  if r1.len() != 32 { return 5; }
  var nz = 0;
  var i = 0;
  while i < 32 {
    if r1[i] != 0 as UInt8 { nz = nz + 1; }
    i = i + 1;
  };
  if nz == 0 { return 6; }
  if hex.hex_encode(&r1) == hex.hex_encode(&r2) { return 7; }

  // 5: monotonic clock
  let m1 = time.monotonic_ms();
  let m2 = time.monotonic_ms();
  if m2 < m1 { return 8; }
  let inst = time.Instant.now();
  let el = inst.elapsed();
  if el.as_millis() < 0 { return 9; }

  // 6: session ergonomics on a live loopback socket
  let l = tcp_listen("127.0.0.1", 45916);
  match l {
    Ok(listener) => {
      let t = socket_tcp();
      match t {
        Ok(fd) => {
          let c = socket_connect(fd, "127.0.0.1", 45916);
          match c {
            Ok(_) => {}
            Err(_) => { socket_close(fd); socket_close(listener.fd); return 11; }
          };
          match socket_reuse_addr(fd, true) {
            Ok(_) => {}
            Err(_) => { socket_close(fd); socket_close(listener.fd); return 12; }
          };
          match socket_set_timeout(fd, 5000) {
            Ok(_) => {}
            Err(_) => { socket_close(fd); socket_close(listener.fd); return 13; }
          };
          match socket_local_addr(fd) {
            Ok(la) => {
              if la.1 <= 0 { socket_close(fd); socket_close(listener.fd); return 14; }
            }
            Err(_) => { socket_close(fd); socket_close(listener.fd); return 15; }
          };
          match socket_shutdown(fd, 1) {
            Ok(_) => {}
            Err(_) => { socket_close(fd); socket_close(listener.fd); return 16; }
          };
          socket_close(fd);
        }
        Err(_) => { socket_close(listener.fd); return 17; }
      };
      socket_close(listener.fd);
    }
    Err(_) => { return 18; }
  };

  return 0;
}

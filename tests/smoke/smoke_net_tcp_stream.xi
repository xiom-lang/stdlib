// smoke_net_tcp_stream.xi -- TcpStream.read/write end-to-end loopback lock
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Compiler v0.64.0 (m196) gated the raw-pointer read builtin, which had
// hijacked TcpStream.read; this smoke is the missing end-to-end fixture
// (stdlib previously had none, which is why the hijack shipped unnoticed).
// Binds 127.0.0.1:39461 (unused elsewhere), connects, accepts, and exchanges
// one message in both directions. Returns 0 when every case holds.

module smoke_net_tcp_stream

use xiom.net;

fn main() -> Int {
  match net.tcp_listen("127.0.0.1", 39461) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39461) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              var msg = Vec[UInt8].new();
              msg.push(104u8);
              msg.push(105u8);
              match c.clone().write(&msg) {
                Ok(n) => { if n != 2 { return 10; } }
                Err(_) => { return 11; }
              }
              var buf = Vec[UInt8].new();
              match s.clone().read(&mut buf) {
                Ok(n) => { if n != 2 { return 12; } }
                Err(_) => { return 14; }
              }
              if buf.len() != 2 { return 13; }
              if buf[0] != 104u8 { return 15; }
              match s.clone().write(&msg) {
                Ok(n) => { if n != 2 { return 16; } }
                Err(_) => { return 17; }
              }
              var buf2 = Vec[UInt8].new();
              match c.clone().read(&mut buf2) {
                Ok(n) => { if n != 2 { return 18; } }
                Err(_) => { return 19; }
              }
              if buf2[1] != 105u8 { return 20; }
              s.close();
              c.close();
              return 0;
            }
            Err(_) => { return 4; }
          }
        }
        Err(_) => { return 3; }
      }
    }
    Err(_) => { return 2; }
  }
}

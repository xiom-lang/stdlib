// p_inline_i32_misread.xi -- COMPILER-CLASS witness (evidence file).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// An UNANNOTATED inline call form `let x = unsafe { extern_i32_fn() }`
// misreads a negative i32 return: the read sees the full 64-bit register
// (upper bits undefined from the C `int`-returning callee) and classifies
// -1 as >= 0. The declared form (`let x: Int32; unsafe { x = ... }`) and
// the annotated inline form (`let x: Int32 = unsafe { ... }`) are correct.
//
// TRIGGER CONTEXT: REL-20261015-1948 (socket_connect returned Ok on a
// refused connection) was exactly this class -- the wrapper used the bare
// inline form around the i32 `xiom_socket_connect`, so -1 was read as
// positive -> Ok; the first send then failed. The C side was always
// correct (a runtime-side diag showed connect rc=-1, WSAECONNREFUSED
// 10061). Fixed stdlib-side in wave 143 (block 196): the affected call
// sites in xiom/net/socket.xi + xiom/net/net.xi are annotated (and the
// i64-typed externs for bind/listen/send/recv/sendto/recvfrom/dns/
// gethostname switched to Int32 to match their C int returns). Filed to
// the compiler lane for the general fix.
//
// Runs (not part of the battery corpus -- evidence/ is not recursed):
//   0 = BOTH forms read the negative return correctly (compiler fixed);
//   1 = the bare inline form misread a genuine -1 (defect reproduced);
//   2 = the declared form failed (unexpected -- investigate);
//   9 = socket setup failed.
// The refused-connect row uses a closed loopback port; nothing listens.

extern "C" {
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int32;
}
use xiom.net.socket;

fn main() -> Int {
  let t = socket_tcp();
  match t {
    Ok(fd) => {
      var h: [16]UInt8;
      h[0] = 49 as UInt8;
      h[1] = 50 as UInt8;
      h[2] = 55 as UInt8;
      h[3] = 46 as UInt8;
      h[4] = 48 as UInt8;
      h[5] = 46 as UInt8;
      h[6] = 48 as UInt8;
      h[7] = 46 as UInt8;
      h[8] = 49 as UInt8;
      h[9] = 0 as UInt8;
      // declared form: correct (-1 -> negative)
      let d: Int32;
      unsafe { d = xiom_socket_connect(fd, &h as *UInt8, 45921); }
      if d >= 0 {
        socket_close(fd);
        return 2;
      }
      // bare inline form: misreads -1 as >= 0 on the current compiler
      let a = unsafe { xiom_socket_connect(fd, &h as *UInt8, 45921); };
      socket_close(fd);
      if a >= 0 {
        return 1;
      }
      return 0;
    }
    Err(_) => { return 9; }
  }
}

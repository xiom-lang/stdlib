// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_shim
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  io.println("A-before-enc"); io.flush_stdout();
  let e = base32.base32_encode(&v);
  io.println("B-enc=" + e); io.flush_stdout();

  let d = base32.base32_decode("MZXW6===");
  io.println("C-after-dec"); io.flush_stdout();
  match d {
    Ok(out) => { io.println("D-dec-len=" + out.len()); io.flush_stdout(); },
    Err(er) => { io.println("D-dec-err=" + er); io.flush_stdout(); },
  }

  let h = base32.base32hex_encode(&v);
  io.println("E-hex=" + h); io.flush_stdout();

  let hd = base32.base32hex_decode("CPNMU===");
  io.println("F-after-hexdec"); io.flush_stdout();
  match hd {
    Ok(o2) => { io.println("G-hexdec-len=" + o2.len()); io.flush_stdout(); },
    Err(e2) => { io.println("G-hexdec-err=" + e2); io.flush_stdout(); },
  }
  io.println("B32 SHIM OK"); io.flush_stdout();
  return 0;
}

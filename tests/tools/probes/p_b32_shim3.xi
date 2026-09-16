// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_shim3
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);

  io.println("A:" + base32.base32_encode(&v)); io.flush_stdout();
  io.println("B:" + base32.base32hex_encode(&v)); io.flush_stdout();

  match base32.base32_decode("MZXW6===") {
    Ok(x) => { io.println("C len=" + x.len()); },
    Err(e) => { io.println("C err=" + e); },
  }
  io.flush_stdout();

  match base32.base32hex_decode("CPNMU===") {
    Ok(x) => { io.println("D len=" + x.len()); },
    Err(e) => { io.println("D err=" + e); },
  }
  io.flush_stdout();

  match base32.base32_decode("MZXW6YTB") {
    Ok(x) => { io.println("E len=" + x.len()); },
    Err(e) => { io.println("E err=" + e); },
  }
  io.flush_stdout();

  match base32.base32_decode("MZXW6YTBOI==") {
    Ok(x) => { io.println("F len=" + x.len()); },
    Err(e) => { io.println("F err=" + e); },
  }
  io.flush_stdout();

  match base32.base32_decode("MZXW6YTBOI") {
    Ok(x) => { io.println("G len=" + x.len()); },
    Err(e) => { io.println("G err=" + e); },
  }
  io.flush_stdout();

  match base32.base32hex_decode("cpnmu") {
    Ok(x) => { io.println("H len=" + x.len()); },
    Err(e) => { io.println("H err=" + e); },
  }
  io.flush_stdout();

  io.println("SHIM3 OK");
  return 0;
}

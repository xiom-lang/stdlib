// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_canonical
use xiom.encoding.base32;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  let e = base32.base32_encode(&v);
  io.println("enc=" + e); io.flush_stdout();
  let d = base32.base32_decode("MZXW6===");
  match d {
    Ok(out) => { io.println("dec-len=" + out.len()); },
    Err(er) => { io.println("dec-err=" + er); },
  }
  io.println("CANONICAL OK");
  io.flush_stdout();
  return 0;
}

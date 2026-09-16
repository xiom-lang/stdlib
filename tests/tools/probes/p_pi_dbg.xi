// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_pi_dbg
use xiom.io;
fn main() -> Int {
  match io.parse_int("42") {
    Ok(v) => { io.println("ok=" + v); }
    Err(e) => { io.println("err=[" + e + "]"); }
  }
  match io.parse_int(" 42 ") {
    Ok(v) => { io.println("ok2=" + v); }
    Err(e) => { io.println("err2=[" + e + "]"); }
  }
  return 0;
}

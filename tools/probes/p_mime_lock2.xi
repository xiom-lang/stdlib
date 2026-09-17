// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_mime_lock2
use xiom.net.mime;
use xiom.io;
fn main() -> Int {
  var mp = mime.mime_parse("text/html; charset=utf-8");
  match mp {
    Err(e) => { io.println("parse-err"); return 1; }
    Ok(m) => {
      if m.kind != "text" { io.println("kind"); return 2; }
      if m.subtype != "html" { io.println("subtype"); return 3; }
      if m.params.len() != 1 { io.println("params"); return 4; }
    }
  }
  var mp2 = mime.mime_parse("application/json");
  match mp2 {
    Err(e) => { io.println("parse2-err"); return 5; }
    Ok(m) => { if m.kind != "application" { io.println("kind2"); return 6; } }
  }
  io.println("mime-lock-OK");
  return 0;
}

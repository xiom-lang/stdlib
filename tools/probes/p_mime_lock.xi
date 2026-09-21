// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_mime_lock
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
  var b = mime.multipart_boundary_new();
  if b.len() == 0 { io.println("bnd"); return 5; }
  var ct = mime.multipart_content_type(b);
  if ct.len() < 10 { io.println("ct"); return 6; }
  io.println("mime-lock-OK");
  return 0;
}

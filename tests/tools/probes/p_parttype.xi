// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_parttype
use xiom.net.multipart;
fn main() -> Int {
  var parts: Vec[multipart.Part] = Vec[multipart.Part].new();
  var part = multipart.Part{ name: "f"; filename: ""; content_type: "text/plain"; data: Vec[UInt8].new(); };
  parts.push(part);
  var body = multipart.multipart_build(&parts, "bnd");
  if body.len() < 20 { return 1; }
  var parsed = multipart.multipart_parse(&body, "bnd");
  match parsed {
    Ok(ps) => { if ps.len() != 1 { return 2; } }
    Err(_) => { return 3; }
  }
  io.println("parttype-OK");
  return 0;
}

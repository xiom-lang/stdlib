// Known failure (v0.64.8): matching on a borrowed enum emits invalid IR.
// Compile-only repro. The same shape in a larger renderer can also compile
// and bind Str payloads to garbage instead of failing. Expected today:
//   clang: '%tmpN' defined with type 'ptr' but expected 'i64'
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_match_borrowed_enum

use xiom.serialize.json;
use xiom.io;

fn main() -> Int {
  let k = json.json_string("world");
  match &k {
    JsonValue.String(s) => { io.println(s); }
    _ => { io.println("not string"); }
  }
  return 0;
}

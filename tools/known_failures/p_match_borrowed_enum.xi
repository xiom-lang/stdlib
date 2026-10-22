// Known failure (v0.64.8): matching on a borrowed enum emits invalid IR.
// Compile-only repro. Fixed on compiler main at ace095744 (with the boxed
// Str payload fix 9d31321df) and verified on the 2026-10-22 debug build:
// the repro now prints "world", rc 0. The larger borrowed renderer also
// matches byte for byte, but a Str payload must be passed by value; passing
// it as &Str still misbinds. On v0.64.8 the failure is:
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

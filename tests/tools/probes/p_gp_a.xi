// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_gp_a
use xiom.io;
use xiom.serialize.json;
fn push_v[V](v: &mut Vec[V], x: V) { v.push(x); }
fn main() -> Int {
  var vs = Vec[JsonValue].new();
  push_v(&vs, json.json_number(42.0));
  io.println("A=[" + json.json_stringify(vs[0]) + "]");
  return 0;
}

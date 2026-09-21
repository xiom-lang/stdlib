// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_gp_b
use xiom.io;
use xiom.serialize.json;
type Holder[V] = { values: Vec[V]; }
fn add_h[V](h: &mut Holder[V], x: V) { h.values.push(x); }
fn make_holder[V]() -> Holder[V] { return Holder[V]{ values: Vec[V].new() }; }
fn main() -> Int {
  var h = make_holder[JsonValue]();
  add_h(&h, json.json_string("tree"));
  io.println("B=[" + json.json_stringify(h.values[0]) + "]");
  return 0;
}

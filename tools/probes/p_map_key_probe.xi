// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_map_key_probe
use xiom.io;
use xiom.serialize.json;
use xiom.collections;

fn main() -> Int {
  var m1 = Map[Str, Str].new();
  m1.insert("hello", "world");
  io.println("m1.keys[0]=[" + m1.keys[0] + "] values[0]=[" + m1.values[0] + "]");
  var m2 = Map[Str, JsonValue].new();
  m2.insert("name", json.json_string("test"));
  io.println("m2.keys[0]=[" + m2.keys[0] + "]");
  var v = m2.values[0];
  io.println("m2 stringify=[" + json.json_stringify(v) + "]");
  return 0;
}

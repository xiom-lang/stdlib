// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_vect_json
use xiom.io;
use xiom.serialize.json;

fn main() -> Int {
  var vals = Vec[JsonValue].new();
  vals.push(json.json_number(42.0));
  io.println("v0=[" + json.json_stringify(vals[0]) + "]");
  vals.push(json.json_string("second"));
  io.println("v1=[" + json.json_stringify(vals[1]) + "]");
  var m = Map[Int, JsonValue].new();
  m.insert(7, json.json_string("seven"));
  io.println("m7=[" + json.json_stringify(m.values[0]) + "]");
  var arr = json.json_array_new();
  arr = json.json_array_push(arr, json.json_number(1.0));
  arr = json.json_array_push(arr, json.json_string("two"));
  io.println("arr=[" + json.json_stringify(arr) + "]");
  return 0;
}

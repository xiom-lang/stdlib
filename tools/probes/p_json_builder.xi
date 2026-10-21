// p_json_builder.xi -- in-place JSON builders (REL-20261020-1704 pulse).
// One Map/Vec per builder; no copy per key/item. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_builder

use xiom.serialize.json;
use xiom.io;

fn main() -> Int {
  var o = json.json_object_builder_new();
  o.put("year", json.json_number(1821.0));
  o.put("related", json.json_bool(true));
  var arr = json.json_array_builder_new();
  arr.push(json.json_number(1.0));
  arr.push(json.json_string("x"));
  o.put("arr", arr.build());
  let s = json.json_stringify(o.build());
  if s != "{\"year\":1821,\"related\":true,\"arr\":[1,\"x\"]}" { return 1; }

  var a = json.json_array_builder_new();
  a.push(json.json_number(2.0));
  a.push(json.json_string("y"));
  let t = json.json_stringify(a.build());
  if t != "[2,\"y\"]" { return 4; }
  return 0;
}

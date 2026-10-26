// p_json_ref_api.xi -- reference-taking JSON entry points (REL-20261020-1704).
// Locks byte parity between the by-value legacy entry points and the new
// json_*_ref forms, and exercises the ref path on a repeated large tree.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_ref_api

use xiom.serialize.json;

fn parse_ok(s: Str) -> JsonValue {
  let p = json.json_parse(s);
  match p {
    Ok(v) => { return v; },
    Err(_) => { return json.json_null(); },
  }
}

fn main() -> Int {
  let s = "{\"a\":1,\"b\":[true,null,\"x\"],\"c\":{\"d\":2.5}}";

  // Compact parity.
  let v1 = parse_ok(s);
  let compact = json.json_stringify_ref(&v1);
  if compact != "{\"a\":1,\"b\":[true,null,\"x\"],\"c\":{\"d\":2.5}}" { return 1; }
  let compact_val = json.json_stringify(v1);
  if compact != compact_val { return 2; }

  // Pretty parity.
  let v2 = parse_ok(s);
  let pretty = json.json_pretty_ref(&v2);
  let pretty_val = json.json_pretty(v2);
  if pretty != pretty_val { return 3; }

  // Type parity (check the ref value before the by-value call moves it).
  let v3 = parse_ok(s);
  let ty = json.json_type_ref(&v3);
  if ty != "object" { return 4; }
  let ty_val = json.json_type(v3);
  if ty != ty_val { return 5; }

  // Get parity: only the found subtree is copied by the ref form.
  let v4 = parse_ok(s);
  let g = json.json_get_ref(&v4, "a");
  if g.is_none { return 6; }
  let gs = json.json_stringify_ref(&g.value);
  if gs != "1" { return 7; }
  let gb = json.json_get(v4, "a");
  if gb.is_none { return 8; }
  if json.json_stringify(gb.value) != gs { return 9; }

  // Non-object get is None.
  let v5 = parse_ok("[1,2]");
  if json.json_get_ref(&v5, "x").is_some { return 10; }
  if json.json_type_ref(&v5) != "array" { return 11; }

  // Scalar variants through the ref renderer.
  let n = json.json_null();
  if json.json_stringify_ref(&n) != "null" { return 12; }
  let b = json.json_bool(false);
  if json.json_stringify_ref(&b) != "false" { return 13; }
  let num = json.json_number(3.5);
  if json.json_stringify_ref(&num) != "3.5" { return 14; }
  let strv = json.json_string("hi");
  if json.json_stringify_ref(&strv) != "\"hi\"" { return 15; }

  // Repeated ref render of a 50-element tree: output stays stable.
  var arr_b = json.json_array_builder_new();
  var i = 0;
  while i < 50 {
    arr_b.push(json.json_number(i as Float64));
    i = i + 1;
  }
  let big = arr_b.build();
  let big_s = json.json_stringify_ref(&big);
  var j = 0;
  while j < 200 {
    let again = json.json_stringify_ref(&big);
    if again.len() != big_s.len() { return 16; }
    j = j + 1;
  }

  return 0;
}

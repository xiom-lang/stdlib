// p_json_stringify_render.xi -- byte-exact JSON renderer after the wave-208
// builder rewrite (REL-20261020-1704 pulse). Covers compact and pretty
// output, string escapes, empty containers, and repeated rendering.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_stringify_render

use xiom.serialize.json;
use xiom.io;

fn main() -> Int {
  var root = json.json_object_new();
  root = json.json_set(root, "s", json.json_string("a\"b\\c\nd\te/f"));
  root = json.json_set(root, "n", json.json_number(1821.0));
  root = json.json_set(root, "b", json.json_bool(true));
  var arr = json.json_array_new();
  arr = json.json_array_push(arr, json.json_null());
  arr = json.json_array_push(arr, json.json_string("x"));
  root = json.json_set(root, "a", arr);

  let want = "{\"s\":\"a\\\"b\\\\c\\nd\\te\\/f\",\"n\":1821,\"b\":true,\"a\":[null,\"x\"]}";
  let got = json.json_stringify(root);
  if got != want {
    io.println("compact got=" + got);
    return 1;
  }

  let want_pretty = "{\n  \"s\": \"a\\\"b\\\\c\\nd\\te\\/f\",\n  \"n\": 1821,\n  \"b\": true,\n  \"a\": [\n    null,\n    \"x\"\n  ]\n}";
  let pretty = json.json_pretty(root);
  if pretty != want_pretty {
    io.println("pretty got=" + pretty);
    return 2;
  }

  // Control bytes use the \u00XX form.
  let ctl = json.json_stringify(json.json_string("z\u{0001}"));
  if ctl != "\"z\\u0001\"" {
    io.println("ctl got=" + ctl);
    return 3;
  }

  // Empty containers.
  if json.json_pretty(json.json_array_new()) != "[]" { return 4; }
  if json.json_pretty(json.json_object_new()) != "{}" { return 5; }
  if json.json_stringify(json.json_array_new()) != "[]" { return 6; }
  if json.json_stringify(json.json_object_new()) != "{}" { return 7; }

  // Repeated rendering must stay byte-exact (the old concat path retained
  // intermediates under this shape).
  var i = 0;
  while i < 500 {
    let compact = json.json_stringify(root);
    if compact != want { return 8; }
    let spaced = json.json_pretty(root);
    if spaced.len() == 0 { return 9; }
    i = i + 1;
  }
  return 0;
}

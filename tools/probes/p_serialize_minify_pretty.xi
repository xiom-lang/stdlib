// p_serialize_minify_pretty.xi -- byte-exact golden checks for the
// string-based JSON minifier and pretty-printer after the wave-208 byte
// builder rewrite. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_serialize_minify_pretty

use xiom.serialize;
use xiom.io;

fn expect_ok(label: Str, r: Result[Str, Str], want: Str) -> Int {
  if !r.is_ok {
    io.println(label + " unexpected ERR");
    return 1;
  }
  if r.value != want {
    io.println(label + " got=[" + r.value + "]");
    return 1;
  }
  return 0;
}

fn expect_err(label: Str, r: Result[Str, Str]) -> Int {
  if r.is_ok {
    io.println(label + " expected ERR, got=[" + r.value + "]");
    return 1;
  }
  return 0;
}

fn main() -> Int {
  // Empty and whitespace-only inputs stay Ok("").
  if expect_ok("empty.min", serialize.json_minify(""), "") != 0 { return 1; }
  if expect_ok("empty.pretty", serialize.json_pretty(""), "") != 0 { return 2; }
  if expect_ok("ws.min", serialize.json_minify("   "), "") != 0 { return 3; }
  if expect_ok("ws.pretty", serialize.json_pretty("   "), "") != 0 { return 4; }

  // Nested object: whitespace outside strings removed, inside preserved.
  let obj = "{\"a\": 1, \"b\": [1, 2], \"c\": {\"d\": \"x y\"}}";
  if expect_ok("obj.min", serialize.json_minify(obj),
      "{\"a\":1,\"b\":[1,2],\"c\":{\"d\":\"x y\"}}") != 0 { return 5; }
  if expect_ok("obj.pretty", serialize.json_pretty(obj),
      "{\n  \"a\": 1,\n  \"b\": [\n    1,\n    2],\n  \"c\": {\n    \"d\": \"x y\"}}") != 0 { return 6; }

  // Array with an escaped backslash inside a string.
  let arr = "[\"a b\", {\"k\": \"v\\\\w\"}, true, null]";
  if expect_ok("arr.min", serialize.json_minify(arr),
      "[\"a b\",{\"k\":\"v\\\\w\"},true,null]") != 0 { return 7; }
  if expect_ok("arr.pretty", serialize.json_pretty(arr),
      "[\n  \"a b\",\n  {\n    \"k\": \"v\\\\w\"},\n  true,\n  null]") != 0 { return 8; }

  // Commas and colons inside strings are data, not separators.
  let seps = "{\"s\":\"a, b: c\"}";
  if expect_ok("seps.min", serialize.json_minify(seps), "{\"s\":\"a, b: c\"}") != 0 { return 9; }
  if expect_ok("seps.pretty", serialize.json_pretty(seps), "{\n  \"s\": \"a, b: c\"}") != 0 { return 10; }

  // Escaped quote inside a string.
  let esc = "{\"esc\":\"a\\\"b\"}";
  if expect_ok("esc.min", serialize.json_minify(esc), "{\"esc\":\"a\\\"b\"}") != 0 { return 11; }
  if expect_ok("esc.pretty", serialize.json_pretty(esc), "{\n  \"esc\": \"a\\\"b\"}") != 0 { return 12; }

  // UTF-8 passes through byte-for-byte.
  let utf8 = "{\"u\":\"h\u{00e9}llo\"}";
  if expect_ok("utf8.min", serialize.json_minify(utf8), "{\"u\":\"h\u{00e9}llo\"}") != 0 { return 13; }
  if expect_ok("utf8.pretty", serialize.json_pretty(utf8), "{\n  \"u\": \"h\u{00e9}llo\"}") != 0 { return 14; }

  // Unterminated strings are rejected by both.
  if expect_err("bad.min", serialize.json_minify("{\"a\":\"b")) != 0 { return 15; }
  if expect_err("bad.pretty", serialize.json_pretty("{\"a\":\"b")) != 0 { return 16; }

  return 0;
}

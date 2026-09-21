// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_glob_step
use xiom.io;
use xiom.convert;
fn one(pattern: Str, s: Str, idx: Int) -> Int {
  io.println("[" + convert.int_to_string(idx) + "] before");
  var m = xiom.misc.glob.glob_match(pattern, s);
  io.println("[" + convert.int_to_string(idx) + "] misc=" + convert.bool_to_string(m));
  var g = xiom.string.glob.glob_match(pattern, s);
  io.println("[" + convert.int_to_string(idx) + "] string=" + convert.bool_to_string(g));
  return 0;
}
fn main() -> Int {
  var _ = one("*.xi", "a.xi", 1);
  var _b = one("a?c", "abc", 2);
  _b = one("a*b*c", "aXXbYYc", 3);
  _b = one("[ab]c", "ac", 4);
  _b = one("a[bc]d", "abd", 5);
  var _c = xiom.misc.glob.glob_match_case_insensitive("*.XI", "a.xi");
  io.println("ci done");
  return 0;
}

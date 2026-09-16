// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_glob_trace
use xiom.io.console;
use xiom.convert;
fn one(pattern: Str, s: Str, idx: Int) -> Int {
  console.console_write_line("[" + convert.int_to_string(idx) + "] pre");
  console.console_flush();
  var m = xiom.misc.glob.glob_match(pattern, s);
  console.console_write_line("[" + convert.int_to_string(idx) + "] misc=" + convert.bool_to_string(m));
  console.console_flush();
  var g = xiom.string.glob.glob_match(pattern, s);
  console.console_write_line("[" + convert.int_to_string(idx) + "] string=" + convert.bool_to_string(g));
  console.console_flush();
  return 0;
}
fn main() -> Int {
  var _ = one("*.xi", "a.xi", 1);
  _ = one("*.xi", "a.txt", 2);
  _ = one("a?c", "abc", 3);
  _ = one("a?c", "ac", 4);
  _ = one("a?c", "abbc", 5);
  _ = one("*", "anything", 6);
  _ = one("*", "", 7);
  _ = one("", "", 8);
  _ = one("", "x", 9);
  _ = one("a*b*c", "aXXbYYc", 10);
  _ = one("a*b*c", "aXXbYY", 11);
  _ = one("[ab]c", "ac", 12);
  _ = one("a[bc]d", "abd", 13);
  _ = one("*.XI", "a.xi", 14);
  console.console_write_line("ci pre");
  console.console_flush();
  var _ci = xiom.misc.glob.glob_match_case_insensitive("*.XI", "a.xi");
  console.console_write_line("ci done");
  console.console_flush();
  return 0;
}

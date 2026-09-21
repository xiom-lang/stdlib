// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_glob_parity
use xiom.io;
use xiom.convert;

fn show(pattern: Str, s: Str) -> Int {
  var m = xiom.misc.glob.glob_match(pattern, s);
  var g = xiom.string.glob.glob_match(pattern, s);
  var tag = "same";
  if m != g { tag = "DIFF"; }
  io.println("[" + pattern + "] vs [" + s + "]: misc=" + convert.bool_to_string(m) + " string=" + convert.bool_to_string(g) + " " + tag);
  return 0;
}

fn main() -> Int {
  show("*.xi", "a.xi");
  show("*.xi", "a.txt");
  show("a?c", "abc");
  show("a?c", "ac");
  show("a?c", "abbc");
  show("*", "anything");
  show("*", "");
  show("", "");
  show("", "x");
  show("a*b*c", "aXXbYYc");
  show("a*b*c", "aXXbYY");
  show("[ab]c", "ac");
  show("a[bc]d", "abd");
  show("a[bc]d", "aed");
  show("*.XI", "a.xi");
  var ci_m = xiom.misc.glob.glob_match_case_insensitive("*.XI", "a.xi");
  var ci_s = xiom.string.glob.glob_match_case_insensitive("*.XI", "a.xi");
  io.println("ci: misc=" + convert.bool_to_string(ci_m) + " string=" + convert.bool_to_string(ci_s));
  return 0;
}

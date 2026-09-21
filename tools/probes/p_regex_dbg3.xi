// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_regex_dbg3
use xiom.io.console;
use xiom.regex;
fn main() -> Int {
  var r1 = regex.Regex.new("abc");
  console.console_write_line("r1 new");
  console.console_flush();
  var m1 = r1.matches("abc");
  console.console_write_line("r1 matches=" + (if m1 { "true" } else { "false" }));
  console.console_flush();
  var c1 = r1.captures("abc");
  console.console_write_line("r1 captures done");
  console.console_flush();
  var r2 = regex.Regex.new("([a-z]+)");
  console.console_write_line("r2 new (group only)");
  console.console_flush();
  var m2 = r2.matches("abc");
  console.console_write_line("r2 matches=" + (if m2 { "true" } else { "false" }));
  console.console_flush();
  var c2 = r2.captures("abc");
  console.console_write_line("r2 captures done");
  console.console_flush();
  return 0;
}

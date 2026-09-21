// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_regex_dbg4
use xiom.io.console;
use xiom.regex;
fn main() -> Int {
  var rn1 = regex.Regex.new("abc");
  match rn1 {
    Err(_) => { console.console_write_line("r1 new err"); console.console_flush(); return 1; }
    Ok(r1) => {
      console.console_write_line("r1 new ok");
      console.console_flush();
      var m1 = r1.is_match("abc");
      console.console_write_line("r1 is_match done");
      console.console_flush();
      var c1 = r1.captures("abc");
      console.console_write_line("r1 captures(non-group) done");
      console.console_flush();
    }
  }
  var rn2 = regex.Regex.new("([a-z]+)");
  match rn2 {
    Err(_) => { console.console_write_line("r2 new err"); console.console_flush(); return 2; }
    Ok(r2) => {
      console.console_write_line("r2 new ok");
      console.console_flush();
      var m2 = r2.is_match("abc");
      console.console_write_line("r2 is_match done");
      console.console_flush();
      var c2 = r2.captures("abc");
      console.console_write_line("r2 captures(group) done");
      console.console_flush();
    }
  }
  return 0;
}

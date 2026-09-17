// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_regex_dbg5
use xiom.io.console;
use xiom.convert;
use xiom.regex;
fn main() -> Int {
  var rn = regex.Regex.new("[a-z]+");
  match rn {
    Err(_) => { return 3; }
    Ok(re) => {
      var c = re.captures("hello42");
      if c.is_none { console.console_write_line("captures none"); console.console_flush(); return 1; }
      var caps = c.unwrap();
      console.console_write_line("len=" + convert.int_to_string(caps.len()));
      console.console_flush();
      var g0 = caps.get(0);
      console.console_write_line("get0 done is_some=" + convert.bool_to_string(g0.is_some));
      console.console_flush();
      if g0.is_some {
        var m = g0.unwrap();
        console.console_write_line("text=[" + m.text + "]");
        console.console_flush();
      }
      var g1 = caps.get(1);
      console.console_write_line("get1 is_some=" + convert.bool_to_string(g1.is_some));
      console.console_flush();
    }
  }
  var rn2 = regex.Regex.new("[0-9]+");
  match rn2 {
    Err(_) => { return 5; }
    Ok(re2) => {
      var cnt = re2.match_count("a1b22c333");
      console.console_write_line("count=" + convert.int_to_string(cnt));
      console.console_flush();
    }
  }
  return 0;
}

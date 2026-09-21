// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_mc
use xiom.io.console;
use xiom.convert;
use xiom.regex;
fn main() -> Int {
  var rn = regex.Regex.new("[0-9]+");
  match rn {
    Err(_) => { console.console_write_line("new err"); console.console_flush(); return 3; }
    Ok(re) => {
      var im = re.is_match("a1b22c333");
      console.console_write_line("is_match=" + convert.bool_to_string(im));
      console.console_flush();
      var cnt = re.match_count("a1b22c333");
      console.console_write_line("count=" + convert.int_to_string(cnt));
      console.console_flush();
      var fa = re.find_all("a1b22c333");
      console.console_write_line("find_all.len=" + convert.int_to_string(fa.len()));
      console.console_flush();
    }
  }
  return 0;
}

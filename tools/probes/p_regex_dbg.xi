// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_regex_dbg
use xiom.io.console;
use xiom.convert;
fn main() -> Int {
  console.console_write_line("step1 pre");
  console.console_flush();
  var re = xiom.regex.Regex.new("([a-z]+)([0-9]+)");
  console.console_write_line("step2 new done plen=" + convert.int_to_string(re.pattern.len()));
  console.console_flush();
  var c = re.captures("abc123");
  console.console_write_line("step3 captures done");
  console.console_flush();
  if c.is_some {
    console.console_write_line("step4 some");
  } else {
    console.console_write_line("step4 none");
  }
  console.console_flush();
  return 0;
}

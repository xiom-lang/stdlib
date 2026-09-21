// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_glob_flush
use xiom.io.console;
use xiom.convert;
fn main() -> Int {
  console.console_write_line("step1");
  console.console_flush();
  var m = xiom.misc.glob.glob_match("a", "a");
  console.console_write_line("step2 m=" + convert.bool_to_string(m));
  console.console_flush();
  var g = xiom.string.glob.glob_match("a", "a");
  console.console_write_line("step3 g=" + convert.bool_to_string(g));
  console.console_flush();
  return 0;
}

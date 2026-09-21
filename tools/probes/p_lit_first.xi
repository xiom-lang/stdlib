// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_lit_first
use xiom.io.console;
fn main() -> Int {
  console.console_write_line("pre");
  console.console_flush();
  var g2 = xiom.misc.glob.glob_match("*.xi", "main.xi");
  console.console_write_line("literals done");
  console.console_flush();
  var pat = "*.xi";
  var s = "main.xi";
  var g1 = xiom.misc.glob.glob_match(pat, s);
  console.console_write_line("vars done");
  console.console_flush();
  return 0;
}

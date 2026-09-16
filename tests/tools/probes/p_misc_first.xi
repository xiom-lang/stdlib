// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_misc_first
use xiom.io.console;
fn main() -> Int {
  console.console_write_line("pre");
  console.console_flush();
  var m = xiom.misc.glob.glob_match("*.xi", "main.xi");
  console.console_write_line("mid");
  console.console_flush();
  var g = xiom.string.glob.glob_match("*.xi", "main.xi");
  console.console_write_line("post");
  console.console_flush();
  return 0;
}

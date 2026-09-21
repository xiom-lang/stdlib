// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_optmatch
use xiom.io.console;
use xiom.regex;
fn main() -> Int {
  var v = Vec[Option[regex.Match]].new();
  var m = regex.Match{ start: 0; end: 3; text: "abc"; };
  v.push(Some(m));
  console.console_write_line("push done len=" + (if true { "" } else { "" }));
  console.console_flush();
  var e = v[0];
  console.console_write_line("read done");
  console.console_flush();
  if e.is_some {
    var mm = e.unwrap();
    console.console_write_line("text=[" + mm.text + "]");
    console.console_flush();
  }
  return 0;
}

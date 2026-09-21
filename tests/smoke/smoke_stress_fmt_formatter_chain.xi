// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_fmt_formatter_chain
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_str("hello");
  f.write_str(" ");
  f.write_str("world");
  var s = f.finish();
  if s == "hello world" { return 0; } else { return 1; }
}

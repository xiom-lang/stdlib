// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_fmt_formatter_reset
use xiom.fmt;

fn main() -> Int {
  var f = fmt.Formatter.new();
  f.write_str("first");
  var s1 = f.finish();
  var f2 = fmt.Formatter.new();
  f2.write_str("second");
  var s2 = f2.finish();
  if s1 == "first" {
    if s2 == "second" { return 0; } else { return 2; }
  } else { return 1; }
}

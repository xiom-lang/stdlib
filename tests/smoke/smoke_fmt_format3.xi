// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_fmt_format3
use xiom.fmt;

fn main() -> Int {
  if fmt.format3("{} {} {}", 1, 2, 3) != "1 2 3" { return 1; }
  if fmt.format3("{}, {}, {}", "a", "b", "c") != "a, b, c" { return 2; }

  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_fmt_print_builtin
use xiom.fmt;

fn main() -> Int {
  fmt.print("hello");
  fmt.println("world");
  return 0;
}

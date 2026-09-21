// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_fmt_negative
use xiom.fmt;

fn main() -> Int {
  if (-42).to_str() != "-42" { return 1; }
  if (-1).to_str() != "-1" { return 2; }

  var s = (-3.14).to_str();
  if s == "" { return 3; }

  return 0;
}

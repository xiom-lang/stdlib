// XIOM stdlib stress -- xiom.string.format basic (no args)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests format with a pattern string containing no placeholders.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_format_basic
use xiom.string;

fn main() -> Int {
  var result = xiom.string.format("hello world");
  if result == "hello world" { return 0; } else { return 1; }
}

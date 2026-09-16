// XIOM stdlib stress -- xiom.string.format2 with two args
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests format with two placeholders and two replacement values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_format2
use xiom.string;

fn main() -> Int {
  var result = xiom.string.format2("{} + {} = 3", "1", "2");
  if result == "1 + 2 = 3" { return 0; } else { return 1; }
}

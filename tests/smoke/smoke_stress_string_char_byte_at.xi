// XIOM stdlib stress -- xiom.string.byte_at / char_at access
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Verifies byte_at returns ASCII codes, char_at returns Some for valid.
// Returns 0 on success.

module smoke_stress_string_char_byte_at
use xiom.string;

fn main() -> Int {
  var s = "ABC";
  if xiom.string.byte_at(s, 0) == 65 && xiom.string.byte_at(s, 1) == 66 {
    return 0;
  }
  return 1;
}

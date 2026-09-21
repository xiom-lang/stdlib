// XIOM stdlib smoke test -- xiom.char
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_char
use xiom.char;

fn main() -> Int {
  if char.is_digit('5') && char.to_uppercase('a') == 'A' && char.to_lowercase('Z') == 'z' {
    return 0;
  }
  return 1;
}

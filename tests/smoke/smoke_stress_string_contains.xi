// XIOM stdlib stress -- xiom.string.str_contains presence/absence
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Checks substring found and not found cases.
// Returns 0 on success.

module smoke_stress_string_contains
use xiom.string;

fn main() -> Int {
  var s = "hello world";
  if xiom.string.str_contains(s, "wor") && not xiom.string.str_contains(s, "xyz") {
    return 0;
  }
  return 1;
}

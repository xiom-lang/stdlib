// XIOM stdlib stress -- xiom.string.str_to_int valid and invalid input
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Parses a valid integer, verifies invalid input returns Err.
// Returns 0 on success.

module smoke_stress_string_to_int_edge
use xiom.string;

fn main() -> Int {
  var ok = xiom.string.str_to_int("42");
  var bad = xiom.string.str_to_int("not_a_number");
  var ok_int = 0;
  var is_err = false;
  match ok {
    Ok(n) => { ok_int = n; }
    Err(_) => { return 1; }
  }
  match bad {
    Ok(_) => { return 2; }
    Err(_) => { is_err = true; }
  }
  if ok_int == 42 && is_err { return 0; } else { return 3; }
}

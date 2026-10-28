// Minimal repro: a match on Result[Bool, Str] with nested literal Bool
// patterns takes the Ok(false) arm for an Ok(true) value.
//
// Observed on the official v0.64.8 and v0.65.2 windows-x64 archives:
// compile rc 0, run rc 2 (the Ok(false) arm). Binding the Bool first
// (`Ok(v) => if !v { ... }`) is the workaround used in
// xiom/net/h2_io.xi's frame reader.
//
// Expected: run rc 0.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_result_bool_pattern

fn f() -> Result[Bool, Str] {
  return Ok(true);
}

fn main() -> Int {
  match f() {
    Err(_) => { return 1; },
    Ok(false) => { return 2; },
    Ok(true) => { },
  }
  return 0;
}

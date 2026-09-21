// XIOM stdlib stress -- io.args returns at least program name
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Verifies that args vector has at least 1 element (the binary path).
// Returns 0 on success.

module smoke_stress_io_args
use xiom.io;

fn main() -> Int {
  var a = io.args();
  if a.len() >= 1 { return 0; } else { return 1; }
}

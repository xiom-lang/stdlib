// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_path_separator
use xiom.path;

fn main() -> Int {
  var sep = path.path_separator();
  if sep.len() > 0 { return 0; } else { return 1; }
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_path_starts_ends_with
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/usr/local/bin/xiom");
  if p.starts_with(path.Path.new("/usr")) {
    if p.ends_with(path.Path.new("xiom")) { return 0; } else { return 2; }
  } else { return 1; }
}

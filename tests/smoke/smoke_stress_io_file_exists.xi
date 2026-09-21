// XIOM stdlib stress -- io.file_exists true/false
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Writes a file, confirms exists, removes, confirms gone.
// Returns 0 on success.

module smoke_stress_io_file_exists
use xiom.io;

fn main() -> Int {
  var path = "__smk_exists.txt";
  io.write_file(path, "test");
  var exists = io.file_exists(path);
  io.remove_file(path);
  var not_exists = io.file_exists("__nonexistent_xyz.xyz");
  if exists && not not_exists { return 0; } else { return 1; }
}

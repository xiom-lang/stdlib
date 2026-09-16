// XIOM stdlib stress -- io.copy_file content preservation
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Copies a file, reads destination, verifies content matches.
// Returns 0 on success.

module smoke_stress_io_copy_file
use xiom.io;

fn main() -> Int {
  var src = "__smk_copy_src.txt";
  var dst = "__smk_copy_dst.txt";
  io.write_file(src, "copy test data");
  io.copy_file(src, dst);
  var rd = io.read_file(dst);
  io.remove_file(src);
  io.remove_file(dst);
  match rd {
    Ok(s) => {
      if s == "copy test data" { return 0; } else { return 1; }
    }
    Err(_) => { return 2; }
  }
}

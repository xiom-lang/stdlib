// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_remove
use xiom.io;

fn main() -> Int {
  let path = "__smoke_io_remove.txt";

  io.write_file(path, "data");
  if !io.file_exists(path) { return 1; }

  match io.remove_file(path) {
    Ok(_) => {},
    Err(_) => { return 2; },
  };

  if io.file_exists(path) { return 3; }

  io.write_file(path, "data2");
  io.remove_file(path);

  return 0;
}

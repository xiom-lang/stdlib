// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Directory rename regression for REL-20261019-2020-stdlib: the old
// postcondition used file_exists (fopen-based, false for directories),
// so a successful directory move tripped the runtime contract.
module smoke_io_rename_dir
use xiom.io;

fn main() -> Int {
  let old = "__smoke_io_rename_dir_old";
  let new = "__smoke_io_rename_dir_new";

  if io.is_dir(old) { let _ = io.remove_dir(old); }
  if io.is_dir(new) { let _ = io.remove_dir(new); }

  match io.create_dir(old) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };

  match io.rename(old, new) {
    Ok(_) => {},
    Err(_) => { let _ = io.remove_dir(old); return 2; },
  };

  if io.is_dir(old) { let _ = io.remove_dir(new); return 3; }
  if !io.is_dir(new) { let _ = io.remove_dir(old); return 4; }

  match io.remove_dir(new) {
    Ok(_) => {},
    Err(_) => { return 5; },
  };
  return 0;
}

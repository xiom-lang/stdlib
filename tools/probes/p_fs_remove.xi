// p_fs_remove.xi -- probe lock: xiom.io.fs.fs_remove
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Bindings-lane relay 2026-10-08 (docs/BINDINGS-STDLIB-WISHLIST.md W-1):
// the fs module had write/read/append/copy but no remove, so binding suites
// could not clean up artifacts (sqlite conformance temp DBs). fs_remove
// delegates to io.remove_file. Returns 0 when removal works.

module p_fs_remove

use xiom.io.fs as fs;
use xiom.io;

fn main() -> Int {
  let path = "__p_fs_remove.txt";

  var data = Vec[UInt8].new();
  data.push(65 as UInt8);
  match fs.fs_write(path, &data) {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  if !io.file_exists(path) { return 2; }

  match fs.fs_remove(path) {
    Ok(_) => {},
    Err(_) => { return 3; },
  };
  if io.file_exists(path) { return 4; }

  // Removing a missing file is an Err, not a silent Ok.
  let again = fs.fs_remove(path);
  if again.is_ok { return 5; }

  return 0;
}

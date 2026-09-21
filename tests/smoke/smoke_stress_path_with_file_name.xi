// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_path_with_file_name
use xiom.path;

fn main() -> Int {
  var p = path.Path.new("/usr/bin/old.txt");
  var renamed = p.with_file_name("new.txt");
  // PathBuf has no file_name -- go through as_path() like the other smokes.
  var name = renamed.as_path().file_name();
  match name {
    Some(n) => {
      if n == "new.txt" { return 0; } else { return 2; }
    }
    None => { return 1; }
  }
}

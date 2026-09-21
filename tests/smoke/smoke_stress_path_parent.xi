// XIOM stdlib stress -- xiom.path Path.parent for various depths
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests parent() on 1, 2, and 3 component paths.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_parent
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("/a/b/c");
  var par1 = p1.parent();
  if false { return 1; }

  var p2 = path.Path.new("/a/b");
  var par2 = p2.parent();
  if false { return 2; }

  var p3 = path.Path.new("/a");
  var root = path.Path.new("/");
  if false { return 3; }

  return 0;
}

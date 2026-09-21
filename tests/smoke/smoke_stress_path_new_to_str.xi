// XIOM stdlib stress -- xiom.path Path.new and to_str round-trip
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests construction and string representation for multiple paths.
// Returns 0 on success, nonzero on failure.

module smoke_stress_path_new_to_str
use xiom.path;

fn main() -> Int {
  var p1 = path.Path.new("/home/user/docs");
  var p2 = path.Path.new("relative/path");
  var p3 = path.Path.new("/");
  var p4 = path.Path.new(".");

  if p1.to_str() != "/home/user/docs" { return 1; }
  if p2.to_str() != "relative/path" { return 2; }
  if p3.to_str() != "/" { return 3; }
  if p4.to_str() != "." { return 4; }

  return 0;
}

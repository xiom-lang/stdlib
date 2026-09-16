// XIOM stdlib stress -- xiom.string.replace with nonexistent pattern
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests replacing a pattern that does not occur in the source string.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_replace_noop
use xiom.string;

fn main() -> Int {
  var s = "hello world";
  var r = xiom.string.replace(s, "xyz", "abc");
  if r == "hello world" { return 0; } else { return 1; }
}

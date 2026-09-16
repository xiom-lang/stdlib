// XIOM stdlib stress -- xiom.string.str_trim edge cases
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Tests trim on whitespace-only, already-trimmed, and mixed strings.
// Returns 0 on success, nonzero on failure.

module smoke_stress_string_trim_edge
use xiom.string;

fn main() -> Int {
  var t1 = xiom.string.str_trim("   hello  ");
  var t2 = xiom.string.str_trim("hello");
  var t3 = xiom.string.str_trim("   ");
  var t4 = xiom.string.str_trim("");
  if t1 != "hello" { return 1; }
  if t2 != "hello" { return 2; }
  if t3 != "" { return 3; }
  if t4 != "" { return 4; }
  return 0;
}

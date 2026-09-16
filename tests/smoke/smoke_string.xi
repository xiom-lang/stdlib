// XIOM stdlib smoke test -- xiom.string
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_string
use xiom.string;

fn main() -> Int {
  if xiom.string.str_len("hello") == 5
     && xiom.string.str_concat("ab", "cd") == "abcd"
     && xiom.string.str_upper("hi") == "HI" {
    return 0;
  }
  return 1;
}

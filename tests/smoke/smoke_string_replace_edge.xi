// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_string_replace_edge
use xiom.string;

fn main() -> Int {
  if string.replace("aaaa", "aa", "b") != "bb" { return 1; }
  if string.replace("ababab", "ab", "x") != "xxx" { return 2; }
  if string.replace("hello", "", "x") != "hello" { return 3; }
  if string.replace("", "a", "b") != "" { return 4; }
  if string.replace("a", "a", "") != "" { return 5; }

  return 0;
}

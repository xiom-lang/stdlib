// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module probe_concat_chain
use xiom.string;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var b = "a";
  b = string.str_concat(b, "b");
  b = string.str_concat(b, "c");
  b = string.str_concat(b, "d");
  b = string.str_concat(b, "e");
  if b.len() != 5 { io.println("len=" + convert.int_to_string(b.len())); return 1; }
  if b != "abcde" { io.println("content=" + b); return 2; }
  io.println("OK");
  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_tuple_str
use xiom.io;
use xiom.string;
fn split(s: Str, sep: Int) -> (Str, Int) {
  var h = string.str_slice(s, 0, sep);
  return (h, 7);
}
fn main() -> Int {
  var parts = split("example.com:8080", 11);
  io.println("h=[" + parts.0 + "] p=" + parts.1);
  var h2 = parts.0;
  io.println("h2=[" + h2 + "]");
  return 0;
}

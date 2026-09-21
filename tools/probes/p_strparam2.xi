// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_strparam2
use xiom.io;
use xiom.convert;
use xiom.string;
fn f(s: Str) -> Int {
  io.println("A s.len=" + convert.int_to_string(s.len()));
  io.println("B s.b0=" + convert.int_to_string(s.byte_at(0) as Int));
  var sl = string.str_slice(s, 0, s.len());
  io.println("C slice.len=" + convert.int_to_string(sl.len()) + " b0=" + convert.int_to_string(sl.byte_at(0) as Int));
  var tr = s.trim();
  io.println("D trim.len=" + convert.int_to_string(tr.len()));
  var tr2 = string.str_trim(s);
  io.println("E str_trim.len=" + convert.int_to_string(tr2.len()));
  return 0;
}
fn main() -> Int {
  var _r = f("42");
  return 0;
}

// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_char_count
use xiom.string;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  io.println("test: len=" + convert.int_to_string("test".len()) + " cc=" + convert.int_to_string("test".char_count()));
  io.println("empty: cc=" + convert.int_to_string("".char_count()));
  io.println("mb: len=" + convert.int_to_string("ab\u{00E4}cd".len()) + " cc=" + convert.int_to_string("ab\u{00E4}cd".char_count()));
  var a = "test".char_at(0);
  if a.is_some { io.println("char_at(0) some"); } else { io.println("char_at(0) none"); }
  return 0;
}

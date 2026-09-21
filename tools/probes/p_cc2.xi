// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_cc2
use xiom.string;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  io.println("test: len=" + convert.int_to_string(string.str_len("test")) + " cc=" + convert.int_to_string(string.char_count("test")));
  io.println("mb: len=" + convert.int_to_string(string.str_len("ab\u{00E4}cd")) + " cc=" + convert.int_to_string(string.char_count("ab\u{00E4}cd")));
  io.println("empty cc=" + convert.int_to_string(string.char_count("")));
  return 0;
}

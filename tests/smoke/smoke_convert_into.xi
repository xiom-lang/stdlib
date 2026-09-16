// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_convert_into
use xiom.convert;

fn main() -> Int {
  match convert.char_to_int('Z') {
    90 => {},
    _ => { return 1; },
  };

  match convert.int_to_char(90) {
    Some(c) => { if c != 'Z' { return 2; } },
    None => { return 3; },
  };

  return 0;
}

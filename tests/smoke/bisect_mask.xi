// BUG 26 #5: high-bit mask AND on byte-extracted values
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module bisect_mask
fn main() -> Int {
  var b0 = 0xC3 as Int;   // a lead byte (byte_at-derived)
  var chk = 0;
  if (b0 & 0xE0) == 0xC0 { chk += 1; }
  if (b0 & 0xF0) == 0xC0 { chk += 1; }
  if (b0 & 0xF8) == 0xC0 { chk += 1; }
  if chk == 3 { return 0; }
  return 1;
}

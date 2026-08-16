// BUG 26 #5: high-bit mask AND on byte-extracted values
fn main() -> Int {
  var b0 = 0xC3 as Int;   // a lead byte (byte_at-derived)
  var chk = 0;
  if (b0 & 0xE0) == 0xC0 { chk += 1; }
  if (b0 & 0xF0) == 0xC0 { chk += 1; }
  if (b0 & 0xF8) == 0xC0 { chk += 1; }
  if chk == 3 { return 0; }
  return 1;
}

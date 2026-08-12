module smoke_string_bidi

use xiom.string.bidi;
use xiom.io;

fn main() -> Int {
  let b1 = bidi.unicode_bidi_class('A');
  if b1 != "L" { io.println("BDI1 b1=" + b1); return 1; }
  let b2 = bidi.unicode_bidi_class(to_char(0x5D0));
  if b2 != "R" { io.println("BDI2 b2=" + b2); return 2; }
  let b3 = bidi.unicode_bidi_class(to_char(0x627));
  if b3 != "AL" { io.println("BDI3 b3=" + b3); return 3; }
  let b4 = bidi.unicode_bidi_class(to_char(0x202D));
  if b4 != "LRO" { io.println("BDI4 b4=" + b4); return 4; }
  let b5 = bidi.unicode_bidi_class('5');
  if b5 != "EN" { io.println("BDI5 b5=" + b5); return 5; }
  let b6 = bidi.unicode_bidi_class(to_char(0x660));
  if b6 != "AN" { io.println("BDI6 b6=" + b6); return 6; }
  let b7 = bidi.unicode_bidi_class('$');
  if b7 != "ET" { io.println("BDI7 b7=" + b7); return 7; }
  if !bidi.unicode_mirrored('(') { io.println("BDI8"); return 8; }
  if bidi.unicode_mirrored('A') { io.println("BDI9"); return 9; }
  let mc1: Char = bidi.unicode_mirror_char('(');
  if mc1 != ')' { io.println("BDI10"); return 10; }
  let mc2: Char = bidi.unicode_mirror_char('}');
  if mc2 != '{' { io.println("BDI11"); return 11; }
  let mc3: Char = bidi.unicode_mirror_char('A');
  if mc3 != 'A' { io.println("BDI12"); return 12; }
  io.println("OK");
  return 0;
}

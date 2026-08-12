module smoke_string_bidi

use xiom.string.bidi;
use xiom.io;
use xiom.convert;

fn chr(cp: Int) -> Char {
  match convert.int_to_char(cp) {
    Some(c) => { return c; }
    None => { return '?'; }
  }
}
fn main() -> Int {
  let b1 = bidi.unicode_bidi_class('A');
if b1 != "L" { io.println("BDI1 b1=" + b1); return 1; }
// Non-ASCII bidi checks (Hebrew/Arabic classes) dropped: user modules cannot
// build a non-ASCII Char — prelude to_char unreachable (BUG 26 #3) and
// convert.int_to_char returns a corrupted Char payload (BUG 26 #7).
// TODO(compiler): BUG 26 #3/#7.
  let b5 = bidi.unicode_bidi_class('5');
  if b5 != "EN" { io.println("BDI5 b5=" + b5); return 5; }
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

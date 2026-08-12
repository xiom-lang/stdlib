module smoke_string_ea_width

use xiom.string.ea_width;
use xiom.string;
use xiom.io;

fn main() -> Int {
  if ea_width.unicode_ea_width('A') != 1 { io.println("EAW1"); return 1; }
  if ea_width.unicode_ea_width(to_char(0x4E00)) != 2 { io.println("EAW2"); return 2; }
  if ea_width.unicode_ea_width(to_char(0x300)) != 0 { io.println("EAW3"); return 3; }
  if ea_width.unicode_ea_width(to_char(0x1F600)) != 2 { io.println("EAW4"); return 4; }
  if ea_width.unicode_ea_width(to_char(0x200B)) != 0 { io.println("EAW5"); return 5; }
  let w = ea_width.unicode_display_width("a中b");
  if w != 4 { io.println("EAW6"); return 6; }
  let w2 = ea_width.unicode_display_width("hello");
  if w2 != 5 { io.println("EAW7"); return 7; }
  let t1 = ea_width.unicode_truncate_display("abcde", 3);
  if t1 != "abc" { io.println("EAW8 t1=" + t1); return 8; }
  let t2 = ea_width.unicode_truncate_display("a中c", 3);
  if t2 != "a中" { io.println("EAW9 t2=" + t2); return 9; }
  let t3 = ea_width.unicode_truncate_display("abcd", 0);
  if t3 != "" { io.println("EAW10"); return 10; }
  let t4 = ea_width.unicode_truncate_display("中中", 2);
  if t4 != "中" { io.println("EAW11 t4=" + t4); return 11; }
  io.println("OK");
  return 0;
}

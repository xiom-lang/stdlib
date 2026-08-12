module smoke_string_category_script

use xiom.string.category;
use xiom.string.script;
use xiom.io;

fn main() -> Int {
  let c1 = category.unicode_general_category('A');
  if c1 != "Lu" { io.println("CAT1 c1=" + c1); return 1; }
  let c2 = category.unicode_general_category('a');
  if c2 != "Ll" { io.println("CAT2"); return 2; }
  let c3 = category.unicode_general_category('1');
  if c3 != "Nd" { io.println("CAT3"); return 3; }
  let c4 = category.unicode_general_category(to_char(0x4E00));
  if c4 != "Lo" { io.println("CAT4"); return 4; }
  let c5 = category.unicode_general_category(to_char(0x300));
  if c5 != "Mn" { io.println("CAT5"); return 5; }
  let c6 = category.unicode_general_category(to_char(0x7F));
  if c6 != "Cc" { io.println("CAT6"); return 6; }
  let c7 = category.unicode_general_category(' ');
  if c7 != "Zs" { io.println("CAT7"); return 7; }
  let c8 = category.unicode_general_category(',');
  if c8 != "Po" { io.println("CAT8"); return 8; }
  let c9 = category.unicode_general_category(to_char(0x100));
  if c9 != "Lu" { io.println("CAT9 c9=" + c9); return 9; }
  let c10 = category.unicode_general_category(to_char(0x101));
  if c10 != "Ll" { io.println("CAT10"); return 10; }
  if !category.unicode_is_letter('A') { io.println("CAT11"); return 11; }
  if !category.unicode_is_digit('5') { io.println("CAT12"); return 12; }
  if !category.unicode_is_punct('!') { io.println("CAT13"); return 13; }
  if !category.unicode_is_symbol('$') { io.println("CAT14"); return 14; }
  if !category.unicode_is_separator(' ') { io.println("CAT15"); return 15; }
  if !category.unicode_is_control(to_char(0x7F)) { io.println("CAT16"); return 16; }
  if !category.unicode_is_printable('A') { io.println("CAT17"); return 17; }
  if category.unicode_is_printable(to_char(0x7F)) { io.println("CAT18"); return 18; }
  let s1 = script.unicode_script('A');
  if s1 != "Latn" { io.println("SCR1 s1=" + s1); return 21; }
  let s2 = script.unicode_script(to_char(0x4E00));
  if s2 != "Hani" { io.println("SCR2"); return 22; }
  let s3 = script.unicode_script(to_char(0x5D0));
  if s3 != "Hebr" { io.println("SCR3"); return 23; }
  let s4 = script.unicode_script(to_char(0x3B1));
  if s4 != "Grek" { io.println("SCR4"); return 24; }
  let s5 = script.unicode_script(' ');
  if s5 != "Zyyy" { io.println("SCR5 s5=" + s5); return 25; }
  let s6 = script.unicode_script(to_char(0x901));
  if s6 != "Deva" { io.println("SCR6"); return 26; }
  let n1 = script.unicode_script_name("Latn");
  if n1 != "Latin" { io.println("SCR7"); return 27; }
  let n2 = script.unicode_script_name("Zzzz");
  if n2 != "Unknown" { io.println("SCR8"); return 28; }
  let n3 = script.unicode_script_name("Zyyy");
  if n3 != "Common" { io.println("SCR9"); return 29; }
  io.println("OK");
  return 0;
}

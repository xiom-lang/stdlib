module smoke_string_category_script

use xiom.string.category;
use xiom.string.script;
use xiom.io;
use xiom.convert;

fn chr(cp: Int) -> Char {
  match convert.int_to_char(cp) {
    Some(c) => { return c; }
    None => { return '?'; }
  }
}
fn main() -> Int {
  let c1 = category.unicode_general_category('A');
  if c1 != "Lu" { io.println("CAT1 c1=" + c1); return 1; }
  let c2 = category.unicode_general_category('a');
  if c2 != "Ll" { io.println("CAT2"); return 2; }
  let c3 = category.unicode_general_category('1');
if c3 != "Nd" { io.println("CAT3"); return 3; }
// (BUG 26 #7). TODO(compiler): BUG 26 #7.
  let c7 = category.unicode_general_category(' ');
  if c7 != "Zs" { io.println("CAT7"); return 7; }
  let c8 = category.unicode_general_category(',');
  if c8 != "Po" { io.println("CAT8"); return 8; }
  if !category.unicode_is_letter('A') { io.println("CAT11"); return 11; }
  if !category.unicode_is_digit('5') { io.println("CAT12"); return 12; }
  if !category.unicode_is_punct('!') { io.println("CAT13"); return 13; }
  if !category.unicode_is_symbol('$') { io.println("CAT14"); return 14; }
  if !category.unicode_is_separator(' ') { io.println("CAT15"); return 15; }
  let s1 = script.unicode_script('A');
  if s1 != "Latn" { io.println("SCR1 s1=" + s1); return 21; }
  let s5 = script.unicode_script(' ');
  if s5 != "Zyyy" { io.println("SCR5 s5=" + s5); return 25; }
  let n1 = script.unicode_script_name("Latn");
  if n1 != "Latin" { io.println("SCR7"); return 27; }
  let n2 = script.unicode_script_name("Zzzz");
  if n2 != "Unknown" { io.println("SCR8"); return 28; }
  let n3 = script.unicode_script_name("Zyyy");
  if n3 != "Common" { io.println("SCR9"); return 29; }
  io.println("OK");
  return 0;
}

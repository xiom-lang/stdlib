module smoke_string_unicode

use xiom.string.unicode;
use xiom.string;
use xiom.io;

fn main() -> Int {
  let n1 = unicode.unicode_normalize_form("①", "NFKC");
  if n1 != "1" { io.println("UNC1"); return 1; }
  let n2 = unicode.unicode_normalize_form("é", "NFD");
  if string.str_len(n2) != 3 { io.println("UNC2"); return 2; }
  if !unicode.unicode_is_normalized("abc", "NFC") { io.println("UNC3"); return 3; }
  if unicode.unicode_is_normalized(n2, "NFC") { io.println("UNC4"); return 4; }
  let cf = unicode.unicode_casefold("Straße");
  if cf != "strasse" { io.println("UNC5"); return 5; }
  let cl: Char = unicode.unicode_casefold_char('A');
  if cl != 'a' { io.println("UNC6"); return 6; }
  let lm: Char = unicode.unicode_lowercase_map('K');
  if lm != 'k' { io.println("UNC7"); return 7; }
  let um: Char = unicode.unicode_uppercase_map('x');
  if um != 'X' { io.println("UNC8"); return 8; }
  let tc = unicode.unicode_titlecase("hELLO wORLD");
  if tc != "Hello World" { io.println("UNC9"); return 9; }
  let clb: Char = unicode.unicode_casefold_char(to_char(0x00C4));
  let cl2 = to_int_from_char(clb);
  if cl2 != 0xE4 { io.println("UNC10"); return 10; }
  let gc = unicode.unicode_grapheme_count(n2);
  if gc != 1 { io.println("UNC11"); return 11; }
  let wc = unicode.unicode_word_count("Hello,world");
  if wc != 3 { io.println("UNC12"); return 12; }
  let sc = unicode.unicode_sentence_count("One. Two.");
  if sc != 2 { io.println("UNC13"); return 13; }
  let dw = unicode.unicode_display_width("a中b");
  if dw != 4 { io.println("UNC14"); return 14; }
  if !unicode.unicode_is_wide(to_char(0x4E00)) { io.println("UNC15"); return 15; }
  if unicode.unicode_is_wide('A') { io.println("UNC16"); return 16; }
  let pd = unicode.unicode_pad_display("ab", 4, "left");
  if pd != "  ab" { io.println("UNC17"); return 17; }
  if !unicode.unicode_is_emoji(to_char(0x1F600)) { io.println("UNC18"); return 18; }
  let ev = unicode.unicode_emoji_version();
  if ev != "15.0" { io.println("UNC19"); return 19; }
  if !unicode.unicode_emoji_zwj(to_char(0x200D)) { io.println("UNC20"); return 20; }
  if !unicode.unicode_emoji_modifier(to_char(0x1F3FB)) { io.println("UNC21"); return 21; }
  let scr = unicode.unicode_script(to_char(0x4E00));
  if scr != "Hani" { io.println("UNC22"); return 22; }
  let sn = unicode.unicode_script_name("Latn");
  if sn != "Latin" { io.println("UNC23"); return 23; }
  let cat = unicode.unicode_general_category('A');
  if cat != "Lu" { io.println("UNC24"); return 24; }
  let cn = unicode.unicode_general_category_name('A');
  if cn != "Uppercase_Letter" { io.println("UNC25"); return 25; }
  let blk = unicode.unicode_block('A');
  if blk != "Basic Latin" { io.println("UNC26"); return 26; }
  let blk2 = unicode.unicode_block(to_char(0x4E00));
  if blk2 != "CJK Unified Ideographs" { io.println("UNC27"); return 27; }
  let bc = unicode.unicode_bidi_class(to_char(0x5D0));
  if bc != "R" { io.println("UNC28"); return 28; }
  let bl = unicode.unicode_bidi_level(to_char(0x5D0));
  if bl != 1 { io.println("UNC29"); return 29; }
  if !unicode.unicode_is_whitespace(' ') { io.println("UNC30"); return 30; }
  if !unicode.unicode_is_alphabetic('A') { io.println("UNC31"); return 31; }
  if !unicode.unicode_is_cased('A') { io.println("UNC32"); return 32; }
  if !unicode.unicode_is_numeric('7') { io.println("UNC33"); return 33; }
  let dv = unicode.unicode_decimal_value('5');
  if !dv.is_some { io.println("UNC34"); return 34; }
  if dv.value != 5 { io.println("UNC35"); return 35; }
  let dv2 = unicode.unicode_decimal_value('x');
  if dv2.is_some { io.println("UNC36"); return 36; }
  let dig = unicode.unicode_digit_value(to_char(0x2460));
  if !dig.is_some { io.println("UNC37"); return 37; }
  if dig.value != 1 { io.println("UNC38"); return 38; }
  let cs = unicode.unicode_combining_sequence(n2 + "b");
  if cs.len() != 2 { io.println("UNC39"); return 39; }
  let cp1 = unicode.unicode_compose_pair('A', to_char(0x301));
  if !cp1.is_some { io.println("UNC40"); return 40; }
  let cpv: Char = cp1.value;
  if to_int_from_char(cpv) != 0xC1 { io.println("UNC41"); return 41; }
  let cp2 = unicode.unicode_compose_pair('A', 'B');
  if cp2.is_some { io.println("UNC42"); return 42; }
  let dec = unicode.unicode_decompose(to_char(0xC1));
  if dec.len() != 2 { io.println("UNC43"); return 43; }
  let sof = unicode.unicode_script_of("中中a");
  if sof != "Hani" { io.println("UNC44"); return 44; }
  let ng = unicode.unicode_next_grapheme(n2 + "b", 0);
  if ng != 3 { io.println("UNC45"); return 45; }
  let pg = unicode.unicode_prev_grapheme(n2 + "b", 4);
  if pg != 3 { io.println("UNC46"); return 46; }
  io.println("OK");
  return 0;
}

module smoke_string_compat
use xiom.string.compat;
use xiom.string.fold;
use xiom.string.mirror;
use xiom.string.rotate;
use xiom.io;

fn main() -> Int {
  // ---- mirror ----
  if mirror.unicode_mirror_char('(') != ')' { io.println("mir-1"); return 1; }
  if mirror.unicode_mirror_char(')') != '(' { io.println("mir-2"); return 2; }
  if mirror.unicode_mirror_char('[') != ']' { io.println("mir-3"); return 3; }
  if mirror.unicode_mirror_char('{') != '}' { io.println("mir-4"); return 4; }
  if mirror.unicode_mirror_char('<') != '>' { io.println("mir-5"); return 5; }
  if mirror.unicode_mirror_char('/') != '\\' { io.println("mir-6"); return 6; }
  if mirror.unicode_mirror_char('a') != 'a' { io.println("mir-7"); return 7; }
  if !mirror.unicode_is_mirrored('(') { io.println("mir-8"); return 8; }
  if !mirror.unicode_is_mirrored(']') { io.println("mir-9"); return 9; }
  if mirror.unicode_is_mirrored('x') { io.println("mir-10"); return 10; }

  // ---- rotate ----
  if rotate.str_rotate("abcde", 2) != "deabc" { io.println("rot-1"); return 11; }
  if rotate.str_rotate("abcde", 5) != "abcde" { io.println("rot-2"); return 12; }
  if rotate.str_rotate("abcde", 7) != "deabc" { io.println("rot-3"); return 13; }
  if rotate.str_rotate("abcde", -1) != "bcdea" { io.println("rot-4"); return 14; }
  if rotate.str_rotate("", 3) != "" { io.println("rot-5"); return 15; }
  if rotate.str_rotate_left("abcde", 2) != "cdeab" { io.println("rot-6"); return 16; }
  if rotate.str_rotate_left("abcde", 7) != "cdeab" { io.println("rot-7"); return 17; }
  if rotate.str_rotate_left("abc", -1) != "cab" { io.println("rot-8"); return 18; }
  if rotate.str_rotate_right("abcde", 2) != "deabc" { io.println("rot-9"); return 19; }
  if rotate.str_rotate_right("abc", 1) != "cab" { io.println("rot-10"); return 20; }

  // ---- fold ----
  if fold.unicode_casefold("ABC") != "abc" { io.println("fold-1"); return 21; }
  if fold.unicode_casefold("AbC") != "abc" { io.println("fold-2"); return 22; }
  if fold.unicode_casefold("123") != "123" { io.println("fold-3"); return 23; }
  if fold.unicode_casefold("") != "" { io.println("fold-4"); return 24; }
  if fold.unicode_fold_full("ABC") != "abc" { io.println("fold-5"); return 25; }
  if fold.unicode_fold_full("AbC") != "abc" { io.println("fold-6"); return 26; }
  if fold.unicode_fold_full("") != "" { io.println("fold-7"); return 27; }

  // ---- compat ----
  if compat.unicode_compatibility_normalize("abc") != "abc" { io.println("compat-1"); return 28; }
  if compat.unicode_compatibility_normalize("") != "" { io.println("compat-2"); return 29; }
  var dec = compat.unicode_decompose("A");
  if dec.len() != 1 { io.println("compat-3"); return 30; }
  var d0 = dec[0];
  if d0 != "A" { io.println("compat-4"); return 31; }
  var dec2 = compat.unicode_decompose("");
  if dec2.len() != 0 { io.println("compat-5"); return 32; }
  var dec3 = compat.unicode_decompose("abc");
  if dec3.len() != 3 { io.println("compat-6"); return 33; }
  var d3 = dec3[0];
  var d4 = dec3[1];
  var d5 = dec3[2];
  if d3 != "a" { io.println("compat-7"); return 34; }
  if d4 != "b" { io.println("compat-8"); return 35; }
  if d5 != "c" { io.println("compat-9"); return 36; }

  io.println("smoke_string_compat: OK");
  return 0;
}

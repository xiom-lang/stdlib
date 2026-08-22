module smoke_string_slice
use xiom.string.slice;
use xiom.io;
use xiom.convert;

fn chr(cp: Int) -> Char {
  match convert.int_to_char(cp) {
    Some(c) => { return c; }
    None => { return '?'; }
  }
}
fn main() -> Int {
  // str_slice(s, start, end): byte range, end exclusive
  if slice.str_slice("hello", 1, 3) != "el" { io.println("slice-1"); return 1; }
  if slice.str_slice("hello", 1, 4) != "ell" { io.println("slice-2"); return 2; }
  if slice.str_slice("hello", 0, 5) != "hello" { io.println("slice-3"); return 3; }
  if slice.str_slice("hello", 2, 2) != "" { io.println("slice-4"); return 4; }
  if slice.str_slice("hello", 3, 1) != "" { io.println("slice-5"); return 5; }
  if slice.str_slice("hello", -1, 3) != "hel" { io.println("slice-6"); return 6; }
  if slice.str_slice("hello", 0, 100) != "hello" { io.println("slice-7"); return 7; }
  if slice.str_slice("", 0, 0) != "" { io.println("slice-8"); return 8; }

  // str_substring(s, start, len)
  if slice.str_substring("hello", 1, 3) != "ell" { io.println("sub-1"); return 11; }
  if slice.str_substring("hello", 0, 5) != "hello" { io.println("sub-2"); return 12; }
  if slice.str_substring("hello", 3, 10) != "lo" { io.println("sub-3"); return 13; }
  if slice.str_substring("hello", 5, 2) != "" { io.println("sub-4"); return 14; }
  if slice.str_substring("hello", -1, 2) != "" { io.println("sub-5"); return 15; }
  if slice.str_substring("hello", 2, 0) != "" { io.println("sub-6"); return 16; }

  // str_chars
  var chars = slice.str_chars("abc");
  if chars.len() != 3 { io.println("chars-1"); return 21; }
  var c0 = chars[0];
  var c1 = chars[1];
  var c2 = chars[2];
  if c0 != 'a' { io.println("chars-2"); return 22; }
  if c1 != 'b' { io.println("chars-3"); return 23; }
  if c2 != 'c' { io.println("chars-4"); return 24; }
  var uchars = slice.str_chars("e\u{03A9}");
  if uchars.len() != 2 { io.println("chars-5"); return 25; }
  var uc0 = uchars[0];
  var uc1 = uchars[1];
  if uc0 != 'e' { io.println("chars-6"); return 26; }
  if (uc1 as Int) != 937 { io.println("chars-7"); return 27; }

  // str_bytes
  var bytes = slice.str_bytes("abc");
  if bytes.len() != 3 { io.println("bytes-1"); return 31; }
  var b0 = bytes[0];
  var b1 = bytes[1];
  var b2 = bytes[2];
  if (b0 as Int) != 97 { io.println("bytes-2"); return 32; }
  if (b1 as Int) != 98 { io.println("bytes-3"); return 33; }
  if (b2 as Int) != 99 { io.println("bytes-4"); return 34; }

  // str_code_points
  var cps = slice.str_code_points("a\u{03A9}");
  if cps.len() != 2 { io.println("cp-1"); return 41; }
  var p0 = cps[0];
  var p1 = cps[1];
  if p0 != 97 { io.println("cp-2"); return 42; }
  if p1 != 937 { io.println("cp-3"); return 43; }

  io.println("smoke_string_slice: OK");
  return 0;
}

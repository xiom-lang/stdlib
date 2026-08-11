module smoke_string_trim
use xiom.string.trim;
use xiom.string.strip;
use xiom.io;

fn main() -> Int {
  if trim.str_trim("  x  ") != "x" { io.println("trim"); return 1; }
  if trim.str_trim_start("  x  ") != "x  " { io.println("trim_start"); return 2; }
  if trim.str_trim_end("  x  ") != "  x" { io.println("trim_end"); return 3; }
  if trim.str_trim_matches("///x///", "/") != "x" { io.println("trim_matches"); return 4; }
  if trim.str_trim_start_matches("###x##", "#") != "x##" { io.println("trim_start_matches"); return 5; }
  if trim.str_trim_end_matches("##x###", "#") != "##x" { io.println("trim_end_matches"); return 6; }

  var sp = strip.str_strip_prefix("prefix-123", "prefix-");
  match sp {
    Some(v) => { if v != "123" { io.println("strip_prefix val"); return 7; } },
    None => { io.println("strip_prefix none"); return 8; },
  }
  var spn = strip.str_strip_prefix("nope", "x");
  if spn.is_some { io.println("strip_prefix no match"); return 9; }

  var ss = strip.str_strip_suffix("file.txt", ".txt");
  match ss {
    Some(v) => { if v != "file" { io.println("strip_suffix val"); return 10; } },
    None => { io.println("strip_suffix none"); return 11; },
  }

  if strip.str_strip_whitespace("a b\tc") != "abc" { io.println("strip_ws"); return 12; }
  if strip.str_strip_control("a\nb") != "ab" { io.println("strip_ctrl"); return 13; }

  io.println("smoke_string_trim: OK");
  return 0;
}

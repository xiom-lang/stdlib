module smoke_string_glob
use xiom.string.glob;
use xiom.string.segment;
use xiom.string.unescape;
use xiom.io;

fn main() -> Int {
  // ---- glob ----
  if !glob.glob_match("*.xi", "main.xi") { io.println("glob-1"); return 1; }
  if glob.glob_match("*.xi", "main.txt") { io.println("glob-2"); return 2; }
  if !glob.glob_match("a?c", "abc") { io.println("glob-3"); return 3; }
  if glob.glob_match("a?c", "ac") { io.println("glob-4"); return 4; }
  if !glob.glob_match("*", "") { io.println("glob-5"); return 5; }
  if !glob.glob_match("", "") { io.println("glob-6"); return 6; }
  if glob.glob_match("", "x") { io.println("glob-7"); return 7; }
  if !glob.glob_match("a*c", "ac") { io.println("glob-8"); return 8; }
  if !glob.glob_match("a*c", "abbbc") { io.println("glob-9"); return 9; }
  if glob.glob_match("a*c", "abd") { io.println("glob-10"); return 10; }
  if !glob.glob_match("*.xi", "a.b.xi") { io.println("glob-11"); return 11; }
  if !glob.glob_match("a**b", "ab") { io.println("glob-12"); return 12; }
  if !glob.glob_match_case_insensitive("*.XI", "main.xi") { io.println("glob-ci-1"); return 12; }
  if glob.glob_match_case_insensitive("*.XI", "main.txt") { io.println("glob-ci-2"); return 13; }
  if !glob.glob_match_case_insensitive("ABC", "abc") { io.println("glob-ci-3"); return 14; }
  if glob.glob_match_case_insensitive("ABD", "abc") { io.println("glob-ci-4"); return 15; }

  // ---- segment ----
  var cl = segment.unicode_grapheme_clusters("abc");
  if cl.len() != 3 { io.println("seg-1"); return 17; }
  var c0 = cl[0];
  var c1 = cl[1];
  var c2 = cl[2];
  if c0 != "a" { io.println("seg-2"); return 18; }
  if c1 != "b" { io.println("seg-3"); return 19; }
  if c2 != "c" { io.println("seg-4"); return 20; }

  var cl2 = segment.unicode_grapheme_clusters("");
  if cl2.len() != 0 { io.println("seg-5"); return 21; }

  var offs = segment.unicode_segment_graphemes("abc");
  if offs.len() != 4 { io.println("seg-6"); return 22; }
  if offs[0] != 0 { io.println("seg-7"); return 23; }
  if offs[1] != 1 { io.println("seg-8"); return 24; }
  if offs[2] != 2 { io.println("seg-9"); return 25; }
  if offs[3] != 3 { io.println("seg-10"); return 26; }

  var offs2 = segment.unicode_segment_graphemes("");
  if offs2.len() != 1 || offs2[0] != 0 { io.println("seg-11"); return 27; }

  // ---- unescape ----
  if unescape.str_unescape("a\\nb") != "a\nb" { io.println("uesc-1"); return 28; }
  if unescape.str_unescape("a\\tb") != "a\tb" { io.println("uesc-2"); return 29; }
  if unescape.str_unescape("\\\"") != "\"" { io.println("uesc-3"); return 30; }
  if unescape.str_unescape("\\\\") != "\\" { io.println("uesc-4"); return 31; }
  if unescape.str_unescape("\\r") != "\r" { io.println("uesc-5"); return 32; }
  if unescape.str_unescape("\\q") != "\\q" { io.println("uesc-6"); return 33; }
  if unescape.str_unescape("") != "" { io.println("uesc-7"); return 34; }
  if unescape.str_unescape("plain") != "plain" { io.println("uesc-8"); return 35; }

  if unescape.str_unescape_ascii("a\\nb") != "a\nb" { io.println("uesc-a1"); return 36; }
  if unescape.str_unescape_ascii("\\x41") != "A" { io.println("uesc-a2"); return 37; }
  if unescape.str_unescape_ascii("\\x0a") != "\n" { io.println("uesc-a3"); return 38; }
  if unescape.str_unescape_ascii("\\x4") != "\\x4" { io.println("uesc-a4"); return 39; }
  if unescape.str_unescape_ascii("\\xzz") != "\\xzz" { io.println("uesc-a5"); return 40; }
  if unescape.str_unescape_ascii("\\u0041") != "\\u0041" { io.println("uesc-a6"); return 41; }

  if unescape.str_unescape_unicode("\\u0041") != "A" { io.println("uesc-u1"); return 42; }
  if unescape.str_unescape_unicode("\\u0030") != "0" { io.println("uesc-u2"); return 43; }
  if unescape.str_unescape_unicode("\\U00000041") != "A" { io.println("uesc-u3"); return 44; }
  if unescape.str_unescape_unicode("\\u004") != "\\u004" { io.println("uesc-u4"); return 45; }
  if unescape.str_unescape_unicode("\\U0000004") != "\\U0000004" { io.println("uesc-u5"); return 46; }
  if unescape.str_unescape_unicode("\\x41") != "\\x41" { io.println("uesc-u6"); return 47; }

  io.println("smoke_string_glob: OK");
  return 0;
}

module smoke_string_reverse_replace
use xiom.string.reverse;
use xiom.string.replace;
use xiom.io;

fn main() -> Int {
  // str_reverse_chars is the alias of str_reverse and exercises the exact same
  // implementation; calling the frozen API name `str_reverse` directly is
  // currently blocked by a compiler bug in the flat string.str_reverse (it is
  // emitted whenever a function named str_reverse is called, and its codegen
  // violates LLVM dominance) — see the reverse.xi module header.
  if reverse.str_reverse_chars("abc") != "cba" { io.println("reverse chars"); return 1; }
  if reverse.str_reverse_chars("") != "" { io.println("reverse chars empty"); return 2; }
  if reverse.str_reverse_words("hello world") != "world hello" { io.println("reverse words"); return 3; }

  if replace.str_replace("aaa", "a", "b") != "bbb" { io.println("replace all"); return 4; }
  if replace.str_replace("abc", "x", "y") != "abc" { io.println("replace none"); return 5; }
  if replace.str_replace_all("aaa", "a", "b") != "bbb" { io.println("replace_all"); return 6; }
  if replace.str_replace_n("aaaa", "a", "b", 2) != "bbaa" { io.println("replace_n"); return 7; }
  if replace.str_replace_first("abab", "ab", "X") != "Xab" { io.println("replace_first"); return 8; }
  if replace.str_replace_last("abab", "ab", "X") != "abX" { io.println("replace_last"); return 9; }

  io.println("smoke_string_reverse_replace: OK");
  return 0;
}

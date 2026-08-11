module smoke_string_truncate_indent
use xiom.string.truncate;
use xiom.string.indent;
use xiom.io;

fn main() -> Int {
  // ---- truncate (by characters) ----
  if truncate.str_truncate("hello world", 5) != "hello" { io.println("tr-1"); return 1; }
  if truncate.str_truncate("hi", 5) != "hi" { io.println("tr-2"); return 2; }
  if truncate.str_truncate("hello", 0) != "" { io.println("tr-3"); return 3; }
  if truncate.str_truncate("hello", -1) != "" { io.println("tr-4"); return 4; }

  // ---- truncate_utf8 (by bytes, UTF-8 boundary aware) ----
  if truncate.str_truncate_utf8("héllo", 3) != "hé" { io.println("tr8-1"); return 11; }
  if truncate.str_truncate_utf8("héllo", 2) != "h" { io.println("tr8-2"); return 12; }
  if truncate.str_truncate_utf8("hello", 10) != "hello" { io.println("tr8-3"); return 13; }
  if truncate.str_truncate_utf8("hello", 0) != "" { io.println("tr8-4"); return 14; }

  // ---- truncate_with_ellipsis ----
  if truncate.str_truncate_with_ellipsis("hello world", 5) != "he..." { io.println("twe-1"); return 21; }
  if truncate.str_truncate_with_ellipsis("hi", 5) != "hi" { io.println("twe-2"); return 22; }
  if truncate.str_truncate_with_ellipsis("hello", 2) != "he" { io.println("twe-3"); return 23; }
  if truncate.str_truncate_with_ellipsis("hello world", 4) != "h..." { io.println("twe-4"); return 24; }

  // ---- truncate_middle ----
  if truncate.str_truncate_middle("hello world", 7) != "helorld" { io.println("tm-1"); return 31; }
  if truncate.str_truncate_middle("hello", 10) != "hello" { io.println("tm-2"); return 32; }
  if truncate.str_truncate_middle("hello world", 0) != "" { io.println("tm-3"); return 33; }

  // ---- indent ----
  if indent.str_indent("a\nb", 2) != "  a\n  b" { io.println("ind-1"); return 41; }
  if indent.str_indent("a\nb", 0) != "a\nb" { io.println("ind-2"); return 42; }
  if indent.str_indent("x", 3) != "   x" { io.println("ind-3"); return 43; }

  // ---- indent_with ----
  if indent.str_indent_with("a\nb", 2, ">") != ">>a\n>>b" { io.println("indw-1"); return 51; }
  if indent.str_indent_with("a", 1, "  ") != "  a" { io.println("indw-2"); return 52; }

  // ---- dedent ----
  if indent.str_dedent("  a\n  b") != "a\nb" { io.println("ded-1"); return 61; }
  if indent.str_dedent("    a\n  b\n    c") != "  a\nb\n  c" { io.println("ded-2"); return 62; }
  if indent.str_dedent("a\nb") != "a\nb" { io.println("ded-3"); return 63; }
  if indent.str_dedent("") != "" { io.println("ded-4"); return 64; }

  // ---- unindent ----
  if indent.str_unindent("    a\n        b") != "a\n    b" { io.println("uni-1"); return 71; }
  if indent.str_unindent("\ta") != "a" { io.println("uni-2"); return 72; }
  if indent.str_unindent("plain") != "plain" { io.println("uni-3"); return 73; }

  io.println("smoke_string_truncate_indent: OK");
  return 0;
}

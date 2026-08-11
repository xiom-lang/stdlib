module smoke_string_align_wrap
use xiom.string.align;
use xiom.string.wrap;
use xiom.io;

fn main() -> Int {
  // ---- align_left ----
  if align.str_align_left("x", 5) != "x    " { io.println("al-1"); return 1; }
  if align.str_align_left("hello", 3) != "hello" { io.println("al-2"); return 2; }

  // ---- align_right ----
  if align.str_align_right("x", 5) != "    x" { io.println("ar-1"); return 11; }
  if align.str_align_right("hello", 3) != "hello" { io.println("ar-2"); return 12; }

  // ---- align_center ----
  if align.str_align_center("x", 5) != "  x  " { io.println("ac-1"); return 21; }
  if align.str_align_center("xx", 5) != " xx  " { io.println("ac-2"); return 22; }
  if align.str_align_center("hello", 3) != "hello" { io.println("ac-3"); return 23; }

  // ---- align_justify ----
  if align.str_align_justify("a b c", 9) != "a   b   c" { io.println("aj-1"); return 31; }
  if align.str_align_justify("a b", 5) != "a   b" { io.println("aj-2"); return 32; }
  if align.str_align_justify("hello world", 5) != "hello world" { io.println("aj-3"); return 33; }
  if align.str_align_justify("single", 10) != "single    " { io.println("aj-4"); return 34; }

  // ---- wrap (soft, hard-splits overlong words) ----
  var w = wrap.str_wrap("aaa bbb ccc", 5);
  if w.len() != 3 { io.println("wr-1"); return 41; }
  var w0 = w[0];
  var w1 = w[1];
  var w2 = w[2];
  if w0 != "aaa" { io.println("wr-2"); return 42; }
  if w1 != "bbb" { io.println("wr-3"); return 43; }
  if w2 != "ccc" { io.println("wr-4"); return 44; }
  var wl = wrap.str_wrap("aaa bbb ccc", 20);
  if wl.len() != 1 { io.println("wr-5"); return 45; }
  var l0 = wl[0];
  if l0 != "aaa bbb ccc" { io.println("wr-6"); return 46; }
  var wl2 = wrap.str_wrap("aaaaaa b", 4);
  if wl2.len() != 2 { io.println("wr-7"); return 47; }
  var n0 = wl2[0];
  var n1 = wl2[1];
  if n0 != "aaaa" { io.println("wr-8"); return 48; }
  if n1 != "aa b" { io.println("wr-9"); return 49; }

  // ---- wrap_hard ----
  var wh = wrap.str_wrap_hard("abcdef", 2);
  if wh.len() != 3 { io.println("wh-1"); return 55; }
  var h0 = wh[0];
  var h1 = wh[1];
  var h2 = wh[2];
  if h0 != "ab" { io.println("wh-2"); return 56; }
  if h1 != "cd" { io.println("wh-3"); return 57; }
  if h2 != "ef" { io.println("wh-4"); return 58; }
  var wh2 = wrap.str_wrap_hard("abcde", 2);
  if wh2.len() != 3 { io.println("wh-5"); return 59; }
  var hh0 = wh2[0];
  var hh1 = wh2[1];
  var hh2 = wh2[2];
  if hh0 != "ab" { io.println("wh-6"); return 60; }
  if hh1 != "cd" { io.println("wh-7"); return 61; }
  if hh2 != "e" { io.println("wh-8"); return 62; }

  // ---- wrap_soft (never splits a word) ----
  var ws = wrap.str_wrap_soft("aaa bbb ccc", 5);
  if ws.len() != 3 { io.println("wso-1"); return 66; }
  var s0 = ws[0];
  var s1 = ws[1];
  var s2 = ws[2];
  if s0 != "aaa" { io.println("wso-2"); return 67; }
  if s1 != "bbb" { io.println("wso-3"); return 68; }
  if s2 != "ccc" { io.println("wso-4"); return 69; }
  var ws2 = wrap.str_wrap_soft("aaaaaa b", 4);
  if ws2.len() != 2 { io.println("wso-5"); return 70; }
  var ss0 = ws2[0];
  var ss1 = ws2[1];
  if ss0 != "aaaaaa" { io.println("wso-6"); return 71; }
  if ss1 != "b" { io.println("wso-7"); return 72; }

  // ---- wrap_join ----
  if wrap.str_wrap_join("aaa bbb ccc", 5, "\n") != "aaa\nbbb\nccc" { io.println("wj-1"); return 76; }
  if wrap.str_wrap_join("a b", 10, "|") != "a b" { io.println("wj-2"); return 77; }

  io.println("smoke_string_align_wrap: OK");
  return 0;
}

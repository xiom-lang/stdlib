module smoke_string_compare_search
use xiom.string.compare;
use xiom.string.search;
use xiom.io;

fn main() -> Int {
  // ---- compare ----
  if compare.str_compare("a", "b") >= 0 { io.println("cmp-1"); return 1; }
  if compare.str_compare("b", "a") <= 0 { io.println("cmp-2"); return 2; }
  if compare.str_compare("abc", "abc") != 0 { io.println("cmp-3"); return 3; }
  if compare.str_compare("abc", "abd") >= 0 { io.println("cmp-4"); return 4; }
  if compare.str_compare("abc", "ab") <= 0 { io.println("cmp-5"); return 5; }
  if compare.str_compare("", "a") >= 0 { io.println("cmp-6"); return 6; }
  if compare.str_compare("z", "") <= 0 { io.println("cmp-7"); return 7; }

  // ---- compare_ignore_case ----
  if compare.str_compare_ignore_case("ABC", "abc") != 0 { io.println("cic-1"); return 11; }
  if compare.str_compare_ignore_case("Abc", "aBd") >= 0 { io.println("cic-2"); return 12; }
  if compare.str_compare_ignore_case("Abc", "AB") <= 0 { io.println("cic-3"); return 13; }

  // ---- eq_ignore_case ----
  if !compare.str_eq_ignore_case("Hello", "HELLO") { io.println("eic-1"); return 21; }
  if compare.str_eq_ignore_case("Hello", "Hella") { io.println("eic-2"); return 22; }
  if !compare.str_eq_ignore_case("", "") { io.println("eic-3"); return 23; }

  // ---- compare_natural ----
  if compare.str_compare_natural("x2", "x10") >= 0 { io.println("nat-1"); return 31; }
  if compare.str_compare_natural("x10", "x9") <= 0 { io.println("nat-2"); return 32; }
  if compare.str_compare_natural("file2.txt", "file10.txt") >= 0 { io.println("nat-3"); return 33; }
  if compare.str_compare_natural("abc", "abc") != 0 { io.println("nat-4"); return 34; }
  if compare.str_compare_natural("a", "b") >= 0 { io.println("nat-5"); return 35; }
  if compare.str_compare_natural("img1", "img01") >= 0 { io.println("nat-6"); return 36; }

  // ---- search: index_of / last_index_of ----
  var i1 = search.str_index_of("hello world", "world");
  match i1 {
    Some(v) => { if v != 6 { io.println("soi-1"); return 41; } };
    None => { io.println("soi-2"); return 42; };
  };
  var i2 = search.str_index_of("hello", "x");
  match i2 {
    Some(_) => { io.println("soi-3"); return 43; };
    None => {};
  };
  var i3 = search.str_last_index_of("abab", "ab");
  match i3 {
    Some(v) => { if v != 2 { io.println("soi-4"); return 44; } };
    None => { io.println("soi-5"); return 45; };
  };
  var i4 = search.str_last_index_of("abab", "z");
  match i4 {
    Some(_) => { io.println("soi-6"); return 46; };
    None => {};
  };

  // ---- search: contains / contains_any ----
  if !search.str_contains("hello", "ell") { io.println("con-1"); return 51; }
  if search.str_contains("hello", "z") { io.println("con-2"); return 52; }
  var needles1 = Vec[Str].new();
  needles1.push("xyz");
  needles1.push("wor");
  if !search.str_contains_any("hello world", &needles1) { io.println("cany-1"); return 53; }
  var needles2 = Vec[Str].new();
  needles2.push("xyz");
  needles2.push("qqq");
  if search.str_contains_any("hello world", &needles2) { io.println("cany-2"); return 54; }

  // ---- search: count_occurrences ----
  if search.str_count_occurrences("aaaa", "aa") != 2 { io.println("cnt-1"); return 61; }
  if search.str_count_occurrences("hello hello", "hello") != 2 { io.println("cnt-2"); return 62; }
  if search.str_count_occurrences("abc", "z") != 0 { io.println("cnt-3"); return 63; }
  if search.str_count_occurrences("abc", "") != 0 { io.println("cnt-4"); return 64; }

  // ---- search: find_any ----
  var fa = search.str_find_any("hello world", &needles1);
  match fa {
    Some(v) => { if v != 6 { io.println("fany-1"); return 71; } };
    None => { io.println("fany-2"); return 72; };
  };
  var fb = search.str_find_any("hello world", &needles2);
  match fb {
    Some(_) => { io.println("fany-3"); return 73; };
    None => {};
  };

  io.println("smoke_string_compare_search: OK");
  return 0;
}

// smoke_string_glob_parity.xi -- locks the string.glob -> misc.glob
// delegation (dedup 2026-09-10): both paths must agree on every vector.
module smoke_string_glob_parity
use xiom.io;

fn chk(pattern: Str, s: Str, want: Bool) -> Int {
  var m = xiom.misc.glob.glob_match(pattern, s);
  var g = xiom.string.glob.glob_match(pattern, s);
  if m != want { io.println("misc-mismatch"); return 1; }
  if g != want { io.println("string-mismatch"); return 1; }
  if m != g { io.println("paths-diverge"); return 1; }
  return 0;
}

fn main() -> Int {
  var r = chk("*.xi", "a.xi", true);
  if r != 0 { return 10; }
  r = chk("*.xi", "a.txt", false);
  if r != 0 { return 11; }
  r = chk("a?c", "abc", true);
  if r != 0 { return 12; }
  r = chk("a?c", "ac", false);
  if r != 0 { return 13; }
  r = chk("a?c", "abbc", false);
  if r != 0 { return 14; }
  r = chk("*", "anything", true);
  if r != 0 { return 15; }
  r = chk("*", "", true);
  if r != 0 { return 16; }
  r = chk("", "", true);
  if r != 0 { return 17; }
  r = chk("", "x", false);
  if r != 0 { return 18; }
  r = chk("a*b*c", "aXXbYYc", true);
  if r != 0 { return 19; }
  r = chk("a*b*c", "aXXbYY", false);
  if r != 0 { return 20; }
  r = chk("[ab]c", "ac", false);
  if r != 0 { return 21; }
  r = chk("a[bc]d", "abd", false);
  if r != 0 { return 22; }
  r = chk("*.XI", "a.xi", false);
  if r != 0 { return 23; }

  var ci_m = xiom.misc.glob.glob_match_case_insensitive("*.XI", "a.xi");
  var ci_s = xiom.string.glob.glob_match_case_insensitive("*.XI", "a.xi");
  if !ci_m { io.println("ci-misc"); return 24; }
  if !ci_s { io.println("ci-string"); return 25; }

  io.println("OK");
  return 0;
}

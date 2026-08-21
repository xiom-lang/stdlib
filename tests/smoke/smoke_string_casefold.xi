module smoke_string_casefold

use xiom.string.casefold;
use xiom.io;

fn main() -> Int {
  let c1 = casefold.str_casefold("Strasse");
  if c1 != "strasse" { io.println("CF1 c1=" + c1); return 1; }
  let c2 = casefold.str_casefold("AOU");
  if c2 != "aou" { io.println("CF2 c2=" + c2); return 2; }
  let c3 = casefold.str_casefold("ABC");
  if c3 != "abc" { io.println("CF3"); return 3; }
  let c4 = casefold.str_casefold("Grusse");
  if c4 != "grusse" { io.println("CF4 c4=" + c4); return 4; }
  let c5 = casefold.str_casefold_ascii("HeLLo");
  if c5 != "hello" { io.println("CF5"); return 5; }
  let c6 = casefold.str_casefold_ascii("123");
  if c6 != "123" { io.println("CF6"); return 6; }
  let c7 = casefold.str_casefold("ETE");
  if c7 != "ete" { io.println("CF7 c7=" + c7); return 7; }
  let c8 = casefold.str_casefold("");
  if c8 != "" { io.println("CF8"); return 8; }
  io.println("OK");
  return 0;
}

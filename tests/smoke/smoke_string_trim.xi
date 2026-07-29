module smoke_string_trim
use xiom.string;

fn main() -> Int {
  if string.str_trim("hello") != "hello" { return 1; }
  if string.str_trim("  hello  ") != "hello" { return 2; }
  if string.str_trim("  hello") != "hello" { return 3; }
  if string.str_trim("hello  ") != "hello" { return 4; }
  if string.str_trim("") != "" { return 5; }
  if string.str_trim("   ") != "" { return 6; }
  if string.str_trim("\t\n") != "" { return 7; }
  if string.str_trim("  a  b  ") != "a  b" { return 8; }

  return 0;
}

module smoke_string_slice
use xiom.string;

fn main() -> Int {
  if string.str_slice("hello", 0, 0) != "" { return 1; }
  if string.str_slice("hello", 0, 1) != "h" { return 2; }
  if string.str_slice("hello", 0, 5) != "hello" { return 3; }
  if string.str_slice("hello", 1, 4) != "ell" { return 4; }
  if string.str_slice("hello", 0, 100) != "hello" { return 5; }
  if string.str_slice("hello", 5, 5) != "" { return 6; }
  if string.str_slice("hello", 2, 2) != "" { return 7; }

  if string.str_slice("", 0, 0) != "" { return 8; }

  if string.str_slice("abc", 1, 3) != "bc" { return 9; }

  return 0;
}

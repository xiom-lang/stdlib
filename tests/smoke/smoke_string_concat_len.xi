module smoke_string_concat_len
use xiom.string;

fn main() -> Int {
  if string.str_len("") != 0 { return 1; }
  if string.str_len("hello") != 5 { return 2; }
  if string.str_len("a") != 1 { return 3; }

  if string.str_concat("", "") != "" { return 4; }
  if string.str_concat("a", "") != "a" { return 5; }
  if string.str_concat("", "b") != "b" { return 6; }
  if string.str_concat("ab", "cd") != "abcd" { return 7; }
  if string.str_concat("hello ", "world") != "hello world" { return 8; }

  var long = "";
  var i: Int = 0;
  while i < 100 {
    long = string.str_concat(long, "x");
    i = i + 1;
  }
  if string.str_len(long) != 100 { return 9; }

  return 0;
}

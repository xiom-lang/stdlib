module smoke_string_case
use xiom.string;

fn main() -> Int {
  if string.str_upper("hello") != "HELLO" { return 1; }
  if string.str_upper("HELLO") != "HELLO" { return 2; }
  if string.str_upper("Hello World") != "HELLO WORLD" { return 3; }
  if string.str_upper("") != "" { return 4; }
  if string.str_upper("a") != "A" { return 5; }

  if string.str_lower("HELLO") != "hello" { return 6; }
  if string.str_lower("hello") != "hello" { return 7; }
  if string.str_lower("Hello World") != "hello world" { return 8; }
  if string.str_lower("") != "" { return 9; }
  if string.str_lower("A") != "a" { return 10; }

  if string.str_upper(string.str_lower("MiXeD CaSe")) != "MIXED CASE" { return 11; }

  return 0;
}

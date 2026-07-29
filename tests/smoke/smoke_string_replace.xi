module smoke_string_replace
use xiom.string;

fn main() -> Int {
  if string.replace("hello world", "world", "xiom") != "hello xiom" { return 1; }
  if string.replace("aaa", "a", "b") != "bbb" { return 2; }
  if string.replace("hello", "x", "y") != "hello" { return 3; }
  if string.replace("abcabc", "abc", "x") != "xx" { return 4; }
  if string.replace("", "a", "b") != "" { return 5; }
  if string.replace("hello", "hello", "bye") != "bye" { return 6; }

  return 0;
}

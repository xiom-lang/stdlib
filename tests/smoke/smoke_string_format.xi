module smoke_string_format
use xiom.string;

fn main() -> Int {
  if string.format1("hello {}", "world") != "hello world" { return 1; }
  if string.format1("{} and {}", "one") != "one and {}" { return 2; }
  if string.format1("no placeholder", "x") != "no placeholder" { return 3; }
  if string.format1("{}", "test") != "test" { return 4; }
  if string.format1("start-{}-end", "mid") != "start-mid-end" { return 5; }

  if string.format2("{} {}", "hello", "world") != "hello world" { return 6; }
  if string.format2("{}, {}", "a", "b") != "a, b" { return 7; }

  return 0;
}

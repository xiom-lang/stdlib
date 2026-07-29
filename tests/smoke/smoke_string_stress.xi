module smoke_string_stress
use xiom.string;

fn main() -> Int {
  var s = "x";
  var i: Int = 0;
  while i < 8 {
    s = string.str_concat(s, s);
    i = i + 1;
  }
  if string.str_len(s) != 256 { return 1; }

  if string.str_starts_with(s, "x") { return 0; }
  return 2;
}

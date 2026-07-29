module smoke_string_empty
use xiom.string;

fn main() -> Int {
  if !string.is_empty("") { return 1; }
  if string.is_empty("a") { return 2; }
  if string.is_empty(" ") { return 3; }

  if string.str_len("") != 0 { return 4; }
  if string.byte_count("") != 0 { return 5; }

  if string.str_upper("") != "" { return 6; }
  if string.str_lower("") != "" { return 7; }
  if string.str_trim("") != "" { return 8; }
  if string.replace("", "x", "y") != "" { return 9; }

  return 0;
}

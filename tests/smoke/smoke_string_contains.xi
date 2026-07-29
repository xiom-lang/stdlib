module smoke_string_contains
use xiom.string;

fn main() -> Int {
  if !string.str_contains("hello", "ell") { return 1; }
  if !string.str_contains("hello", "h") { return 2; }
  if !string.str_contains("hello", "o") { return 3; }
  if !string.str_contains("hello", "hello") { return 4; }
  if string.str_contains("hello", "world") { return 5; }
  if string.str_contains("", "a") { return 6; }

  if !string.str_starts_with("hello", "he") { return 7; }
  if !string.str_starts_with("hello", "hello") { return 8; }
  if string.str_starts_with("hello", "ello") { return 9; }
  if string.str_starts_with("ab", "abc") { return 10; }
  if !string.str_starts_with("", "") { return 11; }

  if !string.str_ends_with("hello", "lo") { return 12; }
  if !string.str_ends_with("hello", "hello") { return 13; }
  if string.str_ends_with("hello", "hel") { return 14; }
  if string.str_ends_with("ab", "abc") { return 15; }

  return 0;
}

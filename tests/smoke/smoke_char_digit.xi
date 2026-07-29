module smoke_char_digit
use xiom.char;

fn main() -> Int {
  if !char.is_digit('0') { return 1; }
  if !char.is_digit('5') { return 2; }
  if !char.is_digit('9') { return 3; }
  if char.is_digit('A') { return 4; }
  if char.is_digit(' ') { return 5; }

  if !char.is_numeric('0') { return 6; }
  if !char.is_numeric('9') { return 7; }
  if char.is_numeric('x') { return 8; }

  if !char.is_lowercase('a') { return 9; }
  if !char.is_lowercase('z') { return 10; }
  if char.is_lowercase('A') { return 11; }
  if char.is_lowercase('9') { return 12; }

  if !char.is_uppercase('A') { return 13; }
  if !char.is_uppercase('Z') { return 14; }
  if char.is_uppercase('a') { return 15; }

  return 0;
}

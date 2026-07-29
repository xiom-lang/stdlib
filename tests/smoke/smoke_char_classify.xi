module smoke_char_classify
use xiom.char;

fn main() -> Int {
  if !char.is_alphabetic('A') { return 1; }
  if !char.is_alphabetic('z') { return 2; }
  if !char.is_alphabetic('M') { return 3; }
  if char.is_alphabetic('5') { return 4; }
  if char.is_alphabetic('!') { return 5; }

  if !char.is_alphanumeric('A') { return 6; }
  if !char.is_alphanumeric('9') { return 7; }
  if char.is_alphanumeric('!') { return 8; }

  if !char.is_ascii('A') { return 9; }
  if !char.is_ascii('~') { return 10; }

  if !char.is_control('\n') { return 11; }
  if char.is_control('A') { return 12; }
  if !char.is_control('\t') { return 13; }

  return 0;
}

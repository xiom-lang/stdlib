module smoke_char_punct_space
use xiom.char;

fn main() -> Int {
  if !char.is_punctuation('!') { return 1; }
  if !char.is_punctuation('.') { return 2; }
  if !char.is_punctuation('?') { return 3; }
  if !char.is_punctuation('[') { return 4; }
  if !char.is_punctuation('{') { return 5; }
  if char.is_punctuation('A') { return 6; }
  if char.is_punctuation('0') { return 7; }

  if !char.is_whitespace(' ') { return 8; }
  if !char.is_whitespace('\t') { return 9; }
  if !char.is_whitespace('\n') { return 10; }
  if !char.is_whitespace('\r') { return 11; }
  if char.is_whitespace('A') { return 12; }
  if char.is_whitespace('!') { return 13; }

  return 0;
}

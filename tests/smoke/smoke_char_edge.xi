module smoke_char_edge
use xiom.char;

fn main() -> Int {
  if !char.is_ascii(to_char(0)) { return 1; }
  if !char.is_ascii(to_char(127)) { return 2; }
  if char.is_ascii(to_char(128)) { return 3; }
  if char.is_ascii(to_char(255)) { return 4; }

  if !char.is_control(to_char(0)) { return 5; }
  if !char.is_control(to_char(31)) { return 6; }
  if !char.is_control(to_char(127)) { return 7; }
  if char.is_control(to_char(32)) { return 8; }

  if char.to_lowercase(to_char(0)) != to_char(0) { return 9; }
  if char.to_uppercase(to_char(0)) != to_char(0) { return 10; }
  if char.to_lowercase(to_char(255)) != to_char(255) { return 11; }

  match char.to_digit(to_char(0), 20) {
    Some(_) => { return 12; },
    None => {},
  };

  return 0;
}

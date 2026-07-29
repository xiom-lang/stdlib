module smoke_char_from_digit
use xiom.char;

fn main() -> Int {
  match char.from_digit(0, 10) {
    Some(c) => { if c != '0' { return 1; } },
    None => { return 2; },
  };
  match char.from_digit(9, 10) {
    Some(c) => { if c != '9' { return 3; } },
    None => { return 4; },
  };
  match char.from_digit(10, 16) {
    Some(c) => { if c != 'A' { return 5; } },
    None => { return 6; },
  };
  match char.from_digit(15, 16) {
    Some(c) => { if c != 'F' { return 7; } },
    None => { return 8; },
  };
  match char.from_digit(35, 36) {
    Some(c) => { if c != 'Z' { return 9; } },
    None => { return 10; },
  };
  match char.from_digit(10, 10) {
    Some(_) => { return 11; },
    None => {},
  };
  match char.from_digit(-1, 10) {
    Some(_) => { return 12; },
    None => {},
  };
  match char.from_digit(0, 1) {
    Some(_) => { return 13; },
    None => {},
  };
  match char.from_digit(0, 37) {
    Some(_) => { return 14; },
    None => {},
  };

  return 0;
}

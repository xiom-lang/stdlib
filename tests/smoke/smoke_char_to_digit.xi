module smoke_char_to_digit
use xiom.char;

fn main() -> Int {
  match char.to_digit('0', 10) {
    Some(d) => { if d != 0 { return 1; } },
    None => { return 2; },
  };
  match char.to_digit('9', 10) {
    Some(d) => { if d != 9 { return 3; } },
    None => { return 4; },
  };
  match char.to_digit('A', 16) {
    Some(d) => { if d != 10 { return 5; } },
    None => { return 6; },
  };
  match char.to_digit('F', 16) {
    Some(d) => { if d != 15 { return 7; } },
    None => { return 8; },
  };
  match char.to_digit('a', 16) {
    Some(d) => { if d != 10 { return 9; } },
    None => { return 10; },
  };
  match char.to_digit('f', 16) {
    Some(d) => { if d != 15 { return 11; } },
    None => { return 12; },
  };
  match char.to_digit('Z', 36) {
    Some(d) => { if d != 35 { return 13; } },
    None => { return 14; },
  };
  match char.to_digit('9', 8) {
    Some(_) => { return 15; },
    None => {},
  };
  match char.to_digit('!', 10) {
    Some(_) => { return 16; },
    None => {},
  };
  match char.to_digit('0', 1) {
    Some(_) => { return 17; },
    None => {},
  };
  match char.to_digit('0', 37) {
    Some(_) => { return 18; },
    None => {},
  };

  return 0;
}

module smoke_convert_char_int
use xiom.convert;

fn main() -> Int {
  if convert.char_to_int('A') != 65 { return 1; }
  if convert.char_to_int('0') != 48 { return 2; }

  match convert.int_to_char(65) {
    Some(c) => { if c != 'A' { return 3; } },
    None => { return 4; },
  };
  match convert.int_to_char(-1) {
    Some(_) => { return 5; },
    None => {},
  };
  match convert.int_to_char(1114112) {
    Some(_) => { return 6; },
    None => {},
  };

  return 0;
}

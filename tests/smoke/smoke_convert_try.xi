module smoke_convert_try
use xiom.convert;
use xiom.core;

fn main() -> Int {
  match convert.int_to_char(48) {
    Some(c) => { if c != '0' { return 1; } },
    None => { return 2; },
  };
  match convert.int_to_char(57) {
    Some(c) => { if c != '9' { return 3; } },
    None => { return 4; },
  };
  match convert.int_to_char(97) {
    Some(c) => { if c != 'a' { return 5; } },
    None => { return 6; },
  };

  return 0;
}

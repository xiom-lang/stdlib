module smoke_string_byte_char
use xiom.string;

fn main() -> Int {
  if string.byte_at("hello", 0) != 104 as UInt8 { return 1; }
  if string.byte_at("hello", 4) != 111 as UInt8 { return 2; }

  match string.char_at("hello", 0) {
    Some(c) => { if c != 'h' { return 3; } },
    None => { return 4; },
  };
  match string.char_at("hello", 5) {
    Some(_) => { return 5; },
    None => {},
  };
  match string.char_at("hello", -1) {
    Some(_) => { return 6; },
    None => {},
  };

  if string.byte_count("hello") != 5 { return 7; }
  if string.byte_count("") != 0 { return 8; }

  return 0;
}

module smoke_convert_roundtrip
use xiom.convert;

fn main() -> Int {
  var s = convert.int_to_string(42);
  if s != "42" { return 1; }

  var i = convert.float_to_int(42.0);
  if i != 42 { return 2; }

  var f = convert.int_to_float(42);
  var i2 = convert.float_to_int(f);
  if i2 != 42 { return 3; }

  var c = 'X';
  var n = convert.char_to_int(c);
  match convert.int_to_char(n) {
    Some(c2) => { if c2 != c { return 4; } },
    None => { return 5; },
  };

  return 0;
}

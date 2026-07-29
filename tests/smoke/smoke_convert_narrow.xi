module smoke_convert_narrow
use xiom.convert;

fn main() -> Int {
  var i8 = convert.float_to_int(127.0);
  var n8 = i8 as Int8;
  if n8 != 127 as Int8 { return 1; }

  var i16 = convert.float_to_int(32767.0);
  var n16 = i16 as Int16;
  if n16 != 32767 as Int16 { return 2; }

  var s = convert.int_to_string(255);
  match convert.char_to_int('A') {
    65 => {},
    _ => { return 3; },
  };

  return 0;
}

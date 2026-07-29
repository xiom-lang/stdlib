module smoke_convert_narrow_roundtrip
use xiom.convert;
use xiom.core;

fn main() -> Int {
  var s = convert.int_to_string(127);
  match core.to_int_from_str(s) {
    Ok(n) => { var n8 = n as Int8; if n8 != 127 as Int8 { return 1; } },
    Err(_) => { return 2; },
  };

  var s2 = convert.int_to_string(-128);
  match core.to_int_from_str(s2) {
    Ok(n) => { var n8 = n as Int8; if n8 != -128 as Int8 { return 3; } },
    Err(_) => { return 4; },
  };

  var s3 = convert.int_to_string(32767);
  match core.to_int_from_str(s3) {
    Ok(n) => { var n16 = n as Int16; if n16 != 32767 as Int16 { return 5; } },
    Err(_) => { return 6; },
  };

  return 0;
}

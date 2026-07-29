module smoke_string_narrow
use xiom.string;
use xiom.core;

fn main() -> Int {
  var s16: Str = "test";
  if string.str_len(s16) != 4 { return 1; }

  match string.str_to_int("127") {
    Ok(n) => { var n8 = n as Int8; if n8 != 127 as Int8 { return 2; } },
    Err(_) => { return 3; },
  };

  match string.str_to_int("-128") {
    Ok(n) => { var n8 = n as Int8; if n8 != -128 as Int8 { return 4; } },
    Err(_) => { return 5; },
  };

  match string.str_to_int("32767") {
    Ok(n) => { var n16 = n as Int16; if n16 != 32767 as Int16 { return 6; } },
    Err(_) => { return 7; },
  };

  var upper = string.str_upper("narrow");
  if string.str_len(upper) != 6 { return 8; }

  var lower = string.str_lower("NARROW");
  if string.str_len(lower) != 6 { return 9; }

  return 0;
}

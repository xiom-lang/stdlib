module smoke_core_convert
use xiom.core;

fn main() -> Int {
  if core.to_int(3.14) != 3 { return 1; }
  if core.to_int(0.0) != 0 { return 2; }
  if core.to_int(-1.5) != -1 { return 3; }

  var f = core.to_float(42);
  if f < 41.9 || f > 42.1 { return 4; }
  if core.to_float(0) != 0.0 { return 5; }

  if core.to_string(0) != "0" { return 6; }
  if core.to_string(42) != "42" { return 7; }
  if core.to_string(-10) != "-10" { return 8; }

  match core.to_int_from_str("42") {
    Ok(n) => { if n != 42 { return 9; } },
    Err(_) => { return 10; },
  };

  match core.to_float_from_str("3.14") {
    Ok(f2) => { if f2 < 3.13 || f2 > 3.15 { return 11; } },
    Err(_) => { return 12; },
  };

  match core.to_bool_from_str("true") {
    Ok(b) => { if !b { return 13; } },
    Err(_) => { return 14; },
  };
  match core.to_bool_from_str("false") {
    Ok(b) => { if b { return 15; } },
    Err(_) => { return 16; },
  };

  return 0;
}

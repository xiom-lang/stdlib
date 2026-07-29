module smoke_core_numeric
use xiom.core;

fn main() -> Int {
  if core.to_int(42.9) != 42 { return 1; }
  if core.to_int(-42.9) != -42 { return 2; }
  if core.to_int(0.0) != 0 { return 3; }

  if core.to_float(0) != 0.0 { return 4; }
  if core.to_float(100) != 100.0 { return 5; }
  if core.to_float(-100) != -100.0 { return 6; }

  if core.to_char(65) != 'A' { return 7; }
  if core.to_int_from_char('A') != 65 { return 8; }

  return 0;
}

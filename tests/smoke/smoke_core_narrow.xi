module smoke_core_narrow
use xiom.core;

fn main() -> Int {
  if core.to_int(127.0) != 127 { return 1; }

  var n8: Int8 = core.to_int(42.0) as Int8;
  if n8 != 42 as Int8 { return 2; }

  var n16: Int16 = core.to_int(32767.0) as Int16;
  if n16 != 32767 as Int16 { return 3; }

  var n32: Int32 = core.to_int(2000000.0) as Int32;
  if n32 != 2000000 as Int32 { return 4; }

  if core.to_int_from_char('Z') == 90 { return 0; }
  return 5;
}

module smoke_math_narrow
use xiom.math;

fn main() -> Int {
  var a8: Int8 = math.abs_int(-100) as Int8;
  if a8 != 100 as Int8 { return 1; }

  var min8: Int8 = math.min_int(10, 20) as Int8;
  if min8 != 10 as Int8 { return 2; }

  var max8: Int8 = math.max_int(10, 20) as Int8;
  if max8 != 20 as Int8 { return 3; }

  var a16: Int16 = math.abs_int(-30000) as Int16;
  if a16 != 30000 as Int16 { return 4; }

  var a32: Int32 = math.abs_int(-100000) as Int32;
  if a32 != 100000 as Int32 { return 5; }

  return 0;
}

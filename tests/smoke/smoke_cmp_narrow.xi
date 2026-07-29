module smoke_cmp_narrow
use xiom.cmp;

fn main() -> Int {
  var min8 = cmp.min_int(10 as Int8, 20 as Int8) as Int8;
  if min8 != 10 as Int8 { return 1; }

  var max16 = cmp.max_int(1000 as Int16, 2000 as Int16) as Int16;
  if max16 != 2000 as Int16 { return 2; }

  var clamp32 = cmp.clamp_int(15, 10, 20) as Int32;
  if clamp32 != 15 as Int32 { return 3; }

  return 0;
}

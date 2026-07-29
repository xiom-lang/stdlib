module smoke_cmp_float
use xiom.cmp;

fn main() -> Int {
  if cmp.max_float(1.5, 2.5) != 2.5 { return 1; }
  if cmp.max_float(2.5, 1.5) != 2.5 { return 2; }

  if cmp.min_float(1.5, 2.5) != 1.5 { return 3; }
  if cmp.min_float(2.5, 1.5) != 1.5 { return 4; }

  if cmp.clamp_float(5.5, 0.0, 10.0) != 5.5 { return 5; }
  if cmp.clamp_float(-1.0, 0.0, 10.0) != 0.0 { return 6; }
  if cmp.clamp_float(15.0, 0.0, 10.0) != 10.0 { return 7; }

  return 0;
}

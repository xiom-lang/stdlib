module smoke_cmp_compound
use xiom.cmp;

fn main() -> Int {
  var a = cmp.min(10, 20);
  var b = cmp.max(a, 5);
  var c = cmp.clamp(b, 0, 15);
  if c != 10 { return 1; }

  var x = cmp.clamp_float(25.0, 0.0, 10.0);
  var y = cmp.max_float(x, 5.0);
  if y != 10.0 { return 2; }

  return 0;
}

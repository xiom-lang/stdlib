module smoke_rand_float
use xiom.rand;

fn main() -> Int {
  var rf = rand.random_float(0.0, 10.0);
  if rf < 0.0 || rf >= 10.0 { return 1; }

  var rf2 = rand.random_float(1.0, 1.0);
  if rf2 != 1.0 { return 2; }

  return 0;
}

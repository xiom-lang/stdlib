module smoke_rand_random
use xiom.rand;

fn main() -> Int {
  var r = rand.random();
  if r < 0.0 || r >= 1.0 { return 1; }

  var r2 = rand.random();
  if r2 < 0.0 || r2 >= 1.0 { return 2; }

  return 0;
}

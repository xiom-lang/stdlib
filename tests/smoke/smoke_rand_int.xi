module smoke_rand_int
use xiom.rand;

fn main() -> Int {
  var ri = rand.random_int(0, 10);
  if ri < 0 || ri > 10 { return 1; }

  var ri2 = rand.random_int(5, 5);
  if ri2 != 5 { return 2; }

  var ri3 = rand.random_int(-10, 10);
  if ri3 < -10 || ri3 > 10 { return 3; }

  return 0;
}

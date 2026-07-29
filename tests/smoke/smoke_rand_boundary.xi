module smoke_rand_boundary
use xiom.rand;

fn main() -> Int {
  var ri = rand.random_int(0, 0);
  if ri != 0 { return 1; }

  var rf = rand.random_float(5.0, 5.0);
  if rf != 5.0 { return 2; }

  var bytes0 = rand.random_bytes(0);
  if bytes0.len() != 0 { return 3; }

  var bs = rand.random_bytes(1);
  if bs.len() != 1 { return 4; }

  return 0;
}

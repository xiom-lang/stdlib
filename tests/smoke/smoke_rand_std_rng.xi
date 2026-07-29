module smoke_rand_std_rng
use xiom.rand;

fn main() -> Int {
  var rng = rand.StdRng.new();
  var n = rng.next_int();
  if n <= 0 { return 0; }

  var f = rng.next_float();
  if f < 0.0 || f >= 1.0 { return 1; }

  return 0;
}

module smoke_math_random
use xiom.math;

fn main() -> Int {
  math.seed_rng(42);

  var r = math.random();
  if r < 0.0 || r >= 1.0 { return 1; }

  math.seed_rng(42);
  var r2 = math.random();
  if r != r2 { return 2; }

  math.seed_rng(100);
  var ri = math.random_range(0, 10);
  if ri < 0 || ri > 10 { return 3; }

  var ri2 = math.random_range(5, 5);
  if ri2 != 5 { return 4; }

  return 0;
}

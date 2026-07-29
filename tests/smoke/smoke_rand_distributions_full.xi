module smoke_rand_distributions_full
use xiom.rand;

fn main() -> Int {
  var g = rand.sample_gamma(2.0, 1.0);
  if g < 0.0 { return 1; }

  var b = rand.sample_beta(2.0, 5.0);
  if b < 0.0 || b > 1.0 { return 2; }

  var n = rand.sample_normal(5.0, 2.0);

  var e = rand.sample_exponential(0.5);
  if e < 0.0 { return 3; }

  return 0;
}

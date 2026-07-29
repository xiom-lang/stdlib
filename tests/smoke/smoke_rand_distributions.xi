module smoke_rand_distributions
use xiom.rand;

fn main() -> Int {
  var u = rand.sample_uniform(0.0, 10.0);
  if u < 0.0 || u >= 10.0 { return 1; }

  var n = rand.sample_normal(0.0, 1.0);

  var e = rand.sample_exponential(1.0);
  if e < 0.0 { return 2; }

  var b = rand.sample_bernoulli(0.5);

  var bi = rand.sample_binomial(10, 0.5);
  if bi < 0 || bi > 10 { return 3; }

  var p = rand.sample_poisson(3.0);
  if p < 0 { return 4; }

  return 0;
}

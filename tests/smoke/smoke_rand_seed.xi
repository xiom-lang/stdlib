module smoke_rand_seed
use xiom.rand;

fn main() -> Int {
  rand.seed_from_value(42);
  var r1 = rand.random();

  rand.seed_from_value(42);
  var r2 = rand.random();

  if r1 != r2 { return 1; }

  rand.seed_from_value(0);
  var r3 = rand.random();

  rand.seed_from_value(0);
  var r4 = rand.random();

  if r3 != r4 { return 2; }

  return 0;
}

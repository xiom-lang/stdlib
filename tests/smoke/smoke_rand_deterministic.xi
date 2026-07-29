module smoke_rand_deterministic
use xiom.rand;

fn main() -> Int {
  rand.seed_from_value(12345);
  var values: Int = 0;
  var i: Int = 0;
  while i < 50 {
    values = values + rand.random_int(0, 100);
    i = i + 1;
  }

  rand.seed_from_value(12345);
  var values2: Int = 0;
  var j: Int = 0;
  while j < 50 {
    values2 = values2 + rand.random_int(0, 100);
    j = j + 1;
  }

  if values != values2 { return 1; }

  return 0;
}

module smoke_rand_uuid_reproducible
use xiom.rand;

fn main() -> Int {
  rand.seed_from_value(42);
  var u1 = rand.uuid_v4();

  rand.seed_from_value(42);
  var u2 = rand.uuid_v4();

  if u1 != u2 { return 1; }
  if u1.len() != 36 { return 2; }

  rand.seed_from_value(42);
  var u3 = rand.uuid_v7();

  rand.seed_from_value(42);
  var u4 = rand.uuid_v7();

  if u3 != u4 { return 3; }
  if u3.len() != 36 { return 4; }

  return 0;
}

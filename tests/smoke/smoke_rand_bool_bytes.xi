module smoke_rand_bool_bytes
use xiom.rand;

fn main() -> Int {
  var rb = rand.random_bool();

  var bytes = rand.random_bytes(10);
  if bytes.len() != 10 { return 1; }

  return 0;
}

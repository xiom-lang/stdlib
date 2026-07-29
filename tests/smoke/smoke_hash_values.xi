module smoke_hash_values
use xiom.hash;

fn main() -> Int {
  if hash.hash_value(0) != hash.hash(0) { return 1; }
  if hash.hash_value(42) != hash.hash(42) { return 2; }

  return 0;
}

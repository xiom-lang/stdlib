module smoke_hash_bool
use xiom.hash;

fn main() -> Int {
  if hash.hash(true) != hash.hash(true) { return 1; }
  if hash.hash(false) != hash.hash(false) { return 2; }
  if hash.hash(true) == hash.hash(false) { return 3; }

  return 0;
}

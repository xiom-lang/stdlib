module smoke_hash_edge
use xiom.hash;

fn main() -> Int {
  if hash.hash(0) != (0 as Int).hash() { return 1; }
  if hash.hash(-1) != (-1).hash() { return 2; }

  if hash.hash(true) != true.hash() { return 3; }
  if hash.hash(false) != false.hash() { return 4; }

  return 0;
}

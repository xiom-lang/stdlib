module smoke_hash_consistency
use xiom.hash;

fn main() -> Int {
  var i: Int = 0;
  while i < 100 {
    if hash.hash(i) != hash.hash(i) { return 1; }
    i = i + 1;
  }

  return 0;
}

module smoke_hash_combine
use xiom.hash;

fn main() -> Int {
  var c1 = hash.hash_combine(0, 0);
  var c2 = hash.hash_combine(1, 2);
  var c3 = hash.hash_combine(2, 1);

  if c2 == c3 { return 1; }

  return 0;
}

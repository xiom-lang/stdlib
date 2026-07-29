module smoke_hash_deterministic
use xiom.hash;

fn main() -> Int {
  var h1 = hash.hash(12345);
  var h2 = hash.hash(12345);
  var h3 = hash.hash(12345);

  if h1 != h2 { return 1; }
  if h2 != h3 { return 2; }
  if h3 != h1 { return 3; }

  return 0;
}

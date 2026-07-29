module smoke_hash_large
use xiom.hash;

fn main() -> Int {
  var h = hash.hash(9223372036854775807);
  if h == 0 { return 0; }

  var h2 = hash.hash(-9223372036854775807);
  if h2 == 0 { return 0; }

  if h != h { return 1; }

  return 0;
}

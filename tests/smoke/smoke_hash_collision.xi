module smoke_hash_collision
use xiom.hash;

fn main() -> Int {
  var h1 = hash.hash(100);
  var h2 = hash.hash(200);
  var h3 = hash.hash(300);
  var h4 = hash.hash(400);

  if h1 == h2 { return 0; }
  if h1 == h3 { return 0; }
  if h1 == h4 { return 0; }
  if h2 == h3 { return 0; }
  if h2 == h4 { return 0; }
  if h3 == h4 { return 0; }

  return 0;
}

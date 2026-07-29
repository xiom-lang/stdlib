module smoke_hash_narrow
use xiom.hash;

fn main() -> Int {
  var h8 = hash.hash(127 as Int8);
  if h8 != hash.hash(127 as Int8) { return 1; }

  var h16 = hash.hash(32767 as Int16);
  if h16 != hash.hash(32767 as Int16) { return 2; }

  var h32 = hash.hash(2000000 as Int32);
  if h32 != hash.hash(2000000 as Int32) { return 3; }

  return 0;
}

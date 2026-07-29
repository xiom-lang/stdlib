module smoke_cross_hash_collections
use xiom.hash;
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Int].new();

  var i: Int = 0;
  while i < 20 {
    m.insert(hash.hash(i), i);
    i = i + 1;
  }

  if m.len() != 20 { return 1; }

  var j: Int = 0;
  while j < 20 {
    var k = hash.hash(j);
    if !m.contains(k) { return 2; }
    j = j + 1;
  }

  return 0;
}

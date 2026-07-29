module smoke_hash_stress
use xiom.hash;

fn main() -> Int {
  var i: Int = 0;
  while i < 500 {
    var h = hash.hash(i);
    if h == 0 && i != 0 { }
    i = i + 1;
  }
  return 0;
}

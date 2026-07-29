module smoke_rand_stress
use xiom.rand;

fn main() -> Int {
  var i: Int = 0;
  while i < 100 {
    var r = rand.random();
    if r < 0.0 || r >= 1.0 { return 1; }
    i = i + 1;
  }
  return 0;
}

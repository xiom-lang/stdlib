module smoke_cmp_stress
use xiom.cmp;

fn main() -> Int {
  var i: Int = 0;
  while i < 100 {
    if cmp.clamp(i, 10, 90) < 10 { return 1; }
    if cmp.clamp(i, 10, 90) > 90 { return 2; }
    i = i + 1;
  }
  return 0;
}

module smoke_stress_iter_range_contains
use xiom.iter;

fn main() -> Int {
    var r = iter.range(5, 15);
    if r.contains(5) && r.contains(10) && r.contains(14) {
      if not r.contains(4) && not r.contains(15) && not r.contains(20) {
        return 0;
      }
    }
    return 1;
}

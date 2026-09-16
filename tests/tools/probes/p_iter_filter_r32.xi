module p_iter_filter_r32
use xiom.iter;
use xiom.io;

fn main() -> Int {
  var all = iter.range(1, 50).filter(fn(x: &Int) -> Bool { return true; }).collect();
  io.println("filter-true.len=" + all.len());

  var none = iter.range(1, 50).filter(fn(x: &Int) -> Bool { return false; }).collect();
  io.println("filter-false.len=" + none.len());

  var mod3 = iter.range(1, 50).filter(fn(x: &Int) -> Bool { return *x % 3 == 0; }).collect();
  io.println("filter-mod3.len=" + mod3.len());

  return 0;
}

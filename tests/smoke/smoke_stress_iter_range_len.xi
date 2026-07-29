module smoke_stress_iter_range_len
  use xiom.iter;

  fn main() -> Int {
    var r = iter.range(3, 7);
    if r.len() == 4 {
      return 0;
    }
    return 1;
  }

module smoke_stress_iter_enumerate
  use xiom.iter;

  fn main() -> Int {
    var r = iter.range(10, 15);
    if r.start == 10 && r.end == 15 {
      return 0;
    }
    return 1;
  }

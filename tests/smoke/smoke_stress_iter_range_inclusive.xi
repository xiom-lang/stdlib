module smoke_stress_iter_range_inclusive
  use xiom.iter;

  fn main() -> Int {
    var ri = iter.range_inclusive(1, 5);
    match ri.next() {
      Some(v) => {
        if v == 1 { return 0; }
        return 1;
      }
      None => { return 1; }
    }
  }

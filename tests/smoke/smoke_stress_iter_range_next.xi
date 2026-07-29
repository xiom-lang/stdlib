module smoke_stress_iter_range_next
  use xiom.iter;

  fn main() -> Int {
    var r = iter.range(0, 3);
    match r.next() {
      Some(v) => {
        if v == 0 {
          match r.next() {
            Some(v2) => {
              if v2 == 1 {
                match r.next() {
                  Some(v3) => {
                    if v3 == 2 {
                      match r.next() {
                        None => { return 0; }
                        Some(_) => { return 1; }
                      }
                    }
                    return 1;
                  }
                  None => { return 1; }
                }
              }
              return 1;
            }
            None => { return 1; }
          }
        }
        return 1;
      }
      None => { return 1; }
    }
  }

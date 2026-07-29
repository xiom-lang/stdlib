module smoke_stress_hash_int
  use xiom.hash;

  fn main() -> Int {
    var h = hash.hash(42);
    if h > 0 {
      return 0;
    }
    return 1;
  }

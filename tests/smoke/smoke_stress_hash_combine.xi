module smoke_stress_hash_combine
  use xiom.hash;

  fn main() -> Int {
    var h1 = hash.hash(42);
    var h2 = hash.hash(100);
    var combined = hash.hash_combine(h1, h2);
    if combined != h1 {
      return 0;
    }
    return 1;
  }

module smoke_stress_crypto_constant_time_compare
  use xiom.crypto;

  fn main() -> Int {
    var a = Vec[UInt8].new();
    a.push(1u8);
    a.push(2u8);
    a.push(3u8);

    var b = Vec[UInt8].new();
    b.push(1u8);
    b.push(2u8);
    b.push(3u8);

    var c = Vec[UInt8].new();
    c.push(4u8);
    c.push(5u8);
    c.push(6u8);

    var eq = crypto.constant_time_compare(&a, &b);
    var neq = crypto.constant_time_compare(&a, &c);

    if eq {
      if not neq {
        return 0;
      }
    }
    return 1;
  }
}

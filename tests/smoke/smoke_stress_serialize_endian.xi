module smoke_stress_serialize_endian
  use xiom.serialize;

  fn main() -> Int {
    var le = serialize.little_endian();
    var be = serialize.big_endian();

    if le or be {
      return 0;
    }
    return 1;
  }
}

module smoke_stress_serialize_is_valid_json
  use xiom.serialize;

  fn main() -> Int {
    var valid = serialize.is_valid_json("{\"x\": 42}");
    var invalid = serialize.is_valid_json("{bad json}");

    if valid {
      if not invalid {
        return 0;
      }
    }
    return 1;
  }
}

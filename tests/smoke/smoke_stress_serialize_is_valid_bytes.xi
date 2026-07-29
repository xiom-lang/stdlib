module smoke_stress_serialize_is_valid_bytes
  use xiom.serialize;

  fn main() -> Int {
    var valid_json = Vec[UInt8].new();
    valid_json.push(123u8); valid_json.push(34u8); valid_json.push(107u8);
    valid_json.push(101u8); valid_json.push(121u8); valid_json.push(34u8);
    valid_json.push(58u8); valid_json.push(32u8); valid_json.push(49u8);
    valid_json.push(125u8);

    var invalid_json = Vec[UInt8].new();
    invalid_json.push(123u8); invalid_json.push(34u8); invalid_json.push(107u8);
    invalid_json.push(101u8); invalid_json.push(121u8); invalid_json.push(34u8);
    invalid_json.push(58u8);

    var v1 = serialize.is_valid_bytes(&valid_json);
    var v2 = serialize.is_valid_bytes(&invalid_json);

    if v1 {
      if not v2 {
        return 0;
      }
    }
    return 1;
  }

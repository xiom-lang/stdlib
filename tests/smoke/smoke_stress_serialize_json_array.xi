module smoke_stress_serialize_json_array
  use xiom.serialize;

  fn main() -> Int {
    var items = Vec[Str].new();
    items.push(serialize.json_number(1.0));
    items.push(serialize.json_number(2.0));
    items.push(serialize.json_number(3.0));

    var arr = serialize.json_array(items);

    if arr.len() > 0 {
      return 0;
    }
    return 1;
  }
}

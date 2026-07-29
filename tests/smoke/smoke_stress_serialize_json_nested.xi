module smoke_stress_serialize_json_nested
  use xiom.serialize;

  fn main() -> Int {
    var arr = serialize.json_array_builder();
    arr.push(serialize.json_int(1));
    arr.push(serialize.json_int(2));
    arr.push(serialize.json_int(3));

    var inner = serialize.json_object_builder();
    inner.insert("x", serialize.json_int(10));
    inner.insert("y", serialize.json_int(20));

    var outer = serialize.json_object_builder();
    outer.insert("name", serialize.json_string("test"));
    outer.insert("points", arr.build());
    outer.insert("coord", inner.build());

    var json_str = outer.build();
    if json_str.len() > 0 {
      var result = serialize.parse_json(&json_str);
      if result.is_ok {
        return 0;
      }
    }
    return 1;
  }

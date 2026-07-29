module smoke_stress_serialize_large_json
  use xiom.serialize;

  fn main() -> Int {
    var arr = serialize.json_array_builder();
    arr.push(serialize.json_int(1));
    arr.push(serialize.json_int(2));
    arr.push(serialize.json_int(3));
    arr.push(serialize.json_int(4));
    arr.push(serialize.json_int(5));
    arr.push(serialize.json_int(6));
    arr.push(serialize.json_int(7));
    arr.push(serialize.json_int(8));
    arr.push(serialize.json_int(9));
    arr.push(serialize.json_int(10));
    arr.push(serialize.json_int(11));
    arr.push(serialize.json_int(12));
    arr.push(serialize.json_int(13));
    arr.push(serialize.json_int(14));
    arr.push(serialize.json_int(15));
    arr.push(serialize.json_int(16));
    arr.push(serialize.json_int(17));
    arr.push(serialize.json_int(18));
    arr.push(serialize.json_int(19));
    arr.push(serialize.json_int(20));
    arr.push(serialize.json_int(21));
    arr.push(serialize.json_int(22));
    arr.push(serialize.json_int(23));
    arr.push(serialize.json_int(24));
    arr.push(serialize.json_int(25));
    arr.push(serialize.json_int(26));
    arr.push(serialize.json_int(27));
    arr.push(serialize.json_int(28));
    arr.push(serialize.json_int(29));
    arr.push(serialize.json_int(30));
    arr.push(serialize.json_int(31));
    arr.push(serialize.json_int(32));
    arr.push(serialize.json_int(33));
    arr.push(serialize.json_int(34));
    arr.push(serialize.json_int(35));
    arr.push(serialize.json_int(36));
    arr.push(serialize.json_int(37));
    arr.push(serialize.json_int(38));
    arr.push(serialize.json_int(39));
    arr.push(serialize.json_int(40));
    arr.push(serialize.json_int(41));
    arr.push(serialize.json_int(42));
    arr.push(serialize.json_int(43));
    arr.push(serialize.json_int(44));
    arr.push(serialize.json_int(45));
    arr.push(serialize.json_int(46));
    arr.push(serialize.json_int(47));
    arr.push(serialize.json_int(48));
    arr.push(serialize.json_int(49));
    arr.push(serialize.json_int(50));

    var json_str = arr.build();
    if json_str.len() > 0 {
      var result = serialize.parse_json(&json_str);
      match result {
        Ok(value) => {
          var elem = value.index(0);
          match elem {
            Some(_) => { return 0; }
            None => { return 2; }
          }
        }
        Err(_) => { return 1; }
      }
    }
    return 1;
  }

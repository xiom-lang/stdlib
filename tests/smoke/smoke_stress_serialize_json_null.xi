module smoke_stress_serialize_json_null
use xiom.serialize;

fn main() -> Int {
    var n = serialize.json_null();

    if n.len() > 0 {
      return 0;
    }
    return 1;}

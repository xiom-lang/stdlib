module smoke_stress_serialize_json_string
use xiom.serialize;

fn main() -> Int {
    var s = serialize.json_string("hello world");

    if s.len() > 0 {
      return 0;
    }
    return 1;
}

module smoke_stress_serialize_json_parse_valid
use xiom.serialize;

fn main() -> Int {
    var parsed = serialize.json_parse("{\"a\": 1, \"b\": \"text\", \"c\": true}");

    if parsed.is_ok() {
      return 0;
    }
    return 1;
}

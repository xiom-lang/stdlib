module smoke_stress_serialize_json_parse_invalid
use xiom.serialize;

fn main() -> Int {
    var parsed = serialize.json_parse("not valid json {{{");

    if not parsed.is_ok() {
      return 0;
    }
    return 1;
}

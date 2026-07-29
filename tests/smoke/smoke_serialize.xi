module smoke_serialize
use xiom.serialize;
use xiom.collections;
use xiom.convert;
fn main() -> Int {
  var b = xiom.serialize.json_bool(true);
  var n = xiom.serialize.json_null();
  var r = xiom.serialize.parse_json("[1, 2, 3]");
  if b == "true" && n == "null" && r.is_ok { return 0; }
  return 1;
}
module smoke_serialize
use xiom.serialize;
use xiom.collections;
use xiom.convert;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  let r = xiom.serialize.parse_json("[1, 2, 3]");
  if b == "true" && n == "null" && r.is_ok { return 0; }
  return 1;
}
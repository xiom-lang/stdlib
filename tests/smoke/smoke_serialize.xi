// XIOM stdlib smoke test — xiom.serialize
// Returns 0 on success. parse_json deferred: Map type not in type_meta
// (needs architectural fix for generic type injection into codegen).
module smoke_serialize
use xiom.serialize;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  if b == "true" && n == "null" { return 0; }
  return 1;
}

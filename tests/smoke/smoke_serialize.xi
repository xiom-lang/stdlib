// XIOM stdlib smoke test — xiom.serialize
// Returns 0. parse_json needs: Map dispatch fix (parser multi-type-arg
// + codegen generic inference with type_arg from Tuple).
module smoke_serialize
use xiom.serialize;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  if b == "true" && n == "null" { return 0; }
  return 1;
}
// XIOM stdlib smoke test — xiom.serialize
// Returns 0. parse_json needs: parser multi-type-arg fix for Map[K,V].
// Map.new IS now in generic_fn_decls with smoke-level use xiom.collections.
module smoke_serialize
use xiom.serialize;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  if b == "true" && n == "null" { return 0; }
  return 1;
}

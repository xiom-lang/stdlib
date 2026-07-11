// XIOM stdlib smoke test — xiom.serialize
// Returns 0 on success. parse_json deferred: Map dispatch issue
// (non-pub generic type methods not injected, needs architectural fix).
module smoke_serialize
use xiom.serialize;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  if b == "true" && n == "null" { return 0; }
  return 1;
}

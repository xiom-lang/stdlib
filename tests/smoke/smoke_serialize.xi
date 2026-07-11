// XIOM stdlib smoke test — xiom.serialize
// Returns 0 on success, nonzero on failure (process exit code).

// XIOM stdlib smoke test — xiom.serialize
// Returns 0 on success, nonzero on failure (process exit code).
module smoke_serialize
use xiom.serialize;
fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  let r = xiom.serialize.parse_json("[1, 2, 3]");
  if b == "true" && n == "null" && r.is_ok { return 0; }
  return 1;
}
  return 1;
}

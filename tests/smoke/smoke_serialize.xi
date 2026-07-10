// XIOM stdlib smoke test — xiom.serialize
// Returns 0 on success, nonzero on failure (process exit code).
// NOTE: parse_json requires Reverse/Map dispatch fix (Tier 2).

module smoke_serialize
use xiom.serialize;

fn main() -> Int {
  let b = xiom.serialize.json_bool(true);
  let n = xiom.serialize.json_null();
  if b == "true" && n == "null" {
    return 0;
  }
  return 1;
}

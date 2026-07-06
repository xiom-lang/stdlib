// XIOM stdlib cross-module smoke test — xiom.serialize + xiom.convert together.
// Proves cross-module resolution AND linking (GAP 3): two stdlib modules are
// resolved via `use`, injected into one program, and linked into one binary.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_cross_serialize_convert
use xiom.serialize;
use xiom.convert;

fn main() -> Int {
  let s = convert.int_to_string(123);
  let b = xiom.serialize.json_bool(true);
  let r = xiom.serialize.parse_json("[1, 2, 3]");
  if s == "123" && b == "true" && r.is_ok {
    return 0;
  }
  return 1;
}

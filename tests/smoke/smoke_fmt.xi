// XIOM stdlib smoke test -- xiom.fmt
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_fmt
use xiom.fmt;

fn main() -> Int {
  var n: Int = 42;
  var b: Bool = true;
  if n.to_str() == "42" && b.to_str() == "true" {
    return 0;
  }
  return 1;
}

// XIOM stdlib smoke test — xiom.fmt
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_fmt
use xiom.fmt;

fn main() -> Int {
  if fmt.to_str(42) == "42" && fmt.to_str(true) == "true" {
    return 0;
  }
  return 1;
}

// XIOM stdlib smoke test — xiom.error
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_error
use xiom.error;

fn main() -> Int {
  let e = error.new("smoke failure");
  if e.to_string().len() > 0 {
    return 0;
  }
  return 1;
}

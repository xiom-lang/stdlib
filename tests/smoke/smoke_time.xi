// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.time
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_time
use xiom.time;

fn main() -> Int {
  var d = time.Duration.from_secs(5);
  if d.as_secs() == 5 {
    return 0;
  }
  return 1;
}

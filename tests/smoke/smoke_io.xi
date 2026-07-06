// NOTE: link/run smoke only
// XIOM stdlib smoke test — xiom.io
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_io
use xiom.io;

fn main() -> Int {
  io.println("smoke_io: link/run ok");
  let a = io.args();
  if a.len() >= 0 {
    return 0;
  }
  return 1;
}

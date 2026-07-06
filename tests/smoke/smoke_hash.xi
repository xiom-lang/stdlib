// XIOM stdlib smoke test — xiom.hash
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_hash
use xiom.hash;

fn main() -> Int {
  if hash.of(42) == hash.of(42) && hash.of(true) != hash.of(false) {
    return 0;
  }
  return 1;
}

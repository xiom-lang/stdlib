// XIOM stdlib smoke test — xiom.hash
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_hash
use xiom.hash;

fn main() -> Int {
  if hash.hash(42) == hash.hash(42) && hash.hash(true) != hash.hash(false) {
    return 0;
  }
  return 1;
}

// XIOM stdlib smoke test — xiom.sync
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_sync
use xiom.sync;

fn main() -> Int {
  // AtomicInt basic operations
  var ai = sync.AtomicInt.new(10);
  ai.store(15);
  if ai.load() != 15 { return 1; }

  // AtomicBool: store true, load true
  var ab = sync.AtomicBool.new(false);
  ab.store(true);
  if not ab.load() { return 2; }

  // AtomicBool: store false, load false
  var ab2 = sync.AtomicBool.new(true);
  ab2.store(false);
  if ab2.load() { return 3; }

  return 0;
}

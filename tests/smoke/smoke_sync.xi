// XIOM stdlib smoke test — xiom.sync
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_sync
use xiom.sync;

fn main() -> Int {
  let a = sync.Arc.new(42);
  var ai = sync.AtomicInt.new(10);
  ai.store(15);
  if a.get() == 42 && ai.load() == 15 {
    return 0;
  }
  return 1;
}

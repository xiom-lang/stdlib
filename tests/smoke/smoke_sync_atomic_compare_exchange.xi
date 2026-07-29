module smoke_sync_atomic_compare_exchange
use xiom.sync;

fn main() -> Int {
  var ai = sync.AtomicInt.new(10);
  if !ai.compare_exchange(10, 20) { return 1; }
  if ai.load() != 20 { return 2; }
  if ai.compare_exchange(10, 30) { return 3; }
  if ai.load() != 20 { return 4; }

  var ab = sync.AtomicBool.new(false);
  if !ab.compare_exchange(false, true) { return 5; }
  if !ab.load() { return 6; }
  if ab.compare_exchange(false, false) { return 7; }

  return 0;
}

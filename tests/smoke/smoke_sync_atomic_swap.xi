module smoke_sync_atomic_swap
use xiom.sync;

fn main() -> Int {
  var ai = sync.AtomicInt.new(100);
  var old = ai.swap(200);
  if old != 100 { return 1; }
  if ai.load() != 200 { return 2; }

  var ab = sync.AtomicBool.new(true);
  var old_b = ab.swap(false);
  if !old_b { return 3; }
  if ab.load() { return 4; }

  return 0;
}

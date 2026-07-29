module smoke_sync_atomic_bool
use xiom.sync;

fn main() -> Int {
  var ab = sync.AtomicBool.new(false);
  if ab.load() { return 1; }

  ab.store(true);
  if !ab.load() { return 2; }

  var old = ab.swap(false);
  if !old { return 3; }
  if ab.load() { return 4; }

  return 0;
}

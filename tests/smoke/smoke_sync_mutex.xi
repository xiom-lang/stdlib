module smoke_sync_mutex
use xiom.sync;

fn main() -> Int {
  var m = sync.Mutex.new(42);
  var g = m.lock();
  if g.get() != 42 { return 1; }

  return 0;
}

module smoke_sync_rwlock
use xiom.sync;

fn main() -> Int {
  var l = sync.RwLock.new(42);

  var rg = l.read();
  if rg.get() != 42 { return 1; }

  var wg = l.write();
  if wg.get() != 42 { return 2; }

  return 0;
}

module smoke_sync_condvar
use xiom.sync;

fn main() -> Int {
  var cv = sync.Condvar.new();
  var m = sync.Mutex.new(0);
  var g = m.lock();
  var g2 = cv.wait(g);

  return 0;
}

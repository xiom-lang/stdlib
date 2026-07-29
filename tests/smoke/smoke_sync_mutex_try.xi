module smoke_sync_mutex_try
use xiom.sync;

fn main() -> Int {
  var m = sync.Mutex.new(10);

  match m.try_lock() {
    Some(g) => { if g.get() != 10 { return 1; }; },
    None => { return 2; },
  };

  return 0;
}

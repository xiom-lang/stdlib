module smoke_sync_mutex
use xiom.sync.mutex;

fn main() -> Int {
  var m = mutex.mutex_new();
  mutex.mutex_lock(&m);
  if not mutex.mutex_is_locked(&m) { return 1; }
  mutex.mutex_unlock(&m);
  if mutex.mutex_is_locked(&m) { return 2; }

  // lock/unlock cycle works repeatedly
  mutex.mutex_lock(&m);
  mutex.mutex_unlock(&m);
  if mutex.mutex_is_locked(&m) { return 3; }

  return 0;
}

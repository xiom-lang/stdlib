module smoke_sync_mutex_try
use xiom.sync.mutex;

fn main() -> Int {
  var m = mutex.mutex_new();
  if not mutex.mutex_try_lock(&m) { return 1; }
  if mutex.mutex_try_lock(&m) { return 2; }
  mutex.mutex_unlock(&m);
  if not mutex.mutex_try_lock(&m) { return 3; }
  mutex.mutex_unlock(&m);
  return 0;
}

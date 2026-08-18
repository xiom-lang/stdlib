module smoke_sync_condvar
use xiom.sync.mutex;
use xiom.sync.condvar;

fn main() -> Int {
  var m = mutex.mutex_new();
  var cv = condvar.condvar_new();
  mutex.mutex_lock(&m);
  // no waiter to notify — notify_one on an empty cv is a no-op (returns)
  condvar.condvar_notify_one(cv);
  mutex.mutex_unlock(&m);
  if mutex.mutex_is_locked(&m) { return 1; }
  return 0;
}

module smoke_sync_rwlock
use xiom.sync.rwlock;

fn main() -> Int {
  var l = rwlock.rwlock_new();
  rwlock.rwlock_read_lock(&l);
  if rwlock.rwlock_is_write_locked(&l) { return 1; }
  rwlock.rwlock_read_unlock(&l);

  rwlock.rwlock_write_lock(&l);
  if not rwlock.rwlock_is_write_locked(&l) { return 2; }
  rwlock.rwlock_write_unlock(&l);
  if rwlock.rwlock_is_write_locked(&l) { return 3; }

  if not rwlock.rwlock_read_try_lock(&l) { return 4; }
  rwlock.rwlock_read_unlock(&l);
  if not rwlock.rwlock_write_try_lock(&l) { return 5; }
  rwlock.rwlock_write_unlock(&l);

  return 0;
}

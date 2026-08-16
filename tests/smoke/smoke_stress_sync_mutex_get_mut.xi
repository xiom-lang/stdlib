module smoke_stress_sync_mutex_get_mut
use xiom.sync.mutex;

fn main() -> Int {
    var m = mutex.mutex_new();
    mutex.mutex_lock(&m);
    if not mutex.mutex_is_locked(&m) { return 1; }
    mutex.mutex_unlock(&m);
    if mutex.mutex_is_locked(&m) { return 2; }
    return 0;
}

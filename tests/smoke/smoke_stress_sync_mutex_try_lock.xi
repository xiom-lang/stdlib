module smoke_stress_sync_mutex_try_lock
use xiom.sync.mutex;

fn main() -> Int {
    var m = mutex.mutex_new();
    // first lock succeeds
    if not mutex.mutex_try_lock(&m) { return 1; }
    // second concurrent lock must fail while held
    if mutex.mutex_try_lock(&m) { return 2; }
    mutex.mutex_unlock(&m);
    // relock after unlock succeeds
    if not mutex.mutex_try_lock(&m) { return 3; }
    mutex.mutex_unlock(&m);
    return 0;
}

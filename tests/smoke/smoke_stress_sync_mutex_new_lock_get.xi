module smoke_stress_sync_mutex_new_lock_get
use xiom.sync.mutex;

fn main() -> Int {
    var m = mutex.mutex_new();
    mutex.mutex_lock(&m);
    var held = mutex.mutex_is_locked(&m);
    mutex.mutex_unlock(&m);
    var released = not mutex.mutex_is_locked(&m);
    if held && released {
        return 0;
    }
    return 1;
}

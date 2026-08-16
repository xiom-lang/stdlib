module smoke_stress_sync_mutex_new_lock_get
use xiom.sync;

fn main() -> Int {
        var m = sync.Mutex.new(42);
        var g = m.lock();
        var v = g.get();
        g.drop();
        if v == 42 {
            return 0;
        } else {
            return 1;
        }
}

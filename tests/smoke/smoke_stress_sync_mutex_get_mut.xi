module smoke_stress_sync_mutex_get_mut
use xiom.sync;

fn main() -> Int {
        var m = sync.Mutex.new(10);
        var g = m.lock();
        var v = g.get_mut();
        g.drop();
        if v == 10 {
            return 0;
        } else {
            return 1;
        }
}

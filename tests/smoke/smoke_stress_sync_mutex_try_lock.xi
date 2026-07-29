module smoke_stress_sync_mutex_try_lock
use xiom.sync;

fn main() -> Int {
    var m = sync.Mutex.new(42);
    match m.try_lock() {
        Some(g) => {
            var v = g.get();
            g.drop();
            if v == 42 {
                return 0;
            } else {
                return 2;
            }
        },
        None => {
            return 1;
        }
    }
}

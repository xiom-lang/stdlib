module smoke_stress_sync_rwlock_try_write
use xiom.sync;

fn main() -> Int {
    var lock = sync.RwLock.new(88);
    match lock.try_write() {
        Some(g) => {
            var v = g.get_mut();
            g.drop();
            if v == 88 {
                return 0;
            } else {
                return 2;
            }
        },
        None => {
            return 1;
        }
}

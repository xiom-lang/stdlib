module smoke_stress_sync_rwlock_read
use xiom.sync;

fn main() -> Int {
        var lock = sync.RwLock.new(55);
        var guard = lock.read();
        var v = guard.get();
        guard.drop();
        if v == 55 {
            return 0;
        } else {
            return 1;
        }}

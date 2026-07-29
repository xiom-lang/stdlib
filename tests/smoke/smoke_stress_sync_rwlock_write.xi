module smoke_stress_sync_rwlock_write
    use xiom.sync;

    fn main() -> Int {
        var lock = sync.RwLock.new(10);
        var guard = lock.write();
        var v = guard.get_mut();
        guard.drop();
        if v == 10 {
            return 0;
        } else {
            return 1;
        }
    }
}

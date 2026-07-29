module smoke_stress_sync_atomic_int_fetch_sub
    use xiom.sync;

    fn main() -> Int {
        var ai = sync.AtomicInt.new(10);
        var old = ai.fetch_sub(4);
        var new_val = ai.load();
        if old == 10 {
            if new_val == 6 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
    }
}

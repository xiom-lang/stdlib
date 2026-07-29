module smoke_stress_sync_atomic_int_swap
    use xiom.sync;

    fn main() -> Int {
        var ai = sync.AtomicInt.new(100);
        var old = ai.swap(200);
        var new_val = ai.load();
        if old == 100 {
            if new_val == 200 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
    }
}

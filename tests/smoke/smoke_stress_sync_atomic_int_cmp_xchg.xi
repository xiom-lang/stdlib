module smoke_stress_sync_atomic_int_cmp_xchg
use xiom.sync;

fn main() -> Int {
        var ai = sync.AtomicInt.new(50);
        var ok = ai.compare_exchange(50, 75);
        var new_val = ai.load();
        if ok {
            if new_val == 75 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
}

module smoke_stress_sync_atomic_int_cmp_xchg
use xiom.sync.atomics;

fn main() -> Int {
    var ai = atomics.atomic_int_new(50);
    var ok = atomics.atomic_compare_exchange(&ai, 50, 75);
    var new_val = atomics.atomic_load(&ai);
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

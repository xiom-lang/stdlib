module smoke_stress_sync_atomic_int_fetch_sub
use xiom.sync.atomics;

fn main() -> Int {
    var ai = atomics.atomic_int_new(10);
    var old = atomics.atomic_fetch_sub(&ai, 4);
    var new_val = atomics.atomic_load(&ai);
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

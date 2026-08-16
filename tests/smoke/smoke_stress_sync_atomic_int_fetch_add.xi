module smoke_stress_sync_atomic_int_fetch_add
use xiom.sync.atomics;

fn main() -> Int {
    var ai = atomics.atomic_int_new(5);
    var old = atomics.atomic_fetch_add(&ai, 3);
    var new_val = atomics.atomic_load(&ai);
    if old == 5 {
        if new_val == 8 {
            return 0;
        } else {
            return 2;
        }
    } else {
        return 1;
    }
}

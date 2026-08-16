module smoke_stress_sync_atomic_int_fetch_add
use xiom.sync;

fn main() -> Int {
        var ai = sync.AtomicInt.new(5);
        var old = ai.fetch_add(3);
        var new_val = ai.load();
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

module smoke_stress_sync_atomic_int_new_load
use xiom.sync;

fn main() -> Int {
        var ai = sync.AtomicInt.new(0);
        var val = ai.load();
        if val == 0 {
            return 0;
        } else {
            return 1;
        }
}

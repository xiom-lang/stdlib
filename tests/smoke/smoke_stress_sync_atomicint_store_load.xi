module smoke_stress_sync_atomicint_store_load
use xiom.sync;

fn main() -> Int {
    var ai = sync.AtomicInt.new(0);
    ai.store(42);
    var val = ai.load();
    if val == 42 { return 0; } else { return 1; }
}

module smoke_stress_sync_barrier
use xiom.sync;

fn main() -> Int {
        var b = sync.Barrier.new(1);
        b.wait();
        return 0;
}

module smoke_stress_sync_arc_strong_count
use xiom.sync;

fn main() -> Int {
        var a = sync.Arc.new(200);
        var count = a.strong_count();
        a.drop();
        if count == 1 {
            return 0;
        } else {
            return 1;
        }
}

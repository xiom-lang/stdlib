module smoke_stress_sync_once
use xiom.sync;

fn main() -> Int {
        var o = sync.Once.new();
        var completed = o.is_completed();
        if not completed {
            return 0;
        } else {
            return 1;
        }}

module smoke_stress_sync_once_completed
use xiom.sync;

fn main() -> Int {
    var o = sync.Once.new();
    var completed_before = o.is_completed();
    if completed_before { return 1; }
    o.call_once(fn() {
        return;
    });
    var completed_after = o.is_completed();
    if completed_after {
        return 0;
    } else {
        return 2;
}

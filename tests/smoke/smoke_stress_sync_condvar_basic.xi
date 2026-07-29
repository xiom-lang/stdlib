module smoke_stress_sync_condvar_basic
use xiom.sync;

fn main() -> Int {
    var cv = sync.Condvar.new();
    cv.notify_one();
    cv.notify_all();
    return 0;
}

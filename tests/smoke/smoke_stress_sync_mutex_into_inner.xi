module smoke_stress_sync_mutex_into_inner
use xiom.sync;

fn main() -> Int {
    var m = sync.Mutex.new(99);
    var v = m.into_inner();
    if v == 99 {
        return 0;
    } else {
        return 1;
}

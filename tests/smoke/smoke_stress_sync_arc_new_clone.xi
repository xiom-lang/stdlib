module smoke_stress_sync_arc_new_clone
use xiom.collect.arc;

fn main() -> Int {
    // The implemented xiom.sync Arc is an adaptive replacement cache
    // (arc_new/arc_put/arc_get); there is no refcount Arc type yet.
    var a = arc_new(4);
    arc_put(&a, 1, 100);
    var v = arc_get(&a, 1);
    match v {
        Some(val) => {
            if val == 100 {
                return 0;
            }
            return 1;
        },
        None => { return 2; }
    }
}

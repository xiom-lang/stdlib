module smoke_stress_sync_arc_ptr_eq
use xiom.sync;

fn main() -> Int {
    var a1 = sync.Arc.new(1);
    var a2 = sync.Arc.new(1);
    var a1_clone = a1.clone();
    var same = a1.ptr_eq(&a1_clone);
    var diff = a1.ptr_eq(&a2);
    a1.drop();
    a2.drop();
    a1_clone.drop();
    if same {
        if not diff {
            return 0;
        } else {
            return 2;
        }
    } else {
        return 1;
    }
}

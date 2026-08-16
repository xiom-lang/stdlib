module smoke_stress_sync_arc_many_clones
use xiom.collect.arc;

fn main() -> Int {
    // Adaptive replacement cache semantics: capacity, puts, gets, contains,
    // size (no refcount clone).
    var a = arc_new(4);
    arc_put(&a, 1, 100);
    arc_put(&a, 2, 200);
    arc_put(&a, 3, 300);
    arc_put(&a, 4, 400);
    if arc_size(&a) != 4 { return 1; }
    if arc_capacity(&a) != 4 { return 2; }
    if not arc_contains(&a, 2) { return 3; }
    if arc_contains(&a, 9) { return 4; }
    var v = arc_get(&a, 3);
    match v {
        Some(val) => { if val != 300 { return 5; } },
        None => { return 6; }
    }
    return 0;
}

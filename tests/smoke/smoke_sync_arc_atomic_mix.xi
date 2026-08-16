module smoke_sync_arc_atomic_mix
use xiom.sync.atomics;
use xiom.collect.arc;

fn main() -> Int {
  var ai = atomics.atomic_int_new(0);
  atomics.atomic_store(&ai, 100);
  if atomics.atomic_load(&ai) != 100 { return 1; }

  var old = atomics.atomic_fetch_add(&ai, 50);
  if old != 100 { return 2; }
  if atomics.atomic_load(&ai) != 150 { return 3; }

  // Arc cache half of the mix
  var a = arc_new(2);
  arc_put(&a, 7, 99);
  var v = arc_get(&a, 7);
  match v {
    Some(val) => { if val != 99 { return 4; } },
    None => { return 5; }
  }

  return 0;
}

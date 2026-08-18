module smoke_sync_arc_get
use xiom.collect.arc;
use xiom.io;

fn main() -> Int {
  // implemented Arc = adaptive replacement cache (arc_new/arc_put/arc_get)
  var a = arc_new(4);
  arc_put(&mut a, 1, 10);
  match arc_get(&mut a, 1) {
    Some(v) => {
      if v != 10 { io.println("arc value"); return 1; }
    },
    None => { io.println("arc miss"); return 2; }
  }
  arc_put(&mut a, 2, 20);
  match arc_get(&mut a, 2) {
    Some(v) => {
      if v != 20 { io.println("arc value2"); return 3; }
    },
    None => { io.println("arc miss2"); return 4; }
  }
  return 0;
}

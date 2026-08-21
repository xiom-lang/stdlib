// XIOM stdlib smoke -- xiom.collect.arc
// ARC cache (delegates to collect.cache): put/get/evict/contains/size/capacity.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_arc
use xiom.collect.arc;
use xiom.io;

fn main() -> Int {
  var c = arc_new(3);
  if arc_capacity(&c) != 3 { io.println("arc capacity"); return 1; }
  if arc_size(&c) != 0 { io.println("arc empty size"); return 2; }
  arc_put(&mut c, 1, 10);
  arc_put(&mut c, 2, 20);
  arc_put(&mut c, 3, 30);
  if arc_size(&c) != 3 { io.println("arc size after puts"); return 3; }
  var g1 = arc_get(&mut c, 1);
  match g1 {
    Some(v) => { if v != 10 { io.println("arc get1"); return 4; } },
    None => { io.println("arc get1 none"); return 5; },
  }
  // key 1 is now MRU; key 2 is the LRU and must be evicted on overflow
  arc_put(&mut c, 4, 40);
  if arc_size(&c) != 3 { io.println("arc size after evict"); return 6; }
  if arc_contains(&mut c, 2) { io.println("arc evicted lru"); return 7; }
  var g3 = arc_get(&mut c, 3);
  match g3 {
    Some(v) => { if v != 30 { io.println("arc get3"); return 8; } },
    None => { io.println("arc get3 none"); return 9; },
  }
  if !arc_contains(&mut c, 1) { io.println("arc contains mru"); return 10; }
  if arc_contains(&mut c, 99) { io.println("arc contains missing"); return 11; }
  var g4 = arc_get(&mut c, 99);
  match g4 {
    Some(_) => { io.println("arc get missing"); return 12; },
    None => {},
  }
  if arc_size(&c) != 3 { io.println("arc final size"); return 13; }

  io.println("OK");
  return 0;
}

// smoke_collect_map_rehash.xi -- IntMap rehash/tombstone behavior
// Heavy delete+insert workloads degrade lookup probe sequences; map_rehash
// rebuilds in place and restores exact semantics (same entries, same
// values, clears tombstones, size preserved).
module smoke_collect_map_rehash
use xiom.collect.map;
use xiom.io;

fn main() -> Int {
  var m = map_new();
  // insert 100 entries, delete half, reinsert a different half
  var i = 0;
  while i < 100 {
    map_put(&mut m, i, i * 10);
    i += 1;
  }
  i = 0;
  while i < 50 {
    map_remove(&mut m, i);
    i += 1;
  }
  // size must be 50 after deletions
  if map_size(&m) != 50 { io.println("size50"); return 1; }
  // reinsert with shifted values
  i = 0;
  while i < 50 {
    map_put(&mut m, i + 200, i + 1);
    i += 1;
  }
  if map_size(&m) != 100 { io.println("size100"); return 2; }

  // ---- rehash ----
  map_rehash(&mut m);
  if map_size(&m) != 100 { io.println("size-after-rehash"); return 3; }
  // every live entry must survive exactly
  i = 50;
  while i < 100 {
    match map_get(&m, i) {
      Some(v) => { if v != i * 10 { io.println("old val"); return 4; } }
      None => { io.println("old lost"); return 5; }
    }
    i += 1;
  }
  i = 200;
  while i < 250 {
    match map_get(&m, i) {
      Some(v) => { if v != i - 199 { io.println("new val"); return 6; } }
      None => { io.println("new lost"); return 7; }
    }
    i += 1;
  }
  // deleted keys must still be absent
  i = 0;
  while i < 50 {
    if map_contains(&m, i) { io.println("deleted resurrected"); return 8; }
    i += 1;
  }
  // map stays usable: insert + get after rehash
  map_put(&mut m, 999, 42);
  match map_get(&m, 999) {
    Some(v) => { if v != 42 { io.println("post-rehash put"); return 9; } }
    None => { io.println("post-rehash miss"); return 10; }
  }
  if map_size(&m) != 101 { io.println("post-rehash size"); return 11; }

  io.println("OK");
  return 0;
}

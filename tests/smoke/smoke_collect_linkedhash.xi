// XIOM stdlib smoke test - xiom.collect.linkedhash
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_linkedhash
use xiom.collect.linkedhash;
use xiom.io;

fn main() -> Int {
  var m = lhmap_new();
  if lhmap_size(&m) != 0 { io.println("lh:size0"); return 1; }
  lhmap_put(&mut m, 10, 100);
  lhmap_put(&mut m, 20, 200);
  lhmap_put(&mut m, 30, 300);
  if lhmap_size(&m) != 3 { io.println("lh:size"); return 2; }
  var g = lhmap_get(&m, 20);
  if !g.is_some || g.value != 200 { io.println("lh:get"); return 3; }
  var miss = lhmap_get(&m, 99);
  if miss.is_some { io.println("lh:miss"); return 4; }
  if !lhmap_contains(&m, 30) { io.println("lh:contains"); return 5; }
  if lhmap_contains(&m, 5) { io.println("lh:contains-miss"); return 6; }

  // insertion order preserved
  var first = lhmap_first(&m);
  if !first.is_some || first.value != 10 { io.println("lh:first"); return 7; }
  var last = lhmap_last(&m);
  if !last.is_some || last.value != 30 { io.println("lh:last"); return 8; }
  var ks = lhmap_iter(&m);
  if ks.len() != 3 { io.println("lh:iterlen"); return 9; }
  if ks[0] != 10 || ks[1] != 20 || ks[2] != 30 { io.println("lh:iter"); return 10; }

  // update keeps position
  lhmap_put(&mut m, 20, 222);
  var g2 = lhmap_get(&m, 20);
  if !g2.is_some || g2.value != 222 { io.println("lh:upd"); return 11; }
  if lhmap_size(&m) != 3 { io.println("lh:updsize"); return 12; }
  var ks2 = lhmap_iter(&m);
  if ks2[1] != 20 { io.println("lh:updpos"); return 13; }

  // remove preserves relative order
  lhmap_remove(&mut m, 20);
  if lhmap_contains(&m, 20) { io.println("lh:rm"); return 14; }
  if lhmap_size(&m) != 2 { io.println("lh:rmsize"); return 15; }
  var ks3 = lhmap_iter(&m);
  if ks3.len() != 2 || ks3[0] != 10 || ks3[1] != 30 { io.println("lh:rmorder"); return 16; }
  lhmap_remove(&mut m, 10);
  var first2 = lhmap_first(&m);
  if !first2.is_some || first2.value != 30 { io.println("lh:rmfirst"); return 17; }
  lhmap_remove(&mut m, 30);
  if lhmap_size(&m) != 0 { io.println("lh:rmall"); return 18; }
  var f0 = lhmap_first(&m);
  if f0.is_some { io.println("lh:firstempty"); return 19; }
  var l0 = lhmap_last(&m);
  if l0.is_some { io.println("lh:lastempty"); return 20; }

  // re-insert after removing everything
  lhmap_put(&mut m, 5, 50);
  var g5 = lhmap_get(&m, 5);
  if !g5.is_some || g5.value != 50 { io.println("lh:reins"); return 21; }
  if lhmap_size(&m) != 1 { io.println("lh:reinsize"); return 22; }

  io.println("smoke_collect_linkedhash: OK");
  return 0;
}

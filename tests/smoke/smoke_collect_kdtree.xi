// XIOM stdlib smoke test - xiom.collect.kdtree + xiom.collect.spatial
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_kdtree
use xiom.collect.kdtree;
use xiom.collect.spatial;
use xiom.io;

fn main() -> Int {
  // --- kdtree: insert / nearest / range ---
  var kt = kdtree_new();
  if kdtree_size(&kt) != 0 { io.println("kdtree: initial size"); return 1; }
  kdtree_insert(&mut kt, 2, 3, 100);
  kdtree_insert(&mut kt, 5, 4, 200);
  kdtree_insert(&mut kt, 9, 6, 300);
  kdtree_insert(&mut kt, 4, 7, 400);
  if kdtree_size(&kt) != 4 { io.println("kdtree: size"); return 2; }
  // nearest to (4,3): (5,4) at dist 2 beats (2,3) at dist 4
  var nn = kdtree_nearest(&kt, 4, 3);
  if !nn.is_some || nn.value != 200 { io.println("kdtree: nearest"); return 3; }
  var nn2 = kdtree_nearest(&kt, 8, 6);
  if !nn2.is_some || nn2.value != 300 { io.println("kdtree: nearest 2"); return 4; }
  var miss = kdtree_nearest(&(kdtree_new()), 0, 0);
  if miss.is_some { io.println("kdtree: nearest empty"); return 5; }
  var kt2 = kdtree_new();
  var miss2 = kdtree_nearest(&kt2, 0, 0);
  if miss2.is_some { io.println("kdtree: nearest empty"); return 5; }
  var rng = kdtree_range(&kt, 0, 0, 5, 5);
  if rng.len() != 2 { io.println("kdtree: range count"); return 6; }
  var rng2 = kdtree_range(&kt, 5, 5, 0, 0);
  if rng2.len() != 2 { io.println("kdtree: range swapped"); return 7; }
  var rng3 = kdtree_range(&kt, 20, 20, 30, 30);
  if rng3.len() != 0 { io.println("kdtree: range empty"); return 8; }

  // --- spatial quadtree (fixed bounds, rect query) ---
  var sq = quadtree_new(0, 0, 100, 100);
  if !quadtree_insert(&mut sq, 5, 5, 55) { io.println("spatial qt: insert"); return 9; }
  if !quadtree_insert(&mut sq, 90, 90, 99) { io.println("spatial qt: insert 2"); return 10; }
  if quadtree_insert(&mut sq, 200, 200, 1) { io.println("spatial qt: oob"); return 11; }
  if quadtree_size(&sq) != 2 { io.println("spatial qt: size"); return 12; }
  var sqr = quadtree_query(&sq, 0, 0, 50, 50);
  if sqr.len() != 1 { io.println("spatial qt: rect count"); return 13; }
  if !(sqr[0] == 55) { io.println("spatial qt: rect value"); return 14; }
  var sqr2 = quadtree_query(&sq, 0, 0, 100, 100);
  if sqr2.len() != 2 { io.println("spatial qt: full rect"); return 15; }

  // --- spatial octree (fixed bounds, box query) ---
  var so = octree_new(0, 0, 0, 50, 50, 50);
  if !octree_insert(&mut so, 10, 10, 10, 5) { io.println("spatial oc: insert"); return 16; }
  if !octree_insert(&mut so, 40, 40, 40, 6) { io.println("spatial oc: insert 2"); return 17; }
  if octree_insert(&mut so, 99, 0, 0, 1) { io.println("spatial oc: oob"); return 18; }
  if octree_size(&so) != 2 { io.println("spatial oc: size"); return 19; }
  var sor = octree_query(&so, 0, 0, 0, 20, 20, 20);
  if sor.len() != 1 { io.println("spatial oc: box count"); return 20; }
  if !(sor[0] == 5) { io.println("spatial oc: box value"); return 21; }
  var sor2 = octree_query(&so, 0, 0, 0, 50, 50, 50);
  if sor2.len() != 2 { io.println("spatial oc: full box"); return 22; }

  io.println("smoke_collect_kdtree: OK");
  return 0;
}

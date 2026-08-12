// XIOM stdlib smoke test - xiom.collect.octree + xiom.collect.quadtree
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_octree
use xiom.collect.octree;
use xiom.collect.quadtree;
use xiom.io;

fn main() -> Int {
  // --- quadtree (growing root, exact point query) ---
  var qt = quadtree_new();
  if quadtree_size(&qt) != 0 { io.println("qt: initial size"); return 1; }
  quadtree_insert(&mut qt, 3, 4, 7);
  quadtree_insert(&mut qt, 8, 2, 9);
  quadtree_insert(&mut qt, -5, 12, 11);
  quadtree_insert(&mut qt, 0, 0, 13);
  if quadtree_size(&qt) != 4 { io.println("qt: size"); return 2; }
  var q1 = quadtree_query(&qt, 3, 4);
  if !q1.is_some || q1.value != 7 { io.println("qt: query 3,4"); return 3; }
  var q2 = quadtree_query(&qt, 8, 2);
  if !q2.is_some || q2.value != 9 { io.println("qt: query 8,2"); return 4; }
  var q3 = quadtree_query(&qt, -5, 12);
  if !q3.is_some || q3.value != 11 { io.println("qt: query -5,12"); return 5; }
  var q4 = quadtree_query(&qt, 0, 0);
  if !q4.is_some || q4.value != 13 { io.println("qt: query 0,0"); return 6; }
  var qm = quadtree_query(&qt, 0, 1);
  if qm.is_some { io.println("qt: miss"); return 7; }
  // duplicate point: both stored, query finds one
  quadtree_insert(&mut qt, 3, 4, 70);
  if quadtree_size(&qt) != 5 { io.println("qt: dup size"); return 8; }

  // --- octree (growing root, exact point query) ---
  var oc = octree_new();
  if octree_size(&oc) != 0 { io.println("oc: initial size"); return 9; }
  octree_insert(&mut oc, 1, 2, 3, 10);
  octree_insert(&mut oc, 4, 5, 6, 20);
  octree_insert(&mut oc, -1, -2, -3, 30);
  octree_insert(&mut oc, 100, -50, 7, 40);
  if octree_size(&oc) != 4 { io.println("oc: size"); return 10; }
  var o1 = octree_query(&oc, 1, 2, 3);
  if !o1.is_some || o1.value != 10 { io.println("oc: query"); return 11; }
  var o2 = octree_query(&oc, 4, 5, 6);
  if !o2.is_some || o2.value != 20 { io.println("oc: query 2"); return 12; }
  var o3 = octree_query(&oc, -1, -2, -3);
  if !o3.is_some || o3.value != 30 { io.println("oc: query neg"); return 13; }
  var o4 = octree_query(&oc, 100, -50, 7);
  if !o4.is_some || o4.value != 40 { io.println("oc: query far"); return 14; }
  var om = octree_query(&oc, 9, 9, 9);
  if om.is_some { io.println("oc: miss"); return 15; }

  io.println("smoke_collect_octree: OK");
  return 0;
}

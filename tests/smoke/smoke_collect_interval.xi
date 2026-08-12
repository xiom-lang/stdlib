// XIOM stdlib smoke test - xiom.collect.interval + xiom.collect.segment
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_interval
use xiom.collect.interval;
use xiom.collect.segment;
use xiom.io;

fn main() -> Int {
  // --- interval tree ---
  var it = interval_tree_new();
  if interval_size(&it) != 0 { io.println("interval: initial size"); return 1; }
  interval_insert(&mut it, 1, 5, 10);
  interval_insert(&mut it, 3, 8, 20);
  interval_insert(&mut it, 10, 15, 30);
  if interval_size(&it) != 3 { io.println("interval: size"); return 2; }
  var q3 = interval_query(&it, 3);
  if q3.len() != 2 { io.println("interval: stab count"); return 3; }
  var q6 = interval_query(&it, 6);
  if q6.len() != 1 { io.println("interval: stab 6"); return 4; }
  var q9 = interval_query(&it, 9);
  if q9.len() != 0 { io.println("interval: stab 9"); return 5; }
  if !interval_contains_point(&it, 4) { io.println("interval: contains 4"); return 6; }
  if interval_contains_point(&it, 9) { io.println("interval: contains 9"); return 7; }
  var rq = interval_range_query(&it, 6, 12);
  if rq.len() != 2 { io.println("interval: range count"); return 8; }
  if !interval_overlaps(&it, 7, 9) { io.println("interval: overlaps"); return 9; }
  if interval_overlaps(&it, 9, 9) { io.println("interval: no overlap"); return 10; }
  if !interval_remove(&mut it, 3, 8) { io.println("interval: remove"); return 11; }
  if interval_remove(&mut it, 3, 8) { io.println("interval: remove again"); return 12; }
  if interval_size(&it) != 2 { io.println("interval: size after remove"); return 13; }
  var q6b = interval_query(&it, 6);
  if q6b.len() != 0 { io.println("interval: stab after remove"); return 14; }
  if interval_contains_point(&it, 6) { io.println("interval: contains after remove"); return 15; }

  // --- segment tree ---
  var st = segtree_new(4);
  if segtree_size(&st) != 4 { io.println("segment: size"); return 16; }
  var vals = Vec[Int].new();
  vals.push(1);
  vals.push(3);
  vals.push(5);
  vals.push(7);
  segtree_build(&mut st, &vals);
  if segtree_query_sum(&st, 1, 2) != 8 { io.println("segment: sum 1..2"); return 17; }
  if segtree_query_sum(&st, 0, 3) != 16 { io.println("segment: sum 0..3"); return 18; }
  if segtree_query_min(&st, 0, 3) != 1 { io.println("segment: min"); return 19; }
  if segtree_query_max(&st, 0, 3) != 7 { io.println("segment: max"); return 20; }
  if segtree_query_min(&st, 1, 2) != 3 { io.println("segment: min 1..2"); return 21; }
  if segtree_query_max(&st, 1, 2) != 5 { io.println("segment: max 1..2"); return 22; }
  segtree_update(&mut st, 2, 10);
  if segtree_query_sum(&st, 1, 2) != 13 { io.println("segment: sum after update"); return 23; }
  if segtree_query_max(&st, 1, 2) != 10 { io.println("segment: max after update"); return 24; }
  if segtree_query_min(&st, 1, 2) != 3 { io.println("segment: min after update"); return 25; }
  if segtree_query_sum(&st, 0, 3) != 21 { io.println("segment: total after update"); return 26; }
  segtree_update(&mut st, 99, 5);
  if segtree_query_sum(&st, 0, 3) != 21 { io.println("segment: oob update"); return 27; }
  // identity values for empty clamped ranges
  if segtree_query_min(&st, 10, 20) != 9223372036854775807 { io.println("segment: min identity"); return 28; }
  if segtree_query_max(&st, 10, 20) != -9223372036854775808 { io.println("segment: max identity"); return 29; }
  if segtree_query_sum(&st, 10, 20) != 0 { io.println("segment: sum identity"); return 30; }

  io.println("smoke_collect_interval: OK");
  return 0;
}

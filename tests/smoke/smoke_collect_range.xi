// XIOM stdlib smoke test - xiom.collect.range
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_range
use xiom.collect.range;
use xiom.io;

fn main() -> Int {
  var it = interval_tree_new();
  interval_insert(&mut it, 1, 5, 10);
  interval_insert(&mut it, 3, 8, 20);
  interval_insert(&mut it, 10, 15, 30);
  var q3 = interval_query(&it, 3);
  if q3.len() != 2 { io.println("range: stab count"); return 1; }
  if !(q3[0] == 10 && q3[1] == 20) { io.println("range: stab values"); return 2; }
  var q6 = interval_query(&it, 6);
  if q6.len() != 1 { io.println("range: stab 6"); return 3; }
  if !(q6[0] == 20) { io.println("range: stab 6 value"); return 4; }
  var q12 = interval_query(&it, 12);
  if q12.len() != 1 { io.println("range: stab 12"); return 5; }
  var q0 = interval_query(&it, 0);
  if q0.len() != 0 { io.println("range: stab 0"); return 6; }
  var q16 = interval_query(&it, 16);
  if q16.len() != 0 { io.println("range: stab 16"); return 7; }
  if !interval_remove(&mut it, 3, 8) { io.println("range: remove"); return 8; }
  if interval_remove(&mut it, 3, 8) { io.println("range: remove again"); return 9; }
  var q6b = interval_query(&it, 6);
  if q6b.len() != 0 { io.println("range: stab after remove"); return 10; }
  var q3b = interval_query(&it, 3);
  if q3b.len() != 1 { io.println("range: stab 3 after remove"); return 11; }
  if !(q3b[0] == 10) { io.println("range: stab 3 value"); return 12; }
  // invalid interval is rejected
  interval_insert(&mut it, 9, 2, 99);
  var q5 = interval_query(&it, 5);
  if q5.len() != 1 { io.println("range: invalid interval"); return 13; }

  io.println("smoke_collect_range: OK");
  return 0;
}

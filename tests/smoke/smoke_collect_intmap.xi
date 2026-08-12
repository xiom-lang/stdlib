// XIOM stdlib smoke test - xiom.collect.intmap
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_intmap
use xiom.collect.intmap;
use xiom.io;

fn main() -> Int {
  // --- int map ---
  var m = int_map_new(4);
  if int_map_size(&m) != 0 { io.println("intmap: initial size"); return 1; }
  int_map_put(&mut m, 1, 10);
  int_map_put(&mut m, 2, 20);
  int_map_put(&mut m, 3, 30);
  if int_map_size(&m) != 3 { io.println("intmap: size"); return 2; }
  int_map_put(&mut m, 2, 99);
  if int_map_size(&m) != 3 { io.println("intmap: overwrite size"); return 3; }
  var g2 = int_map_get(&m, 2);
  if !g2.is_some || g2.value != 99 { io.println("intmap: get 2"); return 4; }
  var g1 = int_map_get(&m, 1);
  if !g1.is_some || g1.value != 10 { io.println("intmap: get 1"); return 5; }
  var miss = int_map_get(&m, 42);
  if miss.is_some { io.println("intmap: get miss"); return 6; }
  if !int_map_contains(&m, 3) { io.println("intmap: contains 3"); return 7; }
  if int_map_contains(&m, 42) { io.println("intmap: contains miss"); return 8; }
  var order1 = int_map_iter(&m);
  if order1.len() != 3 { io.println("intmap: iter size"); return 9; }
  if !(order1[0] == 1 && order1[1] == 2 && order1[2] == 3) { io.println("intmap: iter order"); return 10; }
  if !int_map_remove(&m, 2) { io.println("intmap: remove"); return 11; }
  if int_map_remove(&m, 2) { io.println("intmap: remove again"); return 12; }
  if int_map_contains(&m, 2) { io.println("intmap: contains after remove"); return 13; }
  if int_map_size(&m) != 2 { io.println("intmap: size after remove"); return 14; }
  var order2 = int_map_iter(&m);
  if !(order2[0] == 1 && order2[1] == 3) { io.println("intmap: iter after remove"); return 15; }
  // negative and extreme keys
  int_map_put(&mut m, -5, 50);
  var gneg = int_map_get(&m, -5);
  if !gneg.is_some || gneg.value != 50 { io.println("intmap: negative key"); return 16; }
  int_map_put(&mut m, -9223372036854775808, 7);
  var gmin = int_map_get(&m, -9223372036854775808);
  if !gmin.is_some || gmin.value != 7 { io.println("intmap: INT_MIN key"); return 17; }
  // growth stress
  var i: Int = 0;
  while i < 5000 {
    int_map_put(&mut m, i * 37 + 11, i);
    i = i + 1;
  }
  if int_map_size(&m) != 5004 { io.println("intmap: stress size"); return 18; }
  i = 0;
  while i < 5000 {
    var g = int_map_get(&m, i * 37 + 11);
    if !g.is_some || g.value != i { io.println("intmap: stress get"); return 19; }
    i = i + 1;
  }
  var miss2 = int_map_get(&m, 999999);
  if miss2.is_some { io.println("intmap: stress miss"); return 20; }

  // --- string map ---
  var sm = string_map_new();
  if string_map_size(&sm) != 0 { io.println("stringmap: initial size"); return 21; }
  string_map_put(&mut sm, "alpha", 1);
  string_map_put(&mut sm, "beta", 2);
  string_map_put(&mut sm, "alpha", 10);
  if string_map_size(&sm) != 2 { io.println("stringmap: size"); return 22; }
  var ga = string_map_get(&sm, "alpha");
  if !ga.is_some || ga.value != 10 { io.println("stringmap: get alpha"); return 23; }
  var gb = string_map_get(&sm, "beta");
  if !gb.is_some || gb.value != 2 { io.println("stringmap: get beta"); return 24; }
  var gmiss = string_map_get(&sm, "gamma");
  if gmiss.is_some { io.println("stringmap: get miss"); return 25; }
  if !string_map_contains(&sm, "beta") { io.println("stringmap: contains"); return 26; }
  if string_map_contains(&sm, "gamma") { io.println("stringmap: contains miss"); return 27; }
  if !string_map_remove(&sm, "alpha") { io.println("stringmap: remove"); return 28; }
  if string_map_remove(&sm, "alpha") { io.println("stringmap: remove again"); return 29; }
  if string_map_contains(&sm, "alpha") { io.println("stringmap: contains after remove"); return 30; }
  if string_map_size(&sm) != 1 { io.println("stringmap: size after remove"); return 31; }

  io.println("smoke_collect_intmap: OK");
  return 0;
}

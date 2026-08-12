// XIOM stdlib smoke test - xiom.collect.hamt
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_hamt
use xiom.collect.hamt;
use xiom.io;

fn main() -> Int {
  // --- put / get ---
  var h = hamt_new();
  if hamt_size(&h) != 0 { io.println("hamt: initial size"); return 1; }
  if !hamt_insert(&mut h, 5, 50) { io.println("hamt: insert 5"); return 2; }
  if !hamt_insert(&mut h, 1, 10) { io.println("hamt: insert 1"); return 3; }
  if !hamt_insert(&mut h, 100, 7) { io.println("hamt: insert 100"); return 4; }
  if hamt_insert(&mut h, 5, 99) { io.println("hamt: dup insert"); return 5; }
  if hamt_size(&h) != 3 { io.println("hamt: size after inserts"); return 6; }
  var g5 = hamt_get(&h, 5);
  if !g5.is_some || g5.value != 50 { io.println("hamt: get 5"); return 7; }
  var g1 = hamt_get(&h, 1);
  if !g1.is_some || g1.value != 10 { io.println("hamt: get 1"); return 8; }
  var g100 = hamt_get(&h, 100);
  if !g100.is_some || g100.value != 7 { io.println("hamt: get 100"); return 9; }
  var miss = hamt_get(&h, 42);
  if miss.is_some { io.println("hamt: get miss"); return 10; }
  if !hamt_contains(&h, 100) { io.println("hamt: contains 100"); return 11; }
  if hamt_contains(&h, 42) { io.println("hamt: contains miss"); return 12; }

  // --- remove ---
  if !hamt_remove(&mut h, 1) { io.println("hamt: remove 1"); return 13; }
  if hamt_remove(&mut h, 1) { io.println("hamt: remove 1 again"); return 14; }
  if hamt_contains(&h, 1) { io.println("hamt: contains after remove"); return 15; }
  if hamt_size(&h) != 2 { io.println("hamt: size after remove"); return 16; }
  var ga = hamt_get(&h, 5);
  if !ga.is_some || ga.value != 50 { io.println("hamt: get 5 after remove"); return 17; }
  if !hamt_insert(&mut h, 1, 11) { io.println("hamt: reinsert 1"); return 18; }
  var gb = hamt_get(&h, 1);
  if !gb.is_some || gb.value != 11 { io.println("hamt: get reinserted 1"); return 19; }
  if hamt_size(&h) != 3 { io.println("hamt: size after reinsert"); return 20; }

  // --- stress: many keys, including hash-path collisions ---
  var h2 = hamt_new();
  var i: Int = 0;
  while i < 1000 {
    var k = i * 131 + 7;
    if !hamt_insert(&mut h2, k, i) { io.println("hamt: stress insert"); return 21; }
    i = i + 1;
  }
  if hamt_size(&h2) != 1000 { io.println("hamt: stress size"); return 22; }
  i = 0;
  while i < 1000 {
    var k = i * 131 + 7;
    if !hamt_contains(&h2, k) { io.println("hamt: stress contains"); return 23; }
    var g = hamt_get(&h2, k);
    if !g.is_some || g.value != i { io.println("hamt: stress get"); return 24; }
    i = i + 1;
  }
  i = 0;
  while i < 1000 {
    var k = i * 131 + 7;
    if !hamt_remove(&mut h2, k) { io.println("hamt: stress remove"); return 25; }
    i = i + 1;
  }
  if hamt_size(&h2) != 0 { io.println("hamt: stress empty"); return 26; }

  // --- clear ---
  var h3 = hamt_new();
  hamt_insert(&mut h3, 1, 1);
  hamt_insert(&mut h3, 2, 2);
  hamt_clear(&mut h3);
  if hamt_size(&h3) != 0 { io.println("hamt: clear size"); return 27; }
  if hamt_contains(&h3, 1) { io.println("hamt: clear contains"); return 28; }
  if !hamt_insert(&mut h3, 9, 9) { io.println("hamt: insert after clear"); return 29; }
  var g9 = hamt_get(&h3, 9);
  if !g9.is_some || g9.value != 9 { io.println("hamt: get after clear"); return 30; }

  io.println("smoke_collect_hamt: OK");
  return 0;
}

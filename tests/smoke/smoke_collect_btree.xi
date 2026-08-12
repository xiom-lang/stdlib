// XIOM stdlib smoke test - xiom.collect.btree + btreeplus
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_btree
use xiom.collect.btree;
use xiom.collect.btreeplus;
use xiom.io;

fn main() -> Int {
  // ===================== B-Tree =====================
  var t = btree_new(4);
  if btree_size(&t) != 0 { io.println("bt:size0"); return 1; }
  btree_insert(&mut t, 5, 50);
  btree_insert(&mut t, 3, 30);
  btree_insert(&mut t, 7, 70);
  btree_insert(&mut t, 1, 10);
  btree_insert(&mut t, 9, 90);
  btree_insert(&mut t, 2, 20);
  btree_insert(&mut t, 6, 60);
  btree_insert(&mut t, 8, 80);
  if btree_size(&t) != 8 { io.println("bt:size"); return 2; }
  if !btree_contains(&t, 5) { io.println("bt:c5"); return 3; }
  if !btree_contains(&t, 1) { io.println("bt:c1"); return 4; }
  if !btree_contains(&t, 9) { io.println("bt:c9"); return 5; }
  if btree_contains(&t, 4) { io.println("bt:c4"); return 6; }
  if btree_contains(&t, 100) { io.println("bt:c100"); return 7; }
  var g5 = btree_get(&t, 5);
  if !g5.is_some || g5.value != 50 { io.println("bt:g5"); return 8; }
  var g1 = btree_get(&t, 1);
  if !g1.is_some || g1.value != 10 { io.println("bt:g1"); return 9; }
  var g9 = btree_get(&t, 9);
  if !g9.is_some || g9.value != 90 { io.println("bt:g9"); return 10; }
  var miss = btree_get(&t, 42);
  if miss.is_some { io.println("bt:miss"); return 11; }
  var mn = btree_min(&t);
  if !mn.is_some || mn.value != 1 { io.println("bt:min"); return 12; }
  var mx = btree_max(&t);
  if !mx.is_some || mx.value != 9 { io.println("bt:max"); return 13; }

  // update preserves size
  btree_insert(&mut t, 5, 55);
  if btree_size(&t) != 8 { io.println("bt:updsize"); return 14; }
  var g5b = btree_get(&t, 5);
  if !g5b.is_some || g5b.value != 55 { io.println("bt:upd"); return 15; }

  // remove
  if !btree_remove(&mut t, 3) { io.println("bt:rm3"); return 16; }
  if btree_remove(&mut t, 3) { io.println("bt:rm3-again"); return 17; }
  if btree_contains(&t, 3) { io.println("bt:rmcontains"); return 18; }
  if btree_size(&t) != 7 { io.println("bt:rmsize"); return 19; }
  var mn2 = btree_min(&t);
  if !mn2.is_some || mn2.value != 1 { io.println("bt:min2"); return 20; }
  var mx2 = btree_max(&t);
  if !mx2.is_some || mx2.value != 9 { io.println("bt:max2"); return 21; }
  btree_insert(&mut t, 3, 33);
  if !btree_contains(&t, 3) { io.println("bt:reins"); return 22; }
  var g3 = btree_get(&t, 3);
  if !g3.is_some || g3.value != 33 { io.println("bt:reinsget"); return 23; }

  // remove all
  var t2 = btree_new(3);
  var i: Int = 0;
  while i < 61 {
    btree_insert(&mut t2, (i * 17) % 61, i);
    i = i + 1;
  }
  if btree_size(&t2) != 61 { io.println("bt:stress-size"); return 24; }
  i = 0;
  while i < 61 {
    if !btree_contains(&t2, (i * 17) % 61) { io.println("bt:stress-c"); return 25; }
    i = i + 1;
  }
  var tmn = btree_min(&t2);
  if !tmn.is_some || tmn.value != 0 { io.println("bt:stress-min"); return 26; }
  var tmx = btree_max(&t2);
  if !tmx.is_some || tmx.value != 60 { io.println("bt:stress-max"); return 27; }
  i = 0;
  while i < 30 {
    if !btree_remove(&mut t2, (i * 17) % 61) { io.println("bt:stress-rm"); return 28; }
    i = i + 1;
  }
  if btree_size(&t2) != 31 { io.println("bt:stress-rmsize"); return 29; }
  i = 30;
  while i < 61 {
    if !btree_contains(&t2, (i * 17) % 61) { io.println("bt:stress-c2"); return 30; }
    i = i + 1;
  }
  i = 0;
  while i < 30 {
    if btree_contains(&t2, (i * 17) % 61) { io.println("bt:stress-rmgone"); return 31; }
    i = i + 1;
  }
  var t3 = btree_new(4);
  i = 1;
  while i <= 50 {
    btree_insert(&mut t3, i * 2, i);
    i = i + 1;
  }
  i = 1;
  while i <= 50 {
    if !btree_remove(&mut t3, i * 2) { io.println("bt:drain"); return 32; }
    i = i + 1;
  }
  if btree_size(&t3) != 0 { io.println("bt:drain-size"); return 33; }
  var em = btree_min(&t3);
  if em.is_some { io.println("bt:drain-min"); return 34; }
  var ex = btree_max(&t3);
  if ex.is_some { io.println("bt:drain-max"); return 35; }
  btree_insert(&mut t3, 100, 1);
  var g100 = btree_get(&t3, 100);
  if !g100.is_some || g100.value != 1 { io.println("bt:refill"); return 36; }

  // ===================== B+ Tree =====================
  var p = bptree_new(4);
  if bptree_size(&p) != 0 { io.println("bp:size0"); return 37; }
  bptree_insert(&mut p, 10, 100);
  bptree_insert(&mut p, 20, 200);
  bptree_insert(&mut p, 30, 300);
  bptree_insert(&mut p, 40, 400);
  bptree_insert(&mut p, 50, 500);
  bptree_insert(&mut p, 60, 600);
  if bptree_size(&p) != 6 { io.println("bp:size"); return 38; }
  if !bptree_contains(&p, 30) { io.println("bp:c30"); return 39; }
  if bptree_contains(&p, 35) { io.println("bp:c35"); return 40; }
  var pg = bptree_get(&p, 40);
  if !pg.is_some || pg.value != 400 { io.println("bp:g40"); return 41; }
  var pmiss = bptree_get(&p, 45);
  if pmiss.is_some { io.println("bp:miss"); return 42; }
  bptree_insert(&mut p, 30, 333);  // update
  if bptree_size(&p) != 6 { io.println("bp:updsize"); return 43; }
  var pg30 = bptree_get(&p, 30);
  if !pg30.is_some || pg30.value != 333 { io.println("bp:upd"); return 44; }

  // range scans
  var r1 = bptree_range(&p, 25, 45);
  if r1.len() != 2 { io.println("bp:r1len"); return 45; }
  if r1[0] != 333 || r1[1] != 400 { io.println("bp:r1"); return 46; }
  var r2 = bptree_range(&p, 0, 1000);
  if r2.len() != 6 { io.println("bp:r2len"); return 47; }
  if r2[0] != 100 || r2[5] != 600 { io.println("bp:r2"); return 48; }
  var r3 = bptree_range(&p, 35, 35);
  if r3.len() != 0 { io.println("bp:r3"); return 49; }
  var r4 = bptree_range(&p, 30, 30);
  if r4.len() != 1 || r4[0] != 333 { io.println("bp:r4"); return 50; }

  // remove + ranges after remove
  if !bptree_remove(&mut p, 30) { io.println("bp:rm30"); return 51; }
  if bptree_remove(&mut p, 30) { io.println("bp:rm30-again"); return 52; }
  if bptree_contains(&p, 30) { io.println("bp:rmcontains"); return 53; }
  if bptree_size(&p) != 5 { io.println("bp:rmsize"); return 54; }
  var r5 = bptree_range(&p, 20, 40);
  if r5.len() != 2 || r5[0] != 200 || r5[1] != 400 { io.println("bp:r5"); return 55; }
  bptree_insert(&mut p, 30, 333);
  var r6 = bptree_range(&p, 25, 45);
  if r6.len() != 2 || r6[0] != 333 || r6[1] != 400 { io.println("bp:r6"); return 56; }

  // stress with many keys + range over the whole set
  var p2 = bptree_new(5);
  i = 0;
  while i < 300 {
    bptree_insert(&mut p2, i * 3 + 1, i);
    i = i + 1;
  }
  if bptree_size(&p2) != 300 { io.println("bp:stress-size"); return 57; }
  i = 0;
  while i < 300 {
    var k = i * 3 + 1;
    if !bptree_contains(&p2, k) { io.println("bp:stress-c"); return 58; }
    i = i + 1;
  }
  var rall = bptree_range(&p2, 0, 10000);
  if rall.len() != 300 { io.println("bp:stress-rlen"); return 59; }
  var j: Int = 1;
  while j < rall.len() {
    if rall[j - 1] >= rall[j] { io.println("bp:stress-rsorted"); return 60; }
    j = j + 1;
  }
  var rmid = bptree_range(&p2, 100, 200);
  var expected: Int = 0;
  i = 0;
  while i < 300 {
    var k = i * 3 + 1;
    if k >= 100 && k <= 200 { expected = expected + 1; }
    i = i + 1;
  }
  if rmid.len() != expected { io.println("bp:stress-rmid"); return 61; }
  i = 0;
  while i < 150 {
    if !bptree_remove(&mut p2, i * 3 + 1) { io.println("bp:stress-rm"); return 62; }
    i = i + 1;
  }
  if bptree_size(&p2) != 150 { io.println("bp:stress-rmsize"); return 63; }
  i = 150;
  while i < 300 {
    if !bptree_contains(&p2, i * 3 + 1) { io.println("bp:stress-c2"); return 64; }
    i = i + 1;
  }

  io.println("smoke_collect_btree: OK");
  return 0;
}

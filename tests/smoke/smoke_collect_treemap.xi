// XIOM stdlib smoke test - xiom.collect.treemap + treeset + hashset
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_treemap
use xiom.collect.treemap;
use xiom.collect.treeset;
use xiom.collect.hashset;
use xiom.io;

fn main() -> Int {
  // ===================== TreeMap =====================
  var m = treemap_new();
  if treemap_size(&m) != 0 { io.println("tm:size0"); return 1; }
  treemap_put(&mut m, 5, 50);
  treemap_put(&mut m, 3, 30);
  treemap_put(&mut m, 7, 70);
  treemap_put(&mut m, 1, 10);
  treemap_put(&mut m, 9, 90);
  if treemap_size(&m) != 5 { io.println("tm:size"); return 2; }
  treemap_put(&mut m, 5, 55);  // update
  if treemap_size(&m) != 5 { io.println("tm:updsize"); return 3; }
  var g5 = treemap_get(&m, 5);
  if !g5.is_some || g5.value != 55 { io.println("tm:get5"); return 4; }
  var miss = treemap_get(&m, 4);
  if miss.is_some { io.println("tm:miss"); return 5; }
  if !treemap_contains(&m, 9) { io.println("tm:contains"); return 6; }
  if treemap_contains(&m, 2) { io.println("tm:contains-miss"); return 7; }
  var mn = treemap_min(&m);
  if !mn.is_some || mn.value != 1 { io.println("tm:min"); return 8; }
  var mx = treemap_max(&m);
  if !mx.is_some || mx.value != 9 { io.println("tm:max"); return 9; }
  var it = treemap_iter(&m);
  if it.len() != 5 { io.println("tm:iterlen"); return 10; }
  if it[0].0 != 1 || it[0].1 != 10 { io.println("tm:iter0"); return 11; }
  if it[1].0 != 3 || it[1].1 != 30 { io.println("tm:iter1"); return 12; }
  if it[2].0 != 5 || it[2].1 != 55 { io.println("tm:iter2"); return 13; }
  if it[3].0 != 7 || it[3].1 != 70 { io.println("tm:iter3"); return 14; }
  if it[4].0 != 9 || it[4].1 != 90 { io.println("tm:iter4"); return 15; }
  if !treemap_remove(&m, 3) { io.println("tm:rm"); return 16; }
  if treemap_remove(&m, 3) { io.println("tm:rm-again"); return 17; }
  if treemap_contains(&m, 3) { io.println("tm:rmcontains"); return 18; }
  if treemap_size(&m) != 4 { io.println("tm:rmsize"); return 19; }
  treemap_put(&mut m, 3, 33);
  if !treemap_contains(&m, 3) { io.println("tm:reins"); return 20; }
  var it2 = treemap_iter(&m);
  if it2.len() != 5 { io.println("tm:reinsiter"); return 21; }

  // stress with sorted-order invariant
  var m2 = treemap_new();
  var i: Int = 0;
  while i < 300 {
    treemap_put(&mut m2, (i * 53) % 311, i);
    i = i + 1;
  }
  if treemap_size(&m2) != 300 { io.println("tm:stress-size"); return 22; }
  i = 0;
  while i < 300 {
    var g = treemap_get(&m2, (i * 53) % 311);
    if !g.is_some || g.value != i { io.println("tm:stress-get"); return 23; }
    i = i + 1;
  }
  var sit = treemap_iter(&m2);
  var j: Int = 1;
  while j < sit.len() {
    if sit[j - 1].0 >= sit[j].0 { io.println("tm:stress-order"); return 24; }
    j = j + 1;
  }

  // ===================== TreeSet =====================
  var s = treeset_new();
  if !treeset_insert(&mut s, 5) { io.println("ts:ins5"); return 25; }
  if !treeset_insert(&mut s, 3) { io.println("ts:ins3"); return 26; }
  if treeset_insert(&mut s, 5) { io.println("ts:dup"); return 27; }
  if treeset_size(&s) != 2 { io.println("ts:size"); return 28; }
  if !treeset_contains(&s, 3) { io.println("ts:c3"); return 29; }
  if treeset_contains(&s, 9) { io.println("ts:c9"); return 30; }
  var tmn = treeset_min(&s);
  if !tmn.is_some || tmn.value != 3 { io.println("ts:min"); return 31; }
  var tmx = treeset_max(&s);
  if !tmx.is_some || tmx.value != 5 { io.println("ts:max"); return 32; }
  if !treeset_remove(&s, 3) { io.println("ts:rm"); return 33; }
  if treeset_remove(&s, 3) { io.println("ts:rm-again"); return 34; }
  if treeset_size(&s) != 1 { io.println("ts:rmsize"); return 35; }
  var s2 = treeset_new();
  i = 0;
  while i < 200 {
    treeset_insert(&mut s2, (i * 31) % 199);
    i = i + 1;
  }
  if treeset_size(&s2) != 199 { io.println("ts:stress-size"); return 36; }
  i = 0;
  while i < 199 {
    if !treeset_contains(&s2, (i * 31) % 199) { io.println("ts:stress-c"); return 37; }
    i = i + 1;
  }
  i = 0;
  while i < 100 {
    if !treeset_remove(&mut s2, (i * 31) % 199) { io.println("ts:stress-rm"); return 38; }
    i = i + 1;
  }
  if treeset_size(&s2) != 99 { io.println("ts:stress-rmsize"); return 39; }
  i = 100;
  while i < 199 {
    if !treeset_contains(&s2, (i * 31) % 199) { io.println("ts:stress-c2"); return 40; }
    i = i + 1;
  }

  // ===================== HashSet =====================
  var h = hashset_new();
  hashset_insert(&mut h, 5);
  hashset_insert(&mut h, 3);
  hashset_insert(&mut h, 7);
  hashset_insert(&mut h, 5);
  if hashset_size(&h) != 3 { io.println("hs:size"); return 41; }
  if !hashset_contains(&h, 3) { io.println("hs:c3"); return 42; }
  if hashset_contains(&h, 9) { io.println("hs:c9"); return 43; }
  hashset_remove(&mut h, 3);
  if hashset_contains(&h, 3) { io.println("hs:rm"); return 44; }
  if hashset_size(&h) != 2 { io.println("hs:rmsize"); return 45; }
  hashset_insert(&mut h, 3);
  if !hashset_contains(&h, 3) { io.println("hs:reins"); return 46; }
  var h2 = hashset_new();
  i = 0;
  while i < 500 {
    hashset_insert(&mut h2, i * 11 + 3);
    i = i + 1;
  }
  if hashset_size(&h2) != 500 { io.println("hs:stress-size"); return 47; }
  i = 0;
  while i < 500 {
    if !hashset_contains(&h2, i * 11 + 3) { io.println("hs:stress-c"); return 48; }
    i = i + 1;
  }
  i = 0;
  while i < 250 {
    hashset_remove(&mut h2, i * 11 + 3);
    i = i + 1;
  }
  if hashset_size(&h2) != 250 { io.println("hs:stress-rmsize"); return 49; }
  hashset_clear(&mut h2);
  if hashset_size(&h2) != 0 { io.println("hs:clear"); return 50; }
  if hashset_contains(&h2, 3) { io.println("hs:clearc"); return 51; }

  io.println("smoke_collect_treemap: OK");
  return 0;
}

// XIOM stdlib smoke test - xiom.collect.lfu + xiom.collect.lru
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_lfu_lru
use xiom.collect.lru;
use xiom.collect.lfu;
use xiom.io;

fn main() -> Int {
  // --- LRU ---
  var l = lru_new(3);
  if lru_capacity(&mut l) != 3 { io.println("lru: capacity"); return 1; }
  lru_put(&mut l, 1, 10);
  lru_put(&mut l, 2, 20);
  lru_put(&mut l, 3, 30);
  if lru_size(&mut l) != 3 { io.println("lru: size"); return 2; }
  var g1 = lru_get(&mut l, 1);
  if !g1.is_some || g1.value != 10 { io.println("lru: get 1"); return 3; }
  // 2 is now LRU; inserting 4 evicts 2
  lru_put(&mut l, 4, 40);
  if lru_size(&mut l) != 3 { io.println("lru: size after evict"); return 4; }
  if lru_contains(&mut l, 2) { io.println("lru: 2 evicted"); return 5; }
  if !lru_contains(&mut l, 1) { io.println("lru: 1 present"); return 6; }
  if !lru_contains(&mut l, 4) { io.println("lru: 4 present"); return 7; }
  var g3 = lru_get(&mut l, 3);
  if !g3.is_some || g3.value != 30 { io.println("lru: get 3"); return 8; }
  // 1 is now LRU; inserting 5 evicts 1
  lru_put(&mut l, 5, 50);
  if lru_contains(&mut l, 1) { io.println("lru: 1 evicted"); return 9; }
  if !lru_contains(&mut l, 5) { io.println("lru: 5 present"); return 10; }
  // update existing keeps position
  lru_put(&mut l, 5, 55);
  var g5 = lru_get(&mut l, 5);
  if !g5.is_some || g5.value != 55 { io.println("lru: update"); return 11; }
  // remove
  if !lru_remove(&mut l, 3) { io.println("lru: remove 3"); return 12; }
  if lru_remove(&mut l, 3) { io.println("lru: remove 3 again"); return 13; }
  if lru_contains(&mut l, 3) { io.println("lru: contains after remove"); return 14; }
  if lru_size(&mut l) != 2 { io.println("lru: size after remove"); return 15; }
  lru_clear(&mut l);
  if lru_size(&mut l) != 0 { io.println("lru: clear"); return 16; }
  var gmiss = lru_get(&mut l, 1);
  if gmiss.is_some { io.println("lru: get after clear"); return 17; }

  // --- LFU ---
  var f = lfu_new(2);
  if lfu_capacity(&mut f) != 2 { io.println("lfu: capacity"); return 18; }
  lfu_put(&mut f, 1, 10);
  lfu_put(&mut f, 2, 20);
  var fg1 = lfu_get(&mut f, 1);
  if !fg1.is_some || fg1.value != 10 { io.println("lfu: get 1"); return 19; }
  lfu_get(&mut f, 1);
  // key 1 now freq 3, key 2 freq 1; inserting 3 evicts 2
  lfu_put(&mut f, 3, 30);
  if lfu_contains(&mut f, 2) { io.println("lfu: 2 evicted"); return 20; }
  if !lfu_contains(&mut f, 1) { io.println("lfu: 1 present"); return 21; }
  if !lfu_contains(&mut f, 3) { io.println("lfu: 3 present"); return 22; }
  if lfu_size(&mut f) != 2 { io.println("lfu: size"); return 23; }
  var fg3 = lfu_get(&mut f, 3);
  if !fg3.is_some || fg3.value != 30 { io.println("lfu: get 3"); return 24; }
  if !lfu_remove(&mut f, 1) { io.println("lfu: remove 1"); return 25; }
  if lfu_remove(&mut f, 1) { io.println("lfu: remove 1 again"); return 26; }
  if lfu_contains(&mut f, 1) { io.println("lfu: contains after remove"); return 27; }
  if lfu_size(&mut f) != 1 { io.println("lfu: size after remove"); return 28; }
  lfu_clear(&mut f);
  if lfu_size(&mut f) != 0 { io.println("lfu: clear"); return 29; }
  var fmiss = lfu_get(&mut f, 7);
  if fmiss.is_some { io.println("lfu: get after clear"); return 30; }
  // capacity clamp
  var f0 = lfu_new(0);
  if lfu_capacity(&mut f0) != 1 { io.println("lfu: cap clamp"); return 31; }
  var l0 = lru_new(0);
  if lru_capacity(&mut l0) != 1 { io.println("lru: cap clamp"); return 32; }

  io.println("smoke_collect_lfu_lru: OK");
  return 0;
}

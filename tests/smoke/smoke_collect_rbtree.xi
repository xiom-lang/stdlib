// XIOM stdlib smoke test - xiom.collect.rbtree
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_rbtree
use xiom.collect.rbtree;
use xiom.io;

fn main() -> Int {
  // --- basic insert/get/contains ---
  var t = rbtree_new();
  if rbtree_size(&t) != 0 { io.println("rb:size0"); return 1; }
  if !rbtree_insert(&mut t, 5, 50) { io.println("rb:ins5"); return 2; }
  if !rbtree_insert(&mut t, 3, 30) { io.println("rb:ins3"); return 3; }
  if !rbtree_insert(&mut t, 7, 70) { io.println("rb:ins7"); return 4; }
  if rbtree_insert(&mut t, 5, 99) { io.println("rb:dup"); return 5; }
  if rbtree_size(&t) != 3 { io.println("rb:size"); return 6; }
  var g5 = rbtree_get(&t, 5);
  if !g5.is_some || g5.value != 50 { io.println("rb:get5"); return 7; }
  var g3 = rbtree_get(&t, 3);
  if !g3.is_some || g3.value != 30 { io.println("rb:get3"); return 8; }
  var miss = rbtree_get(&t, 9);
  if miss.is_some { io.println("rb:miss"); return 9; }
  if !rbtree_contains(&t, 7) { io.println("rb:contains"); return 10; }
  if rbtree_contains(&t, 4) { io.println("rb:contains-miss"); return 11; }

  // --- order traversals ---
  var io3 = rbtree_inorder(&t);
  if io3.len() != 3 || io3[0] != 3 || io3[1] != 5 || io3[2] != 7 { io.println("rb:inorder"); return 12; }
  var mn = rbtree_min(&t);
  if !mn.is_some || mn.value != 3 { io.println("rb:min"); return 13; }
  var mx = rbtree_max(&t);
  if !mx.is_some || mx.value != 7 { io.println("rb:max"); return 14; }

  // --- remove ---
  if !rbtree_remove(&mut t, 3) { io.println("rb:rm3"); return 15; }
  if rbtree_remove(&mut t, 3) { io.println("rb:rm3-again"); return 16; }
  if rbtree_contains(&t, 3) { io.println("rb:rmcontains"); return 17; }
  if rbtree_size(&t) != 2 { io.println("rb:rmsize"); return 18; }
  var io2 = rbtree_inorder(&t);
  if io2.len() != 2 || io2[0] != 5 || io2[1] != 7 { io.println("rb:rminorder"); return 19; }
  // reinsert after delete
  if !rbtree_insert(&mut t, 3, 31) { io.println("rb:reins3"); return 20; }
  var g3b = rbtree_get(&t, 3);
  if !g3b.is_some || g3b.value != 31 { io.println("rb:reinsget"); return 21; }

  // --- preorder/postorder shapes ---
  var pre = rbtree_preorder(&t);
  if pre.len() != 3 { io.println("rb:pren"); return 22; }
  var post = rbtree_postorder(&t);
  if post.len() != 3 { io.println("rb:postn"); return 23; }
  if post[2] != pre[0] { io.println("rb:rootlast"); return 24; }

  // --- stress: interleaved inserts/deletes keep the tree sorted ---
  var t2 = rbtree_new();
  var i: Int = 0;
  while i < 400 {
    if !rbtree_insert(&mut t2, (i * 37) % 401, i) { io.println("rb:stress-ins"); return 25; }
    i = i + 1;
  }
  if rbtree_size(&t2) != 400 { io.println("rb:stress-size"); return 26; }
  i = 0;
  while i < 400 {
    if !rbtree_contains(&t2, (i * 37) % 401) { io.println("rb:stress-c"); return 27; }
    i = i + 1;
  }
  i = 0;
  while i < 200 {
    if !rbtree_remove(&mut t2, (i * 37) % 401) { io.println("rb:stress-rm"); return 28; }
    i = i + 1;
  }
  if rbtree_size(&t2) != 200 { io.println("rb:stress-rmsize"); return 29; }
  var sorted = rbtree_inorder(&t2);
  if sorted.len() != 200 { io.println("rb:sorted-len"); return 30; }
  var j: Int = 1;
  while j < sorted.len() {
    if sorted[j - 1] >= sorted[j] { io.println("rb:sorted-order"); return 31; }
    j = j + 1;
  }
  i = 200;
  while i < 400 {
    if !rbtree_contains(&t2, (i * 37) % 401) { io.println("rb:stress-c2"); return 32; }
    i = i + 1;
  }
  var mn2 = rbtree_min(&t2);
  var mx2 = rbtree_max(&t2);
  if !mn2.is_some || mn2.value != sorted[0] { io.println("rb:min2"); return 33; }
  var last = sorted.len() - 1;
  if !mx2.is_some || mx2.value != sorted[last] { io.println("rb:max2"); return 34; }

  io.println("smoke_collect_rbtree: OK");
  return 0;
}

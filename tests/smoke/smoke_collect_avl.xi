// XIOM stdlib smoke test - xiom.collect.avl
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_avl
use xiom.collect.avl;
use xiom.io;

fn main() -> Int {
  // --- basic insert/contains ---
  var t = avl_new();
  if avl_height(&t) != 0 { io.println("av:h0"); return 1; }
  avl_insert(&mut t, 5);
  avl_insert(&mut t, 3);
  avl_insert(&mut t, 7);
  if !avl_contains(&t, 5) { io.println("av:c5"); return 2; }
  if !avl_contains(&t, 3) { io.println("av:c3"); return 3; }
  if !avl_contains(&t, 7) { io.println("av:c7"); return 4; }
  if avl_contains(&t, 9) { io.println("av:c9"); return 5; }
  var mn = avl_min(&t);
  if !mn.is_some || mn.value != 3 { io.println("av:min"); return 6; }
  var mx = avl_max(&t);
  if !mx.is_some || mx.value != 7 { io.println("av:max"); return 7; }
  if avl_height(&t) != 2 { io.println("av:h"); return 8; }

  // --- rotations keep the tree balanced ---
  var t2 = avl_new();
  avl_insert(&mut t2, 10);
  avl_insert(&mut t2, 20);
  avl_insert(&mut t2, 30);  // left rotation
  if avl_height(&t2) != 2 { io.println("av:lr"); return 9; }
  avl_insert(&mut t2, 5);
  avl_insert(&mut t2, 2);   // right rotation
  if avl_height(&t2) != 3 { io.println("av:rr"); return 10; }
  avl_insert(&mut t2, 15);
  avl_insert(&mut t2, 12);  // double rotation (LR)
  avl_insert(&mut t2, 40);
  avl_insert(&mut t2, 35);  // double rotation (RL)
  var i: Int = 0;
  while i < 50 {
    avl_insert(&mut t2, i * 2 + 1);
    i = i + 1;
  }
  // height of 59 elements must stay logarithmic (balanced)
  if avl_height(&t2) > 10 { io.println("av:bal"); return 11; }
  i = 0;
  while i < 50 {
    if !avl_contains(&t2, i * 2 + 1) { io.println("av:stress-c"); return 12; }
    i = i + 1;
  }

  // --- remove ---
  avl_remove(&mut t2, 5);
  if avl_contains(&t2, 5) { io.println("av:rm"); return 13; }
  avl_remove(&mut t2, 3);
  avl_remove(&mut t2, 7);
  if avl_height(&t2) > 10 { io.println("av:rmbal"); return 14; }
  // remove root and verify balance + membership
  avl_remove(&mut t2, 10);
  if avl_contains(&t2, 10) { io.println("av:rmroot"); return 15; }
  if avl_height(&t2) > 10 { io.println("av:rmrootbal"); return 16; }
  i = 0;
  while i < 50 {
    var v = i * 2 + 1;
    if v != 5 && v != 3 && v != 7 && v != 10 {
      if !avl_contains(&t2, v) { io.println("av:afterrm"); return 17; }
    }
    i = i + 1;
  }
  // remove everything
  var t3 = avl_new();
  i = 0;
  while i < 100 {
    avl_insert(&mut t3, (i * 29) % 107);
    i = i + 1;
  }
  i = 0;
  while i < 100 {
    avl_remove(&mut t3, (i * 29) % 107);
    i = i + 1;
  }
  if avl_contains(&t3, 1) { io.println("av:allempty"); return 18; }
  if avl_height(&t3) != 0 { io.println("av:allempty-h"); return 19; }
  var em = avl_min(&t3);
  if em.is_some { io.println("av:empty-min"); return 20; }
  var ex = avl_max(&t3);
  if ex.is_some { io.println("av:empty-max"); return 21; }
  // duplicates are ignored
  avl_insert(&mut t3, 42);
  avl_insert(&mut t3, 42);
  avl_remove(&mut t3, 42);
  if avl_contains(&t3, 42) { io.println("av:dup"); return 22; }

  io.println("smoke_collect_avl: OK");
  return 0;
}

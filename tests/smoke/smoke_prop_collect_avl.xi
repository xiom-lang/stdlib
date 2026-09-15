// XIOM stdlib property smoke -- xiom.collect.avl
// Deterministic LCG permutation of 512 distinct keys: after random-order
// inserts the tree must contain every key, stay height-bounded (AVL balance),
// report min/max correctly, and empty out cleanly under random-order removal.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_prop_collect_avl
use xiom.collect.avl;
use xiom.io;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn main() -> Int {
  let n = 512;
  var perm: [512]Int;
  var i = 0;
  while i < n {
    perm[i] = i;
    i = i + 1;
  };

  // Fisher-Yates shuffle with the deterministic LCG.
  var seed = 2463534242;
  i = n - 1;
  while i > 0 {
    seed = next_seed(seed);
    var j = seed % (i + 1);
    var tmp = perm[i];
    perm[i] = perm[j];
    perm[j] = tmp;
    i = i - 1;
  };

  // Random-order inserts: membership must hold after every insert.
  var t = avl_new();
  i = 0;
  while i < n {
    avl_insert(&mut t, perm[i]);
    if !avl_contains(&t, perm[i]) { io.println("prop: contains after insert"); return 1; };
    i = i + 1;
  };

  // AVL balance: height <= 1.44 * log2(n + 1) + 1; 16 is a safe bound for 512.
  if avl_height(&t) > 16 { io.println("prop: height bound"); return 2; };

  let mn = avl_min(&t);
  if !mn.is_some || mn.value != 0 { io.println("prop: min"); return 3; };
  let mx = avl_max(&t);
  if !mx.is_some || mx.value != 511 { io.println("prop: max"); return 4; };

  // Random-order removal: membership must drop and the tree must survive.
  i = 0;
  while i < n {
    avl_remove(&mut t, perm[i]);
    if avl_contains(&t, perm[i]) { io.println("prop: contains after remove"); return 5; };
    if avl_height(&t) > 16 { io.println("prop: height after remove"); return 6; };
    i = i + 1;
  };

  if avl_height(&t) != 0 { io.println("prop: not empty"); return 7; };
  let empty_min = avl_min(&t);
  if empty_min.is_some { io.println("prop: min after empty"); return 8; };

  io.println("smoke_prop_collect_avl OK");
  return 0;
}

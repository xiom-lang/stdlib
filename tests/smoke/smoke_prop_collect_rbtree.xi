// smoke_prop_collect_rbtree.xi -- red-black tree property smoke.
// 512 distinct keys in a deterministic (LCG Fisher-Yates) shuffle:
// insert order must not matter -- inorder must always be strictly ascending,
// size/get/contains/min/max must agree, removals must keep the BST order,
// and preorder/postorder must contain every remaining key exactly once.
// Returns 0 on success.

module smoke_prop_collect_rbtree
use xiom.collect.rbtree;
use xiom.io;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn inorder_is_sorted(v: &Vec[Int]) -> Bool {
  var i = 1;
  while i < v.len() {
    if v[i] <= v[i - 1] { return false; };
    i = i + 1;
  };
  true
}

fn main() -> Int {
  let n = 512;
  var perm: [512]Int;
  var i = 0;
  while i < n {
    perm[i] = i;
    i = i + 1;
  };
  var seed = 987654321;
  i = n - 1;
  while i > 0 {
    seed = next_seed(seed);
    let j = seed % (i + 1);
    let tmp = perm[i];
    perm[i] = perm[j];
    perm[j] = tmp;
    i = i - 1;
  };

  var t = rbtree_new();
  i = 0;
  while i < n {
    let ins = rbtree_insert(&mut t, perm[i], perm[i] * 3);
    if !ins { io.println("rbt prop: dup insert"); return 1; };
    if !rbtree_contains(&t, perm[i]) { io.println("rbt prop: contains"); return 2; };
    if rbtree_size(&t) != i + 1 { io.println("rbt prop: size"); return 3; };
    i = i + 1;
  };

  let ord = rbtree_inorder(&t);
  if ord.len() != n { io.println("rbt prop: inorder len"); return 4; };
  if !inorder_is_sorted(&ord) { io.println("rbt prop: inorder unsorted"); return 5; };
  i = 0;
  while i < n {
    if ord[i] != i { io.println("rbt prop: inorder gap"); return 6; };
    i = i + 1;
  };

  let mn = rbtree_min(&t);
  if !mn.is_some || mn.value != 0 { io.println("rbt prop: min"); return 7; };
  let mx = rbtree_max(&t);
  if !mx.is_some || mx.value != 511 { io.println("rbt prop: max"); return 8; };

  let pre = rbtree_preorder(&t);
  let post = rbtree_postorder(&t);
  if pre.len() != n || post.len() != n { io.println("rbt prop: traversal len"); return 9; };

  // Remove even keys in shuffled order; order and size must hold throughout.
  var removed = 0;
  i = 0;
  while i < n {
    let k = perm[i];
    if k % 2 == 0 {
      if !rbtree_remove(&mut t, k) { io.println("rbt prop: remove"); return 10; };
      if rbtree_contains(&t, k) { io.println("rbt prop: still there"); return 11; };
      removed = removed + 1;
      if rbtree_size(&t) != n - removed { io.println("rbt prop: size after remove"); return 12; };
      let o2 = rbtree_inorder(&t);
      if !inorder_is_sorted(&o2) { io.println("rbt prop: order after remove"); return 13; };
    };
    i = i + 1;
  };

  let final_ord = rbtree_inorder(&t);
  if final_ord.len() != n - removed { io.println("rbt prop: final len"); return 14; };
  i = 0;
  while i < final_ord.len() {
    if final_ord[i] != 2 * i + 1 { io.println("rbt prop: final odds"); return 15; };
    i = i + 1;
  };

  io.println("smoke_prop_collect_rbtree OK");
  return 0;
}

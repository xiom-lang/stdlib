// XIOM stdlib smoke test — xiom.collect.tree + xiom.collect.heap
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_tree
use xiom.collect.tree;
use xiom.collect.heap;

fn main() -> Int {
  // --- BST ---
  var b = xiom.collect.tree.bst_new();
  xiom.collect.tree.bst_insert(&b, 50);
  xiom.collect.tree.bst_insert(&b, 30);
  xiom.collect.tree.bst_insert(&b, 70);
  xiom.collect.tree.bst_insert(&b, 20);
  xiom.collect.tree.bst_insert(&b, 40);
  xiom.collect.tree.bst_insert(&b, 60);
  xiom.collect.tree.bst_insert(&b, 80);
  if !xiom.collect.tree.bst_contains(&b, 40) { return 1; }
  if xiom.collect.tree.bst_contains(&b, 55) { return 2; }
  if xiom.collect.tree.bst_size(&b) != 7 { return 3; }
  var inorder = xiom.collect.tree.bst_inorder(&b);
  if inorder.len() != 7 { return 4; }
  if !(inorder[0] == 20 && inorder[1] == 30 && inorder[2] == 40 && inorder[3] == 50 && inorder[4] == 60 && inorder[5] == 70 && inorder[6] == 80) { return 5; }
  var mn = xiom.collect.tree.bst_min(&b);
  match mn {
    Some(v) => { if v != 20 { return 6; } },
    None => { return 7; },
  };
  var mx = xiom.collect.tree.bst_max(&b);
  match mx {
    Some(v) => { if v != 80 { return 8; } },
    None => { return 9; },
  };
  var removed = xiom.collect.tree.bst_remove(&b, 50);
  if !removed { return 10; }
  if xiom.collect.tree.bst_size(&b) != 6 { return 11; }
  if xiom.collect.tree.bst_contains(&b, 50) { return 12; }
  if !xiom.collect.tree.bst_is_bst(&b) { return 13; }

  // --- AVL ---
  var a = xiom.collect.tree.avl_new();
  var i = 1;
  while i <= 100 {
    xiom.collect.tree.avl_insert(&a, i);
    i = i + 1;
  }
  var h = xiom.collect.tree.avl_height(&a);
  if h <= 0 || h > 20 { return 14; }
  if xiom.collect.tree.avl_size(&a) != 100 { return 15; }
  var ain = xiom.collect.tree.avl_inorder(&a);
  if ain.len() != 100 { return 16; }
  i = 1;
  while i < ain.len() {
    if ain[i - 1] > ain[i] { return 17; }
    i = i + 1;
  }

  // --- Pairing heap ---
  var ph = xiom.collect.heap.pheap_new();
  xiom.collect.heap.pheap_insert(&ph, 5);
  xiom.collect.heap.pheap_insert(&ph, 3);
  xiom.collect.heap.pheap_insert(&ph, 8);
  xiom.collect.heap.pheap_insert(&ph, 1);
  xiom.collect.heap.pheap_insert(&ph, 9);
  if xiom.collect.heap.pheap_size(&ph) != 5 { return 18; }
  var p1 = xiom.collect.heap.pheap_extract_min(&ph);
  match p1 {
    Some(v) => { if v != 1 { return 19; } },
    None => { return 20; },
  };
  var p2 = xiom.collect.heap.pheap_extract_min(&ph);
  match p2 {
    Some(v) => { if v != 3 { return 21; } },
    None => { return 22; },
  };
  if xiom.collect.heap.pheap_size(&ph) != 3 { return 23; }
  var pfm = xiom.collect.heap.pheap_find_min(&ph);
  match pfm {
    Some(v) => { if v != 5 { return 24; } },
    None => { return 25; },
  };

  // --- Fibonacci heap ---
  var fh = xiom.collect.heap.fib_heap_new();
  xiom.collect.heap.fib_heap_insert(&fh, 5); // node 0
  xiom.collect.heap.fib_heap_insert(&fh, 3); // node 1
  xiom.collect.heap.fib_heap_insert(&fh, 8); // node 2
  xiom.collect.heap.fib_heap_insert(&fh, 1); // node 3
  xiom.collect.heap.fib_heap_insert(&fh, 9); // node 4
  var ffm = xiom.collect.heap.fib_heap_find_min(&fh);
  match ffm {
    Some(v) => { if v != 1 { return 26; } },
    None => { return 27; },
  };
  var fe = xiom.collect.heap.fib_heap_extract_min(&fh);
  match fe {
    Some(v) => { if v != 1 { return 28; } },
    None => { return 29; },
  };
  if xiom.collect.heap.fib_heap_size(&fh) != 4 { return 30; }
  // node 2 currently holds key 8; decrease it to 0 and verify extraction order
  if !xiom.collect.heap.fib_heap_decrease_key(&fh, 2, 0) { return 31; }
  var fd = xiom.collect.heap.fib_heap_find_min(&fh);
  match fd {
    Some(v) => { if v != 0 { return 32; } },
    None => { return 33; },
  };
  var fe2 = xiom.collect.heap.fib_heap_extract_min(&fh);
  match fe2 {
    Some(v) => { if v != 0 { return 34; } },
    None => { return 35; },
  };
  if xiom.collect.heap.fib_heap_size(&fh) != 3 { return 36; }
  if xiom.collect.heap.fib_heap_is_empty(&fh) { return 37; }
  return 0;
}

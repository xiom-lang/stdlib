// XIOM stdlib property smoke -- xiom.collect.heap (pairing heap)
// 512 deterministic LCG values: extract_min must yield them in non-decreasing
// order, size must track inserts/extracts exactly, and the heap must empty.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_prop_collect_heap
use xiom.collect.heap;
use xiom.io;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn main() -> Int {
  let n = 512;
  var h = pheap_new();
  var seed = 999983;
  var i = 0;
  while i < n {
    seed = next_seed(seed);
    pheap_insert(&mut h, seed % 1000);
    if pheap_size(&h) != i + 1 { io.println("prop: size after insert"); return 1; };
    i = i + 1;
  };

  var prev = -1;
  i = 0;
  while i < n {
    let m = pheap_extract_min(&h);
    if !m.is_some { io.println("prop: extract empty"); return 2; };
    if m.value < prev { io.println("prop: order"); return 3; };
    prev = m.value;
    if pheap_size(&h) != n - i - 1 { io.println("prop: size after extract"); return 4; };
    i = i + 1;
  };

  if !pheap_is_empty(&h) { io.println("prop: not empty"); return 5; };
  let none_min = pheap_find_min(&h);
  if none_min.is_some { io.println("prop: min on empty"); return 6; };

  io.println("smoke_prop_collect_heap OK");
  return 0;
}

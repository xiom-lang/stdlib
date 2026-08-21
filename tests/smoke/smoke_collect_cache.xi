// XIOM stdlib smoke test -- xiom.collect.cache / hash / queue / graph
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_collect_cache
use xiom.collect.cache;
use xiom.collect.hash;
use xiom.collect.queue;
use xiom.collect.graph;
use xiom.encoding;

fn make_key(i: Int) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  out.push((97 + (i % 26)) as UInt8);
  out.push((97 + ((i / 26) % 26)) as UInt8);
  out.push((i % 7) as UInt8);
  return out;
}

fn main() -> Int {
  // --- LRU ---
  var lc = xiom.collect.cache.lru_new(3);
  xiom.collect.cache.lru_put(&lc, 1, 10);
  xiom.collect.cache.lru_put(&lc, 2, 20);
  xiom.collect.cache.lru_put(&lc, 3, 30);
  if xiom.collect.cache.lru_size(&lc) != 3 { return 1; }
  var g1 = xiom.collect.cache.lru_get(&lc, 1);
  match g1 {
    Some(v) => { if v != 10 { return 2; } },
    None => { return 3; },
  };
  xiom.collect.cache.lru_put(&lc, 4, 40);
  if xiom.collect.cache.lru_size(&lc) != 3 { return 4; }
  if xiom.collect.cache.lru_contains(&lc, 2) { return 5; }
  var g3 = xiom.collect.cache.lru_get(&lc, 3);
  match g3 {
    Some(v) => { if v != 30 { return 6; } },
    None => { return 7; },
  };
  xiom.collect.cache.lru_put(&lc, 5, 50);
  if xiom.collect.cache.lru_size(&lc) != 3 { return 8; }
  if xiom.collect.cache.lru_contains(&lc, 1) { return 9; }
  if xiom.collect.cache.lru_capacity(&lc) != 3 { return 10; }

  // --- LFU ---
  var lf = xiom.collect.cache.lfu_new(2);
  xiom.collect.cache.lfu_put(&lf, 1, 10);
  xiom.collect.cache.lfu_put(&lf, 2, 20);
  var f1a = xiom.collect.cache.lfu_get(&lf, 1);
  match f1a {
    Some(v) => { if v != 10 { return 11; } },
    None => { return 12; },
  };
  var f1b = xiom.collect.cache.lfu_get(&lf, 1);
  match f1b {
    Some(v) => { if v != 10 { return 13; } },
    None => { return 14; },
  };
  var f2 = xiom.collect.cache.lfu_get(&lf, 2);
  match f2 {
    Some(v) => { if v != 20 { return 15; } },
    None => { return 16; },
  };
  xiom.collect.cache.lfu_put(&lf, 3, 30);
  if xiom.collect.cache.lfu_contains(&lf, 2) { return 17; }
  if xiom.collect.cache.lfu_size(&lf) != 2 { return 18; }

  // --- Bloom filter ---
  var bf = xiom.collect.hash.bloom_new(256, 4);
  var hello = xiom.encoding.utf8_encode("hello");
  var world = xiom.encoding.utf8_encode("world");
  xiom.collect.hash.bloom_insert(&bf, &hello);
  xiom.collect.hash.bloom_insert(&bf, &world);
  if !xiom.collect.hash.bloom_maybe_contains(&bf, &hello) { return 19; }
  if !xiom.collect.hash.bloom_maybe_contains(&bf, &world) { return 20; }
  var i = 0;
  while i < 100 {
    var k = make_key(i);
    xiom.collect.hash.bloom_insert(&bf, &k);
    i = i + 1;
  }
  i = 0;
  while i < 100 {
    var k = make_key(i);
    if !xiom.collect.hash.bloom_maybe_contains(&bf, &k) { return 21; }
    i = i + 1;
  }

  // --- LhMap ---
  var m = xiom.collect.hash.lhmap_new();
  xiom.collect.hash.lhmap_put(&m, 1, 10);
  xiom.collect.hash.lhmap_put(&m, 2, 20);
  xiom.collect.hash.lhmap_put(&m, 1, 99);
  if xiom.collect.hash.lhmap_size(&m) != 2 { return 22; }
  var mg = xiom.collect.hash.lhmap_get(&m, 1);
  match mg {
    Some(v) => { if v != 99 { return 23; } },
    None => { return 24; },
  };
  var ks = xiom.collect.hash.lhmap_keys_in_order(&m);
  if ks.len() != 2 { return 25; }
  if !(ks[0] == 1 && ks[1] == 2) { return 26; }
  if !xiom.collect.hash.lhmap_remove(&m, 2) { return 27; }
  if xiom.collect.hash.lhmap_size(&m) != 1 { return 28; }

  // --- WorkQueue ---
  var q = xiom.collect.queue.workqueue_new();
  xiom.collect.queue.workqueue_push(&q, 1);
  xiom.collect.queue.workqueue_push(&q, 2);
  xiom.collect.queue.workqueue_push(&q, 3);
  var q1 = xiom.collect.queue.workqueue_pop(&q);
  match q1 {
    Some(v) => { if v != 1 { return 29; } },
    None => { return 30; },
  };
  var q2 = xiom.collect.queue.workqueue_peek(&q);
  match q2 {
    Some(v) => { if v != 2 { return 31; } },
    None => { return 32; },
  };
  if xiom.collect.queue.workqueue_len(&q) != 2 { return 33; }
  var q3 = xiom.collect.queue.workqueue_pop(&q);
  match q3 {
    Some(v) => { if v != 2 { return 34; } },
    None => { return 35; },
  };
  var q4 = xiom.collect.queue.workqueue_pop(&q);
  match q4 {
    Some(v) => { if v != 3 { return 36; } },
    None => { return 37; },
  };
  if !xiom.collect.queue.workqueue_is_empty(&q) { return 38; }

  // --- Deque ---
  var d = xiom.collect.queue.deque_new();
  xiom.collect.queue.deque_push_back(&d, 1);
  xiom.collect.queue.deque_push_back(&d, 2);
  xiom.collect.queue.deque_push_front(&d, 0);
  var d1 = xiom.collect.queue.deque_pop_front(&d);
  match d1 {
    Some(v) => { if v != 0 { return 39; } },
    None => { return 40; },
  };
  var d2 = xiom.collect.queue.deque_pop_back(&d);
  match d2 {
    Some(v) => { if v != 2 { return 41; } },
    None => { return 42; },
  };
  var d3 = xiom.collect.queue.deque_pop_back(&d);
  match d3 {
    Some(v) => { if v != 1 { return 43; } },
    None => { return 44; },
  };
  if !xiom.collect.queue.deque_is_empty(&d) { return 45; }

  // --- Graph ---
  var g = xiom.collect.graph.graph_new(5);
  xiom.collect.graph.graph_add_edge(&g, 0, 1);
  xiom.collect.graph.graph_add_edge(&g, 1, 2);
  xiom.collect.graph.graph_add_edge(&g, 2, 3);
  xiom.collect.graph.graph_add_edge(&g, 3, 4);
  if !xiom.collect.graph.graph_path_exists(&g, 0, 4) { return 46; }
  if xiom.collect.graph.graph_has_cycle(&g) { return 47; }
  var bfso = xiom.collect.graph.graph_bfs(&g, 0);
  if bfso.len() != 5 { return 48; }
  if !(bfso[0] == 0 && bfso[1] == 1 && bfso[2] == 2 && bfso[3] == 3 && bfso[4] == 4) { return 49; }
  if xiom.collect.graph.graph_connected_components(&g) != 1 { return 50; }
  xiom.collect.graph.graph_add_edge(&g, 0, 2);
  if !xiom.collect.graph.graph_has_cycle(&g) { return 51; }

  // --- UnionFind ---
  var uf = xiom.collect.graph.uf_new(5);
  if !xiom.collect.graph.uf_union(&uf, 0, 1) { return 52; }
  if !xiom.collect.graph.uf_union(&uf, 1, 2) { return 53; }
  if !xiom.collect.graph.uf_connected(&uf, 0, 2) { return 54; }
  if xiom.collect.graph.uf_count(&uf) != 3 { return 55; }
  if !xiom.collect.graph.uf_union(&uf, 3, 4) { return 56; }
  if xiom.collect.graph.uf_count(&uf) != 2 { return 57; }

  return 0;
}

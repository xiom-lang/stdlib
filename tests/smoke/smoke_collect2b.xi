module smoke_collect2b
use xiom.io;
use xiom.collect.trie;
use xiom.collect.cuckoo;
use xiom.collect.fenwick;
use xiom.collect.objectpool;
use xiom.collect.queue;
use xiom.collect.cache;

// NOTE: trie must NOT be combined with skiplist in one program — dual
// Option-payload instantiations trigger a compiler stack-cookie fast-fail
// (COMPILER_BUGS.md BUG 16). skiplist lives in smoke_collect2a.

fn main() -> Int {
  // ── Trie ──
  var tr = xiom.collect.trie.trie_new();
  if !xiom.collect.trie.trie_insert(&mut tr, "hello") { return 1; }
  if !xiom.collect.trie.trie_insert(&mut tr, "help") { return 2; }
  if !xiom.collect.trie.trie_insert(&mut tr, "world") { return 3; }
  if xiom.collect.trie.trie_insert(&mut tr, "hello") { return 4; }  // dup
  if xiom.collect.trie.trie_insert(&mut tr, "Hello") { return 5; }  // uppercase rejected
  if !xiom.collect.trie.trie_contains(&tr, "help") { return 6; }
  if xiom.collect.trie.trie_contains(&tr, "hel") { return 7; }  // prefix is not a word
  if xiom.collect.trie.trie_size(&tr) != 3 { return 8; }
  var comp = xiom.collect.trie.trie_complete(&tr, "hel");
  if comp.len() != 2 { return 9; }
  if comp[0] != "hello" || comp[1] != "help" { return 10; }
  if !xiom.collect.trie.trie_has_prefix(&tr, "he") { return 11; }
  if xiom.collect.trie.trie_has_prefix(&tr, "xyz") { return 12; }
  if !xiom.collect.trie.trie_remove(&tr, "help") { return 13; }
  if xiom.collect.trie.trie_contains(&tr, "help") { return 14; }
  if xiom.collect.trie.trie_size(&tr) != 2 { return 15; }

  // ── CuckooMap ──
  var cm = xiom.collect.cuckoo.cuckoo_new(8);
  var ck: Int = 0;
  while ck < 200 {
    xiom.collect.cuckoo.cuckoo_put(&mut cm, ck * 13 + 1, ck);
    ck = ck + 1;
  }
  var g = xiom.collect.cuckoo.cuckoo_get(&cm, 13 * 199 + 1);
  if !g.is_some || g.value != 199 { return 16; }

  // ── FenwickTree ──
  var ft = xiom.collect.fenwick.fenwick_new(8);
  xiom.collect.fenwick.fenwick_add(&mut ft, 2, 3);
  xiom.collect.fenwick.fenwick_add(&mut ft, 5, 7);
  if xiom.collect.fenwick.fenwick_range(&ft, 1, 5) != 10 { return 17; }

  // ── ObjectPool ──
  var pl = xiom.collect.objectpool.pool_new(3);
  var h0 = xiom.collect.objectpool.pool_acquire(&mut pl);
  var h1 = xiom.collect.objectpool.pool_acquire(&mut pl);
  if !h0.is_some || h0.value != 0 { return 18; }
  if !h1.is_some || h1.value != 1 { return 19; }
  if !xiom.collect.objectpool.pool_release(&mut pl, 0) { return 20; }
  var h2 = xiom.collect.objectpool.pool_acquire(&mut pl);
  if !h2.is_some || h2.value != 0 { return 21; }

  // ── SpscRing ──
  var rq = xiom.collect.queue.spsc_ring_new(2);
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 7) { return 22; }
  var q1 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  if !q1.is_some || q1.value != 7 { return 23; }

  // ── ArcCache ──
  var ac = xiom.collect.cache.arc_new(2);
  xiom.collect.cache.arc_put(&mut ac, 1, 100);
  xiom.collect.cache.arc_put(&mut ac, 2, 200);
  var ag = xiom.collect.cache.arc_get(&mut ac, 1);
  if !ag.is_some || ag.value != 100 { return 24; }
  xiom.collect.cache.arc_put(&mut ac, 3, 300);
  if xiom.collect.cache.arc_contains(&ac, 2) { return 25; }
  if !xiom.collect.cache.arc_contains(&ac, 3) { return 26; }

  io.println("smoke_collect2b: all 26 checks passed");
  return 0;
}

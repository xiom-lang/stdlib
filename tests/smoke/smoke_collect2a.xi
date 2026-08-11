module smoke_collect2a
use xiom.io;
use xiom.collect.skiplist;
use xiom.collect.cuckoo;
use xiom.collect.fenwick;
use xiom.collect.objectpool;
use xiom.collect.queue;
use xiom.collect.cache;

// NOTE: skiplist must NOT be combined with trie in one program — dual
// Option-payload instantiations trigger a compiler stack-cookie fast-fail
// (COMPILER_BUGS.md BUG 16). trie lives in smoke_collect2b.

fn main() -> Int {
  // ── SkipList ──
  var sl = xiom.collect.skiplist.skiplist_new();
  if !xiom.collect.skiplist.skiplist_insert(&mut sl, 5) { return 1; }
  if !xiom.collect.skiplist.skiplist_insert(&mut sl, 1) { return 2; }
  if !xiom.collect.skiplist.skiplist_insert(&mut sl, 9) { return 3; }
  if !xiom.collect.skiplist.skiplist_insert(&mut sl, 3) { return 4; }
  if xiom.collect.skiplist.skiplist_insert(&mut sl, 5) { return 5; }  // dup rejected
  if !xiom.collect.skiplist.skiplist_contains(&sl, 3) { return 6; }
  if xiom.collect.skiplist.skiplist_contains(&sl, 7) { return 7; }
  if xiom.collect.skiplist.skiplist_size(&sl) != 4 { return 8; }
  var mn = xiom.collect.skiplist.skiplist_min(&sl);
  if !mn.is_some || mn.value != 1 { return 9; }
  var mx = xiom.collect.skiplist.skiplist_max(&sl);
  if !mx.is_some || mx.value != 9 { return 10; }
  if !xiom.collect.skiplist.skiplist_remove(&sl, 3) { return 11; }
  if xiom.collect.skiplist.skiplist_remove(&sl, 3) { return 12; }
  if xiom.collect.skiplist.skiplist_size(&sl) != 3 { return 13; }
  if xiom.collect.skiplist.skiplist_contains(&sl, 3) { return 14; }
  var sl2 = xiom.collect.skiplist.skiplist_new();
  var k: Int = 0;
  while k < 200 {
    xiom.collect.skiplist.skiplist_insert(&mut sl2, k * 7 % 211);
    k = k + 1;
  }
  if xiom.collect.skiplist.skiplist_size(&sl2) != 200 { return 15; }
  var k2: Int = 0;
  while k2 < 200 {
    if !xiom.collect.skiplist.skiplist_contains(&sl2, k2 * 7 % 211) { return 16; }
    k2 = k2 + 1;
  }

  // ── CuckooMap ──
  var cm = xiom.collect.cuckoo.cuckoo_new(8);
  var ck: Int = 0;
  while ck < 500 {
    xiom.collect.cuckoo.cuckoo_put(&mut cm, ck * 13 + 1, ck);
    ck = ck + 1;
  }
  if xiom.collect.cuckoo.cuckoo_size(&cm) != 500 { return 17; }
  var ck2: Int = 0;
  while ck2 < 500 {
    if !xiom.collect.cuckoo.cuckoo_contains(&cm, ck2 * 13 + 1) { return 18; }
    var g = xiom.collect.cuckoo.cuckoo_get(&cm, ck2 * 13 + 1);
    if !g.is_some || g.value != ck2 { return 19; }
    ck2 = ck2 + 1;
  }
  xiom.collect.cuckoo.cuckoo_put(&mut cm, 1, 999);
  var g2 = xiom.collect.cuckoo.cuckoo_get(&cm, 1);
  if !g2.is_some || g2.value != 999 { return 20; }
  if !xiom.collect.cuckoo.cuckoo_remove(&cm, 1) { return 21; }
  if xiom.collect.cuckoo.cuckoo_contains(&cm, 1) { return 22; }
  if xiom.collect.cuckoo.cuckoo_size(&cm) != 499 { return 23; }
  var miss = xiom.collect.cuckoo.cuckoo_get(&cm, 1234567);
  if miss.is_some { return 24; }

  // ── FenwickTree ──
  var ft = xiom.collect.fenwick.fenwick_new(10);
  xiom.collect.fenwick.fenwick_add(&mut ft, 3, 5);
  xiom.collect.fenwick.fenwick_add(&mut ft, 7, 2);
  xiom.collect.fenwick.fenwick_add(&mut ft, 10, 4);
  if xiom.collect.fenwick.fenwick_sum(&ft, 3) != 5 { return 25; }
  if xiom.collect.fenwick.fenwick_sum(&ft, 6) != 5 { return 26; }
  if xiom.collect.fenwick.fenwick_sum(&ft, 7) != 7 { return 27; }
  if xiom.collect.fenwick.fenwick_sum(&ft, 10) != 11 { return 28; }
  if xiom.collect.fenwick.fenwick_range(&ft, 4, 7) != 2 { return 29; }
  if xiom.collect.fenwick.fenwick_get(&ft, 7) != 2 { return 30; }
  if xiom.collect.fenwick.fenwick_get(&ft, 5) != 0 { return 31; }
  xiom.collect.fenwick.fenwick_add(&mut ft, 3, -2);
  if xiom.collect.fenwick.fenwick_get(&ft, 3) != 3 { return 32; }

  // ── ObjectPool ──
  var pl = xiom.collect.objectpool.pool_new(4);
  var h0 = xiom.collect.objectpool.pool_acquire(&mut pl);
  var h1 = xiom.collect.objectpool.pool_acquire(&mut pl);
  var h2 = xiom.collect.objectpool.pool_acquire(&mut pl);
  var h3 = xiom.collect.objectpool.pool_acquire(&mut pl);
  var h4 = xiom.collect.objectpool.pool_acquire(&mut pl);
  if !h0.is_some || h0.value != 0 { return 33; }
  if !h1.is_some || h1.value != 1 { return 34; }
  if !h2.is_some || h2.value != 2 { return 35; }
  if !h3.is_some || h3.value != 3 { return 36; }
  if h4.is_some { return 37; }
  if xiom.collect.objectpool.pool_in_use(&pl) != 4 { return 38; }
  if !xiom.collect.objectpool.pool_release(&mut pl, 2) { return 39; }
  if xiom.collect.objectpool.pool_release(&mut pl, 2) { return 40; }
  if xiom.collect.objectpool.pool_release(&mut pl, 9) { return 41; }
  var h5 = xiom.collect.objectpool.pool_acquire(&mut pl);
  if !h5.is_some || h5.value != 2 { return 42; }
  if xiom.collect.objectpool.pool_available(&pl) != 0 { return 43; }

  // ── SpscRing ──
  var rq = xiom.collect.queue.spsc_ring_new(4);
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 10) { return 44; }
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 20) { return 45; }
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 30) { return 46; }
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 40) { return 47; }
  if xiom.collect.queue.spsc_ring_push(&mut rq, 50) { return 48; }  // full
  if xiom.collect.queue.spsc_ring_len(&rq) != 4 { return 49; }
  var p1 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  var p2 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  if !p1.is_some || p1.value != 10 { return 50; }
  if !p2.is_some || p2.value != 20 { return 51; }
  if !xiom.collect.queue.spsc_ring_push(&mut rq, 50) { return 52; }
  var p3 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  var p4 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  var p5 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  if !p3.is_some || p3.value != 30 { return 53; }
  if !p4.is_some || p4.value != 40 { return 54; }
  if !p5.is_some || p5.value != 50 { return 55; }
  var p6 = xiom.collect.queue.spsc_ring_pop(&mut rq);
  if p6.is_some { return 56; }
  if !xiom.collect.queue.spsc_ring_is_empty(&rq) { return 57; }

  // ── ArcCache ──
  var ac = xiom.collect.cache.arc_new(3);
  xiom.collect.cache.arc_put(&mut ac, 1, 100);
  xiom.collect.cache.arc_put(&mut ac, 2, 200);
  xiom.collect.cache.arc_put(&mut ac, 3, 300);
  if xiom.collect.cache.arc_size(&ac) != 3 { return 58; }
  var ag = xiom.collect.cache.arc_get(&mut ac, 2);
  if !ag.is_some || ag.value != 200 { return 59; }
  xiom.collect.cache.arc_get(&mut ac, 2);
  xiom.collect.cache.arc_get(&mut ac, 2);
  xiom.collect.cache.arc_put(&mut ac, 4, 400);
  if xiom.collect.cache.arc_contains(&ac, 1) { return 60; }
  if !xiom.collect.cache.arc_contains(&ac, 2) { return 61; }
  if !xiom.collect.cache.arc_contains(&ac, 4) { return 62; }
  xiom.collect.cache.arc_put(&mut ac, 2, 222);
  var ag2 = xiom.collect.cache.arc_get(&mut ac, 2);
  if !ag2.is_some || ag2.value != 222 { return 63; }
  if xiom.collect.cache.arc_size(&ac) != 3 { return 64; }
  xiom.collect.cache.arc_put(&mut ac, 1, 111);
  if !xiom.collect.cache.arc_contains(&ac, 1) { return 65; }
  var ag3 = xiom.collect.cache.arc_get(&mut ac, 1);
  if !ag3.is_some || ag3.value != 111 { return 66; }

  io.println("smoke_collect2a: all 66 checks passed");
  return 0;
}

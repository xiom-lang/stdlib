// p_wave193_collect_contracts.xi -- wave 193 lock: collect/thread/compress clauses
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime requires/ensures clauses, so a
// clause that is false on a real return aborts this probe. Rows (0 = all hold):
//  1  -- bitset: fill sets exactly nbits bits; out-of-range set/clear no-op;
//        in-place and_into stays within the universe; counter add/get agree
//  2  -- dense: duplicate add is a no-op; iter length equals size
//  3  -- hamt: insert -> contains/get, remove clears; get/contains agree
//  4  -- interval tree: insert keeps the start point covered; query bounds
//  5  -- segment tree: vacuous ranges return the sum/min/max identities
//  6  -- threadpool: submit/join restore the deterministic counters
//  7  -- thread-local raw keys: set/get round-trip and absent-key zero
//  8  -- huffman: container >= 260 bytes and round-trips
//  9  -- lz77: output bound, round-trip, token/match ranges
// Returns 0 when every case holds.

module p_wave193_collect_contracts

use xiom.collect.bitset;
use xiom.collect.concurrent;
use xiom.collect.dense;
use xiom.collect.hamt;
use xiom.collect.interval;
use xiom.collect.segment;
use xiom.collect.threadpool;
use xiom.thread.local;
use xiom.compress.huffman;
use xiom.compress.lz77;

fn noop() {}

fn main() -> Int {
  // 1: bitset fill/count and bounds.
  var bs = bitset.bitset_new(70);
  bitset.bitset_fill(&mut bs);
  if bitset.bitset_count(&bs) != 70 { return 1; }
  if bitset.bitset_count(&bs) != bitset.bitset_len(&bs) { return 2; }
  if bitset.bitset_set(&bs, 70) { return 3; }
  if bitset.bitset_set(&bs, -1) { return 4; }
  if !bitset.bitset_clear(&mut bs, 3) { return 5; }
  if bitset.bitset_get(&bs, 3) { return 6; }
  var mask = bitset.bitset_new(70);
  if !bitset.bitset_set(&mut mask, 0) { return 51; }
  if !bitset.bitset_and_into(&mut bs, &mask) { return 52; }
  if bitset.bitset_count(&bs) != 1 { return 53; }
  var cc = concurrent.concurrent_counter_new();
  concurrent.ccounter_add(&mut cc, 5);
  if concurrent.ccounter_get(&cc) != 5 { return 54; }

  // 2: dense set dedup and iteration length.
  var ds = dense.dense_set_new();
  dense.dense_add(&mut ds, 5);
  dense.dense_add(&mut ds, 5);
  dense.dense_add(&mut ds, -1);
  if dense.dense_size(&ds) != 1 { return 7; }
  if dense.dense_iter(&ds).len() != dense.dense_size(&ds) { return 8; }
  dense.dense_remove(&mut ds, 5);
  if dense.dense_contains(&ds, 5) { return 9; }
  if dense.dense_size(&ds) != 0 { return 10; }

  // 3: HAMT insert/get/contains/remove agreement.
  var hm = hamt.hamt_new();
  if hamt.hamt_size(&hm) != 0 { return 11; }
  if !hamt.hamt_insert(&mut hm, 7, 70) { return 12; }
  if !hamt.hamt_contains(&hm, 7) { return 13; }
  var hv = hamt.hamt_get(&hm, 7);
  if !hv.is_some || hv.value != 70 { return 14; }
  if hamt.hamt_size(&hm) != 1 { return 15; }
  if !hamt.hamt_remove(&mut hm, 7) { return 16; }
  if hamt.hamt_contains(&hm, 7) { return 17; }
  if hamt.hamt_size(&hm) != 0 { return 18; }

  // 4: interval tree containment and query bounds.
  var it = interval.interval_tree_new();
  interval.interval_insert(&mut it, 1, 5, 42);
  if !interval.interval_contains_point(&it, 3) { return 19; }
  var iq = interval.interval_query(&it, 3);
  if iq.len() != 1 { return 20; }
  if iq.len() > interval.interval_size(&it) { return 21; }
  if !interval.interval_overlaps(&it, 5, 9) { return 22; }
  if !interval.interval_remove(&mut it, 1, 5) { return 23; }
  if interval.interval_contains_point(&it, 3) { return 24; }
  if interval.interval_size(&it) != 0 { return 25; }

  // 5: segment tree identities on empty clamps.
  var sg = segment.segtree_new(4);
  var vals = Vec[Int].new();
  vals.push(3); vals.push(1); vals.push(4); vals.push(2);
  segment.segtree_build(&mut sg, &vals);
  if segment.segtree_size(&sg) != 4 { return 26; }
  if segment.segtree_query_sum(&sg, 0, 3) != 10 { return 27; }
  if segment.segtree_query_min(&sg, 0, 3) != 1 { return 28; }
  if segment.segtree_query_max(&sg, 0, 3) != 4 { return 29; }
  if segment.segtree_query_sum(&sg, 3, 0) != 0 { return 30; }
  if segment.segtree_query_min(&sg, 9, 12) != 9223372036854775807 { return 31; }
  if segment.segtree_query_max(&sg, 9, 12) != -9223372036854775807 - 1 { return 32; }

  // 6: threadpool deterministic assignment bookkeeping.
  var tp = threadpool.thread_pool_new(2);
  if !threadpool.pool_submit(&mut tp, noop) { return 33; }
  if threadpool.pool_busy_count(&tp) != 1 { return 34; }
  threadpool.pool_join(&mut tp);
  if threadpool.pool_busy_count(&tp) != 0 { return 35; }
  if threadpool.pool_idle_count(&tp) != 2 { return 36; }
  if threadpool.pool_submit(&mut tp, noop) == false { return 37; }
  threadpool.pool_shutdown(&mut tp);

  // 7: raw thread-local key round-trip.
  local.tls_key_set(5, 99);
  if local.tls_key_get(5) != 99 { return 38; }
  if local.tls_key_get(6) != 0 { return 39; }

  // 8: huffman container size and round-trip.
  var data = Vec[UInt8].new();
  data.push(65); data.push(65); data.push(66); data.push(67);
  var packed = huffman.huffman_compress(&data);
  if packed.len() < 260 { return 40; }
  var hd = huffman.huffman_decompress(&packed);
  if !hd.is_ok { return 41; }
  if hd.value.len() != data.len() { return 42; }
  if hd.value[0] != 65 || hd.value[2] != 66 { return 43; }

  // 9: lz77 output bound, round-trip and token ranges.
  var lz = lz77.lz77_compress(&data);
  if lz.len() > 2 * data.len() { return 44; }
  var ld = lz77.lz77_decompress(&lz);
  if !ld.is_ok { return 45; }
  if ld.value.len() != data.len() { return 46; }
  if ld.value[3] != 67 { return 47; }
  var m = lz77.lz77_find_longest_match(&data, 2, 16);
  if m.0 < 0 || m.0 > 258 { return 48; }
  if m.0 == 0 && m.1 != 0 { return 49; }
  var tok = lz77.lz77_token_encode(300, 5);
  var td = lz77.lz77_token_decode(tok);
  if td.0 != 300 || td.1 != 5 { return 50; }

  return 0;
}

// p_wave167_shapes.xi -- wave 167 lock: collect/collections wishlist rows
// (docs/STDLIB-WISHLIST.md rows 3, 5, 6, 13, 15, 18, 21, 38, 39, 43).
// New module faces (all xiom.collect):
//   xiom.collect.mailbox   -- row 3  keyed FIFO mailboxes (non-blocking)
//   xiom.collect.eventlog  -- row 5  append-only event log + cursors
//   xiom.collect.composite -- row 6  composite-key (Int-tuple) map
//   xiom.collect.vecops    -- rows 13/21/39  vec copy / pop ergonomics / truncation
//   xiom.collect.groupfold -- row 15 group-by-key running aggregate fold
//   xiom.collect.bitset    -- row 18 bit-set dataflow primitives
//   xiom.collect.vecstr    -- row 38 Vec[Str] helpers
//   xiom.collect.stringmap -- row 43 Str -> Str map (companion type)
// Rows (0 = all hold):
//  1 -- mailboxes: FIFO per key, peek, drain, bounded cap, keys order
//  2 -- eventlog: sequence numbers, cursor-at-end, read-new-since,
//       cursor_at, poll, read_range clamps
//  3 -- composite keys: ckmap put/get/update/remove, key-eq/key-hash pair,
//       arena iteration, growth re-link
//  4 -- vec copy: Int/Str/UInt8 copies are independent, same order
//  5 -- group fold: OHLCV bucket (first/last/min/max/sum/count/avg),
//       missing-key Option shapes, first-seen key order
//  6 -- bitsets: set/get/clear/count/next_set/to_vec, or/and/andnot,
//       subset/equal, in-place or_into/and_into changed flags, fill mask
//  7 -- pop ergonomics: pop_or / last_or / pop_checked (Option face)
//  8 -- Vec[Str]: contains/index_of/last_index_of/equal/copy/unique/join
//  9 -- truncation: truncate_to clamps (negative/oversize), drop_last count
// 10 -- Str -> Str map: put/update/get/remove, entry iteration, growth
// Setup failures use 20+.

module p_wave167_shapes

use xiom.collect.mailbox;
use xiom.collect.eventlog;
use xiom.collect.composite;
use xiom.collect.stringmap;
use xiom.collect.vecops;
use xiom.collect.vecstr;
use xiom.collect.groupfold;
use xiom.collect.bitset;

fn main() -> Int {
  // Row 1: keyed FIFO mailboxes.
  var mb = mailbox.mailboxes_new();
  if mailbox.mailboxes_key_count(&mb) != 0 { return 1; }
  if mailbox.mailboxes_total_len(&mb) != 0 { return 1; }
  mailbox.mailboxes_send(&mut mb, 1, 10);
  mailbox.mailboxes_send(&mut mb, 1, 20);
  mailbox.mailboxes_send(&mut mb, 2, 99);
  if mailbox.mailboxes_len(&mb, 1) != 2 { return 1; }
  if mailbox.mailboxes_len(&mb, 2) != 1 { return 1; }
  if mailbox.mailboxes_len(&mb, 3) != 0 { return 1; }
  if !mailbox.mailboxes_is_empty(&mb, 3) { return 1; }
  if mailbox.mailboxes_total_len(&mb) != 3 { return 1; }
  if mailbox.mailboxes_key_count(&mb) != 2 { return 1; }
  if !mailbox.mailboxes_has_key(&mb, 2) { return 1; }
  var pk = mailbox.mailboxes_peek(&mb, 1);
  if !pk.is_some { return 1; }
  if pk.value != 10 { return 1; }
  if mailbox.mailboxes_len(&mb, 1) != 2 { return 1; }
  var r1 = mailbox.mailboxes_recv(&mut mb, 1);
  if !r1.is_some { return 1; }
  if r1.value != 10 { return 1; }
  var r2 = mailbox.mailboxes_recv(&mut mb, 1);
  if !r2.is_some { return 1; }
  if r2.value != 20 { return 1; }
  var r3 = mailbox.mailboxes_recv(&mut mb, 1);
  if r3.is_some { return 1; }
  var r4 = mailbox.mailboxes_recv(&mut mb, 3);
  if r4.is_some { return 1; }
  if mailbox.mailboxes_has_key(&mb, 3) { return 1; }
  var dr = mailbox.mailboxes_drain(&mut mb, 2);
  if dr.len() != 1 { return 1; }
  if dr[0] != 99 { return 1; }
  if mailbox.mailboxes_len(&mb, 2) != 0 { return 1; }
  if mailbox.mailboxes_total_len(&mb) != 0 { return 1; }
  // bounded send: cap 1 accepts once, then refuses and leaves state alone.
  if !mailbox.mailboxes_send_bounded(&mut mb, 2, 7, 1) { return 1; }
  if mailbox.mailboxes_send_bounded(&mut mb, 2, 8, 1) { return 1; }
  if mailbox.mailboxes_len(&mb, 2) != 1 { return 1; }
  var dr2 = mailbox.mailboxes_drain(&mut mb, 2);
  if dr2.len() != 1 { return 1; }
  if dr2[0] != 7 { return 1; }
  var ks = mailbox.mailboxes_keys(&mb);
  if ks.len() != 2 { return 1; }
  if ks[0] != 1 { return 1; }
  if ks[1] != 2 { return 1; }
  var dmiss = mailbox.mailboxes_drain(&mut mb, 42);
  if dmiss.len() != 0 { return 1; }

  // Row 2: event-log cursors.
  var el = eventlog.eventlog_new();
  if eventlog.eventlog_len(&el) != 0 { return 2; }
  if eventlog.eventlog_last_seq(&el) != 0 - 1 { return 2; }
  if eventlog.eventlog_append(&mut el, 5) != 0 { return 2; }
  if eventlog.eventlog_append(&mut el, 6) != 1 { return 2; }
  if eventlog.eventlog_append(&mut el, 7) != 2 { return 2; }
  if eventlog.eventlog_len(&el) != 3 { return 2; }
  // A cursor taken now reads only events appended later.
  var cur = eventlog.eventlog_cursor(&el);
  var none1 = eventlog.eventlog_read_since(&el, &mut cur);
  if none1.len() != 0 { return 2; }
  if eventlog.eventlog_append(&mut el, 8) != 3 { return 2; }
  if eventlog.eventlog_append(&mut el, 9) != 4 { return 2; }
  var news = eventlog.eventlog_read_since(&el, &mut cur);
  if news.len() != 2 { return 2; }
  if news[0] != 8 { return 2; }
  if news[1] != 9 { return 2; }
  if eventlog.eventlog_cursor_next(&cur) != 5 { return 2; }
  var none2 = eventlog.eventlog_read_since(&el, &mut cur);
  if none2.len() != 0 { return 2; }
  // A cursor positioned at sequence 1 replays from there without copying
  // the prefix into any per-read structure.
  var cur1 = eventlog.eventlog_cursor_at(&el, 1);
  var from1 = eventlog.eventlog_read_since(&el, &mut cur1);
  if from1.len() != 4 { return 2; }
  if from1[0] != 6 { return 2; }
  if from1[3] != 9 { return 2; }
  // Clamped positioning: below 0 -> 0, beyond end -> end.
  var c_neg = eventlog.eventlog_cursor_at(&el, 0 - 5);
  if eventlog.eventlog_cursor_next(&c_neg) != 0 { return 2; }
  var c_far = eventlog.eventlog_cursor_at(&el, 100);
  if eventlog.eventlog_cursor_next(&c_far) != 5 { return 2; }
  // Poll reads one event at a time and stops cleanly at the end.
  var cur2 = eventlog.eventlog_cursor_at(&el, 0);
  var p0 = eventlog.eventlog_poll(&el, &mut cur2);
  if !p0.is_some { return 2; }
  if p0.value != 5 { return 2; }
  var p1 = eventlog.eventlog_poll(&el, &mut cur2);
  if !p1.is_some { return 2; }
  if p1.value != 6 { return 2; }
  if eventlog.eventlog_cursor_next(&cur2) != 2 { return 2; }
  var g4 = eventlog.eventlog_get(&el, 4);
  if !g4.is_some { return 2; }
  if g4.value != 9 { return 2; }
  var g5 = eventlog.eventlog_get(&el, 5);
  if g5.is_some { return 2; }
  if eventlog.eventlog_last_seq(&el) != 4 { return 2; }
  var rg = eventlog.eventlog_read_range(&el, 1, 2);
  if rg.len() != 2 { return 2; }
  if rg[0] != 6 { return 2; }
  if rg[1] != 7 { return 2; }
  var rg2 = eventlog.eventlog_read_range(&el, 10, 5);
  if rg2.len() != 0 { return 2; }
  var rg3 = eventlog.eventlog_read_range(&el, 0, 100);
  if rg3.len() != 5 { return 2; }
  var rg4 = eventlog.eventlog_read_range(&el, 0 - 3, 2);
  if rg4.len() != 2 { return 2; }
  if rg4[0] != 5 { return 2; }

  // Row 3: composite-key map (Int-tuple keys, no string packing).
  var ck = composite.ckmap_new(3);
  if composite.ckmap_arity(&ck) != 3 { return 3; }
  if composite.ckmap_size(&ck) != 0 { return 3; }
  var ka = Vec[Int].new();
  ka.push(1);
  ka.push(2);
  ka.push(3);
  var kb = Vec[Int].new();
  kb.push(4);
  kb.push(5);
  kb.push(6);
  composite.ckmap_put(&mut ck, &ka, 10);
  composite.ckmap_put(&mut ck, &kb, 20);
  composite.ckmap_put(&mut ck, &ka, 11);
  if composite.ckmap_size(&ck) != 2 { return 3; }
  var ga = composite.ckmap_get(&ck, &ka);
  if !ga.is_some { return 3; }
  if ga.value != 11 { return 3; }
  var gb = composite.ckmap_get(&ck, &kb);
  if !gb.is_some { return 3; }
  if gb.value != 20 { return 3; }
  var kc = Vec[Int].new();
  kc.push(7);
  kc.push(8);
  kc.push(9);
  var gc = composite.ckmap_get(&ck, &kc);
  if gc.is_some { return 3; }
  if !composite.ckmap_contains(&ck, &kb) { return 3; }
  // key-hash / key-eq pair (the documented no-string-packing primitives).
  var kd = Vec[Int].new();
  kd.push(1);
  kd.push(2);
  kd.push(3);
  var ke = Vec[Int].new();
  ke.push(1);
  ke.push(2);
  ke.push(4);
  if !composite.ckmap_key_eq(&ka, &kd, 3) { return 3; }
  if composite.ckmap_key_eq(&ka, &ke, 3) { return 3; }
  if !composite.ckmap_key_eq(&ka, &ke, 2) { return 3; }
  if composite.ckmap_key_hash(&ka, 3) != composite.ckmap_key_hash(&kd, 3) { return 3; }
  if composite.ckmap_key_hash(&ka, 3) == composite.ckmap_key_hash(&kb, 3) { return 3; }
  // removal keeps the arena; iteration walks arena entries.
  if !composite.ckmap_remove(&mut ck, &kb) { return 3; }
  if composite.ckmap_contains(&ck, &kb) { return 3; }
  if composite.ckmap_remove(&mut ck, &kb) { return 3; }
  if composite.ckmap_size(&ck) != 1 { return 3; }
  if composite.ckmap_entry_count(&ck) != 2 { return 3; }
  var ev0 = composite.ckmap_entry_value(&ck, 0);
  if !ev0.is_some { return 3; }
  if ev0.value != 11 { return 3; }
  var ek0 = composite.ckmap_entry_key(&ck, 0);
  if ek0.len() != 3 { return 3; }
  if ek0[0] != 1 { return 3; }
  if !composite.ckmap_entry_live(&ck, 0) { return 3; }
  if composite.ckmap_entry_live(&ck, 1) { return 3; }
  var ev1 = composite.ckmap_entry_value(&ck, 1);
  if ev1.is_some { return 3; }
  // growth path: 12 distinct 3-tuples force re-linking.
  var gi = 0;
  while gi < 12 {
    var kg = Vec[Int].new();
    kg.push(gi + 100);
    kg.push(gi + 200);
    kg.push(gi + 300);
    composite.ckmap_put(&mut ck, &kg, gi + 1000);
    gi = gi + 1;
  }
  if composite.ckmap_size(&ck) != 13 { return 3; }
  var gcheck = 0;
  while gcheck < 12 {
    var kg2 = Vec[Int].new();
    kg2.push(gcheck + 100);
    kg2.push(gcheck + 200);
    kg2.push(gcheck + 300);
    var got = composite.ckmap_get(&ck, &kg2);
    if !got.is_some { return 3; }
    if got.value != gcheck + 1000 { return 3; }
    gcheck = gcheck + 1;
  }

  // Row 4: typed-vector copy helper (concrete per element type).
  var cvi = Vec[Int].new();
  cvi.push(1);
  cvi.push(2);
  cvi.push(3);
  var cvc = vecops.vec_copy_int(&cvi);
  if cvc.len() != 3 { return 4; }
  if cvc[0] != 1 { return 4; }
  if cvc[2] != 3 { return 4; }
  cvc[0] = 99;
  if cvi[0] != 1 { return 4; }
  var cvs = Vec[Str].new();
  cvs.push("a");
  cvs.push("b");
  var csc = vecops.vec_copy_str(&cvs);
  if csc.len() != 2 { return 4; }
  if csc[1] != "b" { return 4; }
  csc[0] = "z";
  if cvs[0] != "a" { return 4; }
  var cvb = Vec[UInt8].new();
  cvb.push(7 as UInt8);
  cvb.push(250 as UInt8);
  var cbc = vecops.vec_copy_bytes(&cvb);
  if cbc.len() != 2 { return 4; }
  var ub0 = cbc[0] as Int;
  var ub1 = cbc[1] as Int;
  if ub0 != 7 { return 4; }
  if ub1 != 250 { return 4; }

  // Row 5: group-by-key running aggregate (OHLCV-shaped buckets).
  var gf = groupfold.group_fold_new();
  if groupfold.group_fold_size(&gf) != 0 { return 5; }
  groupfold.group_fold_add(&mut gf, 100, 5);
  groupfold.group_fold_add(&mut gf, 100, 12);
  groupfold.group_fold_add(&mut gf, 100, 8);
  groupfold.group_fold_add(&mut gf, 100, 11);
  groupfold.group_fold_add(&mut gf, 200, 7);
  if groupfold.group_fold_size(&gf) != 2 { return 5; }
  if groupfold.group_fold_count(&gf, 100) != 4 { return 5; }
  if groupfold.group_fold_sum(&gf, 100) != 36 { return 5; }
  var mn = groupfold.group_fold_min(&gf, 100);
  if !mn.is_some { return 5; }
  if mn.value != 5 { return 5; }
  var mx = groupfold.group_fold_max(&gf, 100);
  if !mx.is_some { return 5; }
  if mx.value != 12 { return 5; }
  var op = groupfold.group_fold_first(&gf, 100);
  if !op.is_some { return 5; }
  if op.value != 5 { return 5; }
  var cl = groupfold.group_fold_last(&gf, 100);
  if !cl.is_some { return 5; }
  if cl.value != 11 { return 5; }
  var av = groupfold.group_fold_avg(&gf, 100);
  if !av.is_some { return 5; }
  if av.value != 9 { return 5; }
  if groupfold.group_fold_count(&gf, 200) != 1 { return 5; }
  if !groupfold.group_fold_contains(&gf, 200) { return 5; }
  if groupfold.group_fold_sum(&gf, 9) != 0 { return 5; }
  if groupfold.group_fold_contains(&gf, 9) { return 5; }
  var mn9 = groupfold.group_fold_min(&gf, 9);
  if mn9.is_some { return 5; }
  var av9 = groupfold.group_fold_avg(&gf, 9);
  if av9.is_some { return 5; }
  var gk = groupfold.group_fold_keys(&gf);
  if gk.len() != 2 { return 5; }
  if gk[0] != 100 { return 5; }
  if gk[1] != 200 { return 5; }
  var bk = groupfold.group_fold_bucket_key(&gf, 1);
  if !bk.is_some { return 5; }
  if bk.value != 200 { return 5; }
  var bk9 = groupfold.group_fold_bucket_key(&gf, 9);
  if bk9.is_some { return 5; }
  // signed values: min/max/sum keep their sign
  groupfold.group_fold_add(&mut gf, 300, 0 - 5);
  groupfold.group_fold_add(&mut gf, 300, 0 - 2);
  var nmn = groupfold.group_fold_min(&gf, 300);
  if !nmn.is_some { return 5; }
  if nmn.value != 0 - 5 { return 5; }
  var nmx = groupfold.group_fold_max(&gf, 300);
  if !nmx.is_some { return 5; }
  if nmx.value != 0 - 2 { return 5; }
  if groupfold.group_fold_sum(&gf, 300) != 0 - 7 { return 5; }

  // Row 6: bit-set dataflow primitives.
  var bs = bitset.bitset_new(130);
  if bitset.bitset_len(&bs) != 130 { return 6; }
  if bitset.bitset_word_count(&bs) != 3 { return 6; }
  if bitset.bitset_get(&bs, 5) { return 6; }
  if !bitset.bitset_set(&bs, 5) { return 6; }
  if !bitset.bitset_set(&bs, 64) { return 6; }
  if !bitset.bitset_set(&bs, 129) { return 6; }
  if bitset.bitset_set(&bs, 5) { return 6; }
  if !bitset.bitset_get(&bs, 129) { return 6; }
  if bitset.bitset_get(&bs, 130) { return 6; }
  if bitset.bitset_count(&bs) != 3 { return 6; }
  if !bitset.bitset_clear(&bs, 5) { return 6; }
  if bitset.bitset_clear(&bs, 5) { return 6; }
  if bitset.bitset_count(&bs) != 2 { return 6; }
  if bitset.bitset_next_set(&bs, 0) != 64 { return 6; }
  if bitset.bitset_next_set(&bs, 65) != 129 { return 6; }
  if bitset.bitset_next_set(&bs, 130) != 0 - 1 { return 6; }
  var bsv = bitset.bitset_to_vec(&bs);
  if bsv.len() != 2 { return 6; }
  if bsv[0] != 64 { return 6; }
  if bsv[1] != 129 { return 6; }
  var b2 = bitset.bitset_new(130);
  bitset.bitset_set(&mut b2, 64);
  bitset.bitset_set(&mut b2, 100);
  var uni = bitset.bitset_or(&bs, &b2);
  if bitset.bitset_count(&uni) != 3 { return 6; }
  if !bitset.bitset_get(&uni, 100) { return 6; }
  if !bitset.bitset_get(&uni, 129) { return 6; }
  var ints = bitset.bitset_and(&bs, &b2);
  if bitset.bitset_count(&ints) != 1 { return 6; }
  if !bitset.bitset_get(&ints, 64) { return 6; }
  if bitset.bitset_get(&ints, 100) { return 6; }
  var diff = bitset.bitset_andnot(&bs, &b2);
  if bitset.bitset_count(&diff) != 1 { return 6; }
  if !bitset.bitset_get(&diff, 129) { return 6; }
  if !bitset.bitset_is_subset(&b2, &uni) { return 6; }
  if bitset.bitset_is_subset(&bs, &b2) { return 6; }
  var uni2 = bitset.bitset_or(&b2, &bs);
  if !bitset.bitset_equal(&uni, &uni2) { return 6; }
  // in-place fixpoint pair: changed flags drive worklist loops
  var dst = bitset.bitset_new(64);
  if !bitset.bitset_or_into(&mut dst, &b2) { return 6; }
  if bitset.bitset_count(&dst) != 2 { return 6; }
  if bitset.bitset_len(&dst) != 130 { return 6; }
  if bitset.bitset_or_into(&mut dst, &b2) { return 6; }
  if !bitset.bitset_and_into(&mut dst, &bs) { return 6; }
  if bitset.bitset_count(&dst) != 1 { return 6; }
  if !bitset.bitset_get(&dst, 64) { return 6; }
  if bitset.bitset_and_into(&mut dst, &bs) { return 6; }
  if bitset.bitset_is_empty(&dst) { return 6; }
  // fill masks the tail word of a non-multiple-of-64 universe
  var bf = bitset.bitset_new(70);
  bitset.bitset_fill(&mut bf);
  if bitset.bitset_count(&bf) != 70 { return 6; }
  if !bitset.bitset_get(&bf, 69) { return 6; }
  if bitset.bitset_get(&bf, 70) { return 6; }
  if bitset.bitset_next_set(&bf, 69) != 69 { return 6; }
  bitset.bitset_clear_all(&mut bf);
  if !bitset.bitset_is_empty(&bf) { return 6; }
  if bitset.bitset_count(&bf) != 0 { return 6; }
  if !bitset.bitset_is_subset(&bf, &bs) { return 6; }
  // next_set skip path inside a word
  var b3 = bitset.bitset_new(64);
  bitset.bitset_set(&mut b3, 10);
  bitset.bitset_set(&mut b3, 40);
  if bitset.bitset_next_set(&b3, 0) != 10 { return 6; }
  if bitset.bitset_next_set(&b3, 11) != 40 { return 6; }
  if bitset.bitset_next_set(&b3, 41) != 0 - 1 { return 6; }
  if bitset.bitset_next_set(&b3, 0 - 3) != 10 { return 6; }

  // Row 7: pop ergonomics.
  var pv = Vec[Int].new();
  pv.push(1);
  pv.push(2);
  if vecops.vec_pop_or(&mut pv, 0 - 5) != 2 { return 7; }
  if vecops.vec_pop_or(&mut pv, 0 - 5) != 1 { return 7; }
  if vecops.vec_pop_or(&mut pv, 0 - 5) != 0 - 5 { return 7; }
  if pv.len() != 0 { return 7; }
  if vecops.vec_last_or(&pv, 0 - 7) != 0 - 7 { return 7; }
  pv.push(4);
  if vecops.vec_last_or(&pv, 0 - 7) != 4 { return 7; }
  if pv.len() != 1 { return 7; }
  pv.push(9);
  pv.push(10);
  var pc1 = vecops.vec_pop_checked(&mut pv);
  if !pc1.is_some { return 7; }
  if pc1.value != 10 { return 7; }
  var pc2 = vecops.vec_pop_checked(&mut pv);
  if !pc2.is_some { return 7; }
  if pc2.value != 9 { return 7; }
  var pc3 = vecops.vec_pop_checked(&mut pv);
  if !pc3.is_some { return 7; }
  if pc3.value != 4 { return 7; }
  var pc4 = vecops.vec_pop_checked(&mut pv);
  if pc4.is_some { return 7; }
  if pv.len() != 0 { return 7; }

  // Row 8: Vec[Str] helpers.
  var vs = Vec[Str].new();
  vs.push("a");
  vs.push("b");
  vs.push("c");
  vs.push("a");
  if !vecstr.vec_str_contains(&vs, "b") { return 8; }
  if vecstr.vec_str_contains(&vs, "z") { return 8; }
  if vecstr.vec_str_index_of(&vs, "c") != 2 { return 8; }
  if vecstr.vec_str_index_of(&vs, "z") != 0 - 1 { return 8; }
  if vecstr.vec_str_last_index_of(&vs, "a") != 3 { return 8; }
  if vecstr.vec_str_last_index_of(&vs, "z") != 0 - 1 { return 8; }
  var vs2 = Vec[Str].new();
  vs2.push("a");
  vs2.push("b");
  vs2.push("c");
  vs2.push("a");
  if !vecstr.vec_str_equal(&vs, &vs2) { return 8; }
  var vs3 = Vec[Str].new();
  vs3.push("a");
  if vecstr.vec_str_equal(&vs, &vs3) { return 8; }
  var ve = Vec[Str].new();
  if !vecstr.vec_str_equal(&ve, &ve) { return 8; }
  var vsc = vecstr.vec_str_copy(&vs);
  if vsc.len() != 4 { return 8; }
  vsc[0] = "z";
  if vs[0] != "a" { return 8; }
  var vu = vecstr.vec_str_unique(&vs);
  if vu.len() != 3 { return 8; }
  if vu[0] != "a" { return 8; }
  if vu[1] != "b" { return 8; }
  if vu[2] != "c" { return 8; }
  var vj = Vec[Str].new();
  vj.push("x");
  vj.push("y");
  vj.push("z");
  if vecstr.vec_str_join(&vj, "-") != "x-y-z" { return 8; }
  if vecstr.vec_str_join(&ve, "-") != "" { return 8; }
  var vj1 = Vec[Str].new();
  vj1.push("solo");
  if vecstr.vec_str_join(&vj1, ",") != "solo" { return 8; }

  // Row 9: truncation helpers.
  var tv = Vec[Int].new();
  tv.push(1);
  tv.push(2);
  tv.push(3);
  tv.push(4);
  tv.push(5);
  tv.push(6);
  vecops.vec_truncate_to(&mut tv, 3);
  if tv.len() != 3 { return 9; }
  if tv[2] != 3 { return 9; }
  vecops.vec_truncate_to(&mut tv, 10);
  if tv.len() != 3 { return 9; }
  vecops.vec_truncate_to(&mut tv, 0 - 4);
  if tv.len() != 0 { return 9; }
  var tv2 = Vec[Int].new();
  tv2.push(1);
  tv2.push(2);
  tv2.push(3);
  tv2.push(4);
  tv2.push(5);
  if vecops.vec_drop_last(&mut tv2, 2) != 2 { return 9; }
  if tv2.len() != 3 { return 9; }
  if tv2[2] != 3 { return 9; }
  if vecops.vec_drop_last(&mut tv2, 0) != 0 { return 9; }
  if tv2.len() != 3 { return 9; }
  if vecops.vec_drop_last(&mut tv2, 10) != 3 { return 9; }
  if tv2.len() != 0 { return 9; }
  var tvs = Vec[Str].new();
  tvs.push("a");
  tvs.push("b");
  tvs.push("c");
  if vecops.vec_drop_last(&mut tvs, 1) != 1 { return 9; }
  if tvs.len() != 2 { return 9; }
  if tvs[1] != "b" { return 9; }

  // Row 10: Str -> Str map on the module face (no manual hashing).
  var s2 = stringmap.string_str_map_new();
  if stringmap.string_str_map_size(&s2) != 0 { return 10; }
  stringmap.string_str_map_put(&mut s2, "alpha", "A");
  stringmap.string_str_map_put(&mut s2, "beta", "B");
  stringmap.string_str_map_put(&mut s2, "gamma", "C");
  stringmap.string_str_map_put(&mut s2, "beta", "B2");
  if stringmap.string_str_map_size(&s2) != 3 { return 10; }
  var va = stringmap.string_str_map_get(&s2, "alpha");
  if !va.is_some { return 10; }
  if va.value != "A" { return 10; }
  var vb = stringmap.string_str_map_get(&s2, "beta");
  if !vb.is_some { return 10; }
  if vb.value != "B2" { return 10; }
  if !stringmap.string_str_map_contains(&s2, "gamma") { return 10; }
  var vm = stringmap.string_str_map_get(&s2, "missing");
  if vm.is_some { return 10; }
  if !stringmap.string_str_map_remove(&mut s2, "gamma") { return 10; }
  if stringmap.string_str_map_contains(&s2, "gamma") { return 10; }
  if stringmap.string_str_map_remove(&mut s2, "gamma") { return 10; }
  if stringmap.string_str_map_size(&s2) != 2 { return 10; }
  if stringmap.string_str_map_entry_count(&s2) != 3 { return 10; }
  var ek = stringmap.string_str_map_entry_key(&s2, 0);
  if !ek.is_some { return 10; }
  if ek.value != "alpha" { return 10; }
  var ev = stringmap.string_str_map_entry_value(&s2, 0);
  if !ev.is_some { return 10; }
  if ev.value != "A" { return 10; }
  if stringmap.string_str_map_entry_live(&s2, 2) { return 10; }
  if !stringmap.string_str_map_entry_live(&s2, 1) { return 10; }
  // growth path: 12 distinct keys force table doubling twice.
  stringmap.string_str_map_put(&mut s2, "k0", "v0");
  stringmap.string_str_map_put(&mut s2, "k1", "v1");
  stringmap.string_str_map_put(&mut s2, "k2", "v2");
  stringmap.string_str_map_put(&mut s2, "k3", "v3");
  stringmap.string_str_map_put(&mut s2, "k4", "v4");
  stringmap.string_str_map_put(&mut s2, "k5", "v5");
  stringmap.string_str_map_put(&mut s2, "k6", "v6");
  stringmap.string_str_map_put(&mut s2, "k7", "v7");
  stringmap.string_str_map_put(&mut s2, "k8", "v8");
  stringmap.string_str_map_put(&mut s2, "k9", "v9");
  stringmap.string_str_map_put(&mut s2, "k10", "v10");
  stringmap.string_str_map_put(&mut s2, "k11", "v11");
  if stringmap.string_str_map_size(&s2) != 14 { return 10; }
  var vk7 = stringmap.string_str_map_get(&s2, "k7");
  if !vk7.is_some { return 10; }
  if vk7.value != "v7" { return 10; }
  var vk11 = stringmap.string_str_map_get(&s2, "k11");
  if !vk11.is_some { return 10; }
  if vk11.value != "v11" { return 10; }

  return 0;
}

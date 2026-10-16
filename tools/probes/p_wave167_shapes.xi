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
// 10 -- Str -> Str map: put/update/get/remove, entry iteration, growth
// Setup failures use 20+.

module p_wave167_shapes

use xiom.collect.mailbox;
use xiom.collect.eventlog;
use xiom.collect.composite;
use xiom.collect.stringmap;

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

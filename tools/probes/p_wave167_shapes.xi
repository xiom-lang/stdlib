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
// Setup failures use 20+.

module p_wave167_shapes

use xiom.collect.mailbox;
use xiom.collect.eventlog;

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

  return 0;
}

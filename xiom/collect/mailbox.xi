// XIOM - Collections: keyed mailboxes (multiple FIFO queues over one structure)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.mailbox

// Depends on: none (built-in Vec only)

// ============================================================================
// Mailboxes -- Int-keyed FIFO queues over one arena (packages wishlist:
// "keyed FIFO / mailbox / bounded-queue primitives" -- requesters: actor
// mailboxes/ready-queues, discovery).
//
// Non-blocking, like the xiom.collect.queue workqueue helpers: `send` always
// succeeds on the unbounded face (the bounded variant refuses), `recv`/`peek`
// return Option instead of blocking. Each logical mailbox is an independent
// FIFO: the arena `items` holds payloads and `next` links them per key, so
// one structure serves any number of mailboxes with O(1) send/recv.
// Removed payloads stay in the arena (no compaction), matching the queue
// helpers' documented discipline.
// ============================================================================

/// A set of Int-keyed FIFO mailboxes sharing one payload arena.
pub type Mailboxes = {
  keys: Vec[Int];
  heads: Vec[Int];
  tails: Vec[Int];
  counts: Vec[Int];
  items: Vec[Int];
  next: Vec[Int];
}

/// Create an empty mailbox set.
pub fn mailboxes_new() -> Mailboxes
  ensures: result.keys.len() == 0
{
  return Mailboxes{ keys: Vec[Int].new(); heads: Vec[Int].new(); tails: Vec[Int].new(); counts: Vec[Int].new(); items: Vec[Int].new(); next: Vec[Int].new(); };
}

// Index of `key` in the key table, or -1 when the mailbox does not exist.
fn _mb_find(m: &Mailboxes, key: Int) -> Int {
  var i = 0;
  while i < m.keys.len() {
    if m.keys[i] == key { return i; }
    i = i + 1;
  }
  return -1;
}

// Append one payload to mailbox `idx`'s FIFO.
fn _mb_link(m: &mut Mailboxes, idx: Int, item: Int) {
  var slot = m.items.len();
  m.items.push(item);
  m.next.push(-1);
  if m.tails[idx] < 0 {
    m.heads[idx] = slot;
  } else {
    m.next[m.tails[idx]] = slot;
  }
  m.tails[idx] = slot;
  m.counts[idx] = m.counts[idx] + 1;
}

/// Send `item` to mailbox `key`, creating the mailbox on first use.
/// Never blocks; unbounded. O(1) amortized (mailbox creation is O(keys)).
pub fn mailboxes_send(m: &mut Mailboxes, key: Int, item: Int)
  ensures: mailboxes_total_len(m) == mailboxes_total_len(m)@pre + 1
{
  var idx = _mb_find(m, key);
  if idx < 0 {
    m.keys.push(key);
    m.heads.push(-1);
    m.tails.push(-1);
    m.counts.push(0);
    idx = m.keys.len() - 1;
  }
  _mb_link(m, idx, item);
}

/// Bounded send: refuses with `false` when mailbox `key` already holds `cap`
/// items (and `cap > 0`). `cap <= 0` means unbounded. O(1) amortized.
pub fn mailboxes_send_bounded(m: &mut Mailboxes, key: Int, item: Int, cap: Int) -> Bool
  ensures: result == true => mailboxes_total_len(m) == mailboxes_total_len(m)@pre + 1
  ensures: result == false => mailboxes_total_len(m) == mailboxes_total_len(m)@pre
{
  if cap > 0 {
    var idx = _mb_find(m, key);
    if idx >= 0 {
      if m.counts[idx] >= cap { return false; }
    }
  }
  mailboxes_send(m, key, item);
  return true;
}

/// Remove and return the oldest item of mailbox `key`. None when the mailbox
/// is missing or empty (non-blocking).
pub fn mailboxes_recv(m: &mut Mailboxes, key: Int) -> Option[Int]
  ensures: result is Some => mailboxes_total_len(m) == mailboxes_total_len(m)@pre - 1
  ensures: result is None => mailboxes_total_len(m) == mailboxes_total_len(m)@pre
{
  var idx = _mb_find(m, key);
  if idx < 0 { return None; }
  var h = m.heads[idx];
  if h < 0 { return None; }
  var v = m.items[h];
  m.heads[idx] = m.next[h];
  if m.heads[idx] < 0 { m.tails[idx] = -1; }
  m.counts[idx] = m.counts[idx] - 1;
  return Some(v);
}

/// Return the oldest item of mailbox `key` without removing it. None when
/// missing or empty.
pub fn mailboxes_peek(m: &Mailboxes, key: Int) -> Option[Int]
  ensures: result.is_some == (mailboxes_len(m, key) > 0)
{
  var idx = _mb_find(m, key);
  if idx < 0 { return None; }
  var h = m.heads[idx];
  if h < 0 { return None; }
  return Some(m.items[h]);
}

/// Take every pending item of mailbox `key` in FIFO order, emptying it.
/// O(pending). Useful for batch drains without a match loop.
pub fn mailboxes_drain(m: &mut Mailboxes, key: Int) -> Vec[Int]
  ensures: mailboxes_len(m, key) == 0
{
  var out = Vec[Int].new();
  var idx = _mb_find(m, key);
  if idx < 0 { return out; }
  var e = m.heads[idx];
  while e >= 0 {
    out.push(m.items[e]);
    e = m.next[e];
  }
  m.heads[idx] = -1;
  m.tails[idx] = -1;
  m.counts[idx] = 0;
  return out;
}

/// Number of pending items in mailbox `key` (0 when the mailbox is missing).
pub fn mailboxes_len(m: &Mailboxes, key: Int) -> Int
  ensures: result >= 0
{
  var idx = _mb_find(m, key);
  if idx < 0 { return 0; }
  return m.counts[idx];
}

/// True when mailbox `key` is missing or has no pending items.
pub fn mailboxes_is_empty(m: &Mailboxes, key: Int) -> Bool
  ensures: result == (mailboxes_len(m, key) == 0)
{
  return mailboxes_len(m, key) == 0;
}

/// True when mailbox `key` exists (was ever sent to).
pub fn mailboxes_has_key(m: &Mailboxes, key: Int) -> Bool
  ensures: result == (_mb_find(m, key) >= 0)
{
  return _mb_find(m, key) >= 0;
}

/// Number of logical mailboxes.
pub fn mailboxes_key_count(m: &Mailboxes) -> Int
  ensures: result >= 0
{
  return m.keys.len();
}

/// Total pending items across every mailbox.
pub fn mailboxes_total_len(m: &Mailboxes) -> Int
  ensures: result >= 0
{
  var total = 0;
  var i = 0;
  while i < m.counts.len() {
    total = total + m.counts[i];
    i = i + 1;
  }
  return total;
}

/// Mailbox keys in first-seen order.
pub fn mailboxes_keys(m: &Mailboxes) -> Vec[Int]
  ensures: result.len() == m.keys.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < m.keys.len() {
    out.push(m.keys[i]);
    i = i + 1;
  }
  return out;
}

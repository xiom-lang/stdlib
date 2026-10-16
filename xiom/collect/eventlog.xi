// XIOM - Collections: append-only event log with read cursors
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.collect.eventlog

// Depends on: none (built-in Vec only)

// ============================================================================
// EventLog -- ordered, sequence-numbered, append-only Int event log plus
// opaque read cursors (packages wishlist: "ordered event log + subscription
// cursors (sequence-numbered change feed)" -- requesters: discovery watches,
// messaging).
//
// `eventlog_append` assigns sequence numbers 0, 1, 2, ... (the index in the
// log). A cursor remembers the next unread sequence; `eventlog_read_since`
// returns only the events appended after the cursor and advances it, so a
// reader never copies the whole log. Events are never removed, so sequences
// are stable and remain valid for the reader's lifetime.
// ============================================================================

/// Append-only event log of Int events, sequence-numbered from 0.
pub type EventLog = {
  items: Vec[Int];
}

/// A reader position in an EventLog: the next unread sequence number.
/// Treat as opaque: advance it only through `eventlog_read_since` /
/// `eventlog_poll` so reads stay monotone.
pub type LogCursor = {
  next: Int;
}

/// Create an empty event log.
pub fn eventlog_new() -> EventLog
  ensures: result.items.len() == 0
{
  return EventLog{ items: Vec[Int].new(); };
}

/// Append an event; returns the sequence number assigned to it.
pub fn eventlog_append(l: &mut EventLog, event: Int) -> Int
  ensures: result == eventlog_len(l) - 1
{
  var seq = l.items.len();
  l.items.push(event);
  return seq;
}

/// Number of events in the log (== next sequence to be assigned).
pub fn eventlog_len(l: &EventLog) -> Int
  ensures: result >= 0
{
  return l.items.len();
}

/// Event at sequence `seq`, or None when out of range.
pub fn eventlog_get(l: &EventLog, seq: Int) -> Option[Int]
  ensures: result.is_some == (seq >= 0 && seq < eventlog_len(l))
{
  if seq < 0 || seq >= l.items.len() { return None; }
  return Some(l.items[seq]);
}

/// Highest assigned sequence number, or -1 when the log is empty.
pub fn eventlog_last_seq(l: &EventLog) -> Int
  ensures: result == eventlog_len(l) - 1
{
  return l.items.len() - 1;
}

/// A fresh cursor at the current end of the log: it reads only events
/// appended after this call.
pub fn eventlog_cursor(l: &EventLog) -> LogCursor
  ensures: result.next == eventlog_len(l)
{
  return LogCursor{ next: l.items.len() };
}

/// A cursor positioned at sequence `seq` (clamped to [0, len]): its first
/// read starts at `seq`.
pub fn eventlog_cursor_at(l: &EventLog, seq: Int) -> LogCursor
  ensures: result.next >= 0
  ensures: result.next <= eventlog_len(l)
{
  var n = seq;
  if n < 0 { n = 0; }
  if n > l.items.len() { n = l.items.len(); }
  return LogCursor{ next: n };
}

/// The next sequence number the cursor will read.
pub fn eventlog_cursor_next(c: &LogCursor) -> Int
  ensures: result >= 0
{
  return c.next;
}

/// Every event appended since the cursor, in sequence order; advances the
/// cursor past them. Copies only the new events (never the whole log).
pub fn eventlog_read_since(l: &EventLog, c: &mut LogCursor) -> Vec[Int]
  ensures: eventlog_cursor_next(c) == eventlog_len(l)
  ensures: result.len() <= eventlog_len(l)
{
  var out = Vec[Int].new();
  var start = c.next;
  if start < 0 { start = 0; }
  if start > l.items.len() { start = l.items.len(); }
  var i = start;
  while i < l.items.len() {
    out.push(l.items[i]);
    i = i + 1;
  }
  c.next = l.items.len();
  return out;
}

/// Read the single next event, or None when the cursor is caught up.
pub fn eventlog_poll(l: &EventLog, c: &mut LogCursor) -> Option[Int]
  ensures: result is Some => eventlog_cursor_next(c) == eventlog_cursor_next(c)@pre + 1
  ensures: result is None => eventlog_cursor_next(c) == eventlog_cursor_next(c)@pre
{
  if c.next < 0 { c.next = 0; }
  if c.next >= l.items.len() { return None; }
  var v = l.items[c.next];
  c.next = c.next + 1;
  return Some(v);
}

/// Events in the half-open range [from, from + count), clamped to the log;
/// does not touch any cursor. Returns an empty vector when nothing matches.
pub fn eventlog_read_range(l: &EventLog, from: Int, count: Int) -> Vec[Int]
  ensures: result.len() <= eventlog_len(l)
{
  var out = Vec[Int].new();
  if count <= 0 { return out; }
  var start = from;
  if start < 0 { start = 0; }
  var stop = start + count;
  if stop > l.items.len() { stop = l.items.len(); }
  var i = start;
  while i < stop {
    out.push(l.items[i]);
    i = i + 1;
  }
  return out;
}

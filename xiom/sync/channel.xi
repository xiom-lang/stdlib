// XIOM - Sync: Channel
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sync.channel

// Depends on: xiom.sync

// ============================================================================
// Bounded/unbounded typed channels for message passing between threads.
// Pure-XIOM data structure over Vec[T]: capacity 0 means unbounded. The
// blocking operations (`channel_send` on a full bounded channel, `channel_recv`
// on an empty one, `channel_select`) poll with a 1 ms sleep, so they make
// progress in single-threaded programs as soon as the counterpart op runs.
// ============================================================================

extern "C" {
  fn xiom_thread_sleep_ms(ms: Int);
}

/// Channel[T] - a generic message queue; capacity 0 means unbounded.
pub type Channel[T] = {
  items: Vec[T];
  closed: Bool;
  cap: Int;
}

/// Create a channel with the given capacity (0 = unbounded).
/// Params: capacity - maximum queued items, or 0 for unbounded.
/// Returns: a new empty open channel.
/// Complexity: O(1).
pub fn channel_new[T](capacity: Int) -> Channel[T] {
  var c = capacity;
  if c < 0 {
    c = 0;
  }
  return Channel[T]{ items: Vec[T].new(); closed: false; cap: c; }
}

/// Enqueue `item`, blocking on a full bounded channel; error if closed.
/// Params: ch - the channel; item - the value to send.
/// Returns: Ok(()) on success, Err("channel closed") if closed.
/// Complexity: O(1) per poll; blocks while the channel is full.
pub fn channel_send[T](ch: &mut Channel[T], item: T) -> Result[Unit, Str] {
  var done = false;
  while !done {
    if ch.closed {
      return Err("channel closed");
    }
    if ch.cap == 0 || ch.items.len() < ch.cap {
      ch.items.push(item);
      done = true;
    } else {
      unsafe { xiom_thread_sleep_ms(1); }
    }
  }
  return Ok(());
}

/// Enqueue without blocking; false if full or closed.
/// Params: ch - the channel; item - the value to send.
/// Returns: true if queued, false if the channel is full or closed.
/// Complexity: O(1). Never blocks.
pub fn channel_try_send[T](ch: &mut Channel[T], item: T) -> Bool {
  if ch.closed {
    return false;
  }
  if ch.cap > 0 && ch.items.len() >= ch.cap {
    return false;
  }
  ch.items.push(item);
  return true;
}

/// Dequeue the next item, blocking when empty; None if closed.
/// Params: ch - the channel.
/// Returns: Some(item) in FIFO order, None if closed and drained.
/// Complexity: O(n) shift per pop; blocks while empty.
pub fn channel_recv[T](ch: &mut Channel[T]) -> Option[T] {
  while ch.items.len() == 0 && !ch.closed {
    unsafe { xiom_thread_sleep_ms(1); }
  }
  if ch.items.len() == 0 {
    return None;
  }
  var val = ch.items[0];
  var i: Int = 0;
  while i + 1 < ch.items.len() {
    ch.items[i] = ch.items[i + 1];
    i = i + 1;
  }
  ch.items.pop();
  return Some(val);
}

/// Dequeue without blocking; None if empty or closed.
/// Params: ch - the channel.
/// Returns: Some(item) in FIFO order, None if empty or closed.
/// Complexity: O(n) shift per pop. Never blocks.
pub fn channel_try_recv[T](ch: &mut Channel[T]) -> Option[T] {
  if ch.items.len() == 0 {
    return None;
  }
  var val = ch.items[0];
  var i: Int = 0;
  while i + 1 < ch.items.len() {
    ch.items[i] = ch.items[i + 1];
    i = i + 1;
  }
  ch.items.pop();
  return Some(val);
}

/// Mark the channel closed; pending sends fail, queued items stay readable.
/// Params: ch - the channel.
/// Complexity: O(1).
pub fn channel_close[T](ch: &mut Channel[T]) {
  ch.closed = true;
}

/// True if the channel is closed.
/// Params: ch - the channel.
/// Returns: whether the channel was closed.
/// Complexity: O(1).
pub fn channel_is_closed[T](ch: &Channel[T]) -> Bool {
  return ch.closed;
}

/// Number of items currently queued.
/// Params: ch - the channel.
/// Returns: the queue length.
/// Complexity: O(1).
pub fn channel_len[T](ch: &Channel[T]) -> Int
  ensures: result >= 0
{
  return ch.items.len();
}

/// Configured capacity; 0 for unbounded.
/// Params: ch - the channel.
/// Returns: the capacity configured at creation.
/// Complexity: O(1).
pub fn channel_capacity[T](ch: &Channel[T]) -> Int
  ensures: result >= 0
{
  return ch.cap;
}

/// Block until one channel is ready; returns its index.
/// Params: chs - the channels to watch.
/// Returns: Some(index) of the first channel with a queued item, or None if
///          every channel is closed and drained.
/// Complexity: O(n) per poll; blocks while no channel is ready.
pub fn channel_select[T](chs: &Vec[Channel[T]]) -> Option[Int] {
  var done = false;
  var result: Option[Int] = None;
  while !done {
    var any_open = false;
    var i: Int = 0;
    var found: Option[Int] = None;
    var n = chs.len();
    while i < n {
      var c = chs[i];
      if !c.closed {
        any_open = true;
      }
      if c.items.len() > 0 {
        found = Some(i);
        i = n;
      } else {
        i = i + 1;
      }
    }
    match found {
      Some(idx) => {
        result = Some(idx);
        done = true;
      };
      None => {
        if !any_open {
          done = true;
        } else {
          unsafe { xiom_thread_sleep_ms(1); }
        }
      };
    }
  }
  return result;
}

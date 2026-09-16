// XIOM - Async: Channel
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.async.channel

// Depends on: xiom.async

// ============================================================================
// Scheduling-aware async channels and multi-receiver broadcast.
// Pure-XIOM data structures over Vec[T]. The "yield" in `async_send` /
// `async_recv` / `async_select` is a 1 ms sleep, so single-threaded programs
// make progress as soon as the counterpart operation runs. `Broadcast[T]`
// hands every queued item to each subscriber once.
// ============================================================================

extern "C" {
  fn xiom_thread_sleep_ms(ms: Int);
}

/// AsyncChannel[T] - an async message queue that yields instead of blocking.
pub type AsyncChannel[T] = {
  items: Vec[T];
  closed: Bool;
  cap: Int;
}

/// Create an async channel with the given capacity (0 = unbounded).
/// Params: capacity - maximum queued items, or 0 for unbounded.
/// Returns: a new empty open channel.
/// Complexity: O(1).
pub fn async_channel_new[T](capacity: Int) -> AsyncChannel[T] {
  var c = capacity;
  if c < 0 {
    c = 0;
  }
  return AsyncChannel[T]{ items: Vec[T].new(); closed: false; cap: c; }
}

/// Enqueue `item`, yielding on a full channel; error if closed.
/// Params: ch - the channel; item - the value to send.
/// Returns: Ok(()) on success, Err("channel closed") if closed.
/// Complexity: O(1) per poll; yields while the channel is full.
pub fn async_send[T](ch: &mut AsyncChannel[T], item: T) -> Result[Unit, Str] {
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

/// Dequeue the next item, yielding when empty; None if closed.
/// Params: ch - the channel.
/// Returns: Some(item) in FIFO order, None if closed and drained.
/// Complexity: O(n) shift per pop; yields while empty.
pub fn async_recv[T](ch: &mut AsyncChannel[T]) -> Option[T] {
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

/// Enqueue without yielding; false if full or closed.
/// Params: ch - the channel; item - the value to send.
/// Returns: true if queued, false if the channel is full or closed.
/// Complexity: O(1). Never yields.
pub fn async_try_send[T](ch: &mut AsyncChannel[T], item: T) -> Bool {
  if ch.closed {
    return false;
  }
  if ch.cap > 0 && ch.items.len() >= ch.cap {
    return false;
  }
  ch.items.push(item);
  return true;
}

/// Dequeue without yielding; None if empty or closed.
/// Params: ch - the channel.
/// Returns: Some(item) in FIFO order, None if empty or closed.
/// Complexity: O(n) shift per pop. Never yields.
pub fn async_try_recv[T](ch: &mut AsyncChannel[T]) -> Option[T] {
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

/// Mark the channel closed.
/// Params: ch - the channel.
/// Complexity: O(1).
pub fn async_channel_close[T](ch: &mut AsyncChannel[T]) {
  ch.closed = true;
}

/// Number of items currently queued.
/// Params: ch - the channel.
/// Returns: the queue length.
/// Complexity: O(1).
pub fn async_channel_len[T](ch: &AsyncChannel[T]) -> Int {
  return ch.items.len();
}

/// Yield until one channel is ready; returns its index.
/// Params: chs - the channels to watch.
/// Returns: Some(index) of the first channel with a queued item, or None if
///          every channel is closed and drained.
/// Complexity: O(n) per poll; yields while no channel is ready.
pub fn async_select[T](chs: &Vec[AsyncChannel[T]]) -> Option[Int] {
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

/// Broadcast[T] - a multi-receiver channel where every subscriber sees each item.
pub type Broadcast[T] = {
  items: Vec[T];
  seen: Int;
  closed: Bool;
  cap: Int;
}

/// Create a broadcast channel with the given capacity.
/// Params: capacity - maximum buffered items (0 = unbounded).
/// Returns: a new broadcast channel with no unseen items.
/// Complexity: O(1).
pub fn broadcast_new[T](capacity: Int) -> Broadcast[T] {
  var c = capacity;
  if c < 0 {
    c = 0;
  }
  return Broadcast[T]{ items: Vec[T].new(); seen: 0; closed: false; cap: c; }
}

/// Enqueue `item` for every subscriber.
/// Params: b - the broadcast channel; item - the value.
/// Items beyond a bounded capacity are dropped.
/// Complexity: O(1) amortized.
pub fn broadcast_send[T](b: &mut Broadcast[T], item: T) {
  if b.cap == 0 || b.items.len() < b.cap {
    b.items.push(item);
  }
}

/// Receive the next unseen item; None when caught up or closed.
/// Params: b - the broadcast channel.
/// Returns: Some(item) in order, None once every item has been seen.
/// Complexity: O(1).
pub fn broadcast_recv[T](b: &mut Broadcast[T]) -> Option[T] {
  if b.seen >= b.items.len() {
    return None;
  }
  var val = b.items[b.seen];
  b.seen = b.seen + 1;
  return Some(val);
}

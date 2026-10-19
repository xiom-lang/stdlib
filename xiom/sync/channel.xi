// XIOM - Sync: Channel
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sync.channel

// Depends on: xiom.sync

use xiom.alloc;
use xiom.ptr;
use xiom.core.size_of;  // bare intrinsic binding (strict catalog gate)

// ============================================================================
// Bounded/unbounded typed channels for message passing between threads.
// Pure-XIOM data structure over Vec[T]: capacity 0 means unbounded. The
// blocking operations (`channel_send` on a full bounded channel, `channel_recv`
// on an empty one, `channel_select`) poll with a 1 ms sleep, so they make
// progress in single-threaded programs as soon as the counterpart op runs.
//
// THREAD SAFETY
// - The value form (`Channel[T]`) has NO internal lock. It is safe for
//   single-thread use, or for sharing only when every access is serialized by
//   an external lock held across the whole operation. Its blocking ops poll
//   and do not synchronize.
// - The handle form (`ChannelHandle[T]`, below) is the cross-thread shape:
//   `channel_open` allocates the `Channel[T]` cell once and returns a
//   copyable Int-addressed handle. Every handle operation assumes the CALLER
//   holds the same external `xiom.sync.mutex.SyncMutex`; there is no internal
//   lock. Threads using copies of one handle must agree on that lock.
// - `channel_handle_free` drains and deallocates the cell. Call it exactly
//   once, after every thread that can touch the handle has been joined, and
//   never concurrently with another operation. Copies are dangling after it.
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
pub fn channel_new[T](capacity: Int) -> Channel[T]
  ensures: (capacity < 0) => (result.cap == 0)
  ensures: (capacity >= 0) => (result.cap == capacity)
  ensures: result.closed == false
{
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
pub fn channel_send[T](ch: &mut Channel[T], item: T) -> Result[Unit, Str]
  ensures: result is Err => ch.closed == true
{
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
pub fn channel_recv[T](ch: &mut Channel[T]) -> Option[T]
  ensures: result is None => ch.closed == true && ch.items.len() == 0
{
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
pub fn channel_close[T](ch: &mut Channel[T])
  ensures: ch.closed == true
{
  ch.closed = true;
}

/// True if the channel is closed.
/// Params: ch - the channel.
/// Returns: whether the channel was closed.
/// Complexity: O(1).
pub fn channel_is_closed[T](ch: &Channel[T]) -> Bool
  ensures: result == ch.closed
{
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

// ============================================================================
// Handle form (wishlist row 47 / relay REL-20261018-1518-xvector-2).
//
// All operations below take the handle by value and read/modify/write the
// underlying `Channel[T]` cell. They do NOT lock: the caller must hold one
// external SyncMutex across each whole operation, and every thread using a
// copy of the handle must use that same mutex. `channel_handle_free` is
// single-use and only valid after all users have been joined.
//
// COMPILER NOTE: stage the cell pointer in a local before ptr.read/ptr.write.
// `ptr.read(channel_handle_cell[T](h))` (a generic call nested as the argument
// of another generic call) is silently mis-typed on v0.64.6 and reads garbage;
// see tools/known_failures/p_nested_generic_ptr_read.xi. Every function below
// uses the verified staged-local shape.
// ============================================================================

/// ChannelHandle[T] - a copyable Int-addressed handle to a heap-allocated
/// `Channel[T]` cell. The address is non-zero for a live handle.
pub type ChannelHandle[T] = { addr: Int; }

/// Resolve a live handle to its heap cell.
/// Params: h - a live handle.
/// Returns: the `*Channel[T]` cell at `h.addr`.
/// Complexity: O(1).
fn channel_handle_cell[T](h: ChannelHandle[T]) -> *Channel[T]
  requires: h.addr != 0
{
  unsafe { return h.addr as *Channel[T]; }
}

/// Allocate a channel cell and return its copyable handle.
/// Params: capacity - maximum queued items, or 0 for unbounded; negative
///          values are clamped to 0.
/// Returns: a handle with a non-zero address to a new empty open channel.
/// Thread safety: the caller must serialize all handle operations externally.
/// Complexity: O(1).
pub fn channel_open[T](capacity: Int) -> ChannelHandle[T]
  ensures: result.addr != 0
{
  var cap = capacity;
  if cap < 0 {
    cap = 0;
  }
  let c = Channel[T]{ items: Vec[T].new(); closed: false; cap: cap; };
  let cell = alloc.alloc(size_of[Channel[T]]());
  unsafe { ptr.write(cell as *Channel[T], c); }
  var addr: Int = 0;
  unsafe { addr = cell as Int; }
  return ChannelHandle[T]{ addr: addr; };
}

/// Enqueue without blocking; false if the channel is full or closed.
/// Params: h - the handle; item - the value to send.
/// Returns: true if queued, false if full or closed.
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(1). Never blocks.
pub fn channel_handle_try_send[T](h: ChannelHandle[T], item: T) -> Bool
  requires: h.addr != 0
  ensures: result == false => channel_handle_is_closed[T](h) || (channel_handle_capacity[T](h) > 0 && channel_handle_len[T](h) >= channel_handle_capacity[T](h))
{
  let cell = channel_handle_cell[T](h);
  var c = ptr.read(cell);
  if c.closed {
    return false;
  }
  if c.cap > 0 && c.items.len() >= c.cap {
    return false;
  }
  c.items.push(item);
  ptr.write(cell, c);
  return true;
}

/// Dequeue without blocking; None if the channel is empty (closed or open).
/// Params: h - the handle.
/// Returns: Some(item) in FIFO order, or None when empty.
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(n) shift per pop. Never blocks.
pub fn channel_handle_try_recv[T](h: ChannelHandle[T]) -> Option[T]
  requires: h.addr != 0
  ensures: result is None => channel_handle_len[T](h) == 0
{
  let cell = channel_handle_cell[T](h);
  var c = ptr.read(cell);
  if c.items.len() == 0 {
    return None;
  }
  let val = c.items[0];
  var i: Int = 0;
  while i + 1 < c.items.len() {
    c.items[i] = c.items[i + 1];
    i = i + 1;
  }
  c.items.pop();
  ptr.write(cell, c);
  return Some(val);
}

/// Mark the channel closed; queued items stay readable.
/// Params: h - the handle.
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(1).
pub fn channel_handle_close[T](h: ChannelHandle[T])
  requires: h.addr != 0
  ensures: channel_handle_is_closed[T](h) == true
{
  let cell = channel_handle_cell[T](h);
  var c = ptr.read(cell);
  c.closed = true;
  ptr.write(cell, c);
}

/// True if the channel is closed.
/// Params: h - the handle.
/// Returns: whether the channel was closed.
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(1).
pub fn channel_handle_is_closed[T](h: ChannelHandle[T]) -> Bool
  requires: h.addr != 0
{
  let cell = channel_handle_cell[T](h);
  let c = ptr.read(cell);
  return c.closed;
}

/// Number of items currently queued.
/// Params: h - the handle.
/// Returns: the queue length (>= 0).
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(1).
pub fn channel_handle_len[T](h: ChannelHandle[T]) -> Int
  requires: h.addr != 0
  ensures: result >= 0
{
  let cell = channel_handle_cell[T](h);
  let c = ptr.read(cell);
  return c.items.len();
}

/// Configured capacity; 0 for unbounded.
/// Params: h - the handle.
/// Returns: the capacity configured at `channel_open` (>= 0).
/// Thread safety: caller must hold the external lock for `h`.
/// Complexity: O(1).
pub fn channel_handle_capacity[T](h: ChannelHandle[T]) -> Int
  requires: h.addr != 0
  ensures: result >= 0
{
  let cell = channel_handle_cell[T](h);
  let c = ptr.read(cell);
  return c.cap;
}

/// Drain the channel and deallocate its cell.
/// Params: h - the handle.
/// Thread safety: caller must hold the external lock for `h`; call exactly
///               once, after every thread using the handle has been joined,
///               and never concurrently with another handle operation.
///               Copies of the handle are dangling after this call.
/// Complexity: O(n) drain + O(1) deallocation.
pub fn channel_handle_free[T](h: ChannelHandle[T])
  requires: h.addr != 0
{
  let cell = channel_handle_cell[T](h);
  var c = ptr.read(cell);
  while c.items.len() > 0 {
    c.items.pop();
  }
  unsafe { alloc.dealloc(cell as *UInt8, size_of[Channel[T]]()); }
}

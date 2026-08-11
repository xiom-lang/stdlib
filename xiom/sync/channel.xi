// XIOM - Sync: Channel
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.channel

// Depends on: xiom.sync

// ============================================================================
// Bounded/unbounded typed channels for message passing between threads.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Channel[T] - a generic message queue; capacity 0 means unbounded.
// fn channel_new[T](capacity: Int) -> Channel[T] - create a channel with the given capacity (0 = unbounded). TODO(compiler): implement.
// fn channel_send[T](ch, item: T) -> Result[Unit, Str] - enqueue item, blocking on a full bounded channel; error if closed. TODO(compiler): implement.
// fn channel_try_send[T](ch, item) -> Bool - enqueue without blocking; false if full or closed. TODO(compiler): implement.
// fn channel_recv[T](ch) -> Option[T] - dequeue the next item, blocking when empty; None if closed. TODO(compiler): implement.
// fn channel_try_recv[T](ch) -> Option[T] - dequeue without blocking; None if empty or closed. TODO(compiler): implement.
// fn channel_close[T](ch) - mark the channel closed; pending sends fail, queued items stay readable. TODO(compiler): implement.
// fn channel_is_closed[T](ch) -> Bool - true if the channel is closed. TODO(compiler): implement.
// fn channel_len[T](ch) -> Int - number of items currently queued. TODO(compiler): implement.
// fn channel_capacity[T](ch) -> Int - configured capacity; 0 for unbounded. TODO(compiler): implement.
// fn channel_select[T](chs: &Vec[Channel[T]]) -> Option[Int] - block until one channel is ready; returns its index. TODO(compiler): implement.

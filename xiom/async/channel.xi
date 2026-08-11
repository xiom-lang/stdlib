// XIOM - Async: Channel
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.async.channel

// Depends on: xiom.async

// ============================================================================
// Scheduling-aware async channels and multi-receiver broadcast.
// NOTE: current implementation lives in async.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type AsyncChannel[T] - an async message queue that yields instead of blocking.
// fn async_channel_new[T](capacity: Int) -> AsyncChannel[T] - create an async channel with the given capacity. TODO(compiler): implement.
// fn async_send[T](ch, item: T) -> Result[Unit, Str] - enqueue item, yielding on a full channel; error if closed. TODO(compiler): implement.
// fn async_recv[T](ch) -> Option[T] - dequeue the next item, yielding when empty; None if closed. TODO(compiler): implement.
// fn async_try_send[T](ch, item) -> Bool - enqueue without yielding; false if full or closed. TODO(compiler): implement.
// fn async_try_recv[T](ch) -> Option[T] - dequeue without yielding; None if empty or closed. TODO(compiler): implement.
// fn async_channel_close[T](ch) - mark the channel closed. TODO(compiler): implement.
// fn async_channel_len[T](ch) -> Int - number of items currently queued. TODO(compiler): implement.
// fn async_select[T](chs: &Vec[AsyncChannel[T]]) -> Option[Int] - yield until one channel is ready; returns its index. TODO(compiler): implement.
// type Broadcast[T] - a multi-receiver channel where every subscriber sees each item.
// fn broadcast_new[T](capacity) -> Broadcast[T] - create a broadcast channel with the given capacity. TODO(compiler): implement.
// fn broadcast_send[T](b, item) - enqueue item for every subscriber. TODO(compiler): implement.
// fn broadcast_recv[T](b) -> Option[T] - receive the next unseen item; None when caught up or closed. TODO(compiler): implement.

// XIOM - Collections: Blocking Queue
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.blockingqueue

// Depends on: xiom.sync

// ============================================================================
// Blocking queue (Int items) with a fixed capacity. bq_push blocks while full
// and bq_pop blocks while empty; try_* variants return immediately. bq_close
// wakes all waiters and makes push fail while pop drains the remainder.
// ============================================================================

// fn blocking_queue_new(capacity: Int) - create a blocking queue with capacity slots. TODO(compiler): implement.
// fn bq_push(q, item: Int) -> Bool - enqueue, blocking; false if closed. TODO(compiler): implement.
// fn bq_pop(q) -> Option[Int] - dequeue, blocking; None if closed and drained. TODO(compiler): implement.
// fn bq_try_push(q, item: Int) -> Bool - enqueue without blocking; false if full or closed. TODO(compiler): implement.
// fn bq_try_pop(q) -> Option[Int] - dequeue without blocking; None if empty or closed. TODO(compiler): implement.
// fn bq_size(q) -> Int - number of items currently queued. TODO(compiler): implement.
// fn bq_capacity(q) -> Int - maximum number of items. TODO(compiler): implement.
// fn bq_close(q) - close the queue and wake all blocked waiters. TODO(compiler): implement.
// fn bq_is_closed(q) -> Bool - true if the queue has been closed. TODO(compiler): implement.

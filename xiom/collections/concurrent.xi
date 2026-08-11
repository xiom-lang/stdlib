// XIOM - Collections: Concurrent Queues and Containers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.collect.concurrent

// NOTE: MPMC/MSPC/SPMC need atomic CAS or a Mutex mutation API; see
// docs/COMPILER_BUGS.md BUG 2 / BUG 16 family. The single-producer
// SpscRing already landed in collect/queue.xi; these queue families are
// built on top of that primitive where possible.

// ============================================================================
// Concurrent queues (mpmc/mpsc/spmc) and containers (stack, counter) for Int
// items. Blocking semantics on an internal queue; producer/consumer counts
// constrain which end each operation may use. Returns Bool on push (false if
// full or closed) and Option[Int] on pop (None if empty or closed).
// ============================================================================

// fn mpmc_queue_new(capacity: Int) - create a multi-producer multi-consumer queue. TODO(compiler): implement.
// fn mpmc_push(q, item: Int) -> Bool - enqueue; false if full or closed. TODO(compiler): implement.
// fn mpmc_pop(q) -> Option[Int] - dequeue; None if empty or closed. TODO(compiler): implement.
// fn mpsc_queue_new(capacity: Int) - create a multi-producer single-consumer queue. TODO(compiler): implement.
// fn mpsc_push(q, item: Int) -> Bool - enqueue; false if full or closed. TODO(compiler): implement.
// fn mpsc_pop(q) -> Option[Int] - dequeue from the single consumer end; None if empty or closed. TODO(compiler): implement.
// fn spmc_queue_new(capacity: Int) - create a single-producer multi-consumer queue. TODO(compiler): implement.
// fn spmc_push(q, item: Int) -> Bool - enqueue from the single producer end; false if full or closed. TODO(compiler): implement.
// fn spmc_pop(q) -> Option[Int] - dequeue; None if empty or closed. TODO(compiler): implement.
// fn concurrent_stack_new() - create a concurrent LIFO stack. TODO(compiler): implement.
// fn cstack_push(s, item: Int) -> Bool - push; false if closed. TODO(compiler): implement.
// fn cstack_pop(s) -> Option[Int] - pop; None if empty or closed. TODO(compiler): implement.
// fn concurrent_counter_new() - create a concurrent counter starting at zero. TODO(compiler): implement.
// fn ccounter_add(c, delta: Int) - atomically add delta to the counter. TODO(compiler): implement.
// fn ccounter_get(c) -> Int - read the current counter value. TODO(compiler): implement.

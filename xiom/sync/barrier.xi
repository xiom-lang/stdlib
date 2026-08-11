// XIOM - Sync: Barrier
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.barrier

// Depends on: xiom.sync

// ============================================================================
// Reusable barrier that releases a fixed number of threads simultaneously.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Barrier - a reusable rendezvous for N threads.
// fn barrier_new(count: Int) -> Barrier - create a barrier for count threads. TODO(compiler): implement.
// fn barrier_wait(b) -> Bool - block until all threads arrive; true for the last arriver. TODO(compiler): implement.
// fn barrier_count(b) -> Int - the configured thread count. TODO(compiler): implement.
// fn barrier_reset(b) - reset the waiting counter to zero. TODO(compiler): implement.
// fn barrier_is_ready(b) -> Bool - true if every thread has arrived. TODO(compiler): implement.

// XIOM - Sync: Condvar
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.condvar

// Depends on: xiom.sync

// ============================================================================
// Condition variable for waiting on a state change guarded by a mutex.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Condvar - a condition variable paired with a mutex.
// fn condvar_new() -> Condvar - create a new condition variable. TODO(compiler): implement.
// fn condvar_wait(cv, m) - atomically release m and block until notified. TODO(compiler): implement.
// fn condvar_wait_timeout(cv, m, ms) -> Bool - wait with a timeout; true if notified. TODO(compiler): implement.
// fn condvar_notify_one(cv) - wake one waiting thread. TODO(compiler): implement.
// fn condvar_notify_all(cv) - wake all waiting threads. TODO(compiler): implement.

// XIOM - Sync: Mutex
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.mutex

// Depends on: xiom.sync

// ============================================================================
// Blocking and try-lock mutual exclusion with lock-state introspection.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Mutex - an owned mutual exclusion primitive wrapping the platform mutex.
// fn mutex_new() -> Mutex - create a new unlocked mutex. TODO(compiler): implement.
// fn mutex_lock(m) - block until the mutex is acquired. TODO(compiler): implement.
// fn mutex_try_lock(m) -> Bool - attempt a non-blocking acquire; true on success. TODO(compiler): implement.
// fn mutex_unlock(m) - release a held mutex. TODO(compiler): implement.
// fn mutex_is_locked(m) -> Bool - true if the mutex is currently held. TODO(compiler): implement.
// fn mutex_into_inner(m) -> Int - consume the mutex and return the raw handle. TODO(compiler): implement.

// XIOM - Sync: RwLock
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.rwlock

// Depends on: xiom.sync

// ============================================================================
// Reader-writer lock allowing concurrent readers or one exclusive writer.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type RwLock - a reader-writer lock protecting shared data.
// fn rwlock_new() -> RwLock - create an unlocked reader-writer lock. TODO(compiler): implement.
// fn rwlock_read_lock(l) - acquire a shared read lock, blocking for writers. TODO(compiler): implement.
// fn rwlock_read_try_lock(l) -> Bool - acquire a read lock without blocking. TODO(compiler): implement.
// fn rwlock_read_unlock(l) - release a held read lock. TODO(compiler): implement.
// fn rwlock_write_lock(l) - acquire the exclusive write lock, blocking. TODO(compiler): implement.
// fn rwlock_write_try_lock(l) -> Bool - acquire the write lock without blocking. TODO(compiler): implement.
// fn rwlock_write_unlock(l) - release a held write lock. TODO(compiler): implement.
// fn rwlock_is_write_locked(l) -> Bool - true if the lock is held for writing. TODO(compiler): implement.
// fn rwlock_into_inner(l) -> Int - consume the lock and return the raw handle. TODO(compiler): implement.

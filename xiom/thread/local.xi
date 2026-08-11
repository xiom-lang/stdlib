// XIOM - Thread: Local
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.thread.local

// Depends on: xiom.thread

// ============================================================================
// Per-thread storage: typed thread-locals and raw TLS keys.
// NOTE: current implementation lives in thread.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type ThreadLocal[T] - storage holding one value of T per thread.
// fn thread_local_new[T](init: fn() -> T) -> ThreadLocal[T] - create thread-local storage with a lazy initializer. TODO(compiler): implement.
// fn tls_get[T](tl) -> T - read the calling thread's value, initializing on first access. TODO(compiler): implement.
// fn tls_set[T](tl, value: T) - write the calling thread's value. TODO(compiler): implement.
// fn tls_replace[T](tl, value) -> T - replace and return the previous value. TODO(compiler): implement.
// fn tls_take[T](tl) -> Option[T] - take the value, leaving the slot empty. TODO(compiler): implement.
// fn tls_clear[T](tl) - drop the calling thread's value and reset to uninitialized. TODO(compiler): implement.
// fn thread_local_key_new() -> Int - allocate a raw TLS key. TODO(compiler): implement.
// fn tls_key_get(key: Int) -> Int - read the calling thread's value for a raw key. TODO(compiler): implement.
// fn tls_key_set(key: Int, value: Int) - write the calling thread's value for a raw key. TODO(compiler): implement.

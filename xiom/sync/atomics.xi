// XIOM - Sync: Atomics
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync.atomics

// Depends on: xiom.sync

// ============================================================================
// Lock-free atomic integer, boolean, and pointer operations.
// NOTE: current implementation lives in sync.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type AtomicInt - a lock-free atomically accessed signed integer.
// fn atomic_int_new(init: Int) -> AtomicInt - create an atomic integer initialised to init. TODO(compiler): implement.
// fn atomic_load(a) -> Int - atomically read the current value. TODO(compiler): implement.
// fn atomic_store(a, value) - atomically write a new value. TODO(compiler): implement.
// fn atomic_add(a, delta) -> Int - atomically add and return the new value. TODO(compiler): implement.
// fn atomic_sub(a, delta) -> Int - atomically subtract and return the new value. TODO(compiler): implement.
// fn atomic_fetch_add(a, delta) -> Int - atomically add and return the old value. TODO(compiler): implement.
// fn atomic_fetch_sub(a, delta) -> Int - atomically subtract and return the old value. TODO(compiler): implement.
// fn atomic_swap(a, value) -> Int - atomically store and return the old value. TODO(compiler): implement.
// fn atomic_compare_exchange(a, expected, new) -> Bool - store new if the value equals expected. TODO(compiler): implement.
// type AtomicBool - a lock-free atomically accessed boolean.
// fn atomic_bool_new(init: Bool) -> AtomicBool - create an atomic boolean initialised to init. TODO(compiler): implement.
// fn atomic_bool_load(a) -> Bool - atomically read the current value. TODO(compiler): implement.
// fn atomic_bool_store(a, value) - atomically write a new value. TODO(compiler): implement.
// fn atomic_bool_swap(a, value) -> Bool - atomically store and return the old value. TODO(compiler): implement.
// type AtomicPtr - a lock-free atomically accessed raw pointer.
// fn atomic_ptr_new[T](ptr: Int) -> AtomicPtr - create an atomic pointer from an address. TODO(compiler): implement.
// fn atomic_ptr_load(a) -> Int - atomically read the current address. TODO(compiler): implement.
// fn atomic_ptr_store(a, ptr: Int) - atomically write a new address. TODO(compiler): implement.

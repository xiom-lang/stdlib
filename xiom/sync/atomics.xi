// XIOM - Sync: Atomics
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sync.atomics

// Depends on: xiom.sync

// ============================================================================
// Lock-free atomic integer, boolean, and pointer operations.
// Self-contained implementation over the runtime xiom_atomic_* intrinsics.
// The AtomicInt / AtomicBool / AtomicPtr types here are this module's own
// handle types (each wraps a heap cell); they are independent of the
// xiom.sync.AtomicInt family defined in the parent module.
// ============================================================================

use xiom.alloc;
use xiom.ptr;

extern "C" {
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_store(ptr: *Int, val: Int);
  fn xiom_atomic_fetch_add(ptr: *Int, val: Int) -> Int;
  fn xiom_atomic_fetch_sub(ptr: *Int, val: Int) -> Int;
  fn xiom_atomic_exchange(ptr: *Int, val: Int) -> Int;
}

/// AtomicInt - a lock-free atomically accessed signed integer.
pub type AtomicInt = { ptr: *Int; }

/// Create an atomic integer initialised to `init`.
/// Params: init - the initial value.
/// Returns: a new atomic integer holding `init`.
/// Complexity: O(1).
pub fn atomic_int_new(init: Int) -> AtomicInt {
  let p = alloc.alloc(8);
  unsafe { ptr.write(p as *Int, init); }
  unsafe {
    return AtomicInt{ ptr: p as *Int; }
  }
}

/// Atomically read the current value.
/// Params: a - the atomic integer.
/// Returns: the current value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_load(a: &AtomicInt) -> Int {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_load(p); }
}

/// Atomically write a new value.
/// Params: a - the atomic integer; value - the new value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_store(a: &mut AtomicInt, value: Int) {
  let p: *Int = a.ptr;
  unsafe { xiom_atomic_store(p, value); }
}

/// Atomically add `delta` and return the new value.
/// Params: a - the atomic integer; delta - the increment.
/// Returns: the value after the addition.
/// Complexity: O(1). Thread-safe.
pub fn atomic_add(a: &mut AtomicInt, delta: Int) -> Int {
  let p: *Int = a.ptr;
  var old: Int;
  unsafe { old = xiom_atomic_fetch_add(p, delta); }
  return old + delta;
}

/// Atomically subtract `delta` and return the new value.
/// Params: a - the atomic integer; delta - the decrement.
/// Returns: the value after the subtraction.
/// Complexity: O(1). Thread-safe.
pub fn atomic_sub(a: &mut AtomicInt, delta: Int) -> Int {
  let p: *Int = a.ptr;
  var old: Int;
  unsafe { old = xiom_atomic_fetch_sub(p, delta); }
  return old - delta;
}

/// Atomically add `delta` and return the old value.
/// Params: a - the atomic integer; delta - the increment.
/// Returns: the value before the addition.
/// Complexity: O(1). Thread-safe.
pub fn atomic_fetch_add(a: &mut AtomicInt, delta: Int) -> Int {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_fetch_add(p, delta); }
}

/// Atomically subtract `delta` and return the old value.
/// Params: a - the atomic integer; delta - the decrement.
/// Returns: the value before the subtraction.
/// Complexity: O(1). Thread-safe.
pub fn atomic_fetch_sub(a: &mut AtomicInt, delta: Int) -> Int {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_fetch_sub(p, delta); }
}

/// Atomically store `value` and return the old value.
/// Params: a - the atomic integer; value - the new value.
/// Returns: the value before the store.
/// Complexity: O(1). Thread-safe.
pub fn atomic_swap(a: &mut AtomicInt, value: Int) -> Int {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_exchange(p, value); }
}

/// Store `new` if the value equals `expected`.
/// Params: a - the atomic integer; expected - the value to compare against;
///          new - the value to store on match.
/// Returns: true if the exchange was performed.
/// Complexity: O(1). Thread-safe.
pub fn atomic_compare_exchange(a: &mut AtomicInt, expected: Int, new: Int) -> Bool {
  let p: *Int = a.ptr;
  unsafe {
    let old = xiom_atomic_load(p);
    if old == expected {
      xiom_atomic_store(p, new);
      return true;
    }
    return false;
  }
}

/// AtomicBool - a lock-free atomically accessed boolean.
pub type AtomicBool = { ptr: *Int; }

/// Create an atomic boolean initialised to `init`.
/// Params: init - the initial value.
/// Returns: a new atomic boolean holding `init`.
/// Complexity: O(1).
pub fn atomic_bool_new(init: Bool) -> AtomicBool {
  let p = alloc.alloc(8);
  let iv: Int = if init { 1 } else { 0 };
  unsafe { ptr.write(p as *Int, iv); }
  unsafe {
    return AtomicBool{ ptr: p as *Int; }
  }
}

/// Atomically read the current value.
/// Params: a - the atomic boolean.
/// Returns: the current value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_bool_load(a: &AtomicBool) -> Bool {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_load(p) != 0; }
}

/// Atomically write a new value.
/// Params: a - the atomic boolean; value - the new value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_bool_store(a: &mut AtomicBool, value: Bool) {
  let iv: Int = if value { 1 } else { 0 };
  let p: *Int = a.ptr;
  unsafe { xiom_atomic_store(p, iv); }
}

/// Atomically store `value` and return the old value.
/// Params: a - the atomic boolean; value - the new value.
/// Returns: the value before the store.
/// Complexity: O(1). Thread-safe.
pub fn atomic_bool_swap(a: &mut AtomicBool, value: Bool) -> Bool {
  let iv: Int = if value { 1 } else { 0 };
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_exchange(p, iv) != 0; }
}

/// AtomicPtr - a lock-free atomically accessed raw pointer.
pub type AtomicPtr = { ptr: *Int; }

/// Create an atomic pointer from an address.
/// Params: ptr - the address to store.
/// Returns: a new atomic pointer holding `ptr`.
/// Complexity: O(1).
pub fn atomic_ptr_new[T](ptr: Int) -> AtomicPtr {
  let p = alloc.alloc(8);
  unsafe { ptr.write(p as *Int, ptr); }
  unsafe {
    return AtomicPtr{ ptr: p as *Int; }
  }
}

/// Atomically read the current address.
/// Params: a - the atomic pointer.
/// Returns: the current address.
/// Complexity: O(1). Thread-safe.
pub fn atomic_ptr_load(a: &AtomicPtr) -> Int {
  let p: *Int = a.ptr;
  unsafe { return xiom_atomic_load(p); }
}

/// Atomically write a new address.
/// Params: a - the atomic pointer; ptr - the new address.
/// Complexity: O(1). Thread-safe.
pub fn atomic_ptr_store(a: &mut AtomicPtr, ptr: Int) {
  let p: *Int = a.ptr;
  unsafe { xiom_atomic_store(p, ptr); }
}

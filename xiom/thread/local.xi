// XIOM - Thread: Local
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.thread.local

// Depends on: xiom.thread

// ============================================================================
// Per-thread storage: typed thread-locals and raw TLS keys.
// Pure-XIOM simulation: `ThreadLocal[T]` holds one lazily-initialised value
// (the calling thread's slot in a single-threaded program). Raw TLS keys are
// allocated from a monotonic counter; their values are stored in a single
// global key/value slot (module-level Vec storage does not persist across
// calls in the current compiler, so the table is single-entry).
// ============================================================================

var _tls_keys: Int = 0;
var _raw_key: Int = 0;
var _raw_value: Int = 0;

/// ThreadLocal[T] - storage holding one value of T per thread.
pub type ThreadLocal[T] = {
  init: fn() -> T;
  value: T;
  initialized: Bool;
}

/// Create thread-local storage with a lazy initializer.
/// Params: init - the initializer invoked on first access.
/// Returns: uninitialised thread-local storage.
/// Complexity: O(1).
pub fn thread_local_new[T](init: fn() -> T) -> ThreadLocal[T] {
  return ThreadLocal[T]{ init: init; value: T(); initialized: false; }
}

/// Read the calling thread's value, initializing on first access.
/// Params: tl - the thread-local (mutated on first access).
/// Returns: the current value, running `init` if not yet set.
/// Complexity: O(1).
pub fn tls_get[T](tl: &mut ThreadLocal[T]) -> T {
  if !tl.initialized {
    tl.value = tl.init();
    tl.initialized = true;
  }
  return tl.value;
}

/// Write the calling thread's value.
/// Params: tl - the thread-local; value - the new value.
/// Complexity: O(1).
pub fn tls_set[T](tl: &mut ThreadLocal[T], value: T) {
  tl.value = value;
  tl.initialized = true;
}

/// Replace and return the previous value.
/// Params: tl - the thread-local; value - the replacement.
/// Returns: the previous value (or the initializer's value if unset).
/// Complexity: O(1).
pub fn tls_replace[T](tl: &mut ThreadLocal[T], value: T) -> T {
  if !tl.initialized {
    tl.value = tl.init();
    tl.initialized = true;
  }
  var old = tl.value;
  tl.value = value;
  return old;
}

/// Take the value, leaving the slot empty.
/// Params: tl - the thread-local (cleared).
/// Returns: Some(value) if set, None if uninitialized.
/// Complexity: O(1).
pub fn tls_take[T](tl: &mut ThreadLocal[T]) -> Option[T] {
  if !tl.initialized {
    return None;
  }
  var v = tl.value;
  tl.initialized = false;
  return Some(v);
}

/// Drop the calling thread's value and reset to uninitialized.
/// Params: tl - the thread-local.
/// Complexity: O(1).
pub fn tls_clear[T](tl: &mut ThreadLocal[T]) {
  tl.initialized = false;
}

/// Allocate a raw TLS key.
/// Returns: a fresh positive key value.
/// Complexity: O(1).
pub fn thread_local_key_new() -> Int {
  _tls_keys = _tls_keys + 1;
  return _tls_keys;
}

/// Read the calling thread's value for a raw key.
/// Params: key - the key to look up.
/// Returns: the stored value, or 0 if the key is not the stored one.
/// Complexity: O(1). Single-slot simulation: one raw key per program.
pub fn tls_key_get(key: Int) -> Int {
  if _raw_key == key {
    return _raw_value;
  }
  return 0;
}

/// Write the calling thread's value for a raw key.
/// Params: key - the key; value - the value to store.
/// Complexity: O(1). Single-slot simulation: one raw key per program.
pub fn tls_key_set(key: Int, value: Int) {
  _raw_key = key;
  _raw_value = value;
}

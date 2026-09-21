// XIOM -- Pointer Utilities
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.ptr

/// Null pointer of type `*T` (escape hatch; never dereference).
pub fn null[T]() -> *T
  requires: true  // deliberate null pointer (T003 raw-pointer escape hatch / T007)
{
  unsafe {
    return 0 as *T;
  }
}

/// Null pointer of type `*mut T` (escape hatch; never dereference).
pub fn null_mut[T]() -> *mut T
  requires: true  // deliberate null pointer (T003 raw-pointer escape hatch / T007)
{
  unsafe {
    return 0 as *mut T;
  }
}

/// Non-null marker pointer that must never be dereferenced.
pub fn dangling[T]() -> *T
  // Deliberate marker pointer (never dereference); no input precondition.
  requires: true
{
  unsafe {
    return 1 as *T;
  }
}

/// True when `ptr` is a null pointer.
pub fn is_null[T](ptr: *const T) -> Bool {
  return ptr == null[T]();
}

/// Read the value at `ptr`; requires a non-null, valid pointer.
pub fn read[T](ptr: *const T) -> T
  requires: ptr != null
{
  unsafe {
    return *ptr;
  }
}

/// Write `value` to `ptr`; requires a non-null, valid pointer.
pub fn write[T](ptr: *mut T, value: T)
  requires: ptr != null
{
  unsafe {
    *ptr = value;
  }
}

/// Volatile read at `ptr` (no elision/reordering by the backend).
pub fn read_volatile[T](ptr: *const T) -> T
  requires: ptr != null
{
  unsafe {
    return *ptr;
  }
}

/// Volatile write of `value` to `ptr`.
pub fn write_volatile[T](ptr: *mut T, value: T)
  requires: ptr != null
{
  unsafe {
    *ptr = value;
  }
}

/// Swap the values at `a` and `b`; both must be non-null and valid.
pub fn swap[T](a: *mut T, b: *mut T)
  requires: a != null
  requires: b != null
{
  unsafe {
    let temp = *a;
    *a = *b;
    *b = temp;
  }
}

/// Replace `*dest` with `src`, returning the previous value.
pub fn replace[T](dest: *mut T, src: T) -> T
  requires: dest != null
  ensures:  result == old_value
{
  unsafe {
    let old = *dest;
    *dest = src;
    return old;
  }
}

/// Copy `count` values from `src` to `dst`; ranges may overlap.
pub fn copy[T](src: *const T, dst: *mut T, count: Int)
  requires: src != null
  requires: dst != null
  requires: count > 0
{
  unsafe {
    var i = 0;
    while i < count {
      *(dst + i) = *(src + i);
      i = i + 1;
    }
  }
}

/// Copy `count` values from `src` to `dst`; ranges must not overlap.
pub fn copy_nonoverlapping[T](src: *const T, dst: *mut T, count: Int)
  requires: src != null
  requires: dst != null
  requires: count > 0
{
  unsafe {
    var i = 0;
    while i < count {
      *(dst + i) = *(src + i);
      i = i + 1;
    }
  }
}

/// Pointer equality (address comparison).
pub fn eq[T](a: *const T, b: *const T) -> Bool {
  return a == b;
}

/// Pointer arithmetic: `ptr + count` elements.
pub fn offset[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr + count;
  }
}

/// Wrapping pointer arithmetic (no in-bounds requirement).
pub fn wrapping_offset[T](ptr: *const T, count: Int) -> *const T
  requires: true
{
  unsafe {
    return ptr + count;
  }
}

/// `ptr + count` elements; requires a non-null pointer.
pub fn add[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr + count;
  }
}

/// `ptr - count` elements; requires a non-null pointer.
pub fn sub[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr - count;
  }
}

/// Convert a shared reference to a raw pointer (escape hatch).
pub fn from_ref[T](r: &T) -> *const T
  requires: true  // ref-to-pointer cast, allocator-style escape hatch (T003/T007)
{
  unsafe {
    return r as *const T;
  }
}

/// Convert a mutable reference to a raw mutable pointer (escape hatch).
pub fn from_mut[T](r: &mut T) -> *mut T
  requires: true  // ref-to-pointer cast, allocator-style escape hatch (T003/T007)
{
  unsafe {
    return r as *mut T;
  }
}

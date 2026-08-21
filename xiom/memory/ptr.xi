// XIOM -- Pointer Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ptr

pub fn null[T]() -> *T {
  return 0 as *T;
}

pub fn null_mut[T]() -> *mut T {
  return 0 as *mut T;
}

pub fn dangling[T]() -> *T {
  unsafe {
    return 1 as *T;
  }
}

pub fn is_null[T](ptr: *const T) -> Bool {
  return ptr == null[T]();
}

pub fn read[T](ptr: *const T) -> T
  requires: ptr != null
{
  unsafe {
    return *ptr;
  }
}

pub fn write[T](ptr: *mut T, value: T)
  requires: ptr != null
{
  unsafe {
    *ptr = value;
  }
}

pub fn read_volatile[T](ptr: *const T) -> T
  requires: ptr != null
{
  unsafe {
    return *ptr;
  }
}

pub fn write_volatile[T](ptr: *mut T, value: T)
  requires: ptr != null
{
  unsafe {
    *ptr = value;
  }
}

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

pub fn eq[T](a: *const T, b: *const T) -> Bool {
  return a == b;
}

pub fn offset[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr + count;
  }
}

pub fn wrapping_offset[T](ptr: *const T, count: Int) -> *const T {
  unsafe {
    return ptr + count;
  }
}

pub fn add[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr + count;
  }
}

pub fn sub[T](ptr: *const T, count: Int) -> *const T
  requires: ptr != null
{
  unsafe {
    return ptr - count;
  }
}

pub fn from_ref[T](r: &T) -> *const T {
  return r as *const T;
}

pub fn from_mut[T](r: &mut T) -> *mut T {
  return r as *mut T;
}

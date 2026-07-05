// XIOM — FFI Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ffi

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn memcpy(dest: *UInt8, src: *UInt8, size: UInt);
}

pub fn extern_c(name: Str, ...) -> Int
  requires: name.len() > 0
{
  unsafe {
    return 0;
  }
}

pub fn alloc(size: Int) -> *UInt8
  requires: size > 0
  ensures:  result != null
{
  unsafe {
    return malloc(size as UInt);
  }
}

pub fn free(ptr: *UInt8)
  requires: ptr != null
{
  unsafe {
    free(ptr);
  }
}

pub fn memcpy(dest: *UInt8, src: *UInt8, size: Int)
  requires: dest != null
  requires: src != null
  requires: size > 0
{
  unsafe {
    memcpy(dest, src, size as UInt);
  }
}

pub fn size_of[T]() -> Int {
  return 0;
}

pub fn align_of[T]() -> Int {
  return 0;
}

// XIOM — Memory Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.mem

use xiom.ptr;

pub fn swap[T](a: &mut T, b: &mut T)
  ensures: a == b@pre && b == a@pre
{
  unsafe {
    let pa = ptr.from_mut(a);
    let pb = ptr.from_mut(b);
    ptr.swap(pa, pb);
  };
}

pub fn replace[T](dest: &mut T, src: T) -> T
  ensures: result == dest@pre
{
  unsafe {
    let pd = ptr.from_mut(dest);
    return ptr.replace(pd, src);
  }
}

pub fn take[T: Default](dest: &mut T) -> T
  ensures: dest == T.default()
{
  return replace(dest, T.default());
}

pub fn drop[T](value: T) {
}

// Size queries
// Compiler intrinsic — requires compiler support
pub fn size_of[T]() -> Int;

// Compiler intrinsic — requires compiler support
pub fn align_of[T]() -> Int;

pub fn size_of_val[T](value: &T) -> Int
  ensures: result > 0
{
  return size_of[T]();
}

pub fn min_align_of_val[T](value: &T) -> Int
  ensures: result > 0
{
  return align_of[T]();
}

// Zeroed memory
pub fn zeroed[T]() -> T;

// Uninitialized memory (unsafe)
pub fn uninitialized[T]() -> T;

// Manually drop (defer cleanup)
pub type ManuallyDrop[T] = { value: T; }

pub fn ManuallyDrop.new[T](value: T) -> ManuallyDrop[T] {
  return ManuallyDrop[T]{ value: value };
}

pub fn ManuallyDrop.into_inner[T](self) -> T {
  return value;
}

pub fn ManuallyDrop.take[T](self) -> T {
  return value;
}

pub fn ManuallyDrop.drop[T](self) {
}

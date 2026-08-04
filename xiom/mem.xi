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
    let temp = ptr.read(pa);
    ptr.write(pa, ptr.read(pb));
    ptr.write(pb, temp);
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
  ensures: true
{
  return replace(dest, T.default());
}

pub fn drop[T](value: T)
  ensures: true
{
}

// Size queries
// Compiler intrinsic — requires compiler support
pub fn size_of[T]() -> Int
  ensures: result > 0;

// Compiler intrinsic — requires compiler support
pub fn align_of[T]() -> Int
  ensures: result > 0;

pub fn size_of_val[T](value: &T) -> Int
  ensures: result > 0
  ensures: result == size_of[T]()
{
  return size_of[T]();
}

pub fn min_align_of_val[T](value: &T) -> Int
  ensures: result > 0
  ensures: result == align_of[T]()
{
  return align_of[T]();
}

// Zeroed memory — all bytes set to zero
pub fn zeroed[T]() -> T
  ensures: all bytes of result are 0;

// Uninitialized memory (unsafe — reading before writing is UB)
pub fn uninitialized[T]() -> T
  ensures: true;

// Manually drop (defer cleanup)
pub type ManuallyDrop[T] = { value: T; }

pub fn ManuallyDrop.new[T](value: T) -> ManuallyDrop[T] {
  return ManuallyDrop[T]{ value: value };
}

pub fn ManuallyDrop.into_inner[T](self) -> T
  requires: self.value is a valid T {
  return value;
}

pub fn ManuallyDrop.take[T](self) -> T
  requires: self.value is a valid T
  ensures: result == self.value@pre {
  return value;
}

pub fn ManuallyDrop.drop[T](self)
  requires: self.value is a valid T
  ensures: true {
}

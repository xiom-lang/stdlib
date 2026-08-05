// XIOM — Reference Counting
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.rc

use xiom.alloc;

fn size_of[T]() -> Int;
fn align_of[T]() -> Int;

pub type RcInner[T] = {
  strong: Int;
  weak: Int;
  value: T;
  invariant: strong >= 0;
  invariant: weak >= 0;
  invariant: strong + weak > 0;
}

pub type Rc[T] = {
  ptr: *RcInner[T];
}

pub fn Rc.new[T](value: T) -> Rc[T]
  ensures: strong_count == 1
  ensures: ptr != null
{
  let layout = alloc.Layout.new(size_of[RcInner[T]]());
  let raw = alloc.alloc(layout.size);
  let inner: *RcInner[T] = raw as *RcInner[T];
  unsafe {
    (*inner).strong = 1;
    (*inner).weak = 0;
    (*inner).value = value;
  }
  return Rc[T]{ ptr: inner };
}

pub fn Rc.clone[T](self) -> Rc[T]
  requires: ptr != null
  ensures:  strong_count() == strong_count()@pre + 1
{
  unsafe {
    (*ptr).strong = (*ptr).strong + 1;
  }
  return Rc[T]{ ptr: ptr };
}

pub fn Rc.strong_count[T](self) -> Int
  requires: ptr != null
  ensures:  result >= 1
{
  unsafe {
    return (*ptr).strong;
  }
}

pub fn Rc.weak_count[T](self) -> Int {
  unsafe {
    return (*ptr).weak;
  }
}

pub fn Rc.get[T](self) -> T
  requires: ptr != null
{
  unsafe {
    return (*ptr).value;
  }
}

pub fn Rc.ptr_eq[T, U](self, other: &Rc[U]) -> Bool
  requires: ptr != null
{
  return ptr as *UInt8 == other.ptr as *UInt8;
}

pub fn Rc.downgrade[T](self) -> Weak[T]
  requires: ptr != null
  ensures:  result.weak_count() > 0
{
  unsafe {
    (*ptr).weak = (*ptr).weak + 1;
  }
  return Weak[T]{ ptr: ptr };
}

pub fn Rc.unwrap_or_clone[T: Clone](self) -> T {
  let val = self.get();
  let count = self.strong_count();
  if count == 1 {
    return val;
  }
  return val.clone();
}

pub fn Rc.drop[T](self)
  requires: ptr != null
{
  let layout = alloc.Layout.new(size_of[RcInner[T]]());
  unsafe {
    (*ptr).strong = (*ptr).strong - 1;
     if (*ptr).strong == 0 {
       if (*ptr).weak == 0 {
         alloc.dealloc(ptr as *UInt8, layout.size);
       }
     }
   }
 }

// === M7: Deref impl for Rc[T] ===
// Rc is a shared-ownership pointer. Deref allows `*rc` and auto-deref.
// Note: DerefMut is NOT implemented — Rc provides shared access only.
pub fn Rc[T].deref(self) -> &T
  requires: ptr != null
  ensures: true
{
  unsafe {
    return &(*ptr).value;
  }
}

pub fn Rc[T].as_ref(self) -> &T
  requires: ptr != null
{
  return deref();
}


pub type Weak[T] = {
  ptr: *RcInner[T];
}

pub fn Weak.upgrade[T](self) -> Option[Rc[T]]
  ensures:  result is Some => strong_count() == strong_count()@pre + 1
  ensures:  result is None => strong_count() == 0
{
  unsafe {
    if (*ptr).strong > 0 {
      (*ptr).strong = (*ptr).strong + 1;
      return Some(Rc[T]{ ptr: ptr });
    }
    return None;
  }
}

pub fn Weak.strong_count[T](self) -> Int
  requires: ptr != null
{
  unsafe {
    return (*ptr).strong;
  }
}

pub fn Weak.weak_count[T](self) -> Int {
  unsafe {
    return (*ptr).weak;
  }
}

pub fn Weak.drop[T](self) {
  let layout = alloc.Layout.new(size_of[RcInner[T]]());
  unsafe {
    (*ptr).weak = (*ptr).weak - 1;
    if (*ptr).strong == 0 && (*ptr).weak == 0 {
      alloc.dealloc(ptr as *UInt8, layout.size);
    }
  }
}

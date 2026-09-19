// XIOM -- Reference Counting
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.rc

use xiom.alloc;

fn size_of[T]() -> Int;
fn align_of[T]() -> Int;

/// Control block behind `Rc`/`Weak`: strong and weak counts plus the value.
pub type RcInner[T] = {
  strong: Int;
  weak: Int;
  value: T;
  invariant: strong >= 0;
  invariant: weak >= 0;
  invariant: strong + weak > 0;
}

/// Shared-ownership smart pointer; cloning a handle bumps the strong count.
pub type Rc[T] = {
  ptr: *RcInner[T];
}

/// Allocate a fresh control block with strong count 1 and no weak handles.
pub fn Rc.new[T](value: T) -> Rc[T]
  ensures: strong_count == 1
  ensures: ptr != null
{
  let layout = alloc.Layout.new(size_of[RcInner[T]]());
  let raw = alloc.alloc(layout.size);
  var inner: *RcInner[T];
  unsafe {
    inner = raw as *RcInner[T];
  }
  unsafe {
    (*inner).strong = 1;
    (*inner).weak = 0;
    (*inner).value = value;
  }
  return Rc[T]{ ptr: inner };
}

/// Increment the strong count; the returned handle aliases the same value.
pub fn Rc.clone[T](self) -> Rc[T]
  requires: ptr != null
  ensures:  strong_count() >= 1
{
  unsafe {
    (*ptr).strong = (*ptr).strong + 1;
  }
  return Rc[T]{ ptr: ptr };
}

/// Number of strong handles; at least 1 while any `Rc` is live.
pub fn Rc.strong_count[T](self) -> Int
  requires: ptr != null
  ensures:  result >= 1
{
  unsafe {
    return (*ptr).strong;
  }
}

/// Number of weak handles (they do not keep the value alive).
pub fn Rc.weak_count[T](self) -> Int
  requires: ptr != null
{
  unsafe {
    return (*ptr).weak;
  }
}

/// Read the value by value (moves/copies it out of the control block).
pub fn Rc.get[T](self) -> T
  requires: ptr != null
{
  unsafe {
    return (*ptr).value;
  }
}

/// True when both handles reference the same control block (T and U may differ).
pub fn Rc.ptr_eq[T, U](self, other: &Rc[U]) -> Bool
  requires: ptr != null
{
  unsafe {
    return ptr as *UInt8 == other.ptr as *UInt8;
  }
}

/// Create a `Weak` handle; it does not keep the value alive.
pub fn Rc.downgrade[T](self) -> Weak[T]
  requires: ptr != null
  ensures:  result.weak_count() > 0
{
  unsafe {
    (*ptr).weak = (*ptr).weak + 1;
  }
  return Weak[T]{ ptr: ptr };
}

/// Return the value without cloning when this is the last strong handle;
/// otherwise return a clone.
pub fn Rc.unwrap_or_clone[T: Clone](self) -> T {
  let val = self.get();
  let count = self.strong_count();
  if count == 1 {
    return val;
  }
  return val.clone();
}

/// Decrement the strong count; free the control block when the last strong
/// and weak handles are gone.
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
/// Rc is a shared-ownership pointer. Deref allows `*rc` and auto-deref.
/// Note: DerefMut is NOT implemented -- Rc provides shared access only.
pub fn Rc[T].deref(self) -> &T
  requires: ptr != null
  ensures: true
{
  unsafe {
    return &(*ptr).value;
  }
}

/// Borrow the value as `&T` (shared access only; see `deref`).
pub fn Rc[T].as_ref(self) -> &T
  requires: ptr != null
{
  return deref();
}


/// Non-owning handle; `upgrade` re-acquires a strong `Rc` while the value
/// is alive.
pub type Weak[T] = {
  ptr: *RcInner[T];
}

/// Some(new strong handle) while the value is alive, None after the last
/// strong handle dropped.
pub fn Weak.upgrade[T](self) -> Option[Rc[T]]
  requires: ptr != null
  ensures:  result is Some => strong_count() >= 1
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

/// Strong count observed through the weak handle (0 after the value dies).
pub fn Weak.strong_count[T](self) -> Int
  requires: ptr != null
{
  unsafe {
    return (*ptr).strong;
  }
}

/// Weak count observed through the weak handle.
pub fn Weak.weak_count[T](self) -> Int
  requires: ptr != null
{
  unsafe {
    return (*ptr).weak;
  }
}

/// Decrement the weak count; free the control block when no strong or weak
/// handles remain.
pub fn Weak.drop[T](self) {
  let layout = alloc.Layout.new(size_of[RcInner[T]]());
  unsafe {
    (*ptr).weak = (*ptr).weak - 1;
    if (*ptr).strong == 0 && (*ptr).weak == 0 {
      alloc.dealloc(ptr as *UInt8, layout.size);
    }
  }
}

// XIOM -- Interior Mutability (Cell + RefCell)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Sprint 6D.1: Fixed permanent borrow bug -- Ref/RefMut now hold raw pointers
// to the original RefCell and `release()` decrements the borrow counter.
// Previous implementation copied RefCell by value, making Ref.get() return
// a stale snapshot and never restoring borrow counts.

module xiom.cell

use xiom.ptr;

// ============================================================================
// Cell -- simple interior mutability via unsafe pointer casts
// ============================================================================

pub type Cell[T] = { value: T; }

pub fn Cell.new[T](value: T) -> Cell[T] {
  return Cell[T]{ value: value };
}

pub fn Cell.get[T](self) -> T {
  return value;
}

pub fn Cell.set[T](&mut self, value: T) {
    self.value = value;
}

pub fn Cell.replace[T](&mut self, value: T) -> T
  ensures: result == value@pre
{
  let old = self.value;
  self.value = value;
  return old;
}

pub fn Cell.swap[T](&mut self, other: &mut Cell[T])
  ensures: value == other.value@pre
{
  let temp = self.value;
  self.value = other.value;
  other.value = temp;
}

// ============================================================================
// RefCell -- interior mutability with runtime borrow checking
// ============================================================================

// borrows > 0: active shared borrows
// borrows == -1: one active mutable borrow
// borrows == 0: no active borrows
pub type RefCell[T] = {
  value: T;
  borrows: Int;
  invariant: borrows >= -1;
}

// 6D.1: Ref holds a raw pointer to the ORIGINAL RefCell, not a copy.
pub type Ref[T] = { ptr: *mut RefCell[T]; }

// 6D.1: RefMut holds a raw pointer to the ORIGINAL RefCell.
pub type RefMut[T] = { ptr: *mut RefCell[T]; }

pub fn RefCell.new[T](value: T) -> RefCell[T]
  ensures: borrows == 0
{
  return RefCell[T]{ value: value; borrows: 0 };
}

pub fn RefCell.borrow[T](&mut self) -> Ref[T]
  requires: borrows >= 0
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows == -1 {
      panic("RefCell.borrow: already mutably borrowed");
    };
    (*raw).borrows = (*raw).borrows + 1;
    return Ref[T]{ ptr: raw };
  }
}

pub fn RefCell.borrow_mut[T](&mut self) -> RefMut[T]
  requires: borrows == 0
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows != 0 {
      panic("RefCell.borrow_mut: already borrowed");
    };
    (*raw).borrows = -1;
    return RefMut[T]{ ptr: raw };
  }
}

pub fn RefCell.try_borrow[T](&mut self) -> Option[Ref[T]]
  requires: true
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows == -1 {
      return None;
    };
    (*raw).borrows = (*raw).borrows + 1;
    return Some(Ref[T]{ ptr: raw });
  }
}

pub fn RefCell.try_borrow_mut[T](&mut self) -> Option[RefMut[T]]
  requires: true
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows != 0 {
      return None;
    };
    (*raw).borrows = -1;
    return Some(RefMut[T]{ ptr: raw });
  }
}

pub fn RefCell.replace[T](&mut self, value: T) -> T
  requires: true
  ensures: result == value@pre
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    let old = (*raw).value;
    (*raw).value = value;
    return old;
  }
}

// ============================================================================
// Ref -- shared borrow handle (6D.1: pointer-based, not value copy)
// ============================================================================

// Release the shared borrow. Must be called when done with the Ref.
// Without Drop trait support, the user is responsible for calling this.
pub fn Ref.release[T](self)
  requires: true  // whole-body unsafe borrow release (T007)
{
  unsafe {
    if ptr.is_null() { return; }
    (*ptr).borrows = (*ptr).borrows - 1;
    // borrows must be >= 0 after release (at most one mutable borrow was active)
    // If borrows goes negative, it was released more times than borrowed.
  };
  // ptr is dropped (goes out of scope)
}

// Get the CURRENT value from the RefCell (not a stale copy).
pub fn Ref.get[T](self) -> T
  requires: ptr != null
{
  unsafe {
    return (*ptr).value;
  }
}

// ============================================================================
// RefMut -- mutable borrow handle (6D.1: pointer-based)
// ============================================================================

// Release the mutable borrow. Restores borrows from -1 to 0.
pub fn RefMut.release[T](self)
  requires: true  // whole-body unsafe borrow release (T007)
{
  unsafe {
    if ptr.is_null() { return; }
    // Restore: mutable borrow (-1) -> free (0)
    (*ptr).borrows = 0;
  };
}

// Get the current value. Returns by value (XIOM limitation: no &T references yet).
pub fn RefMut.get[T](self) -> T
  requires: ptr != null
{
  unsafe {
    return (*ptr).value;
  }
}

// Set a new value through the mutable borrow.
pub fn RefMut.set[T](self, value: T)
  requires: ptr != null
{
  unsafe {
    (*ptr).value = value;
  }
}

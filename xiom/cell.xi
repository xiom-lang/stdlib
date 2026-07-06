// XIOM — Interior Mutability
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.cell

use xiom.ptr;

// Cell: provides interior mutability through get/set.
// All mutating methods use unsafe pointer casts to write through &self,
// which is the defining characteristic of interior mutability.
pub type Cell[T] = { value: T; }

pub fn Cell.new[T](value: T) -> Cell[T] {
  return Cell[T]{ value: value };
}

pub fn Cell.get[T](self) -> T {
  return value;
}

pub fn Cell.set[T](self, value: T) {
  unsafe {
    let raw = ptr.from_ref(self) as *mut Cell[T];
    (*raw).value = value;
  };
}

pub fn Cell.replace[T](self, value: T) -> T
  ensures: result == value@pre
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut Cell[T];
    let old = (*raw).value;
    (*raw).value = value;
    return old;
  }
}

pub fn Cell.swap[T](self, other: &Cell[T])
  ensures: value == other.value@pre
{
  unsafe {
    let self_raw = ptr.from_ref(self) as *mut Cell[T];
    let other_raw = ptr.from_ref(other) as *mut Cell[T];
    let temp = (*self_raw).value;
    (*self_raw).value = (*other_raw).value;
    (*other_raw).value = temp;
  };
}

// RefCell: provides interior mutability through runtime borrow checking.
// borrows > 0: active shared borrows
// borrows == -1: one active mutable borrow
// borrows == 0: no active borrows
pub type RefCell[T] = {
  value: T;
  borrows: Int;
  invariant: borrows >= -1;
}

pub fn RefCell.new[T](value: T) -> RefCell[T]
  ensures: borrows == 0
{
  return RefCell[T]{ value: value; borrows: 0 };
}

pub fn RefCell.borrow[T](self) -> Ref[T]
  requires: borrows >= 0
  ensures:  borrows == borrows@pre + 1
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows == -1 {
      panic("RefCell.borrow: already mutably borrowed");
    };
    (*raw).borrows = (*raw).borrows + 1;
  };
  return Ref[T]{ cell: RefCell[T]{ value: value; borrows: borrows } };
}

pub fn RefCell.borrow_mut[T](self) -> RefMut[T]
  requires: borrows == 0
  ensures:  borrows == -1
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows != 0 {
      panic("RefCell.borrow_mut: already borrowed");
    };
    (*raw).borrows = -1;
  };
  return RefMut[T]{ cell: RefCell[T]{ value: value; borrows: borrows } };
}

pub fn RefCell.try_borrow[T](self) -> Option[Ref[T]]
  ensures: result is Some => borrows increased
  ensures: result is None => borrows unchanged
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows == -1 {
      return None;
    };
    (*raw).borrows = (*raw).borrows + 1;
  };
  return Some(Ref[T]{ cell: RefCell[T]{ value: value; borrows: borrows } });
}

pub fn RefCell.try_borrow_mut[T](self) -> Option[RefMut[T]]
  ensures: result is Some => borrows changed to write mode
  ensures: result is None => borrows unchanged
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    if (*raw).borrows != 0 {
      return None;
    };
    (*raw).borrows = -1;
  };
  return Some(RefMut[T]{ cell: RefCell[T]{ value: value; borrows: borrows } });
}

pub fn RefCell.replace[T](self, value: T) -> T
  ensures: result is old value
{
  unsafe {
    let raw = ptr.from_ref(self) as *mut RefCell[T];
    let old = (*raw).value;
    (*raw).value = value;
    return old;
  }
}

pub type Ref[T] = { cell: RefCell[T]; }
pub type RefMut[T] = { cell: RefCell[T]; }

pub fn Ref.get[T](self) -> T {
  return cell.value;
}

pub fn RefMut.get[T](self) -> T {
  return cell.value;
}

pub fn RefMut.set[T](self, value: T) {
  cell.value = value;
}

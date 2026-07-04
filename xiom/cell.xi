// XIOM — Interior Mutability
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.cell

// Cell: provides interior mutability through get/set.
// Only works with Copy types (types that are trivially copyable).
pub type Cell[T] = { value: T; }

pub fn Cell.new[T](value: T) -> Cell[T];
pub fn Cell.get[T](self) -> T;
pub fn Cell.set[T](self, value: T);
pub fn Cell.replace[T](self, value: T) -> T;
pub fn Cell.swap[T](self, other: &Cell[T]);

// RefCell: provides interior mutability through runtime borrow checking.
// Panics at runtime if borrowing rules are violated.
pub type RefCell[T] = { value: T; borrows: Int; }

pub fn RefCell.new[T](value: T) -> RefCell[T];
pub fn RefCell.borrow[T](self) -> Ref[T];
pub fn RefCell.borrow_mut[T](self) -> RefMut[T];
pub fn RefCell.try_borrow[T](self) -> Option<Ref[T]>;
pub fn RefCell.try_borrow_mut[T](self) -> Option<RefMut[T]>;
pub fn RefCell.replace[T](self, value: T) -> T;

pub type Ref[T] = { cell: RefCell[T]; }
pub type RefMut[T] = { cell: RefCell[T]; }

pub fn Ref.get[T](self) -> T;
pub fn RefMut.get[T](self) -> T;
pub fn RefMut.set[T](self, value: T);

// XIOM — Reference Counting
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.rc

pub type Rc[T] = { ptr: *T; strong: Int; weak: Int; }

pub fn Rc.new[T](value: T) -> Rc[T];
pub fn Rc.clone[T](self) -> Rc[T]; // increment strong count
pub fn Rc.strong_count[T](self) -> Int;
pub fn Rc.weak_count[T](self) -> Int;
pub fn Rc.get[T](self) -> &T;
pub fn Rc.ptr_eq[T, U](self, other: &Rc[U]) -> Bool;
pub fn Rc.downgrade[T](self) -> Weak[T];
pub fn Rc.unwrap_or_clone[T: Clone](self) -> T;

// Weak reference (doesn't prevent deallocation)
pub type Weak[T] = { ptr: *T; }

pub fn Weak.upgrade[T](self) -> Option<Rc[T]>;
pub fn Weak.strong_count[T](self) -> Int;

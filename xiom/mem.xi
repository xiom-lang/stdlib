// XIOM — Memory Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.mem

pub fn swap[T](a: &mut T, b: &mut T);
pub fn replace[T](dest: &mut T, src: T) -> T;
pub fn take[T: Default](dest: &mut T) -> T;
pub fn drop[T](value: T);

// Size queries
pub fn size_of[T]() -> Int;
pub fn align_of[T]() -> Int;
pub fn size_of_val[T](value: &T) -> Int;
pub fn min_align_of_val[T](value: &T) -> Int;

// Zeroed memory
pub fn zeroed[T]() -> T;

// Uninitialized memory (unsafe)
pub fn uninitialized[T]() -> T;

// Manually drop (defer cleanup)
pub type ManuallyDrop[T] = { value: T; }
pub fn ManuallyDrop.new[T](value: T) -> ManuallyDrop[T];
pub fn ManuallyDrop.into_inner[T](self) -> T;

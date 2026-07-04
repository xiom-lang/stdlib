// XIOM — Pointer Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.ptr

pub fn null[T]() -> *T;
pub fn null_mut[T]() -> *mut T;
pub fn dangling[T]() -> *T;
pub fn is_null[T](ptr: *const T) -> Bool;

pub fn read[T](ptr: *const T) -> T;
pub fn write[T](ptr: *mut T, value: T);
pub fn read_volatile[T](ptr: *const T) -> T;
pub fn write_volatile[T](ptr: *mut T, value: T);

pub fn swap[T](a: *mut T, b: *mut T);
pub fn replace[T](dest: *mut T, src: T) -> T;

pub fn copy[T](src: *const T, dst: *mut T, count: Int);
pub fn copy_nonoverlapping[T](src: *const T, dst: *mut T, count: Int);

pub fn eq[T](a: *const T, b: *const T) -> Bool;

pub fn offset[T](ptr: *const T, count: Int) -> *const T;
pub fn wrapping_offset[T](ptr: *const T, count: Int) -> *const T;
pub fn add[T](ptr: *const T, count: Int) -> *const T;
pub fn sub[T](ptr: *const T, count: Int) -> *const T;

pub fn from_ref[T](r: &T) -> *const T;
pub fn from_mut[T](r: &mut T) -> *mut T;

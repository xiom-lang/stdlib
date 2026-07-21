// XIOM — Comparison & Ordering
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.cmp

pub type Ordering = enum { Less, Equal, Greater }

pub fn Ordering.reverse(self) -> Ordering
  ensures: match self { Less => result == Greater, Equal => result == Equal, Greater => result == Less }
{
  match self {
    Less => Greater;
    Equal => Equal;
    Greater => Less;
  }
}

pub fn Ordering.then(self, other: Ordering) -> Ordering
  ensures: self != Equal => result == self
{
  if self != Equal {
    return self;
  };
  other
}

pub fn Ordering.then_with(self, f: fn() -> Ordering) -> Ordering {
  if self != Equal {
    return self;
  };
  f()
}

pub fn min[T: Ord](a: T, b: T) -> T
  ensures: result == a || result == b
  ensures: result.compare(a) <= 0 && result.compare(b) <= 0
{
  if a.compare(b) <= 0 {
    a
  } else {
    b
  }
}

pub fn max[T: Ord](a: T, b: T) -> T
  ensures: result == a || result == b
  ensures: result.compare(a) >= 0 && result.compare(b) >= 0
{
  if a.compare(b) >= 0 {
    a
  } else {
    b
  }
}

pub fn clamp[T: Ord](value: T, min_val: T, max_val: T) -> T
  requires: min_val.compare(max_val) <= 0
  ensures: result.compare(min_val) >= 0 && result.compare(max_val) <= 0
{
  if value.compare(min_val) < 0 {
    min_val
  } elif value.compare(max_val) > 0 {
    max_val
  } else {
    value
  }
}

pub fn min_by[T](a: T, b: T, compare: fn(&T, &T) -> Ordering) -> T {
  match compare(&a, &b) {
    Less => a;
    Equal => a;
    Greater => b;
  }
}

pub fn max_by[T](a: T, b: T, compare: fn(&T, &T) -> Ordering) -> T {
  match compare(&a, &b) {
    Greater => a;
    Equal => a;
    Less => b;
  }
}

pub fn max_int(a: Int, b: Int) -> Int {
  if a >= b { a } else { b }
}

pub fn min_int(a: Int, b: Int) -> Int {
  if a <= b { a } else { b }
}

pub fn clamp_int(value: Int, min_val: Int, max_val: Int) -> Int
  requires: min_val <= max_val
  ensures: min_val <= result <= max_val
{
  if value < min_val {
    min_val
  } elif value > max_val {
    max_val
  } else {
    value
  }
}

pub fn max_float(a: Float64, b: Float64) -> Float64 {
  if a >= b { a } else { b }
}

pub fn min_float(a: Float64, b: Float64) -> Float64 {
  if a <= b { a } else { b }
}

pub fn clamp_float(value: Float64, min_val: Float64, max_val: Float64) -> Float64 {
  if value < min_val {
    min_val
  } elif value > max_val {
    max_val
  } else {
    value
  }
}

// Partial comparison (for types that may not be comparable)
pub interface PartialEq[Rhs: Self] {
  fn eq(self, other: &Rhs) -> Bool;
  fn ne(self, other: &Rhs) -> Bool;
}
pub interface PartialOrd[Rhs: Self] {
  fn partial_cmp(self, other: &Rhs) -> Option[Ordering];
  fn lt(self, other: &Rhs) -> Bool;
  fn le(self, other: &Rhs) -> Bool;
  fn gt(self, other: &Rhs) -> Bool;
  fn ge(self, other: &Rhs) -> Bool;
}

// Reverse ordering wrapper
pub type Reverse[T] = { value: T; }
pub fn Reverse.new[T](value: T) -> Reverse[T] {
  Reverse { value: value; }
}

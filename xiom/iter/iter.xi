// XIOM -- Iterator Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter

use xiom.iter.range;
use xiom.iter.map;
use xiom.iter.filter;
use xiom.iter.zip;
use xiom.iter.chain;
use xiom.iter.fold;

// === Range types ===
pub type Range = { start: Int; end: Int; }
pub type RangeInclusive = { start: Int; end: Int; current: Int; done: Bool; }

pub fn range(start: Int, end: Int) -> Range {
  Range { start: start; end: end; }
}

pub fn range_inclusive(start: Int, end: Int) -> RangeInclusive {
  RangeInclusive { start: start; end: end; current: start; done: false; }
}

pub fn Range.next(self) -> Option[Int]
  ensures: true {
  if self.start < self.end {
    let val = self.start;
    self.start = self.start + 1;
    Some(val)
  } else {
    None
  }
}

pub fn Range.len(self) -> Int
  ensures: result >= 0 {
  if self.start < self.end {
    self.end - self.start
  } else {
    0
  }
}

pub fn Range.contains(self, x: Int) -> Bool {
  x >= self.start && x < self.end
}

pub fn Range.sum(self) -> Int {
  var total: Int = 0;
  var i: Int = self.start;
  while i < self.end {
    total = total + i;
    i = i + 1;
  }
  total
}

pub fn Range.product(self) -> Int {
  var total: Int = 1;
  var i: Int = self.start;
  if self.start >= self.end {
    return 1;
  }
  while i < self.end {
    total = total * i;
    i = i + 1;
  }
  total
}

pub fn RangeInclusive.next(self) -> Option[Int] {
  if self.done {
    None
  } else {
    let val = self.current;
    if self.current >= self.end {
      self.done = true;
    } else {
      self.current = self.current + 1;
    }
    Some(val)
  }
}

// === Iterator adapters (closure-based) ===
// The previous design stored iter: Iterator[T] interface values -- the
// checker has no interface-as-value, so those fields defaulted to i64 and
// every adapter call corrupted. The new design stores a NEXT-CLOSURE
// (fn() -> Option[T]); the closure env holds the mutable iterator state.

fn _collect_via[T](next_fn: fn() -> Option[T]) -> Vec[T] {
  var result = Vec[T].new();
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => { result.push(v); item = next_fn(); },
      None => {},
    };
  }
  result
}

fn _fold_via[T, B](next_fn: fn() -> Option[T], init: B, f: fn(B, T) -> B) -> B {
  var acc = init;
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => { acc = f(acc, v); item = next_fn(); },
      None => {},
    };
  }
  acc
}

fn _count_via[T](next_fn: fn() -> Option[T]) -> Int {
  var n = 0;
  var item = next_fn();
  while item is Some {
    n = n + 1;
    item = next_fn();
  }
  n
}

fn _sum_via[T](next_fn: fn() -> Option[T]) -> T {
  var total: T = 0;
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => { total = total + v; item = next_fn(); },
      None => {},
    };
  }
  total
}

fn _product_via[T](next_fn: fn() -> Option[T]) -> T {
  var acc: T = 1;
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => { acc = acc * v; item = next_fn(); },
      None => {},
    };
  }
  acc
}

fn _max_via[T](next_fn: fn() -> Option[T]) -> Option[T] {
  var item = next_fn();
  match item {
    None => { return None; },
    Some(first) => {
      var max_val = first;
      item = next_fn();
      while item is Some {
        match item {
          Some(v) => { if v > max_val { max_val = v; }; item = next_fn(); },
          None => {},
        };
      }
      return Some(max_val);
    },
  }
}

fn _min_via[T](next_fn: fn() -> Option[T]) -> Option[T] {
  var item = next_fn();
  match item {
    None => { return None; },
    Some(first) => {
      var min_val = first;
      item = next_fn();
      while item is Some {
        match item {
          Some(v) => { if v < min_val { min_val = v; }; item = next_fn(); },
          None => {},
        };
      }
      return Some(min_val);
    },
  }
}

pub fn Range.map[U](self, f: fn(Int) -> U) -> MapIter[Int, U] {
  var r = self;
  MapIter[Int, U]{ next_fn: fn() -> Option[Int] { return r.next(); }, f: f }
}

pub fn Range.filter(self, predicate: fn(&Int) -> Bool) -> FilterIter[Int] {
  var r = self;
  FilterIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, predicate: predicate }
}

pub fn Range.enumerate(self) -> EnumerateIter[Int] {
  var r = self;
  EnumerateIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, index: 0 }
}

pub fn Range.take(self, n: Int) -> TakeIter[Int] {
  var r = self;
  TakeIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, remaining: n }
}

pub fn Range.skip(self, n: Int) -> SkipIter[Int] {
  var r = self;
  SkipIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, to_skip: n }
}

pub fn Range.chain(self, other: Range) -> ChainIter[Int, Int] {
  var r1 = self;
  var r2 = other;
  // The next_fn closure consumes ONLY the first source; ChainIter.next
  // hands off to second() when it returns None. Consuming r2 here TOO
  // double-captured it (the closure's env copy and second()'s env copy
  // diverge -- second() replayed r2's elements after the closure
  // exhausted its own copy: chain(1..4, 10..13) counted 9).
  ChainIter[Int, Int]{ next_fn: fn() -> Option[Int] { return r1.next(); }, second: fn() -> Option[Int] { return r2.next(); } }
}

pub fn Range.zip(self, other: Range) -> ZipIter[Int, Int] {
  var r1 = self;
  var r2 = other;
  ZipIter[Int, Int]{ a: fn() -> Option[Int] { return r1.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

pub fn Range.collect(self) -> Vec[Int] {
  var r = self;
  return _collect_via[Int](fn() -> Option[Int] { return r.next(); });
}

pub fn Range.fold[B](self, init: B, f: fn(B, Int) -> B) -> B {
  var r = self;
  return _fold_via[Int, B](fn() -> Option[Int] { return r.next(); }, init, f);
}

pub fn Range.count(self) -> Int {
  var r = self;
  return _count_via[Int](fn() -> Option[Int] { return r.next(); });
}

pub fn Range.max(self) -> Option[Int] {
  var r = self;
  return _max_via[Int](fn() -> Option[Int] { return r.next(); });
}

pub fn Range.min(self) -> Option[Int] {
  var r = self;
  return _min_via[Int](fn() -> Option[Int] { return r.next(); });
}

pub type MapIter[T, U] = { next_fn: fn() -> Option[T]; f: fn(T) -> U; }
pub type FilterIter[T] = { next_fn: fn() -> Option[T]; predicate: fn(&T) -> Bool; }
pub type EnumerateIter[T] = { next_fn: fn() -> Option[T]; index: Int; }
pub type TakeIter[T] = { next_fn: fn() -> Option[T]; remaining: Int; }
pub type SkipIter[T] = { next_fn: fn() -> Option[T]; to_skip: Int; }
pub type ChainIter[T, U] = { next_fn: fn() -> Option[T]; second: fn() -> Option[U]; }
pub type ZipIter[T, U] = { a: fn() -> Option[T]; b: fn() -> Option[U]; }

pub fn MapIter[T, U].next(self) -> Option[U] {
  match self.next_fn() {
    Some(v) => { return Some(self.f(v)); },
    None => { return None; },
  }
}

pub fn FilterIter[T].next(self) -> Option[T] {
  var item = self.next_fn();
  while item is Some {
    match item {
      Some(v) => {
        if self.predicate(&v) { return Some(v); };
        item = self.next_fn();
      },
      None => {},
    };
  }
  None
}

pub fn EnumerateIter[T].next(self) -> Option[(Int, T)] {
  match self.next_fn() {
    Some(v) => {
      let idx = self.index;
      self.index = self.index + 1;
      return Some((idx, v));
    },
    None => { return None; },
  }
}

pub fn TakeIter[T].next(self) -> Option[T] {
  if self.remaining <= 0 {
    return None;
  }
  self.remaining = self.remaining - 1;
  return self.next_fn();
}

pub fn SkipIter[T].next(self) -> Option[T] {
  while self.to_skip > 0 {
    self.to_skip = self.to_skip - 1;
    match self.next_fn() {
      Some(_) => {},
      None => { return None; },
    }
  }
  return self.next_fn();
}

pub fn ChainIter[T, U].next(self) -> Option[T] {
  match self.next_fn() {
    Some(v) => { return Some(v); },
    None => { return self.second(); },
  }
}

pub fn ZipIter[T, U].next(self) -> Option[(T, U)] {
  match self.a() {
    Some(x) => {
      match self.b() {
        Some(y) => { return Some((x, y)); },
        None => { return None; },
      }
    },
    None => { return None; },
  }
}

// ---- per-adapter transforming + terminal methods ----

pub fn MapIter[T, U].map[V](self, f: fn(U) -> V) -> MapIter[U, V] {
  var it = self;
  MapIter[U, V]{ next_fn: fn() -> Option[U] { return it.next(); }, f: f }
}

pub fn MapIter[T, U].filter(self, predicate: fn(&U) -> Bool) -> FilterIter[U] {
  var it = self;
  FilterIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, predicate: predicate }
}

pub fn MapIter[T, U].enumerate(self) -> EnumerateIter[U] {
  var it = self;
  EnumerateIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, index: 0 }
}

pub fn MapIter[T, U].take(self, n: Int) -> TakeIter[U] {
  var it = self;
  TakeIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, remaining: n }
}

pub fn MapIter[T, U].skip(self, n: Int) -> SkipIter[U] {
  var it = self;
  SkipIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, to_skip: n }
}

pub fn MapIter[T, U].chain(self, other: Range) -> ChainIter[U, Int] {
  var it = self;
  var r2 = other;
  // next_fn consumes only the first source (see Range.chain).
  ChainIter[U, Int]{ next_fn: fn() -> Option[U] { return it.next(); }, second: fn() -> Option[Int] { return r2.next(); } }
}

pub fn MapIter[T, U].zip(self, other: Range) -> ZipIter[U, Int] {
  var it = self;
  var r2 = other;
  ZipIter[U, Int]{ a: fn() -> Option[U] { return it.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

pub fn MapIter[T, U].collect(self) -> Vec[U] {
  var it = self;
  return _collect_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn MapIter[T, U].fold[B](self, init: B, f: fn(B, U) -> B) -> B {
  var it = self;
  return _fold_via[U, B](fn() -> Option[U] { return it.next(); }, init, f);
}

pub fn MapIter[T, U].count(self) -> Int {
  var it = self;
  return _count_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn MapIter[T, U].sum(self) -> U {
  var it = self;
  return _sum_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn MapIter[T, U].product(self) -> U {
  var it = self;
  return _product_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn MapIter[T, U].max(self) -> Option[U] {
  var it = self;
  return _max_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn MapIter[T, U].min(self) -> Option[U] {
  var it = self;
  return _min_via[U](fn() -> Option[U] { return it.next(); });
}

pub fn FilterIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

pub fn FilterIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

pub fn FilterIter[T].enumerate(self) -> EnumerateIter[T] {
  var it = self;
  EnumerateIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, index: 0 }
}

pub fn FilterIter[T].take(self, n: Int) -> TakeIter[T] {
  var it = self;
  TakeIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, remaining: n }
}

pub fn FilterIter[T].skip(self, n: Int) -> SkipIter[T] {
  var it = self;
  SkipIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, to_skip: n }
}

pub fn FilterIter[T].chain(self, other: Range) -> ChainIter[T, Int] {
  var it = self;
  var r2 = other;
  // next_fn consumes only the first source (see Range.chain).
  ChainIter[T, Int]{ next_fn: fn() -> Option[T] { return it.next(); }, second: fn() -> Option[Int] { return r2.next(); } }
}

pub fn FilterIter[T].zip(self, other: Range) -> ZipIter[T, Int] {
  var it = self;
  var r2 = other;
  ZipIter[T, Int]{ a: fn() -> Option[T] { return it.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

pub fn FilterIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn FilterIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

pub fn FilterIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn FilterIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn FilterIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn FilterIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn FilterIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn EnumerateIter[T].map[U](self, f: fn((Int, T)) -> U) -> MapIter[(Int, T), U] {
  var it = self;
  MapIter[(Int, T), U]{ next_fn: fn() -> Option[(Int, T)] { return it.next(); }, f: f }
}

pub fn EnumerateIter[T].take(self, n: Int) -> TakeIter[(Int, T)] {
  var it = self;
  TakeIter[(Int, T)]{ next_fn: fn() -> Option[(Int, T)] { return it.next(); }, remaining: n }
}

pub fn EnumerateIter[T].collect(self) -> Vec[(Int, T)] {
  var result = Vec[(Int, T)].new();
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { result.push(v); item = self.next(); },
      None => {},
    };
  }
  result
}

pub fn EnumerateIter[T].count(self) -> Int {
  var it = self;
  return _count_via[(Int, T)](fn() -> Option[(Int, T)] { return it.next(); });
}

pub fn TakeIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

pub fn TakeIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

pub fn TakeIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn TakeIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

pub fn TakeIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn TakeIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn TakeIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn TakeIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn TakeIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

pub fn SkipIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

pub fn SkipIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

pub fn SkipIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn SkipIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

pub fn ChainIter[T, U].collect(self) -> Vec[T] {
  var result = Vec[T].new();
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { result.push(v); item = self.next(); },
      None => {},
    };
  }
  result
}

pub fn ChainIter[T, U].count(self) -> Int {
  var n = 0;
  var item = self.next();
  while item is Some {
    n = n + 1;
    item = self.next();
  }
  n
}

pub fn ChainIter[T, U].map[V](self, f: fn(T) -> V) -> MapIter[T, V] {
  var it = self;
  MapIter[T, V]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

pub fn ChainIter[T, U].take(self, n: Int) -> TakeIter[T] {
  var it = self;
  TakeIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, remaining: n }
}

pub fn ZipIter[T, U].collect(self) -> Vec[(T, U)] {
  var result = Vec[(T, U)].new();
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { result.push(v); item = self.next(); },
      None => {},
    };
  }
  result
}

pub fn ZipIter[T, U].count(self) -> Int {
  var n = 0;
  var item = self.next();
  while item is Some {
    n = n + 1;
    item = self.next();
  }
  n
}


// === M7: Additional iterator adapters ===

// StepBy -- yields every nth element (1-based step)
pub type StepByIter[T] = { iter: Iterator[T]; step: Int; first: Bool; }

pub fn Iterator[T].step_by(self, step: Int) -> StepByIter[T]
  requires: step > 0
{
  StepByIter { iter: self; step: step; first: true; }
}

pub fn StepByIter[T].next(self) -> Option[T]
  ensures: true
{
  if self.first {
    self.first = false;
    return self.iter.next();
  };
  var i = 0;
  while i < self.step - 1 {
    self.iter.next();
    i = i + 1;
  };
  self.iter.next()
}

// TakeWhile -- yields elements while predicate is true
pub type TakeWhileIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; done: Bool; }

pub fn Iterator[T].take_while(self, predicate: fn(&T) -> Bool) -> TakeWhileIter[T] {
  TakeWhileIter { iter: self; predicate: predicate; done: false; }
}

pub fn TakeWhileIter[T].next(self) -> Option[T]
  ensures: self.done => result is None
{
  if self.done {
    return None;
  };
  match self.iter.next() {
    Some(v) => {
      if self.predicate(&v) {
        return Some(v);
      } else {
        self.done = true;
        return None;
      };
    },
    None => None,
  }
}

// SkipWhile -- skips elements while predicate is true, then yields rest
pub type SkipWhileIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; skipped: Bool; }

pub fn Iterator[T].skip_while(self, predicate: fn(&T) -> Bool) -> SkipWhileIter[T] {
  SkipWhileIter { iter: self; predicate: predicate; skipped: false; }
}

pub fn SkipWhileIter[T].next(self) -> Option[T] {
  if !self.skipped {
    var item = self.iter.next();
    while item is Some {
      match item {
        Some(v) => {
          if !self.predicate(&v) {
            self.skipped = true;
            return Some(v);
          };
          item = self.iter.next();
        },
        None => { return None; },
      };
    };
    return None;
  };
  self.iter.next()
}

// Inspect -- calls f on each element for side effects, passes element through
pub type InspectIter[T] = { iter: Iterator[T]; f: fn(&T); }

pub fn Iterator[T].inspect(self, f: fn(&T)) -> InspectIter[T] {
  InspectIter { iter: self; f: f; }
}

pub fn InspectIter[T].next(self) -> Option[T] {
  match self.iter.next() {
    Some(v) => { self.f(&v); Some(v) },
    None => None,
  }
}

// -- RangeStep / Repeat ------------------------------------------------------

/// Create a Vec[Int] containing values from start to end advancing by step.
/// Returns empty Vec if step <= 0 or start >= end. O(N).
pub fn range_step(start: Int, end: Int, step: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if step <= 0 { return result; };
  var i = start;
  while i < end {
    result.push(i);
    i = i + step;
  };
  result
}

/// Create a Vec[Int] containing `value` repeated `n` times. O(N).
/// Returns empty Vec if n <= 0.
pub fn repeat_n(value: Int, n: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if n <= 0 { return result; };
  var i = 0;
  while i < n {
    result.push(value);
    i = i + 1;
  };
  result
}
// XIOM -- Iterator Library
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.iter

use xiom.iter.range;
use xiom.iter.map;
use xiom.iter.filter;
use xiom.iter.zip;
use xiom.iter.chain;
use xiom.iter.fold;

/// === Range types ===
/// Half-open integer range [start, end).
pub type Range = { start: Int; end: Int; }
/// Inclusive integer range [start, end] with cursor state.
pub type RangeInclusive = { start: Int; end: Int; current: Int; done: Bool; }

/// Create a half-open range [start, end).
pub fn range(start: Int, end: Int) -> Range {
  Range { start: start; end: end; }
}

/// Create an inclusive range [start, end].
pub fn range_inclusive(start: Int, end: Int) -> RangeInclusive {
  RangeInclusive { start: start; end: end; current: start; done: false; }
}

/// Yield the next integer; None once `start >= end`. Consumes from the front.
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

/// Number of integers left in the range.
pub fn Range.len(self) -> Int
  ensures: result >= 0 {
  if self.start < self.end {
    self.end - self.start
  } else {
    0
  }
}

/// True when `x` is inside [start, end); does not consume the range.
pub fn Range.contains(self, x: Int) -> Bool {
  x >= self.start && x < self.end
}

/// Sum of the remaining integers (0 for an empty range).
pub fn Range.sum(self) -> Int {
  var total: Int = 0;
  var i: Int = self.start;
  while i < self.end {
    total = total + i;
    i = i + 1;
  }
  total
}

/// Product of the remaining integers (1 for an empty range).
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

/// Yield the next integer; None after the inclusive end was reached.
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

fn _find_via[T](next_fn: fn() -> Option[T], predicate: fn(&T) -> Bool) -> Option[T] {
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => {
        if predicate(&v) { return Some(v); };
        item = next_fn();
      },
      None => {},
    };
  }
  None
}

fn _all_via[T](next_fn: fn() -> Option[T], predicate: fn(&T) -> Bool) -> Bool {
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => {
        if !predicate(&v) { return false; };
        item = next_fn();
      },
      None => {},
    };
  }
  true
}

fn _any_via[T](next_fn: fn() -> Option[T], predicate: fn(&T) -> Bool) -> Bool {
  var item = next_fn();
  while item is Some {
    match item {
      Some(v) => {
        if predicate(&v) { return true; };
        item = next_fn();
      },
      None => {},
    };
  }
  false
}

fn _nth_via[T](next_fn: fn() -> Option[T], n: Int) -> Option[T] {
  var i = 0;
  while i < n {
    match next_fn() {
      Some(_) => {},
      None => { return None; },
    }
    i = i + 1;
  }
  next_fn()
}

fn _last_via[T](next_fn: fn() -> Option[T]) -> Option[T] {
  var item = next_fn();
  match item {
    None => { return None; },
    Some(first) => {
      var last_val = first;
      item = next_fn();
      while item is Some {
        match item {
          Some(v) => { last_val = v; item = next_fn(); },
          None => {},
        };
      }
      return Some(last_val);
    },
  }
}

/// Lazily apply `f` to each integer in the range.
pub fn Range.map[U](self, f: fn(Int) -> U) -> MapIter[Int, U] {
  var r = self;
  MapIter[Int, U]{ next_fn: fn() -> Option[Int] { return r.next(); }, f: f }
}

/// Lazily keep only integers satisfying `predicate`.
pub fn Range.filter(self, predicate: fn(&Int) -> Bool) -> FilterIter[Int] {
  var r = self;
  FilterIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, predicate: predicate }
}

/// Pair each integer with its 0-based position.
pub fn Range.enumerate(self) -> EnumerateIter[Int] {
  var r = self;
  EnumerateIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, index: 0 }
}

/// Yield at most the first `n` integers.
pub fn Range.take(self, n: Int) -> TakeIter[Int] {
  var r = self;
  TakeIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, remaining: n }
}

/// Skip the first `n` integers.
pub fn Range.skip(self, n: Int) -> SkipIter[Int] {
  var r = self;
  SkipIter[Int]{ next_fn: fn() -> Option[Int] { return r.next(); }, to_skip: n }
}

/// Continue with the integers of `other` after this range ends.
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

/// Pair integers with `other` until either runs out.
pub fn Range.zip(self, other: Range) -> ZipIter[Int, Int] {
  var r1 = self;
  var r2 = other;
  ZipIter[Int, Int]{ a: fn() -> Option[Int] { return r1.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

/// Drain the remaining integers into a Vec.
pub fn Range.collect(self) -> Vec[Int] {
  var r = self;
  return _collect_via[Int](fn() -> Option[Int] { return r.next(); });
}

/// Fold the remaining integers with `f`, starting from `init`.
pub fn Range.fold[B](self, init: B, f: fn(B, Int) -> B) -> B {
  var r = self;
  return _fold_via[Int, B](fn() -> Option[Int] { return r.next(); }, init, f);
}

/// Number of remaining integers.
pub fn Range.count(self) -> Int {
  var r = self;
  return _count_via[Int](fn() -> Option[Int] { return r.next(); });
}

/// Largest remaining integer, or None for an empty range.
pub fn Range.max(self) -> Option[Int] {
  var r = self;
  return _max_via[Int](fn() -> Option[Int] { return r.next(); });
}

/// Smallest remaining integer, or None for an empty range.
pub fn Range.min(self) -> Option[Int] {
  var r = self;
  return _min_via[Int](fn() -> Option[Int] { return r.next(); });
}

/// First remaining integer satisfying `predicate`, or None.
pub fn Range.find(self, predicate: fn(&Int) -> Bool) -> Option[Int] {
  var r = self;
  return _find_via[Int](fn() -> Option[Int] { return r.next(); }, predicate);
}

/// True when every remaining integer satisfies `predicate`.
pub fn Range.all(self, predicate: fn(&Int) -> Bool) -> Bool {
  var r = self;
  return _all_via[Int](fn() -> Option[Int] { return r.next(); }, predicate);
}

/// True when at least one remaining integer satisfies `predicate`.
pub fn Range.any(self, predicate: fn(&Int) -> Bool) -> Bool {
  var r = self;
  return _any_via[Int](fn() -> Option[Int] { return r.next(); }, predicate);
}

/// Skip to and return the `n`-th remaining integer (0-based), or None.
pub fn Range.nth(self, n: Int) -> Option[Int] {
  var r = self;
  return _nth_via[Int](fn() -> Option[Int] { return r.next(); }, n);
}

/// Consume and return the final integer, or None for an empty range.
pub fn Range.last(self) -> Option[Int] {
  var r = self;
  return _last_via[Int](fn() -> Option[Int] { return r.next(); });
}

/// Lazy map iterator, produced by `map`.
pub type MapIter[T, U] = { next_fn: fn() -> Option[T]; f: fn(T) -> U; }
/// Lazy filter iterator, produced by `filter`.
pub type FilterIter[T] = { next_fn: fn() -> Option[T]; predicate: fn(&T) -> Bool; }
/// Iterator pairing elements with a 0-based index.
pub type EnumerateIter[T] = { next_fn: fn() -> Option[T]; index: Int; }
/// Iterator yielding at most a fixed number of elements.
pub type TakeIter[T] = { next_fn: fn() -> Option[T]; remaining: Int; }
/// Iterator skipping a fixed number of leading elements.
pub type SkipIter[T] = { next_fn: fn() -> Option[T]; to_skip: Int; }
/// Iterator continuing with a second iterator after the first ends.
pub type ChainIter[T, U] = { next_fn: fn() -> Option[T]; second: fn() -> Option[U]; }
/// Iterator pairing elements of two iterators.
pub type ZipIter[T, U] = { a: fn() -> Option[T]; b: fn() -> Option[U]; }

/// Advance and apply the mapping function; None when exhausted.
pub fn MapIter[T, U].next(self) -> Option[U] {
  match self.next_fn() {
    Some(v) => { return Some(self.f(v)); },
    None => { return None; },
  }
}

/// Advance to the next element satisfying the predicate; None when exhausted.
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

/// Yield (index, element); None when exhausted.
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

/// Yield the next element while the limit lasts; None after.
pub fn TakeIter[T].next(self) -> Option[T] {
  if self.remaining <= 0 {
    return None;
  }
  self.remaining = self.remaining - 1;
  return self.next_fn();
}

/// Skip the configured prefix, then yield elements; None when exhausted.
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

/// Yield from the first iterator, then from the second; None when both end.
pub fn ChainIter[T, U].next(self) -> Option[T] {
  match self.next_fn() {
    Some(v) => { return Some(v); },
    None => { return self.second(); },
  }
}

/// Yield the next (a, b) pair; None when either side ends.
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

/// ---- per-adapter transforming + terminal methods ----
/// Lazily apply `f` to each mapped element.
pub fn MapIter[T, U].map[V](self, f: fn(U) -> V) -> MapIter[U, V] {
  var it = self;
  MapIter[U, V]{ next_fn: fn() -> Option[U] { return it.next(); }, f: f }
}

/// Lazily keep mapped elements satisfying `predicate`.
pub fn MapIter[T, U].filter(self, predicate: fn(&U) -> Bool) -> FilterIter[U] {
  var it = self;
  FilterIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, predicate: predicate }
}

/// Pair each mapped element with its 0-based index.
pub fn MapIter[T, U].enumerate(self) -> EnumerateIter[U] {
  var it = self;
  EnumerateIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, index: 0 }
}

/// Yield at most `n` mapped elements.
pub fn MapIter[T, U].take(self, n: Int) -> TakeIter[U] {
  var it = self;
  TakeIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, remaining: n }
}

/// Skip the first `n` mapped elements.
pub fn MapIter[T, U].skip(self, n: Int) -> SkipIter[U] {
  var it = self;
  SkipIter[U]{ next_fn: fn() -> Option[U] { return it.next(); }, to_skip: n }
}

/// Continue with the integers of `other` after this iterator ends.
pub fn MapIter[T, U].chain(self, other: Range) -> ChainIter[U, Int] {
  var it = self;
  var r2 = other;
  // next_fn consumes only the first source (see Range.chain).
  ChainIter[U, Int]{ next_fn: fn() -> Option[U] { return it.next(); }, second: fn() -> Option[Int] { return r2.next(); } }
}

/// Pair mapped elements with the integers of `other`.
pub fn MapIter[T, U].zip(self, other: Range) -> ZipIter[U, Int] {
  var it = self;
  var r2 = other;
  ZipIter[U, Int]{ a: fn() -> Option[U] { return it.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

/// Drain the mapped elements into a Vec.
pub fn MapIter[T, U].collect(self) -> Vec[U] {
  var it = self;
  return _collect_via[U](fn() -> Option[U] { return it.next(); });
}

/// Fold the mapped elements with `f`, starting from `init`.
pub fn MapIter[T, U].fold[B](self, init: B, f: fn(B, U) -> B) -> B {
  var it = self;
  return _fold_via[U, B](fn() -> Option[U] { return it.next(); }, init, f);
}

/// Number of remaining mapped elements.
pub fn MapIter[T, U].count(self) -> Int {
  var it = self;
  return _count_via[U](fn() -> Option[U] { return it.next(); });
}

/// Sum of the remaining mapped elements.
pub fn MapIter[T, U].sum(self) -> U {
  var it = self;
  return _sum_via[U](fn() -> Option[U] { return it.next(); });
}

/// Product of the remaining mapped elements.
pub fn MapIter[T, U].product(self) -> U {
  var it = self;
  return _product_via[U](fn() -> Option[U] { return it.next(); });
}

/// Largest remaining mapped element, or None.
pub fn MapIter[T, U].max(self) -> Option[U] {
  var it = self;
  return _max_via[U](fn() -> Option[U] { return it.next(); });
}

/// Smallest remaining mapped element, or None.
pub fn MapIter[T, U].min(self) -> Option[U] {
  var it = self;
  return _min_via[U](fn() -> Option[U] { return it.next(); });
}

/// First mapped element satisfying `predicate`, or None.
pub fn MapIter[T, U].find(self, predicate: fn(&U) -> Bool) -> Option[U] {
  var it = self;
  return _find_via[U](fn() -> Option[U] { return it.next(); }, predicate);
}

/// True when every mapped element satisfies `predicate`.
pub fn MapIter[T, U].all(self, predicate: fn(&U) -> Bool) -> Bool {
  var it = self;
  return _all_via[U](fn() -> Option[U] { return it.next(); }, predicate);
}

/// True when at least one mapped element satisfies `predicate`.
pub fn MapIter[T, U].any(self, predicate: fn(&U) -> Bool) -> Bool {
  var it = self;
  return _any_via[U](fn() -> Option[U] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th mapped element (0-based), or None.
pub fn MapIter[T, U].nth(self, n: Int) -> Option[U] {
  var it = self;
  return _nth_via[U](fn() -> Option[U] { return it.next(); }, n);
}

/// Consume and return the final mapped element, or None.
pub fn MapIter[T, U].last(self) -> Option[U] {
  var it = self;
  return _last_via[U](fn() -> Option[U] { return it.next(); });
}

/// Lazily apply `f` to each filtered element.
pub fn FilterIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

/// Narrow to elements satisfying both predicates.
pub fn FilterIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

/// Pair each filtered element with its 0-based index.
pub fn FilterIter[T].enumerate(self) -> EnumerateIter[T] {
  var it = self;
  EnumerateIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, index: 0 }
}

/// Yield at most `n` filtered elements.
pub fn FilterIter[T].take(self, n: Int) -> TakeIter[T] {
  var it = self;
  TakeIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, remaining: n }
}

/// Skip the first `n` filtered elements.
pub fn FilterIter[T].skip(self, n: Int) -> SkipIter[T] {
  var it = self;
  SkipIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, to_skip: n }
}

/// Continue with the integers of `other` after this iterator ends.
pub fn FilterIter[T].chain(self, other: Range) -> ChainIter[T, Int] {
  var it = self;
  var r2 = other;
  // next_fn consumes only the first source (see Range.chain).
  ChainIter[T, Int]{ next_fn: fn() -> Option[T] { return it.next(); }, second: fn() -> Option[Int] { return r2.next(); } }
}

/// Pair filtered elements with the integers of `other`.
pub fn FilterIter[T].zip(self, other: Range) -> ZipIter[T, Int] {
  var it = self;
  var r2 = other;
  ZipIter[T, Int]{ a: fn() -> Option[T] { return it.next(); }, b: fn() -> Option[Int] { return r2.next(); } }
}

/// Drain the filtered elements into a Vec.
pub fn FilterIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

/// Fold the filtered elements with `f`, starting from `init`.
pub fn FilterIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

/// Number of remaining filtered elements.
pub fn FilterIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

/// Sum of the remaining filtered elements.
pub fn FilterIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

/// Product of the remaining filtered elements.
pub fn FilterIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

/// Largest remaining filtered element, or None.
pub fn FilterIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

/// Smallest remaining filtered element, or None.
pub fn FilterIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

/// First filtered element satisfying `predicate`, or None.
pub fn FilterIter[T].find(self, predicate: fn(&T) -> Bool) -> Option[T] {
  var it = self;
  return _find_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when every filtered element satisfies `predicate`.
pub fn FilterIter[T].all(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _all_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when at least one filtered element satisfies `predicate`.
pub fn FilterIter[T].any(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _any_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th filtered element (0-based), or None.
pub fn FilterIter[T].nth(self, n: Int) -> Option[T] {
  var it = self;
  return _nth_via[T](fn() -> Option[T] { return it.next(); }, n);
}

/// Consume and return the final filtered element, or None.
pub fn FilterIter[T].last(self) -> Option[T] {
  var it = self;
  return _last_via[T](fn() -> Option[T] { return it.next(); });
}

/// Lazily apply `f` to each (index, element) pair.
pub fn EnumerateIter[T].map[U](self, f: fn((Int, T)) -> U) -> MapIter[(Int, T), U] {
  var it = self;
  MapIter[(Int, T), U]{ next_fn: fn() -> Option[(Int, T)] { return it.next(); }, f: f }
}

/// Yield at most `n` (index, element) pairs.
pub fn EnumerateIter[T].take(self, n: Int) -> TakeIter[(Int, T)] {
  var it = self;
  TakeIter[(Int, T)]{ next_fn: fn() -> Option[(Int, T)] { return it.next(); }, remaining: n }
}

/// Drain the (index, element) pairs into a Vec.
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

/// Number of remaining (index, element) pairs.
pub fn EnumerateIter[T].count(self) -> Int {
  var it = self;
  return _count_via[(Int, T)](fn() -> Option[(Int, T)] { return it.next(); });
}

/// Lazily apply `f` to each taken element.
pub fn TakeIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

/// Lazily keep taken elements satisfying `predicate`.
pub fn TakeIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

/// Drain the taken elements into a Vec.
pub fn TakeIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

/// Fold the taken elements with `f`, starting from `init`.
pub fn TakeIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

/// Number of taken elements remaining.
pub fn TakeIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

/// Sum of the taken elements.
pub fn TakeIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

/// Product of the taken elements.
pub fn TakeIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

/// Largest taken element, or None.
pub fn TakeIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

/// Smallest taken element, or None.
pub fn TakeIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

/// First taken element satisfying `predicate`, or None.
pub fn TakeIter[T].find(self, predicate: fn(&T) -> Bool) -> Option[T] {
  var it = self;
  return _find_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when every taken element satisfies `predicate`.
pub fn TakeIter[T].all(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _all_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when at least one taken element satisfies `predicate`.
pub fn TakeIter[T].any(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _any_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th taken element (0-based), or None.
pub fn TakeIter[T].nth(self, n: Int) -> Option[T] {
  var it = self;
  return _nth_via[T](fn() -> Option[T] { return it.next(); }, n);
}

/// Consume and return the final taken element, or None.
pub fn TakeIter[T].last(self) -> Option[T] {
  var it = self;
  return _last_via[T](fn() -> Option[T] { return it.next(); });
}

/// Lazily apply `f` to each element after the skipped prefix.
pub fn SkipIter[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  var it = self;
  MapIter[T, U]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

/// Lazily keep post-prefix elements satisfying `predicate`.
pub fn SkipIter[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  var it = self;
  FilterIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, predicate: predicate }
}

/// Drain the post-prefix elements into a Vec.
pub fn SkipIter[T].collect(self) -> Vec[T] {
  var it = self;
  return _collect_via[T](fn() -> Option[T] { return it.next(); });
}

/// Fold the post-prefix elements with `f`, starting from `init`.
pub fn SkipIter[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var it = self;
  return _fold_via[T, B](fn() -> Option[T] { return it.next(); }, init, f);
}

/// Number of post-prefix elements remaining.
pub fn SkipIter[T].count(self) -> Int {
  var it = self;
  return _count_via[T](fn() -> Option[T] { return it.next(); });
}

/// Sum of the post-prefix elements.
pub fn SkipIter[T].sum(self) -> T {
  var it = self;
  return _sum_via[T](fn() -> Option[T] { return it.next(); });
}

/// Product of the post-prefix elements.
pub fn SkipIter[T].product(self) -> T {
  var it = self;
  return _product_via[T](fn() -> Option[T] { return it.next(); });
}

/// Largest post-prefix element, or None.
pub fn SkipIter[T].max(self) -> Option[T] {
  var it = self;
  return _max_via[T](fn() -> Option[T] { return it.next(); });
}

/// Smallest post-prefix element, or None.
pub fn SkipIter[T].min(self) -> Option[T] {
  var it = self;
  return _min_via[T](fn() -> Option[T] { return it.next(); });
}

/// First post-prefix element satisfying `predicate`, or None.
pub fn SkipIter[T].find(self, predicate: fn(&T) -> Bool) -> Option[T] {
  var it = self;
  return _find_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when every post-prefix element satisfies `predicate`.
pub fn SkipIter[T].all(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _all_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when at least one post-prefix element satisfies `predicate`.
pub fn SkipIter[T].any(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _any_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th post-prefix element (0-based), or None.
pub fn SkipIter[T].nth(self, n: Int) -> Option[T] {
  var it = self;
  return _nth_via[T](fn() -> Option[T] { return it.next(); }, n);
}

/// Consume and return the final post-prefix element, or None.
pub fn SkipIter[T].last(self) -> Option[T] {
  var it = self;
  return _last_via[T](fn() -> Option[T] { return it.next(); });
}

/// Drain the chained elements into a Vec.
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

/// Number of chained elements remaining.
pub fn ChainIter[T, U].count(self) -> Int {
  var n = 0;
  var item = self.next();
  while item is Some {
    n = n + 1;
    item = self.next();
  }
  n
}

/// Lazily apply `f` to each chained element.
pub fn ChainIter[T, U].map[V](self, f: fn(T) -> V) -> MapIter[T, V] {
  var it = self;
  MapIter[T, V]{ next_fn: fn() -> Option[T] { return it.next(); }, f: f }
}

/// Yield at most `n` chained elements.
pub fn ChainIter[T, U].take(self, n: Int) -> TakeIter[T] {
  var it = self;
  TakeIter[T]{ next_fn: fn() -> Option[T] { return it.next(); }, remaining: n }
}

/// First chained element satisfying `predicate`, or None.
pub fn ChainIter[T, U].find(self, predicate: fn(&T) -> Bool) -> Option[T] {
  var it = self;
  return _find_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when every chained element satisfies `predicate`.
pub fn ChainIter[T, U].all(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _all_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// True when at least one chained element satisfies `predicate`.
pub fn ChainIter[T, U].any(self, predicate: fn(&T) -> Bool) -> Bool {
  var it = self;
  return _any_via[T](fn() -> Option[T] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th chained element (0-based), or None.
pub fn ChainIter[T, U].nth(self, n: Int) -> Option[T] {
  var it = self;
  return _nth_via[T](fn() -> Option[T] { return it.next(); }, n);
}

/// Consume and return the final chained element, or None.
pub fn ChainIter[T, U].last(self) -> Option[T] {
  var it = self;
  return _last_via[T](fn() -> Option[T] { return it.next(); });
}

/// Drain the zipped pairs into a Vec.
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

/// Number of pairs remaining on the shorter side.
pub fn ZipIter[T, U].count(self) -> Int {
  var n = 0;
  var item = self.next();
  while item is Some {
    n = n + 1;
    item = self.next();
  }
  n
}

/// First pair satisfying `predicate`, or None.
pub fn ZipIter[T, U].find(self, predicate: fn(&(T, U)) -> Bool) -> Option[(T, U)] {
  var it = self;
  return _find_via[(T, U)](fn() -> Option[(T, U)] { return it.next(); }, predicate);
}

/// True when every remaining pair satisfies `predicate`.
pub fn ZipIter[T, U].all(self, predicate: fn(&(T, U)) -> Bool) -> Bool {
  var it = self;
  return _all_via[(T, U)](fn() -> Option[(T, U)] { return it.next(); }, predicate);
}

/// True when at least one remaining pair satisfies `predicate`.
pub fn ZipIter[T, U].any(self, predicate: fn(&(T, U)) -> Bool) -> Bool {
  var it = self;
  return _any_via[(T, U)](fn() -> Option[(T, U)] { return it.next(); }, predicate);
}

/// Skip to and return the `n`-th pair (0-based), or None.
pub fn ZipIter[T, U].nth(self, n: Int) -> Option[(T, U)] {
  var it = self;
  return _nth_via[(T, U)](fn() -> Option[(T, U)] { return it.next(); }, n);
}

/// Consume and return the final pair, or None.
pub fn ZipIter[T, U].last(self) -> Option[(T, U)] {
  var it = self;
  return _last_via[(T, U)](fn() -> Option[(T, U)] { return it.next(); });
}

// === M7: Additional iterator adapters ===

/// StepBy -- yields every nth element (1-based step)
/// Iterator taking every `step`-th element of an underlying iterator.
pub type StepByIter[T] = { iter: Iterator[T]; step: Int; first: Bool; }

/// Take every `step`-th element, starting with the first.
pub fn Iterator[T].step_by(self, step: Int) -> StepByIter[T]
  requires: step > 0
{
  StepByIter { iter: self; step: step; first: true; }
}

/// Yield the next kept element at the configured stride; None when done.
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

/// TakeWhile -- yields elements while predicate is true
/// Iterator yielding elements while a predicate holds.
pub type TakeWhileIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; done: Bool; }

/// Yield elements while `predicate` holds, then stop permanently.
pub fn Iterator[T].take_while(self, predicate: fn(&T) -> Bool) -> TakeWhileIter[T] {
  TakeWhileIter { iter: self; predicate: predicate; done: false; }
}

/// Yield the next element while the predicate still holds; None once it fails.
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

/// SkipWhile -- skips elements while predicate is true, then yields rest
/// Iterator skipping elements while a predicate holds.
pub type SkipWhileIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; skipped: Bool; }

/// Skip elements while `predicate` holds, then yield the rest.
pub fn Iterator[T].skip_while(self, predicate: fn(&T) -> Bool) -> SkipWhileIter[T] {
  SkipWhileIter { iter: self; predicate: predicate; skipped: false; }
}

/// Yield the next element after the skipped prefix; None when exhausted.
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

/// Inspect -- calls f on each element for side effects, passes element through
/// Iterator running a side effect on each element.
pub type InspectIter[T] = { iter: Iterator[T]; f: fn(&T); }

/// Call `f` on each element as it is consumed, passing it through unchanged.
pub fn Iterator[T].inspect(self, f: fn(&T)) -> InspectIter[T] {
  InspectIter { iter: self; f: f; }
}

/// Run the side effect, then yield the underlying next element.
pub fn InspectIter[T].next(self) -> Option[T] {
  match self.iter.next() {
    Some(v) => { self.f(&v); Some(v) },
    None => None,
  }
}

// -- RangeStep / Repeat ------------------------------------------------------

/// Create a Vec[Int] containing values from start to end advancing by step.
/// Returns empty Vec if step <= 0 or start >= end. O(N).
/// Collect [start, end) stepping by `step` into a Vec (empty when step <= 0).
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
/// Vec with `value` repeated `n` times (empty when n <= 0).
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
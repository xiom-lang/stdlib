// XIOM — Iterator Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter

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

// === Iterator adapters ===
pub fn Iterator[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U] {
  MapIter { iter: self; f: f; }
}

pub fn Iterator[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T] {
  FilterIter { iter: self; predicate: predicate; }
}

pub fn Iterator[T].enumerate(self) -> EnumerateIter[T] {
  EnumerateIter { iter: self; index: 0; }
}

pub fn Iterator[T].take(self, n: Int) -> TakeIter[T] {
  TakeIter { iter: self; remaining: n; }
}

pub fn Iterator[T].skip(self, n: Int) -> SkipIter[T] {
  SkipIter { iter: self; to_skip: n; }
}

pub fn Iterator[T].chain[U](self, other: Iterator[U]) -> ChainIter[T, U] {
  ChainIter { first: self; second: other; }
}

pub fn Iterator[T].zip[U](self, other: Iterator[U]) -> ZipIter[T, U] {
  ZipIter { a: self; b: other; }
}

// === Collectors ===
pub fn Iterator[T].collect(self) -> Vec[T] {
  var result = Vec.new();
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { result.push(v); item = self.next(); },
      None => {},
    };
  }
  result
}

pub fn Iterator[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B {
  var acc = init;
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { acc = f(acc, v); item = self.next(); },
      None => {},
    };
  }
  acc
}

pub fn Iterator[T].count(self) -> Int
  ensures: result >= 0 {
  var n = 0;
  var item = self.next();
  while item is Some {
    n = n + 1;
    item = self.next();
  }
  n
}

pub fn Iterator[T].sum(self) -> T {
  var total: T = 0;
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { total = total + v; item = self.next(); },
      None => {},
    };
  }
  total
}

pub fn Iterator[T].product(self) -> T
  requires: true
  ensures: true
{
  var acc: T = 1;
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => { acc = acc * v; item = self.next(); },
      None => {},
    };
  }
  acc
}

pub fn Iterator[T].max(self) -> Option[T]
  ensures: true
  ensures: true
{
  var item = self.next();
  match item {
    None => None,
    Some(first) => {
      var max_val = first;
      item = self.next();
      while item is Some {
        match item {
          Some(v) => {
            if v > max_val { max_val = v; };
            item = self.next();
          },
          None => {},
        };
      }
      Some(max_val)
    },
  }
}

pub fn Iterator[T].min(self) -> Option[T]
  ensures: true
  ensures: true
{
  var item = self.next();
  match item {
    None => None,
    Some(first) => {
      var min_val = first;
      item = self.next();
      while item is Some {
        match item {
          Some(v) => {
            if v < min_val { min_val = v; };
            item = self.next();
          },
          None => {},
        };
      }
      Some(min_val)
    },
  }
}

pub fn Iterator[T].find(self, predicate: fn(&T) -> Bool) -> Option[T]
  ensures: true
  ensures: true
{
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => {
        if predicate(&v) { return Some(v); };
        item = self.next();
      },
      None => {},
    };
  }
  None
}

pub fn Iterator[T].all(self, predicate: fn(&T) -> Bool) -> Bool {
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => {
        if !predicate(&v) { return false; };
        item = self.next();
      },
      None => {},
    };
  }
  true
}

pub fn Iterator[T].any(self, predicate: fn(&T) -> Bool) -> Bool {
  var item = self.next();
  while item is Some {
    match item {
      Some(v) => {
        if predicate(&v) { return true; };
        item = self.next();
      },
      None => {},
    };
  }
  false
}

pub fn Iterator[T].nth(self, n: Int) -> Option[T]
  requires: n >= 0
  ensures: true
  ensures: true
{
  var item = self.next();
  var i = 0;
  while item is Some {
    if i == n { return item; };
    i = i + 1;
    item = self.next();
  }
  None
}

pub fn Iterator[T].last(self) -> Option[T] {
  var last: Option[T] = None;
  var item = self.next();
  while item is Some {
    last = item;
    item = self.next();
  }
  last
}

// === Adapter types ===
pub type MapIter[T, U] = { iter: Iterator[T]; f: fn(T) -> U; }
pub type FilterIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; }
pub type EnumerateIter[T] = { iter: Iterator[T]; index: Int; }
pub type TakeIter[T] = { iter: Iterator[T]; remaining: Int; }
pub type SkipIter[T] = { iter: Iterator[T]; to_skip: Int; }
pub type ChainIter[T, U] = { first: Iterator[T]; second: Iterator[U]; }
pub type ZipIter[T, U] = { a: Iterator[T]; b: Iterator[U]; }

// === Adapter implementations ===
pub fn MapIter[T, U].next(self) -> Option[U] {
  match self.iter.next() {
    Some(v) => Some(self.f(v)),
    None => None,
  }
}

pub fn FilterIter[T].next(self) -> Option[T] {
  var item = self.iter.next();
  while item is Some {
    match item {
      Some(v) => {
        if self.predicate(&v) { return Some(v); };
        item = self.iter.next();
      },
      None => {},
    };
  }
  None
}

pub fn EnumerateIter[T].next(self) -> Option[(Int, T)] {
  match self.iter.next() {
    Some(v) => {
      let idx = self.index;
      self.index = self.index + 1;
      Some((idx, v))
    },
    None => None,
  }
}

pub fn TakeIter[T].next(self) -> Option[T] {
  if self.remaining <= 0 {
    None
  } else {
    self.remaining = self.remaining - 1;
    self.iter.next()
  }
}

pub fn SkipIter[T].next(self) -> Option[T] {
  while self.to_skip > 0 {
    self.iter.next();
    self.to_skip = self.to_skip - 1;
  }
  self.iter.next()
}

pub fn ChainIter[T, U].next(self) -> Option[T] {
  match self.first.next() {
    Some(v) => Some(v),
    None => self.second.next(),
  }
}

pub fn ZipIter[T, U].next(self) -> Option[(T, U)] {
  match self.a.next() {
    Some(av) => {
      match self.b.next() {
        Some(bv) => Some((av, bv)),
        None => None,
      }
    },
    None => None,
  }
}

// === M7: Additional iterator adapters ===

// StepBy — yields every nth element (1-based step)
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

// TakeWhile — yields elements while predicate is true
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

// SkipWhile — skips elements while predicate is true, then yields rest
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

// Inspect — calls f on each element for side effects, passes element through
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

// ── RangeStep / Repeat ──────────────────────────────────────────────────────

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

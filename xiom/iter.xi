// XIOM — Iterator Library
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter

// === Range types ===
pub type Range = { start: Int; end: Int; }
pub type RangeInclusive = { start: Int; end: Int; current: Int; done: Bool; }

pub fn range(start: Int, end: Int) -> Range;
pub fn range_inclusive(start: Int, end: Int) -> RangeInclusive;

pub fn Range.next(self) -> Option[Int];
pub fn Range.len(self) -> Int;
pub fn Range.contains(self, x: Int) -> Bool;

pub fn RangeInclusive.next(self) -> Option[Int];

// === Iterator adapters ===
pub fn Iterator[T].map[U](self, f: fn(T) -> U) -> MapIter[T, U];
pub fn Iterator[T].filter(self, predicate: fn(&T) -> Bool) -> FilterIter[T];
pub fn Iterator[T].enumerate(self) -> EnumerateIter[T];
pub fn Iterator[T].take(self, n: Int) -> TakeIter[T];
pub fn Iterator[T].skip(self, n: Int) -> SkipIter[T];
pub fn Iterator[T].chain[U](self, other: Iterator[U]) -> ChainIter[T, U];
pub fn Iterator[T].zip[U](self, other: Iterator[U]) -> ZipIter[T, U];

// === Collectors ===
pub fn Iterator[T].collect(self) -> Vec[T];
pub fn Iterator[T].fold[B](self, init: B, f: fn(B, T) -> B) -> B;
pub fn Iterator[T].count(self) -> Int;
pub fn Iterator[T].sum(self) -> T;
pub fn Iterator[T].product(self) -> T;
pub fn Iterator[T].max(self) -> Option[T];
pub fn Iterator[T].min(self) -> Option[T];
pub fn Iterator[T].find(self, predicate: fn(&T) -> Bool) -> Option[T];
pub fn Iterator[T].all(self, predicate: fn(&T) -> Bool) -> Bool;
pub fn Iterator[T].any(self, predicate: fn(&T) -> Bool) -> Bool;
pub fn Iterator[T].nth(self, n: Int) -> Option[T];
pub fn Iterator[T].last(self) -> Option[T];

// === Adapter types ===
pub type MapIter[T, U] = { iter: Iterator[T]; f: fn(T) -> U; }
pub type FilterIter[T] = { iter: Iterator[T]; predicate: fn(&T) -> Bool; }
pub type EnumerateIter[T] = { iter: Iterator[T]; index: Int; }
pub type TakeIter[T] = { iter: Iterator[T]; remaining: Int; }
pub type SkipIter[T] = { iter: Iterator[T]; to_skip: Int; }
pub type ChainIter[T, U] = { first: Iterator[T]; second: Iterator[U]; }
pub type ZipIter[T, U] = { a: Iterator[T]; b: Iterator[U]; }

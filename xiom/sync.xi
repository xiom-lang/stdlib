// XIOM — Synchronization Primitives
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync

use xiom.alloc

// === Mutex ===
pub type Mutex[T] = { data: T; locked: Bool; }

pub fn Mutex.new[T](data: T) -> Mutex[T] {
  Mutex[T]{ data: data; locked: false; }
}

pub fn Mutex.lock[T](self) -> MutexGuard[T] {
  MutexGuard[T]{ mutex: self; }
}

pub fn Mutex.try_lock[T](self) -> Option[MutexGuard[T]] {
  Some(MutexGuard[T]{ mutex: self; })
}

pub type MutexGuard[T] = { mutex: Mutex[T]; }

pub fn MutexGuard.get[T](self) -> T {
  self.mutex.data
}

pub fn MutexGuard.get_mut[T](self) -> T {
  self.mutex.data
}

// === RwLock ===
pub type RwLock[T] = { data: T; readers: Int; writer: Bool; }

pub fn RwLock.new[T](data: T) -> RwLock[T] {
  RwLock[T]{ data: data; readers: 0; writer: false; }
}

pub fn RwLock.read[T](self) -> ReadGuard[T] {
  ReadGuard[T]{ lock: self; }
}

pub fn RwLock.write[T](self) -> WriteGuard[T] {
  WriteGuard[T]{ lock: self; }
}

pub fn RwLock.try_read[T](self) -> Option[ReadGuard[T]] {
  Some(ReadGuard[T]{ lock: self; })
}

pub fn RwLock.try_write[T](self) -> Option[WriteGuard[T]] {
  Some(WriteGuard[T]{ lock: self; })
}

pub type ReadGuard[T] = { lock: RwLock[T]; }
pub type WriteGuard[T] = { lock: RwLock[T]; }

// === Condvar ===
pub type Condvar = { waiters: Int; }

pub fn Condvar.new() -> Condvar {
  Condvar{ waiters: 0; }
}

pub fn Condvar.wait[T](self, guard: MutexGuard[T]) -> MutexGuard[T] {
  guard
}

pub fn Condvar.notify_one(self) {
}

pub fn Condvar.notify_all(self) {
}

// === Once ===
pub type Once = { done: Bool; }

pub fn Once.new() -> Once {
  Once{ done: false; }
}

pub fn Once.call_once(self, f: fn()) {
  if !self.done {
    self.done = true;
    f();
  }
}

// === Arc (Atomic Reference Counted) ===
pub type Arc[T] = {
  ptr: *ArcInner[T];
}

pub type ArcInner[T] = {
  count: Int;
  value: T;
}

pub fn Arc.new[T](value: T) -> Arc[T] {
  let size = size_of[ArcInner[T]];
  unsafe {
    let raw = alloc(size);
    let inner = raw as *mut ArcInner[T];
    (*inner).count = 1;
    (*inner).value = value;
    Arc[T]{ ptr: raw as *ArcInner[T]; }
  }
}

pub fn Arc.clone[T](self) -> Arc[T] {
  unsafe {
    (*self.ptr).count = (*self.ptr).count + 1;
  };
  Arc[T]{ ptr: self.ptr; }
}

pub fn Arc.get[T](self) -> T {
  unsafe {
    (*self.ptr).value
  }
}

pub fn Arc.strong_count[T](self) -> Int {
  unsafe {
    (*self.ptr).count
  }
}

pub fn Arc.ptr_eq[T, U](self, other: &Arc[U]) -> Bool {
  self.ptr as *UInt8 == other.ptr as *UInt8
}

// === Atomic types ===
pub type AtomicBool = { val: Bool; }
pub type AtomicInt = { val: Int; }

pub fn AtomicBool.new(val: Bool) -> AtomicBool {
  AtomicBool{ val: val; }
}

pub fn AtomicBool.load(self) -> Bool {
  self.val
}

pub fn AtomicBool.store(self, val: Bool) {
  self.val = val;
}

pub fn AtomicBool.swap(self, val: Bool) -> Bool {
  let old = self.val;
  self.val = val;
  old
}

pub fn AtomicInt.new(val: Int) -> AtomicInt {
  AtomicInt{ val: val; }
}

pub fn AtomicInt.load(self) -> Int {
  self.val
}

pub fn AtomicInt.store(self, val: Int) {
  self.val = val;
}

pub fn AtomicInt.fetch_add(self, val: Int) -> Int {
  let old = self.val;
  self.val = self.val + val;
  old
}

pub fn AtomicInt.fetch_sub(self, val: Int) -> Int {
  let old = self.val;
  self.val = self.val - val;
  old
}

// === Barrier ===
pub type Barrier = { count: Int; generation: Int; }

pub fn Barrier.new(n: Int) -> Barrier {
  Barrier{ count: n; generation: 0; }
}

pub fn Barrier.wait(self) {
}

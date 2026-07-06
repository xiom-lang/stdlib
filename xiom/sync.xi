// XIOM -- Synchronization Primitives
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sync

use xiom.alloc;
use xiom.ptr;

// Declare threading runtime functions
extern "C" {
  fn xiom_mutex_init(m: *UInt8);
  fn xiom_mutex_lock(m: *UInt8);
  fn xiom_mutex_trylock(m: *UInt8) -> Int32;
  fn xiom_mutex_unlock(m: *UInt8);
  fn xiom_mutex_destroy(m: *UInt8);
  fn xiom_cond_init(c: *UInt8);
  fn xiom_cond_wait(c: *UInt8, m: *UInt8);
  fn xiom_cond_signal(c: *UInt8);
  fn xiom_cond_broadcast(c: *UInt8);
  fn xiom_atomic_load(ptr: *Int) -> Int;
  fn xiom_atomic_store(ptr: *Int, val: Int);
  fn xiom_atomic_fetch_add(ptr: *Int, val: Int) -> Int;
  fn xiom_atomic_fetch_sub(ptr: *Int, val: Int) -> Int;
  fn xiom_atomic_exchange(ptr: *Int, val: Int) -> Int;
  fn xiom_thread_sleep_ms(ms: Int);
  fn xiom_thread_yield();
}

// === Mutex ===
pub type Mutex[T] = {
  inner: *UInt8;  // platform mutex (sizeof(pthread_mutex_t) or CRITICAL_SECTION)
  data: *T;       // heap-allocated protected data
}

pub fn Mutex.new[T](value: T) -> Mutex[T] {
  let m = alloc.alloc(64);  // enough for any platform mutex
  unsafe { xiom_mutex_init(m); }
  let d = alloc.alloc(size_of[T]());
  unsafe { ptr.write(d as *T, value); }
  return Mutex[T]{ inner: m; data: d; }
}

pub fn Mutex.lock[T](self) -> MutexGuard[T] {
  unsafe { xiom_mutex_lock(inner); }
  return MutexGuard[T]{ mutex: self; }
}

pub fn Mutex.try_lock[T](self) -> Option[MutexGuard[T]] {
  unsafe {
    if xiom_mutex_trylock(inner) == 0 {
      return Some(MutexGuard[T]{ mutex: self; });
    }
    return None;
  }
}

pub fn Mutex.into_inner[T](self) -> T {
  unsafe {
    let val = ptr.read(data as *T);
    xiom_mutex_destroy(inner);
    alloc.dealloc(inner, 64);
    alloc.dealloc(data as *UInt8, size_of[T]());
    return val;
  }
}

pub type MutexGuard[T] = {
  mutex: Mutex[T];
}

pub fn MutexGuard.get[T](self) -> T {
  unsafe { return ptr.read(mutex.data as *T); }
}

pub fn MutexGuard.get_mut[T](self) -> T {
  unsafe { return ptr.read(mutex.data as *T); }
}

pub fn MutexGuard.drop[T](self) {
  unsafe { xiom_mutex_unlock(mutex.inner); }
}

// === RwLock ===
pub type RwLock[T] = {
  inner: *UInt8;     // platform mutex
  rcond: *UInt8;     // condvar for readers
  wcond: *UInt8;     // condvar for writers
  data: *T;          // heap-allocated protected data
  state: *Int;       // atomic state: 0=free, >0 = reader count, -1 = writer
}

pub fn RwLock.new[T](data: T) -> RwLock[T] {
  let m = alloc.alloc(64);
  unsafe { xiom_mutex_init(m); }
  let rc = alloc.alloc(64);
  unsafe { xiom_cond_init(rc); }
  let wc = alloc.alloc(64);
  unsafe { xiom_cond_init(wc); }
  let d = alloc.alloc(size_of[T]());
  unsafe { ptr.write(d as *T, data); }
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return RwLock[T]{ inner: m; rcond: rc; wcond: wc; data: d; state: s; }
}

pub fn RwLock.read[T](self) -> ReadGuard[T] {
  unsafe { xiom_mutex_lock(inner); }
  unsafe {
    var st = xiom_atomic_load(state);
    while st == -1 {
      xiom_cond_wait(rcond, inner);
      st = xiom_atomic_load(state);
    };
    xiom_atomic_fetch_add(state, 1);
  };
  unsafe { xiom_mutex_unlock(inner); }
  return ReadGuard[T]{ lock: self; }
}

pub fn RwLock.write[T](self) -> WriteGuard[T] {
  unsafe { xiom_mutex_lock(inner); }
  unsafe {
    var st = xiom_atomic_load(state);
    while st != 0 {
      xiom_cond_wait(wcond, inner);
      st = xiom_atomic_load(state);
    };
    xiom_atomic_store(state, -1);
  };
  unsafe { xiom_mutex_unlock(inner); }
  return WriteGuard[T]{ lock: self; }
}

pub fn RwLock.try_read[T](self) -> Option[ReadGuard[T]] {
  unsafe { xiom_mutex_lock(inner); }
  unsafe {
    let st = xiom_atomic_load(state);
    if st == -1 {
      xiom_mutex_unlock(inner);
      return None;
    };
    xiom_atomic_fetch_add(state, 1);
  };
  unsafe { xiom_mutex_unlock(inner); }
  return Some(ReadGuard[T]{ lock: self; });
}

pub fn RwLock.try_write[T](self) -> Option[WriteGuard[T]] {
  unsafe { xiom_mutex_lock(inner); }
  unsafe {
    let st = xiom_atomic_load(state);
    if st != 0 {
      xiom_mutex_unlock(inner);
      return None;
    };
    xiom_atomic_store(state, -1);
  };
  unsafe { xiom_mutex_unlock(inner); }
  return Some(WriteGuard[T]{ lock: self; });
}

pub type ReadGuard[T] = { lock: RwLock[T]; }

pub fn ReadGuard.get[T](self) -> T {
  unsafe { return ptr.read(lock.data as *T); }
}

pub fn ReadGuard.drop[T](self) {
  unsafe { xiom_mutex_lock(lock.inner); }
  unsafe {
    xiom_atomic_fetch_sub(lock.state, 1);
    if xiom_atomic_load(lock.state) == 0 {
      xiom_cond_signal(lock.wcond);
    };
  };
  unsafe { xiom_mutex_unlock(lock.inner); }
}

pub type WriteGuard[T] = { lock: RwLock[T]; }

pub fn WriteGuard.get[T](self) -> T {
  unsafe { return ptr.read(lock.data as *T); }
}

pub fn WriteGuard.get_mut[T](self) -> T {
  unsafe { return ptr.read(lock.data as *T); }
}

pub fn WriteGuard.drop[T](self) {
  unsafe { xiom_mutex_lock(lock.inner); }
  unsafe {
    xiom_atomic_store(lock.state, 0);
    xiom_cond_broadcast(lock.rcond);
    xiom_cond_signal(lock.wcond);
  };
  unsafe { xiom_mutex_unlock(lock.inner); }
}

// === Condvar ===
pub type Condvar = { inner: *UInt8; }

pub fn Condvar.new() -> Condvar {
  let c = alloc.alloc(64);
  unsafe { xiom_cond_init(c); }
  return Condvar{ inner: c; }
}

pub fn Condvar.wait[T](self, guard: MutexGuard[T]) -> MutexGuard[T] {
  unsafe { xiom_cond_wait(inner, guard.mutex.inner); }
  return guard;
}

pub fn Condvar.notify_one(self) {
  unsafe { xiom_cond_signal(inner); }
}

pub fn Condvar.notify_all(self) {
  unsafe { xiom_cond_broadcast(inner); }
}

// === Once ===
pub type Once = {
  inner: *UInt8;     // platform mutex
  state: *Int;       // atomic: 0=not run, 1=in progress, 2=done
}

pub fn Once.new() -> Once {
  let m = alloc.alloc(64);
  unsafe { xiom_mutex_init(m); }
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return Once{ inner: m; state: s; }
}

pub fn Once.call_once(self, f: fn())
  ensures: f has been called exactly once
  ensures: state == 2
{
  unsafe {
    let st = xiom_atomic_load(state);
    if st == 2 { return; };
    xiom_mutex_lock(inner);
    st = xiom_atomic_load(state);
    if st == 2 {
      xiom_mutex_unlock(inner);
      return;
    };
    xiom_atomic_store(state, 1);
    xiom_mutex_unlock(inner);
    f();
    xiom_atomic_store(state, 2);
  }
}

pub fn Once.is_completed(self) -> Bool {
  unsafe { return xiom_atomic_load(state) == 2; }
}

// === Barrier ===
pub type Barrier = {
  inner: *UInt8;     // platform mutex
  cond: *UInt8;      // condvar
  count: Int;        // total threads
  waiting: *Int;     // atomic: current waiters
  generation: *Int;  // atomic: current generation
  invariant: count > 0;
}

pub fn Barrier.new(n: Int) -> Barrier
  requires: n > 0
{
  let m = alloc.alloc(64);
  unsafe { xiom_mutex_init(m); }
  let c = alloc.alloc(64);
  unsafe { xiom_cond_init(c); }
  let w = alloc.alloc(8);
  unsafe { ptr.write(w as *Int, 0); }
  let g = alloc.alloc(8);
  unsafe { ptr.write(g as *Int, 0); }
  return Barrier{ inner: m; cond: c; count: n; waiting: w; generation: g; }
}

pub fn Barrier.wait(self) {
  unsafe { xiom_mutex_lock(inner); }
  unsafe {
    let gen = xiom_atomic_load(generation);
    let w = xiom_atomic_fetch_add(waiting, 1) + 1;
    if w == count {
      xiom_atomic_store(waiting, 0);
      xiom_atomic_fetch_add(generation, 1);
      xiom_cond_broadcast(cond);
      xiom_mutex_unlock(inner);
      return;
    };
    var cur_gen = xiom_atomic_load(generation);
    while cur_gen == gen {
      xiom_cond_wait(cond, inner);
      cur_gen = xiom_atomic_load(generation);
    };
  };
  unsafe { xiom_mutex_unlock(inner); }
}

// === Arc (Atomic Reference Counted) ===
pub type Arc[T] = {
  ptr: *ArcInner[T];
  invariant: ptr != null => (*ptr).count >= 1;
}

pub type ArcInner[T] = {
  count: *Int;  // atomic reference count
  value: T;
}

pub fn Arc.new[T](value: T) -> Arc[T]
  requires: ptr != null
  ensures:  strong_count == 1
{
  let c = alloc.alloc(8);
  unsafe { ptr.write(c as *Int, 1); }
  let inner = ArcInner[T]{ count: c; value: value; };
  let isize = size_of[ArcInner[T]]();
  let raw = alloc.alloc(isize);
  unsafe {
    let dest = raw as *mut ArcInner[T];
    ptr.write(dest, inner);
  };
  return Arc[T]{ ptr: raw as *ArcInner[T]; }
}

pub fn Arc.clone[T](self) -> Arc[T]
  requires: ptr != null
  ensures:  strong_count() == strong_count()@pre + 1
{
  unsafe {
    xiom_atomic_fetch_add(ptr.count, 1);
  };
  return Arc[T]{ ptr: ptr; }
}

pub fn Arc.get[T](self) -> T {
  unsafe {
    (*ptr).value
  }
}

pub fn Arc.strong_count[T](self) -> Int
  requires: ptr != null
  ensures:  result >= 1
{
  unsafe {
    xiom_atomic_load(ptr.count)
  }
}

pub fn Arc.ptr_eq[T, U](self, other: &Arc[U]) -> Bool {
  ptr as *UInt8 == other.ptr as *UInt8
}

pub fn Arc.drop[T](self)
  requires: ptr != null
{
  unsafe {
    let c = xiom_atomic_fetch_sub(ptr.count, 1);
    if c == 1 {
      alloc.dealloc(ptr.count, 8);
      alloc.dealloc(ptr as *UInt8, size_of[ArcInner[T]]());
    };
  }
}

// === AtomicBool -- real atomic operations ===
pub type AtomicBool = { ptr: *Int; }

pub fn AtomicBool.new(val: Bool) -> AtomicBool {
  let p = alloc.alloc(8);
  let iv: Int = if val { 1 } else { 0 };
  unsafe { ptr.write(p as *Int, iv); }
  return AtomicBool{ ptr: p as *Int; }
}

pub fn AtomicBool.load(self) -> Bool {
  unsafe { return xiom_atomic_load(ptr) != 0; }
}

pub fn AtomicBool.store(self, val: Bool) {
  let iv: Int = if val { 1 } else { 0 };
  unsafe { xiom_atomic_store(ptr, iv); }
}

pub fn AtomicBool.swap(self, val: Bool) -> Bool {
  let iv: Int = if val { 1 } else { 0 };
  unsafe { return xiom_atomic_exchange(ptr, iv) != 0; }
}

pub fn AtomicBool.compare_exchange(self, current: Bool, new: Bool) -> Bool {
  let c: Int = if current { 1 } else { 0 };
  let n: Int = if new { 1 } else { 0 };
  unsafe {
    let old = xiom_atomic_load(ptr);
    if old == c {
      xiom_atomic_store(ptr, n);
      return true;
    };
    return false;
  }
}

// === AtomicInt -- real atomic operations ===
pub type AtomicInt = { ptr: *Int; }

pub fn AtomicInt.new(val: Int) -> AtomicInt {
  let p = alloc.alloc(8);
  unsafe { ptr.write(p as *Int, val); }
  return AtomicInt{ ptr: p as *Int; }
}

pub fn AtomicInt.load(self) -> Int {
  unsafe { return xiom_atomic_load(ptr); }
}

pub fn AtomicInt.store(self, val: Int) {
  unsafe { xiom_atomic_store(ptr, val); }
}

pub fn AtomicInt.fetch_add(self, val: Int) -> Int {
  unsafe { return xiom_atomic_fetch_add(ptr, val); }
}

pub fn AtomicInt.fetch_sub(self, val: Int) -> Int {
  unsafe { return xiom_atomic_fetch_sub(ptr, val); }
}

pub fn AtomicInt.swap(self, val: Int) -> Int {
  unsafe { return xiom_atomic_exchange(ptr, val); }
}

pub fn AtomicInt.compare_exchange(self, current: Int, new: Int) -> Bool {
  unsafe {
    let old = xiom_atomic_load(ptr);
    if old == current {
      xiom_atomic_store(ptr, new);
      return true;
    };
    return false;
  }
}

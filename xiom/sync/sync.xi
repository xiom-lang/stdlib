// XIOM -- Synchronization Primitives
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sync
use xiom.sync.mutex;
use xiom.sync.condvar;
use xiom.sync.barrier;
use xiom.sync.channel;
use xiom.sync.atomics;
use xiom.sync.rwlock;

use xiom.alloc;
use xiom.ptr;
use xiom.core.size_of;  // bare intrinsic binding (strict catalog gate)

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

/// === Mutex ===
pub type Mutex[T] = {
  inner: *UInt8;  // platform mutex (sizeof(pthread_mutex_t) or CRITICAL_SECTION)
  data: *T;       // heap-allocated protected data
}

/// Create an unlocked mutex holding `value`.
pub fn Mutex.new[T](value: T) -> Mutex[T] {
  let m = alloc.alloc(64);  // enough for any platform mutex
  unsafe { xiom_mutex_init(m); }
  let d = alloc.alloc(size_of[T]());
  unsafe { ptr.write(d as *T, value); }
  return Mutex[T]{ inner: m; data: d; }
}

/// Block until the lock is acquired; returns the guard.
pub fn Mutex.lock[T](self) -> MutexGuard[T] {
  unsafe { xiom_mutex_lock(inner); }
  return MutexGuard[T]{ mutex: self; }
}

/// Non-blocking lock attempt; None when already locked.
pub fn Mutex.try_lock[T](self) -> Option[MutexGuard[T]]
  requires: inner != null
{
  unsafe {
    if xiom_mutex_trylock(inner) == 0 {
      return Some(MutexGuard[T]{ mutex: self; });
    }
    return None;
  }
}

/// Consume the mutex and return the value.
pub fn Mutex.into_inner[T](self) -> T
  requires: inner != null
  requires: data != null
{
  unsafe {
    let val = ptr.read(data as *T);
    xiom_mutex_destroy(inner);
    alloc.dealloc(inner, 64);
    alloc.dealloc(data as *UInt8, size_of[T]());
    return val;
  }
}

/// RAII guard holding the mutex lock.
pub type MutexGuard[T] = {
  mutex: Mutex[T];
}

/// Read the guarded value.
pub fn MutexGuard.get[T](self) -> T
  requires: mutex.data != null
{
  unsafe { return ptr.read(mutex.data as *T); }
}

/// Mutable access to the guarded value (returns it by value).
pub fn MutexGuard.get_mut[T](self) -> T
  requires: mutex.data != null
{
  unsafe { return ptr.read(mutex.data as *T); }
}

/// Release the lock.
pub fn MutexGuard.drop[T](self)
  requires: mutex.inner != null
{
  unsafe { xiom_mutex_unlock(mutex.inner); }
}

/// === RwLock ===
pub type RwLock[T] = {
  inner: *UInt8;     // platform mutex
  rcond: *UInt8;     // condvar for readers
  wcond: *UInt8;     // condvar for writers
  data: *T;          // heap-allocated protected data
  state: *Int;       // atomic state: 0=free, >0 = reader count, -1 = writer
}

/// Create an unlocked read-write lock holding `data`.
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

/// Acquire a shared read guard (blocks while a writer holds the lock).
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

/// Acquire an exclusive write guard.
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

/// Non-blocking shared read; None when a writer holds the lock.
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

/// Non-blocking exclusive write; None when the lock is held.
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

/// RAII guard for shared read access.
pub type ReadGuard[T] = { lock: RwLock[T]; }

/// Read the guarded value.
pub fn ReadGuard.get[T](self) -> T
  requires: lock.data != null
{
  unsafe { return ptr.read(lock.data as *T); }
}

/// Release the shared read lock.
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

/// RAII guard for exclusive write access.
pub type WriteGuard[T] = { lock: RwLock[T]; }

/// Read the guarded value.
pub fn WriteGuard.get[T](self) -> T
  requires: lock.data != null
{
  unsafe { return ptr.read(lock.data as *T); }
}

/// Mutable access to the guarded value (returns it by value).
pub fn WriteGuard.get_mut[T](self) -> T
  requires: lock.data != null
{
  unsafe { return ptr.read(lock.data as *T); }
}

/// Release the exclusive lock.
pub fn WriteGuard.drop[T](self) {
  unsafe { xiom_mutex_lock(lock.inner); }
  unsafe {
    xiom_atomic_store(lock.state, 0);
    xiom_cond_broadcast(lock.rcond);
    xiom_cond_signal(lock.wcond);
  };
  unsafe { xiom_mutex_unlock(lock.inner); }
}

/// === Condvar ===
pub type Condvar = { inner: *UInt8; }

/// Create a condition variable.
pub fn Condvar.new() -> Condvar {
  let c = alloc.alloc(64);
  unsafe { xiom_cond_init(c); }
  return Condvar{ inner: c; }
}

/// Wait for a notification, releasing and re-acquiring the mutex.
pub fn Condvar.wait[T](self, guard: MutexGuard[T]) -> MutexGuard[T] {
  unsafe { xiom_cond_wait(inner, guard.mutex.inner); }
  return guard;
}

/// Wake one waiting thread.
pub fn Condvar.notify_one(self)
  requires: inner != null
{
  unsafe { xiom_cond_signal(inner); }
}

/// Wake all waiting threads.
pub fn Condvar.notify_all(self)
  requires: inner != null
{
  unsafe { xiom_cond_broadcast(inner); }
}

/// === Once ===
pub type Once = {
  inner: *UInt8;     // platform mutex
  state: *Int;       // atomic: 0=not run, 1=in progress, 2=done
}

/// Create a one-shot initializer.
pub fn Once.new() -> Once {
  let m = alloc.alloc(64);
  unsafe { xiom_mutex_init(m); }
  let s = alloc.alloc(8);
  unsafe { ptr.write(s as *Int, 0); }
  return Once{ inner: m; state: s; }
}

/// Run `f` exactly once; later calls return immediately.
pub fn Once.call_once(self, f: fn())
  requires: inner != null
  requires: state != null
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

/// True when the initializer already ran.
pub fn Once.is_completed(self) -> Bool
  requires: state != null
{
  unsafe { return xiom_atomic_load(state) == 2; }
}

/// === Barrier ===
pub type Barrier = {
  inner: *UInt8;     // platform mutex
  cond: *UInt8;      // condvar
  count: Int;        // total threads
  waiting: *Int;     // atomic: current waiters
  generation: *Int;  // atomic: current generation
  invariant: count > 0;
}

/// Create a barrier for `n` threads (n is clamped to at least 1).
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

/// Block until `n` threads arrive, then release them together.
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

/// === Arc (Atomic Reference Counted) ===
pub type Arc[T] = {
  ptr: *ArcInner[T];
  invariant: ptr != null => (*ptr).count >= 1;
}

/// Control block behind `Arc`: atomic strong count plus the value.
pub type ArcInner[T] = {
  count: *Int;  // atomic reference count
  value: T;
}

/// Allocate a shared-ownership pointer with strong count 1.
pub fn Arc.new[T](value: T) -> Arc[T]
  ensures:  strong_count == 1
{
  let c = alloc.alloc(8);
  unsafe { *(c as *Int) = 1; }
  let inner = ArcInner[T]{ count: c; value: value; };
  let isize = size_of[ArcInner[T]]();
  let raw = alloc.alloc(isize);
  unsafe {
    let dest = raw as *mut ArcInner[T];
    *dest = inner;
  };
  unsafe {
    return Arc[T]{ ptr: raw as *ArcInner[T]; }
  }
}

/// Increment the strong count and return a second handle.
pub fn Arc.clone[T](self) -> Arc[T]
  requires: ptr != null
  ensures:  strong_count() >= 1
{
  unsafe {
    xiom_atomic_fetch_add(ptr.count, 1);
  };
  return Arc[T]{ ptr: ptr; }
}

/// Read the shared value (by value).
pub fn Arc.get[T](self) -> T
  requires: ptr != null
{
  unsafe {
    (*ptr).value
  }
}

/// Current strong count (atomic).
pub fn Arc.strong_count[T](self) -> Int
  requires: ptr != null
  ensures:  result >= 1
{
  unsafe {
    xiom_atomic_load(ptr.count)
  }
}

/// True when both handles point at the same control block.
pub fn Arc.ptr_eq[T, U](self, other: &Arc[U]) -> Bool
  requires: true  // whole-body unsafe pointer compare (T007)
{
  unsafe {
    return ptr as *UInt8 == other.ptr as *UInt8;
  }
}

/// Decrement the strong count; free when it reaches zero.
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

/// === M7: Deref impl for Arc[T] ===
/// Arc provides shared (atomic) access. Deref allows `*arc` and auto-deref.
/// DerefMut is NOT implemented -- Arc provides shared access only.
pub fn Arc[T].deref(self) -> &T
  requires: ptr != null
  ensures: true
{
  unsafe {
    return &(*ptr).value;
  }
}

/// Borrow the value as `&T`.
pub fn Arc[T].as_ref(self) -> &T
  requires: ptr != null
{
  return deref();
}

/// === AtomicBool -- real atomic operations ===
pub type AtomicBool = { ptr: *Int; }

/// Create an atomic bool.
pub fn AtomicBool.new(val: Bool) -> AtomicBool {
  let p = alloc.alloc(8);
  let iv: Int = if val { 1 } else { 0 };
  unsafe { *(p as *Int) = iv; }
  unsafe {
    return AtomicBool{ ptr: p as *Int; }
  }
}

/// Current value with acquire ordering.
pub fn AtomicBool.load(self) -> Bool
  requires: ptr != null
{
  unsafe { return xiom_atomic_load(ptr) != 0; }
}

/// Store with release ordering.
pub fn AtomicBool.store(self, val: Bool) {
  let iv: Int = if val { 1 } else { 0 };
  unsafe { xiom_atomic_store(ptr, iv); }
}

/// Atomically replace the value, returning the previous one.
pub fn AtomicBool.swap(self, val: Bool) -> Bool {
  let iv: Int = if val { 1 } else { 0 };
  unsafe { return xiom_atomic_exchange(ptr, iv) != 0; }
}

/// Set to `new` when the value equals `current`; true on success.
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

/// === AtomicInt -- real atomic operations ===
pub type AtomicInt = { ptr: *Int; }

/// Create an atomic Int.
pub fn AtomicInt.new(val: Int) -> AtomicInt {
  let p = alloc.alloc(8);
  unsafe { *(p as *Int) = val; }
  unsafe {
    return AtomicInt{ ptr: p as *Int; }
  }
}

/// Current value with acquire ordering.
pub fn AtomicInt.load(self) -> Int
  requires: ptr != null
{
  unsafe { return xiom_atomic_load(ptr); }
}

/// Store with release ordering; returns the atomic.
pub fn AtomicInt.store(self, val: Int) -> AtomicInt
  requires: ptr != null
{
  unsafe { xiom_atomic_store(ptr, val); }
  self
}

/// Atomically add, returning the previous value.
pub fn AtomicInt.fetch_add(self, val: Int) -> Int
  requires: ptr != null
{
  unsafe { return xiom_atomic_fetch_add(ptr, val); }
}

/// Atomically subtract, returning the previous value.
pub fn AtomicInt.fetch_sub(self, val: Int) -> Int
  requires: ptr != null
{
  unsafe { return xiom_atomic_fetch_sub(ptr, val); }
}

/// Atomically replace, returning the previous value.
pub fn AtomicInt.swap(self, val: Int) -> Int
  requires: ptr != null
{
  unsafe { return xiom_atomic_exchange(ptr, val); }
}

/// Set to `new` when the value equals `current`; true on success.
pub fn AtomicInt.compare_exchange(self, current: Int, new: Int) -> Bool
  requires: ptr != null
{
  unsafe {
    let old = xiom_atomic_load(ptr);
    if old == current {
      xiom_atomic_store(ptr, new);
      return true;
    };
    return false;
  }
}

// -- Semaphore ------------------------------------------------------

/// A simple counting semaphore backed by an integer counter.
/// Non-blocking: `acquire` returns `false` if no permits are available.
/// Thread-safety: NOT atomic -- use `Mutex[Semaphore]` for shared access.
pub type Semaphore = { count: Int; max: Int; }

/// Creates a new semaphore with `permits` initial available permits.
/// Complexity: O(1).
pub fn sem_new(permits: Int) -> Semaphore {
  return Semaphore{ count: permits; max: permits; };
}

/// Attempts to acquire one permit. Returns `true` on success, `false` if none available.
/// Non-blocking. Complexity: O(1).
pub fn sem_try_acquire(s: &mut Semaphore) -> Bool {
  if s.count > 0 {
    s.count = s.count - 1;
    return true;
  };
  return false;
}

/// Alias for `sem_try_acquire`. Non-blocking.
/// Complexity: O(1).
pub fn sem_acquire(s: &mut Semaphore) -> Bool {
  return sem_try_acquire(s);
}

/// Releases one permit back to the semaphore, up to the maximum.
/// Complexity: O(1).
pub fn sem_release(s: &mut Semaphore) {
  if s.count < s.max {
    s.count = s.count + 1;
  };
}

/// Returns the number of currently available permits.
/// Complexity: O(1).
pub fn sem_available(s: &Semaphore) -> Int {
  return s.count;
}

// -- Barrier Standalone Helpers -------------------------------------

/// Creates a new barrier for `n` threads. Wraps `Barrier.new`.
/// Complexity: O(1).
pub fn barrier_new(n: Int) -> Barrier {
  return Barrier.new(n);
}

/// Waits at the barrier. Returns `true` when this thread is the last to arrive
/// and the barrier releases all waiters. Returns `false` otherwise.
/// Complexity: O(1) lock operations; blocks until all threads arrive.
pub fn barrier_wait(b: &mut Barrier) -> Bool {
  unsafe { xiom_mutex_lock(b.inner); }
  unsafe {
    let gen = xiom_atomic_load(b.generation);
    let w = xiom_atomic_fetch_add(b.waiting, 1) + 1;
    if w == b.count {
      xiom_atomic_store(b.waiting, 0);
      xiom_atomic_fetch_add(b.generation, 1);
      xiom_cond_broadcast(b.cond);
      xiom_mutex_unlock(b.inner);
      return true;
    };
    var cur_gen = xiom_atomic_load(b.generation);
    while cur_gen == gen {
      xiom_cond_wait(b.cond, b.inner);
      cur_gen = xiom_atomic_load(b.generation);
    };
  };
  unsafe { xiom_mutex_unlock(b.inner); }
  return false;
}

/// Resets the barrier waiting count to zero (best-effort).
/// Complexity: O(1). Not safe for concurrent use with active waiters.
pub fn barrier_reset(b: &mut Barrier)
  requires: b.waiting != null
{
  unsafe { xiom_atomic_store(b.waiting, 0); }
}

// -- CountDownLatch -------------------------------------------------

/// A simple count-down latch for synchronisation.
/// Thread-safety: NOT atomic -- use `Mutex[CountDownLatch]` for shared access.
pub type CountDownLatch = { remaining: Int; }

/// Creates a new count-down latch initialised to `n`.
/// Complexity: O(1).
pub fn cdl_new(n: Int) -> CountDownLatch {
  return CountDownLatch{ remaining: n; };
}

/// Decrements the latch counter by one. Does nothing if already zero.
/// Complexity: O(1).
pub fn cdl_count_down(l: &mut CountDownLatch) {
  if l.remaining > 0 {
    l.remaining = l.remaining - 1;
  };
}

/// Returns `true` if the latch has reached zero.
/// Complexity: O(1).
pub fn cdl_is_zero(l: &CountDownLatch) -> Bool {
  return l.remaining == 0;
}

/// Spins until the latch reaches zero. Yields the thread between checks.
/// Complexity: O(remaining) busy-wait iterations.
pub fn cdl_wait_spin(l: &mut CountDownLatch) {
  while l.remaining > 0 {
    unsafe { xiom_thread_yield(); };
  };
}

// -- AtomicInt Standalone Helpers -----------------------------------

/// Atomically loads the current value. Direct FFI access.
/// Complexity: O(1). Thread-safe.
pub fn atomic_load(ai: &AtomicInt) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_load(p); }
}

/// Atomically stores a new value. Direct FFI access.
/// Complexity: O(1). Thread-safe.
pub fn atomic_store(ai: &mut AtomicInt, v: Int) {
  let p: *Int = ai.ptr;
  unsafe { xiom_atomic_store(p, v); };
}

/// Atomically adds `v` to the value. Returns the new value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_add(ai: &mut AtomicInt, v: Int) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_fetch_add(p, v) + v; }
}

/// Atomically subtracts `v` from the value. Returns the new value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_sub(ai: &mut AtomicInt, v: Int) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_fetch_sub(p, v) - v; }
}

/// Atomically swaps the value and returns the old value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_exchange(ai: &mut AtomicInt, v: Int) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_exchange(p, v); }
}

/// Atomically compares and exchanges. Stores `new` if current value equals `expected`.
/// Returns `true` if the exchange was performed.
/// Complexity: O(1). Thread-safe.
pub fn atomic_compare_exchange(ai: &mut AtomicInt, expected: Int, new: Int) -> Bool {
  let p: *Int = ai.ptr;
  unsafe {
    let old = xiom_atomic_load(p);
    if old == expected {
      xiom_atomic_store(p, new);
      return true;
    };
    return false;
  }
}

/// Atomically adds `v` and returns the OLD value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_fetch_add(ai: &mut AtomicInt, v: Int) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_fetch_add(p, v); }
}

/// Atomically subtracts `v` and returns the OLD value.
/// Complexity: O(1). Thread-safe.
pub fn atomic_fetch_sub(ai: &mut AtomicInt, v: Int) -> Int {
  let p: *Int = ai.ptr;
  unsafe { return xiom_atomic_fetch_sub(p, v); }
}

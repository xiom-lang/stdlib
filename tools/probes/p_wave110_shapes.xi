// p_wave110_shapes.xi -- wave 110 shape validation: xiom.sync surfaces --
// parent-module Mutex/RwLock/Condvar/Once/Barrier/AtomicBool/AtomicInt tails
// plus the standalone atomic/cdl/sem helpers, and the mutex/atomics/rwlock/
// barrier/channel/condvar submodules (constructors, state mirrors, guard
// shapes, channel close/drain semantics).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave110_shapes

use xiom.sync;
use xiom.sync.mutex as mu;
use xiom.sync.rwlock as rw;
use xiom.sync.barrier as br;
use xiom.sync.channel as cch;
use xiom.sync.condvar as cv;

fn main() -> Int {
  // NOTE: the parent-module `sync.Mutex[T]` surface (new/lock/MutexGuard)
  // cannot be exercised from user code on v0.64.2: the compiler's builtin
  // `Mutex.new/lock/unlock` (deadlock detection) shadows the stdlib type at
  // name resolution time -- `sync.Mutex.new(42)` is a T001 error and the
  // zero-arg form binds the builtin (returns Int). Filed as
  // tools/known_failures/p_sync_mutex_builtin_shadow.xi.

  // ---- parent RwLock representative (the write/try_read/try_write
  // round-trips live in the smoke_stress_sync_rwlock_* corpus smokes; this
  // compilation stays under the compiler's 64 `#[unsafe_direct]` block cap)
  var rl = sync.RwLock.new(7);
  let rg = rl.read();
  if rg.get() != 7 { return 3; }
  rg.drop();

  // ---- parent Once / Barrier / Condvar constructors
  var once = sync.Once.new();
  if once.is_completed() { return 7; }
  once.call_once(fn() { });
  if !once.is_completed() { return 7; }
  var bar = sync.Barrier.new(1);
  bar.wait();
  var bw = sync.Barrier.new(1);
  if !sync.barrier_wait(&mut bw) { return 7; }
  var cnd = sync.Condvar.new();
  cnd.notify_one();
  cnd.notify_all();

  // ---- parent AtomicBool / AtomicInt representatives
  var sb = sync.AtomicBool.new(true);
  if !sb.swap(false) { return 8; }
  var si = sync.AtomicInt.new(5);
  if si.fetch_add(3) != 5 { return 10; }
  if si.load() != 8 { return 10; }

  // ---- standalone atomic helpers in xiom.sync
  if sync.atomic_load(&si) != 8 { return 14; }
  sync.atomic_store(&mut si, 20);
  if sync.atomic_add(&mut si, 5) != 25 { return 14; }
  if sync.atomic_sub(&mut si, 5) != 20 { return 15; }
  if sync.atomic_exchange(&mut si, 3) != 20 { return 15; }
  if !sync.atomic_compare_exchange(&mut si, 3, 4) { return 16; }
  if sync.atomic_fetch_add(&mut si, 2) != 4 { return 16; }
  if sync.atomic_fetch_sub(&mut si, 2) != 6 { return 17; }
  if sync.atomic_load(&si) != 4 { return 17; }

  // ---- count-down latch + semaphore
  var cdl = sync.cdl_new(2);
  if sync.cdl_is_zero(&cdl) { return 18; }
  sync.cdl_count_down(&mut cdl);
  if sync.cdl_is_zero(&cdl) { return 18; }
  sync.cdl_count_down(&mut cdl);
  if !sync.cdl_is_zero(&cdl) { return 19; }
  sync.cdl_wait_spin(&mut cdl);
  var sem = sync.sem_new(1);
  if sync.sem_available(&sem) != 1 { return 20; }
  if !sync.sem_try_acquire(&mut sem) { return 20; }
  if sync.sem_try_acquire(&mut sem) { return 21; }
  sync.sem_release(&mut sem);
  if sync.sem_available(&sem) != 1 { return 21; }

  // ---- submodule mutex
  var mm = mu.mutex_new();
  if mu.mutex_is_locked(&mm) { return 22; }
  mu.mutex_lock(&mut mm);
  if !mu.mutex_is_locked(&mm) { return 22; }
  if mu.mutex_try_lock(&mut mm) { return 23; }
  mu.mutex_unlock(&mut mm);
  if mu.mutex_is_locked(&mm) { return 23; }
  if !mu.mutex_try_lock(&mut mm) { return 24; }
  mu.mutex_unlock(&mut mm);
  if mu.mutex_into_inner(&mut mm) == 0 { return 24; }

  // ---- submodule atomics
  // (SURFACING NOTE: xiom.sync + xiom.sync.atomics in ONE compilation trips
  // the compiler's 64 `#[unsafe_direct]` unsafe-block cap; the atomics
  // submodule is therefore validated by tests/smoke/smoke_sync_atomics.xi +
  // smoke_sync_arc_battery.xi in the same battery instead of this probe.)

  // ---- submodule rwlock: try paths + blocking lock/unlock cycle
  var rl2 = rw.rwlock_new();
  if rw.rwlock_is_write_locked(&rl2) { return 33; }
  if !rw.rwlock_read_try_lock(&mut rl2) { return 33; }
  if !rw.rwlock_read_try_lock(&mut rl2) { return 34; }
  rw.rwlock_read_unlock(&mut rl2);
  rw.rwlock_read_unlock(&mut rl2);
  if !rw.rwlock_write_try_lock(&mut rl2) { return 34; }
  if rw.rwlock_read_try_lock(&mut rl2) { return 35; }
  if !rw.rwlock_is_write_locked(&rl2) { return 35; }
  rw.rwlock_write_unlock(&mut rl2);
  rw.rwlock_read_lock(&mut rl2);
  rw.rwlock_read_unlock(&mut rl2);
  rw.rwlock_write_lock(&mut rl2);
  rw.rwlock_write_unlock(&mut rl2);
  if rw.rwlock_into_inner(&mut rl2) == 0 { return 36; }

  // ---- submodule barrier: clamp + single-thread rendezvous
  var b2 = br.barrier_new(0);
  if br.barrier_count(&b2) != 1 { return 37; }
  if br.barrier_is_ready(&b2) { return 37; }
  if !br.barrier_wait(&mut b2) { return 38; }
  if br.barrier_is_ready(&b2) { return 38; }
  br.barrier_reset(&mut b2);
  if br.barrier_is_ready(&b2) { return 39; }

  // ---- channel: clamp, send/recv FIFO, bounded try paths, close/drain
  var c0 = cch.channel_new(-3);
  if cch.channel_capacity(&c0) != 0 { return 40; }
  if cch.channel_len(&c0) != 0 { return 40; }
  if cch.channel_is_closed(&c0) { return 41; }
  let snd0 = cch.channel_send(&mut c0, 11);
  if snd0.is_err { return 41; }
  if cch.channel_len(&c0) != 1 { return 42; }
  let rcv0 = cch.channel_recv(&mut c0);
  match rcv0 {
    Some(v) => { if v != 11 { return 42; } },
    None => { return 42; }
  }
  var c1 = cch.channel_new(2);
  if cch.channel_capacity(&c1) != 2 { return 43; }
  if !cch.channel_try_send(&mut c1, 1) { return 43; }
  if !cch.channel_try_send(&mut c1, 2) { return 44; }
  if cch.channel_try_send(&mut c1, 3) { return 44; }
  let tr1 = cch.channel_try_recv(&mut c1);
  match tr1 {
    Some(v) => { if v != 1 { return 45; } },
    None => { return 45; }
  }
  cch.channel_close(&mut c1);
  if !cch.channel_is_closed(&c1) { return 46; }
  let tr2 = cch.channel_try_recv(&mut c1);
  match tr2 {
    Some(v) => { if v != 2 { return 46; } },
    None => { return 46; }
  }
  if cch.channel_try_send(&mut c1, 9) { return 47; }
  let tr3 = cch.channel_try_recv(&mut c1);
  match tr3 {
    None => {},
    Some(_) => { return 47; }
  }
  let rc1 = cch.channel_recv(&mut c1);
  match rc1 {
    None => {},
    Some(_) => { return 48; }
  }
  let sc1 = cch.channel_send(&mut c1, 9);
  if !sc1.is_err { return 48; }

  // ---- submodule condvar: notify + timeout/counter semantics
  var cvv = cv.condvar_new();
  var mcv = mu.mutex_new();
  cv.condvar_notify_one(cvv);
  cv.condvar_wait(cvv, mcv);
  mu.mutex_unlock(&mut mcv);
  var cv2 = cv.condvar_new();
  let t0 = cv.condvar_wait_timeout(cv2, mcv, 0);
  if t0 { return 49; }
  cv.condvar_notify_all(cv2);
  let t1 = cv.condvar_wait_timeout(cv2, mcv, 5);
  if !t1 { return 49; }

  return 0;
}


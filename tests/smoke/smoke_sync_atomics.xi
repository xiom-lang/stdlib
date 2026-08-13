// XIOM stdlib smoke - xiom.sync.atomics / barrier / mutex / rwlock / condvar
// Returns 0 on success with "OK" printed; nonzero + tag on failure.

module smoke_sync_atomics
use xiom.sync.atomics;
use xiom.sync.barrier;
use xiom.sync.mutex;
use xiom.sync.rwlock;
use xiom.sync.condvar;
use xiom.io;
use xiom.convert;

fn main() -> Int {
  // atomics: load/store/swap/add semantics
  var ai = atomics.atomic_int_new(0);
  if atomics.atomic_load(&ai) != 0 { io.println("atomics:load"); return 1; }
  atomics.atomic_store(&mut ai, 42);
  if atomics.atomic_load(&ai) != 42 { io.println("atomics:store"); return 2; }
  if atomics.atomic_add(&mut ai, 10) != 52 { io.println("atomics:add"); return 3; }
  if atomics.atomic_load(&ai) != 52 { io.println("atomics:add2"); return 4; }
  if atomics.atomic_fetch_add(&mut ai, 1) != 52 { io.println("atomics:fetch_add"); return 5; }
  if atomics.atomic_fetch_sub(&mut ai, 2) != 53 { io.println("atomics:fetch_sub"); return 6; }
  if atomics.atomic_swap(&mut ai, 7) != 51 { io.println("atomics:swap"); return 7; }
  if atomics.atomic_load(&ai) != 7 { io.println("atomics:swap2"); return 8; }
  if !atomics.atomic_compare_exchange(&mut ai, 7, 9) { io.println("atomics:cas"); return 9; }
  if atomics.atomic_load(&ai) != 9 { io.println("atomics:cas2"); return 10; }
  if atomics.atomic_compare_exchange(&mut ai, 1, 2) { io.println("atomics:cas3"); return 11; }

  var ab = atomics.atomic_bool_new(true);
  if !atomics.atomic_bool_load(&ab) { io.println("atomics:bool_load"); return 12; }
  atomics.atomic_bool_store(&mut ab, false);
  if atomics.atomic_bool_load(&ab) { io.println("atomics:bool_store"); return 13; }
  if atomics.atomic_bool_swap(&mut ab, true) { io.println("atomics:bool_swap"); return 14; }
  if !atomics.atomic_bool_load(&ab) { io.println("atomics:bool_swap2"); return 15; }

  var ap = atomics.atomic_ptr_new(12345);
  if atomics.atomic_ptr_load(&ap) != 12345 { io.println("atomics:ptr_load"); return 16; }
  atomics.atomic_ptr_store(&mut ap, 999);
  if atomics.atomic_ptr_load(&ap) != 999 { io.println("atomics:ptr_store"); return 17; }

  // mutex: try_lock semantics
  var m = mutex.mutex_new();
  if !mutex.mutex_try_lock(&mut m) { io.println("mutex:try_lock"); return 18; }
  if mutex.mutex_try_lock(&mut m) { io.println("mutex:try_lock2"); return 19; }
  if !mutex.mutex_is_locked(&m) { io.println("mutex:is_locked"); return 20; }
  mutex.mutex_unlock(&mut m);
  if mutex.mutex_is_locked(&m) { io.println("mutex:unlock"); return 21; }
  var h = mutex.mutex_into_inner(&mut m);
  if h == 0 { io.println("mutex:into_inner"); return 22; }

  // rwlock: readers concurrent, writer exclusive
  var rl = rwlock.rwlock_new();
  if !rwlock.rwlock_read_try_lock(&mut rl) { io.println("rwlock:read1"); return 23; }
  if !rwlock.rwlock_read_try_lock(&mut rl) { io.println("rwlock:read2"); return 24; }
  rwlock.rwlock_read_unlock(&mut rl);
  rwlock.rwlock_read_unlock(&mut rl);
  if !rwlock.rwlock_write_try_lock(&mut rl) { io.println("rwlock:write"); return 25; }
  if rwlock.rwlock_read_try_lock(&mut rl) { io.println("rwlock:write2"); return 26; }
  if !rwlock.rwlock_is_write_locked(&rl) { io.println("rwlock:is_write"); return 27; }
  rwlock.rwlock_write_unlock(&mut rl);
  if rwlock.rwlock_is_write_locked(&rl) { io.println("rwlock:unlock"); return 28; }

  // barrier: count, wait returns true for the last arriver
  var b = barrier.barrier_new(1);
  if barrier.barrier_count(&b) != 1 { io.println("barrier:count"); return 29; }
  if barrier.barrier_is_ready(&b) { io.println("barrier:ready"); return 30; }
  if !barrier.barrier_wait(&mut b) { io.println("barrier:wait"); return 31; }
  if barrier.barrier_is_ready(&b) { io.println("barrier:ready2"); return 32; }
  barrier.barrier_reset(&mut b);
  if barrier.barrier_is_ready(&b) { io.println("barrier:reset"); return 33; }

  // condvar: notify then wait_timeout sees it; empty wait times out
  var cv = condvar.condvar_new();
  condvar.condvar_notify_one(cv);
  var n1 = condvar.condvar_wait_timeout(cv, m, 20);
  if !n1 { io.println("condvar:notify"); return 34; }
  var cv2 = condvar.condvar_new();
  var n2 = condvar.condvar_wait_timeout(cv2, m, 20);
  if n2 { io.println("condvar:timeout"); return 35; }
  condvar.condvar_notify_all(cv2);

  io.println("OK");
  return 0;
}

// p_wave131_shapes.xi -- wave 131 lock: the REL-20261013-1423 thread-buffer
// hoist (alloc.alloc moved outside the confined block in xiom.thread.spawn)
// plus the thread module's spawn-independent surfaces. The full spawn[T]
// e2e (return 42) is compiler-gated on m282 (the raw-fn handover) and hangs
// on the v0.64.4 pin, so it is deliberately NOT exercised here; the hoist
// itself is compile-locked by this probe's import and by check_modules.
// Returns 0 when every case holds.

module p_wave131_shapes

use xiom.thread;

fn main() -> Int {
  let t1 = thread.available_parallelism();
  if t1 < 1 { return 1; }
  let t2 = thread.thread_count();
  if t2 != t1 { return 2; }
  let t3 = thread.hardware_threads();
  if t3 != t1 { return 3; }

  let id1 = thread.current_thread_id();
  if id1 < 0 { return 4; }
  let cur = thread.Thread.current();
  let id2 = cur.id();
  if id2 != id1 { return 5; }
  let nm = thread.thread_name_current();
  if !nm.is_none { return 6; }

  thread.sleep_ms(0);
  thread.sleep(0);
  thread.thread_sleep_us(500);
  thread.yield_now();
  thread.thread_yield();

  return 0;
}

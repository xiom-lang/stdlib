// p_wave78_shapes.xi -- wave 78 shape validation: thread (thread/spawn/
// pool/park/local)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-78 clause guards across xiom.thread (Thread
// introspection + delegation aliases), xiom.thread.spawn (simulated
// spawn/join/scoped plus the intro), xiom.thread.pool (new/submit_with/
// size/idle/busy), xiom.thread.local (tls new/set/get/replace/take/clear
// and raw keys) and xiom.thread.park (token notify/wait, unpark-before-
// park, park_timeout(0)). Returns 0 when every case holds.
// Landmines: `xiom.thread.spawn` is imported LAST (module-name collision,
// BUG 25 #9); tls_get is never called on an uninitialized ThreadLocal (the
// stored init fn-field call miscompiles on this toolchain); `Vec.new()`
// temporaries passed as `&Vec` are bound first.

module p_wave78_shapes

use xiom.thread.pool;
use xiom.thread.local;
use xiom.thread.park;
use xiom.thread;
use xiom.thread.spawn;

var _pf: Int = 0;

fn _noop() { }

fn _pfor(_i: Int) {
  _pf = _pf + 1;
}

fn _init42() -> Int {
  return 42;
}

fn _scope_fn(s: &Scope) -> Int {
  return 7;
}

fn main() -> Int {
  // ---- xiom.thread introspection and aliases
  let cur = Thread.current();
  if cur.id() <= 0 { return 1; }
  if cur.id() != thread.current_thread_id() { return 2; }
  if !cur.name().is_none { return 3; }
  if !thread.thread_name_current().is_none { return 4; }
  if thread.available_parallelism() < 1 { return 5; }
  if thread.hardware_threads() < 1 { return 6; }
  if thread.thread_count() < 1 { return 7; }
  thread.sleep_ms(0);
  thread.sleep(0);
  thread.thread_sleep_us(0);
  thread.yield_now();
  thread.thread_yield();
  thread.thread_parallel_for(0, 3, _pfor);
  if _pf != 3 { return 8; }
  if thread.scope(_scope_fn) != 7 { return 9; }

  // ---- xiom.thread.spawn (simulation)
  let t1 = spawn.spawn(_noop);
  if t1.id <= 0 { return 10; }
  let t2 = spawn.spawn_with(_pfor, 3);
  if t2.id <= 0 { return 11; }
  if _pf != 4 { return 12; }
  match spawn.join(t1) {
    Ok(_) => { },
    Err(_) => { return 13; },
  }
  let sr = spawn.spawn_scoped(_noop);
  if sr.is_err { return 14; }
  spawn.detach(t2);
  spawn.sleep_ms(-5);
  spawn.yield_now();
  if spawn.thread_id() <= 0 { return 15; }
  if spawn.thread_count() < 1 { return 16; }
  if !spawn.is_main_thread() { return 17; }

  // ---- xiom.thread.pool
  var p = pool.thread_pool_new(4);
  if pool.tp_size(&p) != 4 { return 18; }
  if pool.tp_idle(&p) != 4 { return 19; }
  if pool.tp_busy(&p) != 0 { return 20; }
  if !pool.tp_submit_with(&mut p, _pfor, 2) { return 21; }
  if pool.tp_busy(&p) != 1 { return 22; }
  if pool.tp_idle(&p) != 3 { return 23; }
  pool.tp_join(&mut p);
  if pool.tp_busy(&p) != 0 { return 24; }
  if pool.tp_idle(&p) != 4 { return 25; }
  pool.tp_shutdown(&mut p);
  if pool.tp_submit_with(&mut p, _pfor, 2) { return 26; }

  // ---- xiom.thread.local
  var tl = local.thread_local_new(_init42);
  if tl.initialized { return 27; }
  local.tls_set(&mut tl, 7);
  if !tl.initialized { return 28; }
  if local.tls_get(&mut tl) != 7 { return 29; }
  if !tl.initialized { return 30; }
  if local.tls_replace(&mut tl, 9) != 7 { return 31; }
  if !tl.initialized { return 32; }
  let taken = local.tls_take(&mut tl);
  match taken {
    Some(v) => { if v != 9 { return 33; } }
    None => { return 34; }
  }
  if tl.initialized { return 35; }
  let taken2 = local.tls_take(&mut tl);
  if !taken2.is_none { return 36; }
  local.tls_clear(&mut tl);
  let k = local.thread_local_key_new();
  if k <= 0 { return 37; }
  local.tls_key_set(k, 555);
  if local.tls_key_get(k) != 555 { return 38; }

  // ---- xiom.thread.park
  let tok = park.park_token_new();
  park.park_token_notify(tok);
  park.park_token_wait(tok);
  let me = SpawnThread{ id: spawn.thread_id() };
  park.unpark(me);
  park.park();
  let pt = park.park_timeout(0);
  if pt { return 39; }
  var tl2 = Vec[SpawnThread].new();
  tl2.push(me);
  park.unpark_all(&tl2);
  park.park();

  return 0;
}

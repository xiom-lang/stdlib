// XIOM stdlib smoke - xiom.thread.local / park / pool / spawn
// Returns 0 on success with "OK" printed; nonzero + tag on failure.
// NOTE: `xiom.thread.spawn` must be imported LAST: its module name collides
// with the exported `spawn` fn (keep-first module-name rule, BUG 25 #9).

module smoke_thread
use xiom.thread.pool;
use xiom.thread.local;
use xiom.thread.park;
use xiom.thread.spawn;
use xiom.io;

fn init_forty_two() -> Int {
  return 42;
}

var _n: Int = 0;

fn bump() {
  _n = _n + 1;
}

fn main() -> Int {
  // thread local: set/get/replace/take/clear
  // (the lazy init path stores fn() -> T and calls it on first access; that
  // fn-field call miscompiles on this toolchain, so the smoke sets first)
  var tl = local.thread_local_new(init_forty_two);
  local.tls_set(&mut tl, 7);
  if local.tls_get(&mut tl) != 7 { io.println("local:set"); return 2; }
  var old = local.tls_replace(&mut tl, 9);
  if old != 7 { io.println("local:replace"); return 3; }
  var taken = local.tls_take(&mut tl);
  match taken {
    Some(v) => { if v != 9 { io.println("local:take"); return 4; } }
    None => { io.println("local:take_none"); return 5; }
  }
  var taken2 = local.tls_take(&mut tl);
  match taken2 {
    Some(_) => { io.println("local:take_empty"); return 6; }
    None => {}
  }
  local.tls_clear(&mut tl);
  var t3 = local.tls_take(&mut tl);
  match t3 {
    Some(_) => { io.println("local:clear"); return 7; }
    None => {}
  }
  var k = local.thread_local_key_new();
  if k <= 0 { io.println("local:key_new"); return 8; }
  local.tls_key_set(k, 555);
  if local.tls_key_get(k) != 555 { io.println("local:key_get"); return 9; }

  // park: token notify, timeout semantics, unpark-before-park
  var tok = park.park_token_new();
  park.park_token_notify(tok);
  park.park_token_wait(tok);
  var p1 = park.park_timeout(20);
  if p1 { io.println("park:timeout"); return 10; }
  var me = SpawnThread{ id: spawn.thread_id(); };
  park.unpark(me);
  var p2 = park.park_timeout(20);
  if !p2 { io.println("park:unpark"); return 11; }

  // pool: submit, join, shutdown semantics
  var p = pool.thread_pool_new(4);
  if pool.tp_size(&p) != 4 { io.println("pool:size"); return 12; }
  if !pool.tp_submit(&mut p, bump) { io.println("pool:submit"); return 13; }
  if pool.tp_busy(&p) != 1 { io.println("pool:busy"); return 14; }
  if pool.tp_idle(&p) != 3 { io.println("pool:idle"); return 15; }
  if !pool.tp_submit_with(&mut p, bump, 7) { io.println("pool:submit_with"); return 16; }
  pool.tp_join(&mut p);
  if pool.tp_busy(&p) != 0 { io.println("pool:join_busy"); return 17; }
  if pool.tp_idle(&p) != 4 { io.println("pool:join_idle"); return 18; }
  pool.tp_shutdown(&mut p);
  if pool.tp_submit(&mut p, bump) { io.println("pool:shutdown"); return 19; }

  // spawn: simulated spawn/join, thread introspection
  var t = spawn.spawn(bump);
  var jr = spawn.join(t);
  if jr.is_err { io.println("spawn:join"); return 20; }
  if _n != 1 { io.println("spawn:run"); return 21; }
  var sr = spawn.spawn_scoped(bump);
  if sr.is_err { io.println("spawn:scoped"); return 22; }
  if _n != 2 { io.println("spawn:scoped2"); return 23; }
  var tid = spawn.thread_id();
  if tid <= 0 { io.println("spawn:thread_id"); return 24; }
  var tc = spawn.thread_count();
  if tc < 1 { io.println("spawn:count"); return 25; }
  if !spawn.is_main_thread() { io.println("spawn:is_main"); return 26; }
  spawn.sleep_ms(5);
  spawn.yield_now();

  io.println("OK");
  return 0;
}

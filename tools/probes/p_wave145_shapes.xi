// p_wave145_shapes.xi -- wave 145 lock: REAL thread spawn e2e
// (REL-20261013-1423 acceptance + REL-20261010-1834-engine-6 spawn leg).
// The wave-131 probe deliberately omitted the spawn[Int] e2e (compiler-gated
// on m282, hung on v0.64.4); this probe carries it on the official v0.64.5.
// Rows (0 = all hold):
//  1 -- spawn[Int] join == 42
//  2 -- two concurrent spawns join 42 / 7
//  3 -- worker thread id != main id
//  4 -- is_finished flips true within a 200ms window
//  5 -- spawn.xi spawn(fn()) completes n=1 on a real thread
//  6 -- spawn_scoped completes n=2
//  7 -- spawn_with runs on a real worker with its arg (engine-6 channel)
// Setup failures use 10+ (never a silent pass).

module p_wave145_shapes

use xiom.thread;
use xiom.thread.spawn;

var _n: Int = 0;
var _w_id: Int = 0;

fn forty_two() -> Int {
  return 42;
}

fn seven() -> Int {
  return 7;
}

fn record_id_and_zero() -> Int {
  _w_id = thread.current_thread_id();
  return 0;
}

fn bump() {
  _n = _n + 1;
}

var _seen_arg: Int = -1;
var _seen_tid: Int = 0;

fn take_arg(x: Int) {
  _seen_arg = x;
  _seen_tid = thread.current_thread_id();
}

fn main() -> Int {
  // 1: spawn[Int] e2e
  let h1 = thread.spawn[Int](forty_two);
  let r1 = h1.join();
  match r1 {
    Ok(v) => { if v != 42 { return 1; } }
    Err(_) => { return 10; }
  };

  // 2: two concurrent spawns join their values
  let h2 = thread.spawn[Int](forty_two);
  let h3 = thread.spawn[Int](seven);
  let r2 = h2.join();
  let r3 = h3.join();
  var v2 = 0;
  match r2 {
    Ok(v) => { v2 = v; }
    Err(_) => { return 11; }
  };
  var v3 = 0;
  match r3 {
    Ok(v) => { v3 = v; }
    Err(_) => { return 12; }
  };
  if v2 != 42 || v3 != 7 { return 2; }

  // 3: worker id differs from main
  let main_id = thread.current_thread_id();
  let h4 = thread.spawn[Int](record_id_and_zero);
  let r4 = h4.join();
  match r4 {
    Ok(_) => {}
    Err(_) => { return 13; }
  };
  if _w_id == main_id { return 3; }
  if _w_id == 0 { return 14; }

  // 4: is_finished flips true within the window
  let h5 = thread.spawn[Int](forty_two);
  thread.sleep_ms(200);
  if !h5.is_finished() { return 4; }
  let r5 = h5.join();
  match r5 {
    Ok(v) => { if v != 42 { return 5; } }
    Err(_) => { return 15; }
  };

  // 5: spawn.xi real spawn(fn())
  let t1 = spawn.spawn(bump);
  let jr1 = spawn.join(t1);
  if jr1.is_err { return 6; }
  if _n != 1 { return 7; }

  // 6: spawn_scoped runs and joins
  let sr = spawn.spawn_scoped(bump);
  if sr.is_err { return 8; }
  if _n != 2 { return 9; }

  // 7: spawn_with runs on a real worker with its arg
  let t2 = spawn.spawn_with(take_arg, 55);
  let jr2 = spawn.join(t2);
  if jr2.is_err { return 16; }
  if _seen_arg != 55 { return 17; }
  if _seen_tid == 0 { return 18; }
  if _seen_tid == thread.current_thread_id() { return 19; }

  return 0;
}

// smoke_sync_arc_battery.xi -- permanent regression battery for the round-14/15
// sync-constructor fixes (commit ba6a045b family) + Rc tower.
// Locks: AtomicInt full op set incl. CAS, AtomicBool, AtomicPtr, Rc clone/
// strong_count/get/ptr_eq, Weak downgrade/upgrade round trip.
// NOTE: Rc uses the PROVEN shapes -- `module xiom.rc` (file lives at
// memory/rc.xi) with METHOD calls r.clone()/r.get()/r.strong_count().
// Prefix-call shape `Rc.clone(&r)` on generic methods currently misresolves
// the by-value receiver (probe: tmp/kilo/stdlib_campaign/probes/probe_rc_counts
// -- counts return pointer garbage). Revisit when the compiler lands the
// generic-method receiver ABI fix.
module smoke_sync_arc_battery
use xiom.sync.atomics;
use xiom.rc;
use xiom.io;

fn main() -> Int {
  // ---- AtomicInt ----
  var ai = atomics.atomic_int_new(0);
  if atomics.atomic_load(&ai) != 0 { io.println("ai:load0"); return 1; }
  atomics.atomic_store(&mut ai, 42);
  if atomics.atomic_load(&ai) != 42 { io.println("ai:store"); return 2; }
  if atomics.atomic_add(&mut ai, 10) != 52 { io.println("ai:add"); return 3; }
  if atomics.atomic_sub(&mut ai, 2) != 50 { io.println("ai:sub"); return 4; }
  if atomics.atomic_fetch_add(&mut ai, 5) != 50 { io.println("ai:fetch_add"); return 5; }
  if atomics.atomic_load(&ai) != 55 { io.println("ai:load-after-fetch"); return 6; }
  if atomics.atomic_fetch_sub(&mut ai, 4) != 55 { io.println("ai:fetch_sub"); return 7; }
  if atomics.atomic_swap(&mut ai, 7) != 51 { io.println("ai:swap"); return 8; }
  if !atomics.atomic_compare_exchange(&mut ai, 7, 9) { io.println("ai:cas-hit"); return 9; }
  if atomics.atomic_compare_exchange(&mut ai, 7, 100) { io.println("ai:cas-miss"); return 10; }
  if atomics.atomic_load(&ai) != 9 { io.println("ai:final"); return 11; }

  // ---- AtomicBool ----
  var ab = atomics.atomic_bool_new(false);
  if atomics.atomic_bool_load(&ab) { io.println("ab:init"); return 12; }
  atomics.atomic_bool_store(&mut ab, true);
  if !atomics.atomic_bool_load(&ab) { io.println("ab:store"); return 13; }
  if atomics.atomic_bool_swap(&mut ab, false) != true { io.println("ab:swap"); return 14; }
  if atomics.atomic_bool_load(&ab) { io.println("ab:after-swap"); return 15; }

  // ---- AtomicPtr (raw address slot) ----
  var ap = atomics.atomic_ptr_new(4096);
  if atomics.atomic_ptr_load(&ap) != 4096 { io.println("ap:load"); return 16; }
  atomics.atomic_ptr_store(&mut ap, 8192);
  if atomics.atomic_ptr_load(&ap) != 8192 { io.println("ap:store"); return 17; }

  // ---- Rc tower (method-call shapes; see header note) ----
  var r = rc.Rc.new(1234);
  var r2 = r.clone();
  if r.strong_count() != 2 { io.println("rc:clone-count"); return 18; }
  if r.get() != 1234 { io.println("rc:get"); return 20; }
  if !r.ptr_eq(&r2) { io.println("rc:ptr_eq"); return 21; }

  // ---- Weak round trip ----
  var w = r.downgrade();
  match w.upgrade() {
    Some(back) => {
      if back.get() != 1234 { io.println("weak:get"); return 22; }
    },
    None => { io.println("weak:upgrade-none"); return 23; },
  }

  // ---- Rc over Str payload (generic second instantiation) ----
  var rs = rc.Rc.new("payload");
  if rs.get() != "payload" { io.println("rc:str-payload"); return 24; }

  io.println("OK");
  return 0;
}

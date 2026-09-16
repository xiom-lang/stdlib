// smoke_prop_collect_persistent.xi -- persistence property smoke for
// xiom.collect.persistent (PVec/PMap). Core property: an operation returns a
// NEW version and the OLD version is unchanged (structural persistence),
// plus value/length consistency. Returns 0 on success.

module smoke_prop_collect_persistent
use xiom.collect.persistent;
use xiom.io;

fn main() -> Int {
  // --- PVec persistence ---
  var v0 = persistent_vec_new();
  if pvec_len(&v0) != 0 { io.println("pvec:v0-len"); return 1; };
  var v1 = pvec_push(&v0, 7);
  if pvec_len(&v0) != 0 { io.println("pvec:v0-after-push"); return 2; };
  if pvec_len(&v1) != 1 { io.println("pvec:v1-len"); return 3; };
  var v2 = pvec_push(&v1, 9);
  if pvec_len(&v1) != 1 { io.println("pvec:v1-after-push"); return 4; };
  if pvec_len(&v2) != 2 { io.println("pvec:v2-len"); return 5; };

  let a0 = pvec_get(&v2, 0);
  if !a0.is_some || a0.value != 7 { io.println("pvec:v2-0"); return 6; };
  let a1 = pvec_get(&v2, 1);
  if !a1.is_some || a1.value != 9 { io.println("pvec:v2-1"); return 7; };
  let old = pvec_get(&v1, 1);
  if old.is_some { io.println("pvec:v1-1-persist"); return 8; };
  let oob = pvec_get(&v2, 2);
  if oob.is_some { io.println("pvec:v2-oob"); return 9; };

  var v3 = pvec_update(&v2, 0, 100);
  let n0 = pvec_get(&v3, 0);
  if !n0.is_some || n0.value != 100 { io.println("pvec:v3-0"); return 10; };
  let p0 = pvec_get(&v2, 0);
  if !p0.is_some || p0.value != 7 { io.println("pvec:update-persist"); return 11; };

  // --- PMap persistence ---
  var m0 = persistent_map_new();
  let e0 = pmap_get(&m0, 1);
  if e0.is_some { io.println("pmap:m0-empty"); return 12; };
  var m1 = pmap_put(&m0, 1, 10);
  var m2 = pmap_put(&m1, 2, 20);
  let g0 = pmap_get(&m0, 1);
  if g0.is_some { io.println("pmap:m0-persist"); return 13; };
  let g1 = pmap_get(&m1, 1);
  if !g1.is_some || g1.value != 10 { io.println("pmap:m1-1"); return 14; };
  let g1b = pmap_get(&m1, 2);
  if g1b.is_some { io.println("pmap:m1-persist"); return 15; };
  let g2 = pmap_get(&m2, 2);
  if !g2.is_some || g2.value != 20 { io.println("pmap:m2-2"); return 16; };
  let g2b = pmap_get(&m2, 1);
  if !g2b.is_some || g2b.value != 10 { io.println("pmap:m2-1"); return 17; };

  var m3 = pmap_remove(&m2, 1);
  let r3 = pmap_get(&m3, 1);
  if r3.is_some { io.println("pmap:m3-removed"); return 18; };
  let r2 = pmap_get(&m2, 1);
  if !r2.is_some || r2.value != 10 { io.println("pmap:remove-persist"); return 19; };
  let r3b = pmap_get(&m3, 2);
  if !r3b.is_some || r3b.value != 20 { io.println("pmap:m3-kept"); return 20; };

  io.println("smoke_prop_collect_persistent OK");
  return 0;
}

// XIOM stdlib smoke — xiom.collect.immutable / persistent
// Copy-on-write (mutating) and functional (returning new) persistent
// structures. Both modules export the same pvec_*/pmap_* names, so they are
// called through their short module prefixes.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_immutable
use xiom.collect.immutable;
use xiom.collect.persistent;
use xiom.io;

fn main() -> Int {
  // --- immutable: copy-on-write mutating API retains prior versions ---
  var v = immutable.persistent_vec_new();
  immutable.pvec_push(&mut v, 5);
  immutable.pvec_push(&mut v, 9);
  if immutable.pvec_len(&v) != 2 { io.println("im pvec len"); return 1; }
  var old = v;
  immutable.pvec_push(&mut v, 7);
  if immutable.pvec_len(&v) != 3 { io.println("im pvec len after"); return 2; }
  if immutable.pvec_len(&old) != 2 { io.println("im prior retained"); return 3; }
  var iv1 = immutable.pvec_get(&v, 2);
  match iv1 {
    Some(val) => { if val != 7 { io.println("im pvec get2"); return 4; } },
    None => { io.println("im pvec get2 none"); return 5; },
  }
  var iv0 = immutable.pvec_get(&old, 0);
  match iv0 {
    Some(val) => { if val != 5 { io.println("im old get0"); return 6; } },
    None => { io.println("im old get0 none"); return 7; },
  }
  var ivx = immutable.pvec_get(&v, 9);
  match ivx {
    Some(_) => { io.println("im pvec oob"); return 8; },
    None => {},
  }
  var m = immutable.persistent_map_new();
  immutable.pmap_put(&mut m, 1, 10);
  immutable.pmap_put(&mut m, 2, 20);
  immutable.pmap_put(&mut m, 1, 99);
  var im1 = immutable.pmap_get(&m, 1);
  match im1 {
    Some(val) => { if val != 99 { io.println("im pmap upsert"); return 9; } },
    None => { io.println("im pmap get1 none"); return 10; },
  }
  var im2 = immutable.pmap_get(&m, 2);
  match im2 {
    Some(val) => { if val != 20 { io.println("im pmap get2"); return 11; } },
    None => { io.println("im pmap get2 none"); return 12; },
  }
  immutable.pmap_remove(&mut m, 2);
  var im3 = immutable.pmap_get(&m, 2);
  match im3 {
    Some(_) => { io.println("im pmap removed"); return 13; },
    None => {},
  }

  // --- persistent: every update returns a new structure, input stays intact ---
  var p0 = persistent.persistent_vec_new();
  var p1 = persistent.pvec_push(&p0, 7);
  var p2 = persistent.pvec_push(&p1, 8);
  if persistent.pvec_len(&p0) != 0 { io.println("pe pvec p0 intact"); return 14; }
  if persistent.pvec_len(&p1) != 1 { io.println("pe pvec p1 len"); return 15; }
  if persistent.pvec_len(&p2) != 2 { io.println("pe pvec p2 len"); return 16; }
  var pp0 = persistent.pvec_get(&p1, 0);
  match pp0 {
    Some(val) => { if val != 7 { io.println("pe pvec p1 get0"); return 17; } },
    None => { io.println("pe pvec p1 get0 none"); return 18; },
  }
  var pp1 = persistent.pvec_get(&p2, 1);
  match pp1 {
    Some(val) => { if val != 8 { io.println("pe pvec p2 get1"); return 19; } },
    None => { io.println("pe pvec p2 get1 none"); return 20; },
  }
  var p3 = persistent.pvec_update(&p2, 1, 88);
  var pu = persistent.pvec_get(&p3, 1);
  match pu {
    Some(val) => { if val != 88 { io.println("pe pvec update"); return 21; } },
    None => { io.println("pe pvec update none"); return 22; },
  }
  var p4 = persistent.pvec_update(&p2, 5, 1);
  if persistent.pvec_len(&p4) != 2 { io.println("pe pvec update oob len"); return 23; }

  var pm0 = persistent.persistent_map_new();
  var pm1 = persistent.pmap_put(&pm0, 1, 100);
  var pm2 = persistent.pmap_put(&pm1, 2, 200);
  var pmg0 = persistent.pmap_get(&pm0, 1);
  match pmg0 {
    Some(_) => { io.println("pe pmap pm0 intact"); return 24; },
    None => {},
  }
  var pmg1 = persistent.pmap_get(&pm1, 1);
  match pmg1 {
    Some(val) => { if val != 100 { io.println("pe pmap pm1"); return 25; } },
    None => { io.println("pe pmap pm1 none"); return 26; },
  }
  var pmg2 = persistent.pmap_get(&pm2, 2);
  match pmg2 {
    Some(val) => { if val != 200 { io.println("pe pmap pm2"); return 27; } },
    None => { io.println("pe pmap pm2 none"); return 28; },
  }
  var pm3 = persistent.pmap_remove(&pm2, 1);
  var pmg3 = persistent.pmap_get(&pm3, 1);
  match pmg3 {
    Some(_) => { io.println("pe pmap removed"); return 29; },
    None => {},
  }
  var pmg4 = persistent.pmap_get(&pm3, 2);
  match pmg4 {
    Some(val) => { if val != 200 { io.println("pe pmap keep"); return 30; } },
    None => { io.println("pe pmap keep none"); return 31; },
  }

  io.println("OK");
  return 0;
}

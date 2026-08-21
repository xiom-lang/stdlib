// XIOM stdlib smoke -- xiom.collect.hasharray / stringmap
// HAMT (Int keys) with upsert + Str-keyed hash map.
// Returns 0 on success, nonzero + tag on failure.

module smoke_collect_hasharray
use xiom.collect.hasharray;
use xiom.collect.stringmap;
use xiom.io;

fn main() -> Int {
  // --- HAMT: insert, upsert, get, contains, remove, size ---
  var h = hamt_new();
  if hamt_size(&h) != 0 { io.println("hamt empty size"); return 1; }
  hamt_insert(&mut h, 1, 100);
  hamt_insert(&mut h, 2, 200);
  hamt_insert(&mut h, 3, 300);
  hamt_insert(&mut h, 1, 999);
  if hamt_size(&h) != 3 { io.println("hamt size"); return 2; }
  var g1 = hamt_get(&h, 1);
  match g1 {
    Some(v) => { if v != 999 { io.println("hamt upsert"); return 3; } },
    None => { io.println("hamt get1 none"); return 4; },
  }
  var g2 = hamt_get(&h, 2);
  match g2 {
    Some(v) => { if v != 200 { io.println("hamt get2"); return 5; } },
    None => { io.println("hamt get2 none"); return 6; },
  }
  var g3 = hamt_get(&h, 42);
  match g3 {
    Some(_) => { io.println("hamt missing"); return 7; },
    None => {},
  }
  if !hamt_contains(&h, 3) { io.println("hamt contains"); return 8; }
  if hamt_contains(&h, 5) { io.println("hamt contains missing"); return 9; }
  hamt_remove(&mut h, 2);
  if hamt_contains(&h, 2) { io.println("hamt removed"); return 10; }
  if hamt_size(&h) != 2 { io.println("hamt size after remove"); return 11; }
  // force a deep trie: many keys exercising multiple 5-bit levels
  var big = hamt_new();
  var i: Int = 0;
  while i < 60 {
    hamt_insert(&mut big, i * 13 + 1, i);
    i = i + 1;
  }
  if hamt_size(&big) != 60 { io.println("hamt big size"); return 12; }
  i = 0;
  while i < 60 {
    if !hamt_contains(&big, i * 13 + 1) { io.println("hamt big key"); return 13; }
    i = i + 1;
  }
  var bg = hamt_get(&big, 40 * 13 + 1);
  match bg {
    Some(v) => { if v != 40 { io.println("hamt big get"); return 14; } },
    None => { io.println("hamt big get none"); return 15; },
  }

  // --- String map: put, get, contains, remove, size ---
  var sm = string_map_new();
  if string_map_size(&sm) != 0 { io.println("smap empty size"); return 16; }
  string_map_put(&mut sm, "alpha", 1);
  string_map_put(&mut sm, "beta", 2);
  string_map_put(&mut sm, "gamma", 3);
  string_map_put(&mut sm, "alpha", 10);
  if string_map_size(&sm) != 3 { io.println("smap size"); return 17; }
  var sg1 = string_map_get(&sm, "alpha");
  match sg1 {
    Some(v) => { if v != 10 { io.println("smap update"); return 18; } },
    None => { io.println("smap alpha none"); return 19; },
  }
  var sg2 = string_map_get(&sm, "beta");
  match sg2 {
    Some(v) => { if v != 2 { io.println("smap beta"); return 20; } },
    None => { io.println("smap beta none"); return 21; },
  }
  var sg3 = string_map_get(&sm, "nope");
  match sg3 {
    Some(_) => { io.println("smap missing"); return 22; },
    None => {},
  }
  if !string_map_contains(&sm, "gamma") { io.println("smap contains"); return 23; }
  if string_map_contains(&sm, "zzz") { io.println("smap contains missing"); return 24; }
  string_map_remove(&mut sm, "beta");
  if string_map_contains(&sm, "beta") { io.println("smap removed"); return 25; }
  if string_map_size(&sm) != 2 { io.println("smap size after remove"); return 26; }

  io.println("OK");
  return 0;
}

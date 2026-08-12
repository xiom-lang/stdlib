// XIOM stdlib smoke test — xiom.hash.farm
// FarmHash 32/64/128 determinism, empty input, different inputs, seeds and
// fingerprint aliases. Returns 0 on success, nonzero on failure.

module smoke_hash_farm
use xiom.hash.farm;
use xiom.io;
use xiom.string;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn main() -> Int {
  var empty = _bytes("");
  var hello = _bytes("hello");
  var world = _bytes("world");
  var long = _bytes("The quick brown fox jumps over the lazy dog 1234567890");

  // 64-bit, no seed
  var a1 = farm.farmhash64(&hello);
  var a2 = farm.farmhash64(&hello);
  if a1 != a2 { io.println("farm64-not-deterministic"); return 1; }
  var a3 = farm.farmhash64(&world);
  if a1 == a3 { io.println("farm64-collision"); return 2; }
  var a4 = farm.farmhash64(&empty);
  if a4 == a1 { io.println("farm64-empty-eq"); return 3; }

  // 64-bit with one seed
  var b1 = farm.farmhash64_seed(&hello, 55 as UInt64);
  var b2 = farm.farmhash64_seed(&hello, 55 as UInt64);
  if b1 != b2 { io.println("farm64-seed-not-deterministic"); return 4; }
  var b3 = farm.farmhash64_seed(&hello, 56 as UInt64);
  if b1 == b3 { io.println("farm64-seed-insensitive"); return 5; }
  if a1 == b1 { io.println("farm64-seed-ignored"); return 6; }

  // 64-bit with two seeds
  var c1 = farm.farmhash64_seed2(&long, 7 as UInt64, 8 as UInt64);
  var c2 = farm.farmhash64_seed2(&long, 7 as UInt64, 8 as UInt64);
  if c1 != c2 { io.println("farm64-seed2-not-deterministic"); return 7; }
  var c3 = farm.farmhash64_seed2(&long, 7 as UInt64, 9 as UInt64);
  if c1 == c3 { io.println("farm64-seed2-insensitive"); return 8; }

  // 128-bit
  var d1 = farm.farmhash128(&hello);
  var d2 = farm.farmhash128(&hello);
  if d1.0 != d2.0 { io.println("farm128-lo"); return 9; }
  if d1.1 != d2.1 { io.println("farm128-hi"); return 10; }
  var d3 = farm.farmhash128(&world);
  if d1.0 == d3.0 && d1.1 == d3.1 { io.println("farm128-collision"); return 11; }
  var d4 = farm.farmhash128(&empty);
  if d4.0 == d1.0 && d4.1 == d1.1 { io.println("farm128-empty-eq"); return 12; }

  // 128-bit seeded
  var e1 = farm.farmhash128_seed(&long, 21 as UInt64, 22 as UInt64);
  var e2 = farm.farmhash128_seed(&long, 21 as UInt64, 22 as UInt64);
  if e1.0 != e2.0 || e1.1 != e2.1 { io.println("farm128-seed-not-deterministic"); return 13; }
  if d1.0 == e1.0 && d1.1 == e1.1 { io.println("farm128-seed-ignored"); return 14; }

  // 32-bit
  var f1 = farm.farmhash32(&hello);
  var f2 = farm.farmhash32(&hello);
  if f1 != f2 { io.println("farm32-not-deterministic"); return 15; }
  var f3 = farm.farmhash32(&world);
  if f1 == f3 { io.println("farm32-collision"); return 16; }
  var f4 = farm.farmhash32(&empty);
  if f4 == f1 { io.println("farm32-empty-eq"); return 17; }

  // fingerprints match the base variants
  var fp64v = farm.farmhash_fingerprint64(&hello);
  if fp64v != a1 { io.println("fp64-mismatch"); return 18; }
  var fp32v = farm.farmhash_fingerprint32(&long);
  var f32v = farm.farmhash32(&long);
  if fp32v != f32v { io.println("fp32-mismatch"); return 19; }
  var fp128v = farm.farmhash_fingerprint128(&long);
  var f128direct = farm.farmhash128(&long);
  if fp128v.0 != f128direct.0 { io.println("fp128-mismatch"); return 20; }
  if fp128v.1 != f128direct.1 { io.println("fp128-mismatch-2"); return 21; }

  io.println("OK");
  return 0;
}

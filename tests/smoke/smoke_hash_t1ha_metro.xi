// XIOM stdlib smoke test -- xiom.hash.t1ha and xiom.hash.metro
// Determinism, empty input, different inputs, seeded variants, 128-bit twins.
// Returns 0 on success, nonzero on failure.

module smoke_hash_t1ha_metro
use xiom.hash.t1ha;
use xiom.hash.metro;
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

  // t1ha0
  var a1 = t1ha.t1ha0(&hello, 7 as UInt64);
  var a2 = t1ha.t1ha0(&hello, 7 as UInt64);
  if a1 != a2 { io.println("t1ha0-not-deterministic"); return 1; }
  var a3 = t1ha.t1ha0(&world, 7 as UInt64);
  if a1 == a3 { io.println("t1ha0-collision"); return 2; }
  var a4 = t1ha.t1ha0(&empty, 7 as UInt64);
  if a4 == a1 { io.println("t1ha0-empty-eq"); return 3; }

  // t1ha1
  var b1 = t1ha.t1ha1(&long, 9 as UInt64);
  var b2 = t1ha.t1ha1(&long, 9 as UInt64);
  if b1 != b2 { io.println("t1ha1-not-deterministic"); return 4; }
  var b3 = t1ha.t1ha1(&hello, 9 as UInt64);
  if b1 == b3 { io.println("t1ha1-collision"); return 5; }

  // t1ha2 (seed 0 equals atonce)
  var c1 = t1ha.t1ha2(&hello, 0 as UInt64);
  var c2 = t1ha.t1ha2(&hello, 0 as UInt64);
  if c1 != c2 { io.println("t1ha2-not-deterministic"); return 6; }
  var c3 = t1ha.t1ha2_atonce(&hello);
  if c1 != c3 { io.println("t1ha2-atonce-mismatch"); return 7; }
  var c4 = t1ha.t1ha2(&world, 0 as UInt64);
  if c1 == c4 { io.println("t1ha2-collision"); return 8; }
  var c5 = t1ha.t1ha2(&empty, 0 as UInt64);
  if c5 == c1 { io.println("t1ha2-empty-eq"); return 9; }

  // t1ha2 128-bit
  var e1 = t1ha.t1ha2_atonce128(&long);
  var e2 = t1ha.t1ha2_atonce128(&long);
  if e1.0 != e2.0 { io.println("t1ha2-128-lane0"); return 10; }
  if e1.1 != e2.1 { io.println("t1ha2-128-lane1"); return 11; }

  // t1ha_ia32
  var f1 = t1ha.t1ha_ia32(&long, 3 as UInt64);
  var f2 = t1ha.t1ha_ia32(&long, 3 as UInt64);
  if f1 != f2 { io.println("t1ha-ia32-not-deterministic"); return 12; }

  // metrohash64 v1
  var g1 = metro.metrohash64(&hello, 11 as UInt64);
  var g2 = metro.metrohash64(&hello, 11 as UInt64);
  if g1 != g2 { io.println("metro64-not-deterministic"); return 13; }
  var g3 = metro.metrohash64(&world, 11 as UInt64);
  if g1 == g3 { io.println("metro64-collision"); return 14; }
  var g4 = metro.metrohash64(&empty, 11 as UInt64);
  if g4 == g1 { io.println("metro64-empty-eq"); return 15; }

  // metrohash64 v2
  var h1 = metro.metrohash64_2(&long, 5 as UInt64);
  var h2 = metro.metrohash64_2(&long, 5 as UInt64);
  if h1 != h2 { io.println("metro64-2-not-deterministic"); return 16; }
  var h3 = metro.metrohash64_2(&long, 6 as UInt64);
  if h1 == h3 { io.println("metro64-2-seed-insensitive"); return 17; }
  if g1 == h1 { io.println("metro64-1-eq-2"); return 18; }

  // metrohash128
  var i1 = metro.metrohash128(&hello, 13 as UInt64);
  var i2 = metro.metrohash128(&hello, 13 as UInt64);
  if i1.0 != i2.0 { io.println("metro128-lo"); return 19; }
  if i1.1 != i2.1 { io.println("metro128-hi"); return 20; }
  var i3 = metro.metrohash128(&world, 13 as UInt64);
  if i1.0 == i3.0 && i1.1 == i3.1 { io.println("metro128-collision"); return 21; }

  // metrohash128crc fallback matches the pure variant
  var j1 = metro.metrohash128crc(&long, 17 as UInt64);
  var j2 = metro.metrohash128(&long, 17 as UInt64);
  if j1.0 != j2.0 || j1.1 != j2.1 { io.println("metro128crc-mismatch"); return 22; }

  // metrohash32
  var k1 = metro.metrohash32(&long, 99 as UInt32);
  var k2 = metro.metrohash32(&long, 99 as UInt32);
  if k1 != k2 { io.println("metro32-not-deterministic"); return 23; }
  var k3 = metro.metrohash32(&hello, 99 as UInt32);
  if k1 == k3 { io.println("metro32-collision"); return 24; }

  io.println("OK");
  return 0;
}

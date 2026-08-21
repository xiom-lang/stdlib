// XIOM stdlib smoke test -- xiom.hash.highway
// HighwayHash 64/128/256 determinism, empty input, different inputs, key-vector
// and verify helpers. Returns 0 on success, nonzero on failure.

module smoke_hash_highway
use xiom.hash.highway;
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
  var k0: UInt64 = 0x0706050403020100;
  var k1: UInt64 = 0x0f0e0d0c0b0a0908;
  var k2: UInt64 = 0x1716151413121110;
  var k3: UInt64 = 0x1f1e1d1c1b1a1918;

  // 64-bit: deterministic, differs across inputs, empty works
  var h1 = highway.highway64(&hello, k0, k1, k2, k3);
  var h2 = highway.highway64(&hello, k0, k1, k2, k3);
  if h1 != h2 { io.println("highway64-not-deterministic"); return 1; }
  var h3 = highway.highway64(&world, k0, k1, k2, k3);
  if h1 == h3 { io.println("highway64-collision"); return 2; }
  var he = highway.highway64(&empty, k0, k1, k2, k3);
  if he == h1 { io.println("highway64-empty-eq"); return 3; }

  // 128-bit: both words deterministic
  var s1 = highway.highway128(&hello, k0, k1, k2, k3);
  var s2 = highway.highway128(&hello, k0, k1, k2, k3);
  if s1.low != s2.low { io.println("highway128-low"); return 4; }
  if s1.high != s2.high { io.println("highway128-high"); return 5; }

  // 256-bit: all four lanes deterministic
  var t1 = highway.highway256(&hello, k0, k1, k2, k3);
  var t2 = highway.highway256(&hello, k0, k1, k2, k3);
  if t1.0 != t2.0 { io.println("highway256-lane0"); return 6; }
  if t1.1 != t2.1 { io.println("highway256-lane1"); return 7; }
  if t1.2 != t2.2 { io.println("highway256-lane2"); return 8; }
  if t1.3 != t2.3 { io.println("highway256-lane3"); return 9; }

  // key-vector entry point matches the scalar call
  var keys = Vec[UInt64].new();
  keys.push(k0);
  keys.push(k1);
  keys.push(k2);
  keys.push(k3);
  var hh = highway.highway_hash(&hello, keys);
  if hh != h1 { io.println("highway-hash-mismatch"); return 10; }

  // verify helper
  if !highway.highway_verify(&hello, k0, k1, k2, k3, h1) { io.println("highway-verify-neg"); return 11; }
  if highway.highway_verify(&hello, k0, k1, k2, k3, he) { io.println("highway-verify-pos"); return 12; }

  io.println("OK");
  return 0;
}

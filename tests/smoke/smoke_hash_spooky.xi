// XIOM stdlib smoke test — xiom.hash.spooky
// SpookyHash 32/64/128 determinism, empty input, different inputs and seeds.
// Returns 0 on success, nonzero on failure.

module smoke_hash_spooky
use xiom.hash.spooky;
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

  // 32-bit
  var a1 = spooky.spooky32(&hello);
  var a2 = spooky.spooky32(&hello);
  if a1 != a2 { io.println("spooky32-not-deterministic"); return 1; }
  var a3 = spooky.spooky32(&world);
  if a1 == a3 { io.println("spooky32-collision"); return 2; }
  var a4 = spooky.spooky32(&empty);
  if a4 == a1 { io.println("spooky32-empty-eq"); return 3; }

  // 64-bit with seed
  var b1 = spooky.spooky64(&hello, 42 as UInt64);
  var b2 = spooky.spooky64(&hello, 42 as UInt64);
  if b1 != b2 { io.println("spooky64-not-deterministic"); return 4; }
  var b3 = spooky.spooky64(&hello, 43 as UInt64);
  if b1 == b3 { io.println("spooky64-seed-insensitive"); return 5; }
  var b4 = spooky.spooky64(&world, 42 as UInt64);
  if b1 == b4 { io.println("spooky64-collision"); return 6; }

  // 128-bit with two seeds
  var c1 = spooky.spooky128(&hello, 1 as UInt64, 2 as UInt64);
  var c2 = spooky.spooky128(&hello, 1 as UInt64, 2 as UInt64);
  if c1.0 != c2.0 { io.println("spooky128-h1"); return 7; }
  if c1.1 != c2.1 { io.println("spooky128-h2"); return 8; }
  var c3 = spooky.spooky128(&world, 1 as UInt64, 2 as UInt64);
  if c1.0 == c3.0 && c1.1 == c3.1 { io.println("spooky128-collision"); return 9; }
  var c4 = spooky.spooky128(&empty, 1 as UInt64, 2 as UInt64);
  if c4.0 == c1.0 && c4.1 == c1.1 { io.println("spooky128-empty-eq"); return 10; }

  // short path (<= 8 bytes)
  var d1 = spooky.spooky_short(&hello);
  var d2 = spooky.spooky_short(&hello);
  if d1 != d2 { io.println("spooky-short-not-deterministic"); return 11; }
  var d3 = spooky.spooky_short(&world);
  if d1 == d3 { io.println("spooky-short-collision"); return 12; }

  io.println("OK");
  return 0;
}

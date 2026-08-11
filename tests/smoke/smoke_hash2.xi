module smoke_hash2
use xiom.hash;
use xiom.io;

fn to_bytes(s: Str) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < s.len() {
    out.push(xiom.string.byte_at(s, i));
    i = i + 1;
  }
  return out;
}

fn main() -> Int {
  // XXH64 reference vectors (seed 0, verified against a clang-built C
  // reference implementation of the canonical algorithm)
  var b0 = Vec[UInt8].new();
  if xiom.hash.xxhash64(&b0, 0) != -1205034819632174695 { io.println("xxh64 empty"); return 1; }
  var ba = to_bytes("a");
  if xiom.hash.xxhash64(&ba, 0) != -3292477735350538661 { io.println("xxh64 a"); return 2; }
  var babc = to_bytes("abc");
  if xiom.hash.xxhash64(&babc, 0) != 4952883123889572249 { io.println("xxh64 abc"); return 3; }
  var bmsg = to_bytes("message digest");
  if xiom.hash.xxhash64(&bmsg, 0) != 463544382707905470 { io.println("xxh64 msg"); return 4; }
  var bfox = to_bytes("The quick brown fox jumps over the lazy dog");
  if xiom.hash.xxhash64(&bfox, 0) != -2050589360526790301 { io.println("xxh64 fox"); return 5; }
  // boundary lengths 31/32/33 and 35/36 (block / 4-byte / 8-byte tail paths)
  var b31 = to_bytes("1234567890123456789012345678901");
  if xiom.hash.xxhash64(&b31, 0) != -8127171345887447186 { io.println("xxh64 31"); return 6; }
  var b32 = to_bytes("12345678901234567890123456789012");
  if xiom.hash.xxhash64(&b32, 0) != -2113764571158603405 { io.println("xxh64 32"); return 7; }
  var b33 = to_bytes("123456789012345678901234567890123");
  if xiom.hash.xxhash64(&b33, 0) != 8101967755977761037 { io.println("xxh64 33"); return 8; }
  var b36 = to_bytes("123456789012345678901234567890123456");
  var h36 = xiom.hash.xxhash64(&b36, 0);
  if h36 == xiom.hash.xxhash64(&b33, 0) { io.println("xxh64 distinct"); return 9; }
  // seeded differs from seed 0
  var hseed = xiom.hash.xxhash64(&bfox, 42);
  if hseed == xiom.hash.xxhash64(&bfox, 0) { io.println("xxh64 seed"); return 10; }
  // FNV-1 32-bit: offset basis for empty; differs from FNV-1a
  if xiom.hash.fnv1_32("") != 2166136261 { io.println("fnv1 empty"); return 11; }
  if xiom.hash.fnv1_32("hello") == xiom.hash.fnv1a32(&to_bytes("hello")) { io.println("fnv1 vs fnv1a"); return 12; }
  if xiom.hash.fnv1_32("hello world") != xiom.hash.fnv1_32("hello world") { io.println("fnv1 det"); return 13; }
  io.println("hash2 ok");
  return 0;
}

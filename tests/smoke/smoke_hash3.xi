module smoke_hash3
use xiom.hash;
use xiom.hash.siphash;
use xiom.hash.superfast;
use xiom.hash.crc;
use xiom.hash.xxhash;
use xiom.io;

// XXH3 / SipHash-2-4 / SipHash-1-3 / SuperFastHash / Adler-32.
// All vectors generated from a clang-built reference (official xxHash
// v0.8.3 header + canonical SipHash/SuperFastHash/Adler-32 C code).

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
  var b0 = Vec[UInt8].new();
  var ba = to_bytes("a");
  var babc = to_bytes("abc");
  var bmsg = to_bytes("message digest");
  var bfox = to_bytes("The quick brown fox jumps over the lazy dog");
  var b80 = to_bytes("12345678901234567890123456789012345678901234567890123456789012345678901234567890");
  var bwiki = to_bytes("Wikipedia");

  // ── XXH3-64 (seed 0) ──
  if xiom.hash.xxhash.xxh3_64(&b0) != 0x2d06800538d394c2 { io.println("xxh3_64 empty"); return 1; }
  if xiom.hash.xxhash.xxh3_64(&ba) != 0xe6c632b61e964e1f { io.println("xxh3_64 a"); return 2; }
  if xiom.hash.xxhash.xxh3_64(&babc) != 0x78af5f94892f3950 { io.println("xxh3_64 abc"); return 3; }
  if xiom.hash.xxhash.xxh3_64(&bmsg) != 0x160d8e9329be94f9 { io.println("xxh3_64 msg"); return 4; }
  if xiom.hash.xxhash.xxh3_64(&bfox) != 0xce7d19a5418fb365 { io.println("xxh3_64 fox"); return 5; }
  if xiom.hash.xxhash.xxh3_64(&b80) != 0x7f58aa2520c681f9 { io.println("xxh3_64 80"); return 6; }
  // seeded: XXH3_64bits_withSeed("abc", 42)
  if xiom.hash.xxhash.xxh3_64_with_seed(&babc, 42) != 0xd8438def21bbdcc3 { io.println("xxh3_64 seed"); return 7; }

  // ── XXH3-128 (seed 0) ──
  var h0 = xiom.hash.xxhash.xxh3_128(&b0);
  if h0.low64 != 0x6001c324468d497f || h0.high64 != 0x99aa06d3014798d8 { io.println("xxh3_128 empty"); return 8; }
  var ha = xiom.hash.xxhash.xxh3_128(&ba);
  if ha.low64 != 0xe6c632b61e964e1f || ha.high64 != 0xa96faf705af16834 { io.println("xxh3_128 a"); return 9; }
  var habc = xiom.hash.xxhash.xxh3_128(&babc);
  if habc.low64 != 0x78af5f94892f3950 || habc.high64 != 0x06b05ab6733a6185 { io.println("xxh3_128 abc"); return 10; }
  var hmsg = xiom.hash.xxhash.xxh3_128(&bmsg);
  if hmsg.low64 != 0x0abfabecb8e3a424 || hmsg.high64 != 0x34ab715d95e3b649 { io.println("xxh3_128 msg"); return 11; }
  var hfox = xiom.hash.xxhash.xxh3_128(&bfox);
  if hfox.low64 != 0x24a1cc2e3a8a7651 || hfox.high64 != 0xddd650205ca3e7fa { io.println("xxh3_128 fox"); return 12; }
  var h80 = xiom.hash.xxhash.xxh3_128(&b80);
  if h80.low64 != 0x40cb8d6ac672dcb8 || h80.high64 != 0x08dd22c3ddc34ce6 { io.println("xxh3_128 80"); return 13; }

  // ── SipHash-2-4 / 1-3 (key = 0x0706050403020100, 0x0f0e0d0c0b0a0908) ──
  var k0: UInt64 = 0x0706050403020100;
  var k1: UInt64 = 0x0f0e0d0c0b0a0908;
  if xiom.hash.siphash.siphash24(&b0, k0, k1) != 0x726fdb47dd0e0e31 { io.println("sip24 empty"); return 14; }
  if xiom.hash.siphash.siphash24(&ba, k0, k1) != 0x2ba3e8e9a71148ca { io.println("sip24 a"); return 15; }
  if xiom.hash.siphash.siphash24(&babc, k0, k1) != 0x5dbcfa53aa2007a5 { io.println("sip24 abc"); return 16; }
  if xiom.hash.siphash.siphash24(&bmsg, k0, k1) != 0xb670bf0a59c7f5c9 { io.println("sip24 msg"); return 17; }
  if xiom.hash.siphash.siphash24(&bfox, k0, k1) != 0x52276105dc1f6fe4 { io.println("sip24 fox"); return 18; }
  if xiom.hash.siphash.siphash24(&b80, k0, k1) != 0x5e2bf18609da580a { io.println("sip24 80"); return 19; }
  if xiom.hash.siphash.siphash13(&b0, k0, k1) != 0xabac0158050fc4dc { io.println("sip13 empty"); return 20; }
  if xiom.hash.siphash.siphash13(&ba, k0, k1) != 0x1c2697ab786a6237 { io.println("sip13 a"); return 21; }
  if xiom.hash.siphash.siphash13(&babc, k0, k1) != 0x6fce24e8af8146eb { io.println("sip13 abc"); return 22; }
  if xiom.hash.siphash.siphash13(&bmsg, k0, k1) != 0x8544dec4bdebeddd { io.println("sip13 msg"); return 23; }
  if xiom.hash.siphash.siphash13(&bfox, k0, k1) != 0x9bd930430f05b1ce { io.println("sip13 fox"); return 24; }
  if xiom.hash.siphash.siphash13(&b80, k0, k1) != 0x838989b67e4b45fe { io.println("sip13 80"); return 25; }
  // zero-key sanity (Wikipedia vectors)
  if xiom.hash.siphash.siphash24_zerokey(&ba) != 0x96c20860cd93a249 { io.println("sip24 zk a"); return 26; }
  if xiom.hash.siphash.siphash24_zerokey(&b0) != 0x1e924b9d737700d7 { io.println("sip24 zk empty"); return 27; }

  // ── SuperFastHash ──
  if xiom.hash.superfast.superfast32(&b0) != 0 { io.println("sf empty"); return 28; }
  if xiom.hash.superfast.superfast32(&ba) != 0x1266f960 { io.println("sf a"); return 29; }
  if xiom.hash.superfast.superfast32(&babc) != 0xd7be8b0f { io.println("sf abc"); return 30; }
  if xiom.hash.superfast.superfast32(&bmsg) != 0x32bb9891 { io.println("sf msg"); return 31; }
  if xiom.hash.superfast.superfast32(&bfox) != 0x385751ee { io.println("sf fox"); return 32; }
  if xiom.hash.superfast.superfast32(&b80) != 0xde28c84f { io.println("sf 80"); return 33; }

  // ── Adler-32 ──
  if xiom.hash.crc.adler32(&b0) != 0x00000001 { io.println("adler empty"); return 34; }
  if xiom.hash.crc.adler32(&ba) != 0x00620062 { io.println("adler a"); return 35; }
  if xiom.hash.crc.adler32(&babc) != 0x024d0127 { io.println("adler abc"); return 36; }
  if xiom.hash.crc.adler32(&bmsg) != 0x29750586 { io.println("adler msg"); return 37; }
  if xiom.hash.crc.adler32(&bfox) != 0x5bdc0fda { io.println("adler fox"); return 38; }
  if xiom.hash.crc.adler32(&bwiki) != 0x11e60398 { io.println("adler wiki"); return 39; }

  io.println("smoke_hash3: all 39 checks passed");
  return 0;
}

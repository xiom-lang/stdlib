// XIOM stdlib smoke test — xiom.hash.city / xiom.hash.xxhash /
//                       xiom.hash.murmur / xiom.hash.jenkins / xiom.hash.crc
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_hash_folder
use xiom.hash.city;
use xiom.hash.xxhash;
use xiom.hash.murmur;
use xiom.hash.jenkins;
use xiom.hash.crc;
use xiom.string;
use xiom.convert.toint;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    let ch: Option[Char] = char_at(s, i);
    if ch.is_some {
      var code = to_int_from_char(ch.value);
      v.push(code as UInt8);
    };
    i = i + 1;
  };
  return v;
}

fn main() -> Int {
  var empty = _bytes("");
  var hello = _bytes("hello");
  var abc = _bytes("abc");
  var fox = _bytes("The quick brown fox jumps over the lazy dog");
  var long70 = _bytes("1234567890123456789012345678901234567890123456789012345678901234567890");
  var long170 = _bytes("1234567890123456789012345678901234567890123456789012345678901234567890AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
  var nums = _bytes("123456789");
  var hello_world = _bytes("hello world");

  // ---- xiom.hash.city: CityHash64 ----
  var h1 = city.city64(&empty);
  var h2 = city.city64(&hello);
  var h3 = city.city64(&abc);
  var h4 = city.city64(&fox);
  var h5 = city.city64(&long70);
  var h6 = city.city64(&long170);
  var h7 = city.city64_with_seed(&hello, 1234567 as UInt64);
  if h1 != 0x9ae16a3b2f90404f as UInt64 { return 1; }
  if h2 != 0xb48be5a931380ce8 as UInt64 { return 2; }
  if h3 != 0x24a5b3a074e7f369 as UInt64 { return 3; }
  if h4 != 0xc268724928feca7d as UInt64 { return 4; }
  if h5 != 0xf526a3c20019847e as UInt64 { return 5; }
  if h6 != 0xcf72ca0892fd8a86 as UInt64 { return 6; }
  if h7 != 0xabaa94343ec4adb1 as UInt64 { return 7; }

  // ---- xiom.hash.city: CityHash128 [low, high] ----
  var c128_hello = city.city128(&hello);
  if c128_hello.len() != 2 { return 8; }
  if c128_hello[0] != 0x6f72e4abb491a74a as UInt64 { return 9; }
  if c128_hello[1] != 0x65148f580b45f347 as UInt64 { return 10; }
  var c128_long70 = city.city128(&long70);
  if c128_long70[0] != 0xc8a4ca40a4e0e8a0 as UInt64 { return 11; }
  if c128_long70[1] != 0xee2032c6fa6a7620 as UInt64 { return 12; }
  var c128_long170 = city.city128(&long170);
  if c128_long170[0] != 0x0f06dda60bfbee4f as UInt64 { return 13; }
  if c128_long170[1] != 0xbff68938e4618197 as UInt64 { return 14; }

  // ---- xiom.hash.xxhash: XXH64 ----
  var x1 = xxhash.xxh64(&empty, 0 as UInt64);
  var x2 = xxhash.xxh64(&hello, 0 as UInt64);
  var x3 = xxhash.xxh64(&hello_world, 0 as UInt64);
  var x4 = xxhash.xxh64(&nums, 0 as UInt64);
  if x1 != 0xef46db3751d8e999 as UInt64 { return 15; }
  if x2 != 0x26c7827d889f6da3 as UInt64 { return 16; }
  if x3 != 0x45ab6734b21e6968 as UInt64 { return 17; }
  if x4 != 0x8cb841db40e6ae83 as UInt64 { return 18; }

  // ---- xiom.hash.xxhash: XXH32 ----
  var z1 = xxhash.xxh32(&empty, 0 as UInt32);
  var z2 = xxhash.xxh32(&hello, 0 as UInt32);
  var z3 = xxhash.xxh32(&nums, 0 as UInt32);
  if z1 != 0x02cc5d05 as UInt32 { return 19; }
  if z2 != 0x679baef8 as UInt32 { return 20; }
  if z3 != 0xf7584115 as UInt32 { return 21; }

  // ---- xiom.hash.murmur: MurmurHash3 x64_128 ----
  var m_hello = murmur.murmur3_128(&hello, 0 as UInt32);
  if m_hello.len() != 2 { return 22; }
  if m_hello[0] != 0xcbd8a7b341bd9b02 as UInt64 { return 23; }
  if m_hello[1] != 0x5b1e906a48ae1d19 as UInt64 { return 24; }
  var m_empty = murmur.murmur3_128(&empty, 0 as UInt32);
  if m_empty[0] != 0 as UInt64 { return 25; }
  if m_empty[1] != 0 as UInt64 { return 26; }
  var m_world = murmur.murmur3_128(&hello_world, 0 as UInt32);
  if m_world[0] != 0x533f6046eb7f610e as UInt64 { return 27; }
  if m_world[1] != 0xab97467d60eb63b1 as UInt64 { return 28; }

  // ---- xiom.hash.murmur: MurmurHash64A ----
  var m2a = murmur.murmur2_64(&hello, 0 as UInt64);
  var m2b = murmur.murmur2_64(&hello_world, 0 as UInt64);
  if m2a != 0x1e68d17c457bf117 as UInt64 { return 29; }
  if m2b != 0xd3ba2368a832afce as UInt64 { return 30; }

  // ---- xiom.hash.jenkins: lookup3 hashlittle (a, b) ----
  var j_empty1 = jenkins.jenkins_lookup3(&empty, 0 as UInt32);
  var j_empty2 = jenkins.jenkins_lookup3(&empty, 0 as UInt32);
  if j_empty1.len() != 2 { return 31; }
  if j_empty2.len() != 2 { return 31; }
  if j_empty1[0] != j_empty2[0] { return 31; }
  if j_empty1[1] != j_empty2[1] { return 31; }
  var j_hello = jenkins.jenkins_lookup3(&hello, 0 as UInt32);
  if j_hello[0] != 0xe4384163 as UInt32 { return 32; }
  if j_hello[1] != 0x2a105b94 as UInt32 { return 33; }
  var j_world = jenkins.jenkins_lookup3(&hello_world, 0 as UInt32);
  if j_world[0] != 0xd9d4975b as UInt32 { return 34; }
  if j_world[1] != 0x3e509025 as UInt32 { return 35; }
  var j_fox = jenkins.jenkins_lookup3(&fox, 0 as UInt32);
  if j_fox[0] == j_empty1[0] && j_fox[1] == j_empty1[1] { return 36; }

  // ---- xiom.hash.crc: CRC-64 / CRC-32C / CRC-16 / checksums ----
  var r1 = crc.crc64_ecma(&nums);
  var r2 = crc.crc64_we(&nums);
  var r3 = crc.crc32c(&nums);
  var r4 = crc.crc16_ccitt(&nums);
  var r5 = crc.checksum_bsd(&hello);
  var r6 = crc.checksum_sysv(&hello);
  var r7 = crc.checksum_internet(&hello);
  if r1 != 0x995dc9bbdf1939fa as UInt64 { return 37; }
  if r2 != 0x62ec59e3f1a4f00a as UInt64 { return 38; }
  if r3 != 0xe3069283 as UInt32 { return 39; }
  if r4 != 0x29b1 as UInt32 { return 40; }
  if r5 != 0x20d3 as UInt32 { return 41; }
  var bsd2 = crc.checksum_bsd(&hello);
  if r5 != bsd2 { return 41; }
  if r6 != 0x9069 as UInt32 { return 42; }
  if r7 != 0xbc2d as UInt32 { return 43; }

  return 0;
}

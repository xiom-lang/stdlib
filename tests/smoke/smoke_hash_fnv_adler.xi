// XIOM stdlib smoke test — xiom.hash.fnv, xiom.hash.adler, xiom.hash.checksum
// FNV-1a known answers, Adler-32 known answer and combine, classic checksums.
// Returns 0 on success, nonzero on failure.

module smoke_hash_fnv_adler
use xiom.hash.fnv;
use xiom.hash.adler;
use xiom.hash.checksum;
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
  var a = _bytes("a");
  var hello = _bytes("hello");
  var world = _bytes("world");
  var hello_world = _bytes("helloworld");

  // FNV-1a 64-bit known answers: "" -> offset basis, "a" -> af63dc4c8601ec8c
  if fnv.fnv1a64(&empty) != 0xCBF29CE484222325 as UInt64 {
    io.println("fnv1a64-empty"); return 1;
  }
  if fnv.fnv1a64(&a) != 0xAF63DC4C8601EC8C as UInt64 {
    io.println("fnv1a64-a"); return 2;
  }
  var f1 = fnv.fnv1a64(&hello);
  var f2 = fnv.fnv1a64(&hello);
  if f1 != f2 { io.println("fnv1a64-not-deterministic"); return 3; }
  var f3 = fnv.fnv1a64(&world);
  if f1 == f3 { io.println("fnv1a64-collision"); return 4; }

  // FNV-1/1a 128-bit: empty input yields the offset basis
  var o128: UInt128 = 0x6C62272E07BB014262B821756295C58D as UInt128;
  if fnv.fnv1a_128(&empty) != o128 { io.println("fnv1a128-empty"); return 5; }
  if fnv.fnv1_128(&empty) != o128 { io.println("fnv1-128-empty"); return 6; }
  var g1 = fnv.fnv1a_128(&hello);
  var g2 = fnv.fnv1a_128(&hello);
  if g1 != g2 { io.println("fnv1a128-not-deterministic"); return 7; }
  var g3 = fnv.fnv1a_128(&world);
  if g1 == g3 { io.println("fnv1a128-collision"); return 8; }
  if fnv.fnv1_128(&hello) == fnv.fnv1a_128(&hello) { io.println("fnv1-eq-fnv1a"); return 9; }

  // FNV-1a 128-bit seeded: seeding with the 64-bit offset basis and empty input
  // reproduces the FNV-1a 64-bit offset basis (the required known answer).
  var seed64: UInt128 = 0xCBF29CE484222325 as UInt128;
  if fnv.fnv1a_128_seed(&empty, seed64) != seed64 { io.println("fnv1a128-seed"); return 10; }
  var h1 = fnv.fnv1a_128_seed(&hello, seed64);
  var h2 = fnv.fnv1a_128_seed(&hello, seed64);
  if h1 != h2 { io.println("fnv1a128-seed-not-deterministic"); return 11; }

  // Adler-32 known answers: "" -> 1, "Wikipedia" -> 0x11E60398
  if adler.adler32(&empty) != 1 as UInt32 { io.println("adler32-empty"); return 12; }
  var wiki = _bytes("Wikipedia");
  var ad_w = adler.adler32(&wiki);
  if ad_w != 0x11E60398 as UInt32 {
    io.println("adler32-wikipedia"); return 13;
  }
  var ad_ws = adler.adler32_str("Wikipedia");
  if ad_ws != 0x11E60398 as UInt32 {
    io.println("adler32-str-wikipedia"); return 14;
  }
  var ad_b = adler.adler32(&hello);
  var ad_bs = adler.adler32_str("hello");
  if ad_b != ad_bs {
    io.println("adler32-str-mismatch"); return 15;
  }

  // Adler-32 combine: combine(adler(A), adler(B), len(B)) == adler(A || B)
  var combo1 = adler.adler32(&hello);
  var combo2 = adler.adler32(&world);
  var combo3 = adler.adler32_combine(combo1, combo2, 5);
  var combo4 = adler.adler32(&hello_world);
  if combo3 != combo4 { io.println("adler32-combine"); return 16; }

  // Classic checksums: single byte "a" -> 0x61 for BSD (sum of bytes)
  var bs_a = checksum.checksum_bsd(&a);
  if bs_a != 0x61 as UInt32 { io.println("bsd-a"); return 17; }
  var sv_a = checksum.checksum_sysv(&a);
  if sv_a != 0x8030 as UInt32 { io.println("sysv-a"); return 18; }
  var ab = _bytes("ab");
  var inet = checksum.checksum_internet(&ab);
  if inet != 0x9E9D as UInt32 {
    io.println("internet-ab"); return 19;
  }
  var b1 = checksum.checksum_bsd(&hello);
  var b2 = checksum.checksum_bsd(&hello);
  if b1 != b2 { io.println("bsd-not-deterministic"); return 20; }

  // Fletcher-16: sum1 component equals the byte sum mod 255
  var abcde = _bytes("abcde");
  var f16 = checksum.checksum_fletcher16(&abcde);
  if f16 != 0xC8F0 as UInt16 { io.println("fletcher16-abcde"); return 21; }
  var byte_sum = 97 + 98 + 99 + 100 + 101;
  var sum_mod = byte_sum % 255;
  if (f16 as Int & 0xFF) != sum_mod { io.println("fletcher16-sum"); return 22; }

  io.println("OK");
  return 0;
}

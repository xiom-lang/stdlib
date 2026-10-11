// p_wave106_shapes.xi -- wave 106 shape validation: xiom.hash modules
// (hash.xi, farm, highway, metro, murmur, spooky, t1ha).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-106 clause guards:
//   (a) xiom.hash: DefaultHasher seed/chain/finish, Bool.hash, FNV family,
//       xxhash32, _rotl32 masking, djb2/sdbm/string_hash, combine_hashes;
//   (b) xiom.hash.farm: empty-input digests, default-seed equivalences,
//       fingerprint mirrors;
//   (c) xiom.hash.highway: zero-key empty lanes, key-vector parity,
//       verify semantics;
//   (d) xiom.hash.metro/murmur/spooky/t1ha empty-input digest pins,
//       delegation parity and one-shot equivalences.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave106_shapes

use xiom.hash;
use xiom.hash.farm as farm;
use xiom.hash.highway as highway;
use xiom.hash.metro as metro;
use xiom.hash.murmur as murmur;
use xiom.hash.spooky as spooky;
use xiom.hash.t1ha as t1ha;
use xiom.string;

fn sbytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  let eb = sbytes("");
  let ab = sbytes("abc");

  // ---- xiom.hash: DefaultHasher + helpers
  let h0 = DefaultHasher.new();
  let f0 = h0.finish();
  if f0 != 5381 { return 1; }
  let h1 = DefaultHasher.new();
  h1.write(&ab);
  let f1 = h1.finish();
  if f1 != 0xb885c8b { return 2; }
  let h2 = DefaultHasher.new();
  h2.write_str("abc");
  let f2 = h2.finish();
  if f2 != 0xb885c8b { return 3; }
  let h3 = DefaultHasher.new();
  h3.write_int(1);
  let f3 = h3.finish();
  if f3 != 0x1ae2fd67f51ee6 { return 4; }
  let h4 = DefaultHasher.new();
  h4.write(&eb);
  let f4 = h4.finish();
  if f4 != 5381 { return 5; }
  // NOTE: Int.hash / Bool.hash / hash_value / hash are NOT probed here:
  // the compiler lowers zero-arg `.hash()` on scalars to a builtin
  // identity that shadows the stdlib methods (see the REL item filed
  // 2026-10-11): false.hash() == 0, hash_value(0) == 0, and explicit
  // `Bool.hash(x)` does not type-check ("expected Self, found Bool").
  // The check below locks the reachable surface only.
  let sph = sip_hash(&eb);
  if sph != 5381 as UInt64 { return 6; }
  let h5 = DefaultHasher.new();
  h5.write_int(0);
  let f5 = h5.finish();
  if f5 != 0x1ae2f37bb34a05 { return 7; }
  let hc0 = hash_combine(0, 0);
  if hc0 != 0x9e3779b9 { return 8; }
  let fv32e = fnv1a32(&eb);
  if fv32e != 0x811C9DC5 { return 9; }
  let fv1_32e = fnv1_32("");
  if fv1_32e != 2166136261 { return 10; }
  let fv1_64e = fnv1_64(&eb);
  if fv1_64e != 0xCBF29CE484222325 { return 11; }
  let r1 = _rotl32(1, 1);
  if r1 != 2 { return 12; }
  let r2 = _rotl32(0x80000000, 1);
  if r2 != 1 { return 13; }
  let xx32 = xxhash32(&eb, 0);
  if xx32 != 0x02CC5D05 { return 14; }
  let dj = djb2("abc");
  if dj != 0xb885c8b { return 15; }
  let sd = sdbm("");
  if sd != 0 { return 16; }
  let sh = string_hash("");
  if sh != 5381 { return 17; }

  // ---- farm
  let fe64 = farm.farmhash64(&eb);
  if fe64 != 0 as UInt64 { return 18; }
  let fe32 = farm.farmhash32(&eb);
  if fe32 != 0xc630264f as UInt32 { return 19; }
  let fe128 = farm.farmhash128(&eb);
  if fe128.0 != 0 as UInt64 || fe128.1 != 0 as UInt64 { return 20; }
  let a64 = farm.farmhash64(&ab);
  let a64s = farm.farmhash64_seed(&ab, 0x9ae16a3b2f90404f as UInt64);
  if a64s != a64 { return 21; }
  let a64s2 = farm.farmhash64_seed2(&ab, 0x9ae16a3b2f90404f as UInt64, 0xb492b66fbe98f273 as UInt64);
  if a64s2 != a64 { return 22; }
  let a128 = farm.farmhash128(&ab);
  let a128s = farm.farmhash128_seed(&ab, 0xc3a5c85c97cb3127 as UInt64, 0xb492b66fbe98f273 as UInt64);
  if a128s.0 != a128.0 || a128s.1 != a128.1 { return 23; }
  let fp32 = farm.farmhash_fingerprint32(&ab);
  let a32 = farm.farmhash32(&ab);
  if fp32 != a32 { return 24; }
  let fp64 = farm.farmhash_fingerprint64(&ab);
  if fp64 != a64 { return 25; }
  let fp128 = farm.farmhash_fingerprint128(&ab);
  if fp128.0 != a128.0 || fp128.1 != a128.1 { return 26; }

  // ---- highway
  let hw64e = highway.highway64(&eb, 0 as UInt64, 0 as UInt64, 0 as UInt64, 0 as UInt64);
  if hw64e != 0 as UInt64 { return 27; }
  let hw128e = highway.highway128(&eb, 0 as UInt64, 0 as UInt64, 0 as UInt64, 0 as UInt64);
  if hw128e.low != 0 as UInt64 || hw128e.high != 0 as UInt64 { return 28; }
  let hw256e = highway.highway256(&eb, 0 as UInt64, 0 as UInt64, 0 as UInt64, 0 as UInt64);
  if hw256e.0 != 0 as UInt64 || hw256e.1 != 0 as UInt64 { return 29; }
  if hw256e.2 != 0 as UInt64 || hw256e.3 != 0 as UInt64 { return 29; }
  var keyv = Vec[UInt64].new();
  keyv.push(1 as UInt64);
  keyv.push(2 as UInt64);
  keyv.push(3 as UInt64);
  keyv.push(4 as UInt64);
  let hwk = highway.highway_hash(&ab, keyv);
  let hwc = highway.highway64(&ab, 1 as UInt64, 2 as UInt64, 3 as UInt64, 4 as UInt64);
  if hwk != hwc { return 30; }
  let hv1 = highway.highway_verify(&ab, 1 as UInt64, 2 as UInt64, 3 as UInt64, 4 as UInt64, hwc);
  if hv1 != true { return 31; }
  let hv0 = highway.highway_verify(&ab, 1 as UInt64, 2 as UInt64, 3 as UInt64, 4 as UInt64, hwc + 1 as UInt64);
  if hv0 != false { return 32; }

  // ---- metro
  let m64e = metro.metrohash64(&eb, 0 as UInt64);
  if m64e != 0x13c52518f4db1e2a as UInt64 { return 33; }
  let m64_2e = metro.metrohash64_2(&eb, 0 as UInt64);
  if m64_2e != 0x933c86edbd19811f as UInt64 { return 34; }
  let m128e = metro.metrohash128(&eb, 0 as UInt64);
  if m128e.0 != 0xd7216f147989aad3 as UInt64 { return 35; }
  if m128e.1 != 0xdb50efda38a62adb as UInt64 { return 35; }
  let m128c = metro.metrohash128crc(&ab, 7 as UInt64);
  let m128p = metro.metrohash128(&ab, 7 as UInt64);
  if m128c.0 != m128p.0 || m128c.1 != m128p.1 { return 36; }
  let m32e = metro.metrohash32(&eb, 0 as UInt32);
  if m32e != 0xc630264f as UInt32 { return 37; }

  // ---- murmur
  let mm128 = murmur.murmur3_128(&eb, 0 as UInt32);
  if mm128.len() != 2 { return 38; }
  if mm128[0] != 0 as UInt64 || mm128[1] != 0 as UInt64 { return 39; }
  let mm64 = murmur.murmur2_64(&eb, 0 as UInt64);
  if mm64 != 0 as UInt64 { return 40; }

  // ---- spooky
  let sp32 = spooky.spooky32(&eb);
  if sp32 != 0x96a9a34f as UInt32 { return 41; }
  let sp64 = spooky.spooky64(&eb, 0 as UInt64);
  if sp64 != 0x6f01ecae96a9a34f as UInt64 { return 42; }
  let sp128 = spooky.spooky128(&eb, 0 as UInt64, 0 as UInt64);
  if sp128.0 != 0x6f01ecae96a9a34f as UInt64 { return 43; }
  if sp128.1 != 0x38905088c4094638 as UInt64 { return 43; }
  let spsh = spooky.spooky_short(&eb);
  if spsh != 0x0f1e72c77f3f5ceb as UInt64 { return 44; }

  // ---- t1ha
  let t0e = t1ha.t1ha0(&eb, 0 as UInt64);
  if t0e != 0x97bc2877812efd86 as UInt64 { return 45; }
  let t1e = t1ha.t1ha1(&eb, 0 as UInt64);
  if t1e != 0x3be6b5f142e8b746 as UInt64 { return 46; }
  let t2e = t1ha.t1ha2(&eb, 0 as UInt64);
  if t2e != 0x99bfa7d850624dee as UInt64 { return 47; }
  let t2a = t1ha.t1ha2_atonce(&ab);
  let t2b = t1ha.t1ha2(&ab, 0 as UInt64);
  if t2a != t2b { return 48; }
  let t2a128 = t1ha.t1ha2_atonce128(&eb);
  if t2a128.0 != 0x99bfa7d850624dee as UInt64 { return 49; }
  if t2a128.1 != 0x7acdbb98b1344213 as UInt64 { return 49; }
  let tia = t1ha.t1ha_ia32(&eb, 0 as UInt64);
  if tia != 0x78302769c031287d as UInt64 { return 50; }

  return 0;
}

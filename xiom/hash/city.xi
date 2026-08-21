// XIOM -- Hashing: Google CityHash (CityHash64 / CityHash128)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.city

// Faithful port of the reference CityHash64/CityHash128 (google/cityhash v1.1).
// All arithmetic is wrapping UInt64. The builtin `>>` on UInt64 is arithmetic
// (sign-filling), so every logical right shift goes through _u64_shr.

const _K0: UInt64 = 0xc3a5c85c97cb3127;
const _K1: UInt64 = 0xb492b66fbe98f273;
const _K2: UInt64 = 0x9ae16a3b2f90404f;

/// Logical (unsigned) right shift of a UInt64 by k bits.
fn _u64_shr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 { return x; }
  if k >= 64 { var z: UInt64 = 0; return z; }
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

/// city_fetch64: little-endian load of 8 bytes at data[i .. i+8).
fn city_fetch64(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 8 {
    var b: UInt64 = data[i + j] as UInt64;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  return r;
}

/// city_fetch32: little-endian load of 4 bytes as a 32-bit value.
fn city_fetch32(data: &Vec[UInt8], i: Int) -> UInt64 {
  var r: UInt64 = 0;
  var j = 0;
  while j < 4 {
    var b: UInt64 = data[i + j] as UInt64;
    r = r | (b << (8 * j));
    j = j + 1;
  }
  return r & 0xFFFFFFFF;
}

/// city_rotate64: rotate-right by shift bits (mirrors the reference Rotate()).
fn city_rotate64(v: UInt64, shift: Int) -> UInt64 {
  var s = shift % 64;
  if s == 0 { return v; }
  return _u64_shr(v, s) | (v << (64 - s));
}

/// city_shift_mix: val ^ (val >> 47).
fn city_shift_mix(v: UInt64) -> UInt64 {
  return v ^ _u64_shr(v, 47);
}

/// city_bswap64: byte-reverse a 64-bit value.
fn city_bswap64(v: UInt64) -> UInt64 {
  var r: UInt64 = 0;
  var i = 0;
  while i < 8 {
    var byte = _u64_shr(v, i * 8) & 0xFF;
    r = r | (byte << ((7 - i) * 8));
    i = i + 1;
  }
  return r;
}

/// city_hash_len16: two-argument HashLen16 == Hash128to64({u, v}).
fn city_hash_len16(u: UInt64, v: UInt64) -> UInt64 {
  var k_mul: UInt64 = 0x9ddfea08eb382d69;
  var a = (u ^ v) * k_mul;
  a = a ^ _u64_shr(a, 47);
  var b = (v ^ a) * k_mul;
  b = b ^ _u64_shr(b, 47);
  b = b * k_mul;
  return b;
}

/// city_hash_len16_with_seed: three-argument HashLen16(u, v, mul).
fn city_hash_len16_with_seed(u: UInt64, v: UInt64, mul: UInt64) -> UInt64 {
  var a = (u ^ v) * mul;
  a = a ^ _u64_shr(a, 47);
  var b = (v ^ a) * mul;
  b = b ^ _u64_shr(b, 47);
  b = b * mul;
  return b;
}

fn city_hash_len_0to16(data: &Vec[UInt8], start: Int, len: Int) -> UInt64 {
  if len >= 8 {
    var mul = _K2 + ((len * 2) as UInt64);
    var a = city_fetch64(data, start) + _K2;
    var b = city_fetch64(data, start + len - 8);
    var c = city_rotate64(b, 37) * mul + a;
    var d = (city_rotate64(a, 25) + b) * mul;
    return city_hash_len16_with_seed(c, d, mul);
  }
  if len >= 4 {
    var mul = _K2 + ((len * 2) as UInt64);
    var a = city_fetch32(data, start);
    var u = (len as UInt64) + (a << 3);
    return city_hash_len16_with_seed(u, city_fetch32(data, start + len - 4), mul);
  }
  if len > 0 {
    var a0: UInt64 = data[start] as UInt64;
    var b0: UInt64 = data[start + (len >> 1)] as UInt64;
    var c0: UInt64 = data[start + len - 1] as UInt64;
    var y = a0 + (b0 << 8);
    var z = (len as UInt64) + (c0 << 2);
    return city_shift_mix((y * _K2) ^ (z * _K0)) * _K2;
  }
  return _K2;
}

fn city_hash_len_17to32(data: &Vec[UInt8], start: Int, len: Int) -> UInt64 {
  var mul = _K2 + ((len * 2) as UInt64);
  var a = city_fetch64(data, start) * _K1;
  var b = city_fetch64(data, start + 8);
  var c = city_fetch64(data, start + len - 8) * mul;
  var d = city_fetch64(data, start + len - 16) * _K2;
  var u = city_rotate64(a + b, 43) + city_rotate64(c, 30) + d;
  var v = a + city_rotate64(b + _K2, 18) + c;
  return city_hash_len16_with_seed(u, v, mul);
}

fn city_hash_len_33to64(data: &Vec[UInt8], start: Int, len: Int) -> UInt64 {
  var mul = _K2 + ((len * 2) as UInt64);
  var a = city_fetch64(data, start) * _K2;
  var b = city_fetch64(data, start + 8);
  var c = city_fetch64(data, start + len - 24);
  var d = city_fetch64(data, start + len - 32);
  var e = city_fetch64(data, start + 16) * _K2;
  var f = city_fetch64(data, start + 24) * 9;
  var g = city_fetch64(data, start + len - 8);
  var h = city_fetch64(data, start + len - 16) * mul;
  var u = city_rotate64(a + g, 43) + (city_rotate64(b, 30) + c) * 9;
  var v = ((a + g) ^ d) + f + 1;
  var w = city_bswap64((u + v) * mul) + h;
  var x = city_rotate64(e + f, 42) + c;
  var y = (city_bswap64((v + w) * mul) + g) * mul;
  var z = e + f + c;
  a = city_bswap64((x + z) * mul + y) + b;
  b = city_shift_mix((z + a) * mul + d + h) * mul;
  return b + x;
}

/// WeakHashLen32WithSeeds(s, a, b) -> [lo, hi].
fn city_weak_hash_len32_with_seeds(data: &Vec[UInt8], start: Int, a0: UInt64, b0: UInt64) -> Vec[UInt64] {
  var w = city_fetch64(data, start);
  var x = city_fetch64(data, start + 8);
  var y = city_fetch64(data, start + 16);
  var z = city_fetch64(data, start + 24);
  var a = a0 + w;
  var b = city_rotate64(b0 + a + z, 21);
  var c = a;
  a = a + x;
  a = a + y;
  b = b + city_rotate64(a, 44);
  var out = Vec[UInt64].new();
  out.push(a + z);
  out.push(b + c);
  return out;
}

fn city64_long(data: &Vec[UInt8], len0: Int) -> UInt64 {
  var len = len0;
  var x = city_fetch64(data, len - 40);
  var y = city_fetch64(data, len - 16) + city_fetch64(data, len - 56);
  var z = city_hash_len16(city_fetch64(data, len - 48) + (len as UInt64), city_fetch64(data, len - 24));
  var v = city_weak_hash_len32_with_seeds(data, len - 64, (len as UInt64), z);
  var w = city_weak_hash_len32_with_seeds(data, len - 32, y + _K1, x);
  x = x * _K1 + city_fetch64(data, 0);
  len = (len - 1) & ~63;
  var pos = 0;
  while len != 0 {
    x = city_rotate64(x + y + v[0] + city_fetch64(data, pos + 8), 37) * _K1;
    y = city_rotate64(y + v[1] + city_fetch64(data, pos + 48), 42) * _K1;
    x = x ^ w[1];
    y = y + v[0] + city_fetch64(data, pos + 40);
    z = city_rotate64(z + w[0], 33) * _K1;
    v = city_weak_hash_len32_with_seeds(data, pos, v[1] * _K1, x + w[0]);
    w = city_weak_hash_len32_with_seeds(data, pos + 32, z + w[1], y + city_fetch64(data, pos + 16));
    var t = z;
    z = x;
    x = t;
    pos = pos + 64;
    len = len - 64;
  }
  var h1 = city_hash_len16(v[0], w[0]) + city_shift_mix(y) * _K1 + z;
  var h2 = city_hash_len16(v[1], w[1]) + x;
  return city_hash_len16(h1, h2);
}

/// CityHash64 of a byte string.
pub fn city64(data: &Vec[UInt8]) -> UInt64 {
  let len = data.len();
  if len <= 32 {
    if len <= 16 {
      return city_hash_len_0to16(data, 0, len);
    }
    return city_hash_len_17to32(data, 0, len);
  } elif len <= 64 {
    return city_hash_len_33to64(data, 0, len);
  }
  return city64_long(data, len);
}

/// CityHash64WithSeed: HashLen16(CityHash64(s) - k2, seed).
pub fn city64_with_seed(data: &Vec[UInt8], seed: UInt64) -> UInt64 {
  return city_hash_len16(city64(data) - _K2, seed);
}

fn city_murmur(data: &Vec[UInt8], start: Int, l0: Int, seed_lo: UInt64, seed_hi: UInt64) -> Vec[UInt64] {
  var l = l0;
  var a = seed_lo;
  var b = seed_hi;
  var c: UInt64 = 0;
  var d: UInt64 = 0;
  var pos = start;
  if l <= 16 {
    a = city_shift_mix(a * _K1) * _K1;
    c = b * _K1 + city_hash_len_0to16(data, start, l);
    var t = a;
    if l >= 8 {
      t = t + city_fetch64(data, start);
    } else {
      t = t + c;
    }
    d = city_shift_mix(t);
  } else {
    c = city_hash_len16(city_fetch64(data, start + l - 8) + _K1, a);
    d = city_hash_len16(b + (l as UInt64), c + city_fetch64(data, start + l - 16));
    a = a + d;
    while l > 16 {
      a = a ^ (city_shift_mix(city_fetch64(data, pos) * _K1) * _K1);
      a = a * _K1;
      b = b ^ a;
      c = c ^ (city_shift_mix(city_fetch64(data, pos + 8) * _K1) * _K1);
      c = c * _K1;
      d = d ^ c;
      pos = pos + 16;
      l = l - 16;
    }
  }
  a = city_hash_len16(a, c);
  b = city_hash_len16(d, b);
  var out = Vec[UInt64].new();
  out.push(a ^ b);
  out.push(city_hash_len16(b, a));
  return out;
}

fn city128_with_seed(data: &Vec[UInt8], start: Int, l0: Int, seed_lo: UInt64, seed_hi: UInt64) -> Vec[UInt64] {
  var l = l0;
  if l < 128 {
    return city_murmur(data, start, l, seed_lo, seed_hi);
  }
  var x = seed_lo;
  var y = seed_hi;
  var z = (l as UInt64) * _K1;
  var pos = start;
  var v = city_weak_hash_len32_with_seeds(data, start, 0, 0);
  v[0] = city_rotate64(y ^ _K1, 49) * _K1 + city_fetch64(data, start);
  v[1] = city_rotate64(v[0], 42) * _K1 + city_fetch64(data, start + 8);
  var w = city_weak_hash_len32_with_seeds(data, start, 0, 0);
  w[0] = city_rotate64(y + z, 35) * _K1 + x;
  w[1] = city_rotate64(x + city_fetch64(data, start + 88), 53) * _K1;
  while l >= 128 {
    x = city_rotate64(x + y + v[0] + city_fetch64(data, pos + 8), 37) * _K1;
    y = city_rotate64(y + v[1] + city_fetch64(data, pos + 48), 42) * _K1;
    x = x ^ w[1];
    y = y + v[0] + city_fetch64(data, pos + 40);
    z = city_rotate64(z + w[0], 33) * _K1;
    v = city_weak_hash_len32_with_seeds(data, pos, v[1] * _K1, x + w[0]);
    w = city_weak_hash_len32_with_seeds(data, pos + 32, z + w[1], y + city_fetch64(data, pos + 16));
    var t = z;
    z = x;
    x = t;
    pos = pos + 64;
    x = city_rotate64(x + y + v[0] + city_fetch64(data, pos + 8), 37) * _K1;
    y = city_rotate64(y + v[1] + city_fetch64(data, pos + 48), 42) * _K1;
    x = x ^ w[1];
    y = y + v[0] + city_fetch64(data, pos + 40);
    z = city_rotate64(z + w[0], 33) * _K1;
    v = city_weak_hash_len32_with_seeds(data, pos, v[1] * _K1, x + w[0]);
    w = city_weak_hash_len32_with_seeds(data, pos + 32, z + w[1], y + city_fetch64(data, pos + 16));
    t = z;
    z = x;
    x = t;
    pos = pos + 64;
    l = l - 128;
  }
  x = x + city_rotate64(v[0] + z, 49) * _K0;
  y = y * _K0 + city_rotate64(w[1], 37);
  z = z * _K0 + city_rotate64(w[0], 27);
  w[0] = w[0] * 9;
  v[0] = v[0] * _K0;
  var tail_done = 0;
  while tail_done < l {
    tail_done = tail_done + 32;
    y = city_rotate64(x + y, 42) * _K0 + v[1];
    w[0] = w[0] + city_fetch64(data, pos + l - tail_done + 16);
    x = x * _K0 + w[0];
    z = z + w[1] + city_fetch64(data, pos + l - tail_done);
    w[1] = w[1] + v[0];
    v = city_weak_hash_len32_with_seeds(data, pos + l - tail_done, v[0] + z, v[1]);
    v[0] = v[0] * _K0;
  }
  x = city_hash_len16(x, v[0]);
  y = city_hash_len16(y + z, w[0]);
  var lo = city_hash_len16(x + v[1], w[1]) + y;
  var hi = city_hash_len16(x + w[1], y + v[1]);
  var out = Vec[UInt64].new();
  out.push(lo);
  out.push(hi);
  return out;
}

/// CityHash128 of a byte string; returns [low, high].
pub fn city128(data: &Vec[UInt8]) -> Vec[UInt64] {
  let len = data.len();
  var out = Vec[UInt64].new();
  var r = Vec[UInt64].new();
  if len >= 16 {
    var seed_lo = city_fetch64(data, 0);
    var seed_hi = city_fetch64(data, 8) + _K0;
    r = city128_with_seed(data, 16, len - 16, seed_lo, seed_hi);
  } else {
    r = city_murmur(data, 0, len, _K0, _K1);
  }
  out.push(r[0]);
  out.push(r[1]);
  return out;
}

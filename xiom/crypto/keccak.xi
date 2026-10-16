// XIOM - Cryptography: Keccak-256
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.keccak

// Depends on: xiom.crypto.hash, xiom.encoding

// ============================================================================
// Keccak-256 -- the ORIGINAL Keccak submission (pad10*1 with the 0x01 domain
// byte; the Ethereum-family variant). This is NOT FIPS 202 SHA3-256, which
// uses the 0x06 domain byte and produces different digests.
//
// Parameters: rate 1088 bits (136 bytes), capacity 512 bits, 32-byte digest,
// Keccak-f[1600] permutation with 24 rounds.
//
// Known answers (cross-checked 2026-10-16 against pycryptodome 3.24.1,
// Crypto.Hash.keccak digest_bits=256):
//   keccak256("")    = c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
//   keccak256("abc") = 4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45
//
// All 64-bit lanes live in Int locals (two's complement); right shifts that
// must move bit patterns (never sign bits) go through the wave-161 logical
// helpers u64_lshr/u64_rotr in xiom.crypto.hash. Lanes are loaded/stored
// low-byte-first like the BLAKE2b helpers in that module. State, round
// constants and rho offsets are LOCAL Vecs only -- module-level arrays are
// mis-materialized by this toolchain (see compress/gzip.xi).
// ============================================================================

use xiom.crypto.hash;
use xiom.encoding;

const _KECCAK_RATE: Int = 136;
const _KECCAK_ROUNDS: Int = 24;
const _KECCAK_LANES: Int = 25;

/// Keccak-f[1600] round constants (FIPS 202 RC[0..23]), built locally.
fn _keccak_rc_table() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(0x0000000000000001);
  t.push(0x0000000000008082);
  t.push(0x800000000000808A);
  t.push(0x8000000080008000);
  t.push(0x000000000000808B);
  t.push(0x0000000080000001);
  t.push(0x8000000080008081);
  t.push(0x8000000000008009);
  t.push(0x000000000000008A);
  t.push(0x0000000000000088);
  t.push(0x0000000080008009);
  t.push(0x000000008000000A);
  t.push(0x000000008000808B);
  t.push(0x800000000000008B);
  t.push(0x8000000000008089);
  t.push(0x8000000000008003);
  t.push(0x8000000000008002);
  t.push(0x8000000000000080);
  t.push(0x000000000000800A);
  t.push(0x800000008000000A);
  t.push(0x8000000080008081);
  t.push(0x8000000000008080);
  t.push(0x0000000080000001);
  t.push(0x8000000080008008);
  return t;
}

/// Rho rotation offsets, indexed by lane index x + 5*y (FIPS 202 table).
fn _keccak_rho_table() -> Vec[Int] {
  var t = Vec[Int].new();
  t.push(0);
  t.push(1);
  t.push(62);
  t.push(28);
  t.push(27);
  t.push(36);
  t.push(44);
  t.push(6);
  t.push(55);
  t.push(20);
  t.push(3);
  t.push(10);
  t.push(43);
  t.push(25);
  t.push(39);
  t.push(41);
  t.push(45);
  t.push(15);
  t.push(21);
  t.push(8);
  t.push(18);
  t.push(2);
  t.push(61);
  t.push(56);
  t.push(14);
  return t;
}

/// Rotate the 64-bit pattern left by n bits (n outside 0..63 is identity).
fn _rotl64(x: Int, n: Int) -> Int
  ensures: (n <= 0) => (result == x)
  ensures: (n >= 64) => (result == x)
{
  if n <= 0 {
    return x;
  };
  if n >= 64 {
    return x;
  };
  return (x << n) | hash.u64_lshr(x, 64 - n);
}

/// Load 8 bytes little-endian into a 64-bit lane (low byte first, matching
/// the BLAKE2b load pattern; byte i is built up without sign interference).
fn _keccak_load64(data: &Vec[UInt8], offset: Int) -> Int {
  var v: Int = 0;
  var i = 7;
  while i >= 0 {
    v = v * 256 + ((data[offset + i] as Int) & 0xFF);
    i = i - 1;
  }
  return v;
}

/// XOR one 136-byte block into lanes 0..16 and permute.
fn _keccak_absorb_block(a: &mut Vec[Int], data: &Vec[UInt8], off: Int) {
  var i = 0;
  while i < 17 {
    var lane = _keccak_load64(data, off + i * 8);
    a[i] = a[i] ^ lane;
    i = i + 1;
  }
  _keccak_f1600(a);
}

/// Keccak-f[1600]: 24 rounds of theta, rho+pi, chi, iota over the 25-lane
/// state `a` (indexed x + 5*y). Mutates `a` in place.
fn _keccak_f1600(a: &mut Vec[Int]) {
  var rc = _keccak_rc_table();
  var rho = _keccak_rho_table();
  var round = 0;
  while round < _KECCAK_ROUNDS {
    // theta: C[x] = column parity; D[x] = C[x-1] ^ rotl(C[x+1], 1).
    var c = Vec[Int].new();
    var x = 0;
    while x < 5 {
      c.push(a[x] ^ a[x + 5] ^ a[x + 10] ^ a[x + 15] ^ a[x + 20]);
      x = x + 1;
    }
    x = 0;
    while x < 5 {
      var xm = x + 4;
      if xm >= 5 { xm = xm - 5; };
      var xp = x + 1;
      if xp >= 5 { xp = xp - 5; };
      var d = c[xm] ^ _rotl64(c[xp], 1);
      var y = 0;
      while y < 5 {
        var i0 = x + 5 * y;
        a[i0] = a[i0] ^ d;
        y = y + 1;
      }
      x = x + 1;
    }
    // rho + pi: B[y + 5*((2x + 3y) % 5)] = rotl(A[x + 5y], rho[x + 5y]).
    var b = Vec[Int].new();
    var k = 0;
    while k < _KECCAK_LANES {
      b.push(0);
      k = k + 1;
    }
    x = 0;
    while x < 5 {
      var y = 0;
      while y < 5 {
        var idx = x + 5 * y;
        var dst = y + 5 * ((2 * x + 3 * y) % 5);
        b[dst] = _rotl64(a[idx], rho[idx]);
        y = y + 1;
      }
      x = x + 1;
    }
    // chi: A[x + 5y] = B[x + 5y] ^ ((~B[x+1 + 5y]) & B[x+2 + 5y]).
    x = 0;
    while x < 5 {
      var y = 0;
      while y < 5 {
        var xp1 = x + 1;
        if xp1 >= 5 { xp1 = xp1 - 5; };
        var xp2 = x + 2;
        if xp2 >= 5 { xp2 = xp2 - 5; };
        var i0 = x + 5 * y;
        a[i0] = b[i0] ^ ((~b[xp1 + 5 * y]) & b[xp2 + 5 * y]);
        y = y + 1;
      }
      x = x + 1;
    }
    // iota: lane (0,0) ^= RC[round].
    a[0] = a[0] ^ rc[round];
    round = round + 1;
  }
}

/// Keccak-256 digest (32 bytes) of `data`. Original-Keccak padding (0x01),
/// i.e. the Ethereum keccak256 -- not FIPS 202 SHA3-256. O(n).
pub fn keccak256(data: &Vec[UInt8]) -> Vec[UInt8]
  ensures: result.len() == 32
{
  var a = Vec[Int].new();
  var k = 0;
  while k < _KECCAK_LANES {
    a.push(0);
    k = k + 1;
  }
  var total = data.len();
  var pos = 0;
  while pos + _KECCAK_RATE <= total {
    _keccak_absorb_block(&mut a, data, pos);
    pos = pos + _KECCAK_RATE;
  }
  // Final block: message tail + 0x01 pad, zeros, and 0x80 folded into the
  // last rate byte (pad10*1).
  var last = Vec[UInt8].new();
  var r = 0;
  while r < _KECCAK_RATE {
    last.push(0);
    r = r + 1;
  }
  var i = pos;
  while i < total {
    last[i - pos] = data[i];
    i = i + 1;
  }
  last[total - pos] = 0x01;
  last[_KECCAK_RATE - 1] = last[_KECCAK_RATE - 1] | 0x80;
  var lane_i = 0;
  while lane_i < 17 {
    var lane = _keccak_load64(&last, lane_i * 8);
    a[lane_i] = a[lane_i] ^ lane;
    lane_i = lane_i + 1;
  }
  _keccak_f1600(&mut a);
  // Squeeze: first 4 lanes little-endian = 32 bytes.
  var out = Vec[UInt8].new();
  var n = 0;
  while n < 4 {
    var lane = a[n];
    var j = 0;
    while j < 8 {
      out.push(((lane >> (8 * j)) & 0xFF) as UInt8);
      j = j + 1;
    }
    n = n + 1;
  }
  return out;
}

/// Keccak-256 digest as 64 lowercase hex characters. O(n).
pub fn keccak256_hex(data: &Vec[UInt8]) -> Str
  ensures: result.len() == 64
{
  var digest = keccak256(data);
  return encoding.hex_encode(&digest);
}

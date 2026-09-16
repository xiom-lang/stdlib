// XIOM -- MT19937 (Mersenne Twister) 32-bit PRNG
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.
//
// Faithful implementation of the classic 32-bit Mersenne Twister by
// Makoto Matsumoto and Takuji Nishimura (1998). All internal arithmetic
// is done on masked i64 values to emulate unsigned 32-bit wrapping.

module xiom.rand.mt19937

const _MT_N: Int = 624;
const _MT_M: Int = 397;
const _MT_MATRIX_A: Int = 0x9908b0df;
const _MT_UPPER_MASK: Int = 0x80000000;
const _MT_LOWER_MASK: Int = 0x7fffffff;
const _MT_DEFAULT_SEED: Int = 5489;

/// Emulate a u32 value in the signed-i64 arithmetic layer.
fn _mt_u32(x: Int) -> Int {
  return x & 0xFFFFFFFF;
}

/// Build the 624-word MT19937 state array from a 32-bit seed.
/// Seeding: state[0] = seed; state[i] = 1812433253 * (state[i-1] ^ (state[i-1] >> 30)) + i.
fn _mt_seed_state(seed: UInt32) -> Vec[UInt32] {
  var st = Vec[UInt32].new();
  var s: Int = _mt_u32(seed as Int);
  st.push(s as UInt32);
  var i: Int = 1;
  while i < _MT_N {
    let prev: Int = _mt_u32(st[i - 1] as Int);
    let v: Int = 1812433253 * (prev ^ (prev >> 30)) + i;
    st.push(_mt_u32(v) as UInt32);
    i = i + 1;
  }
  return st;
}

pub type Mt19937 = {
  state: Vec[UInt32];
  index: Int;
}

/// Create an MT19937 generator with the classic default seed 5489.
pub fn mt19937_new() -> Mt19937 {
  return Mt19937{ state: _mt_seed_state(_MT_DEFAULT_SEED as UInt32); index: _MT_N; };
}

/// Create an MT19937 generator from an explicit 32-bit seed.
pub fn mt19937_from_seed(seed: UInt32) -> Mt19937 {
  return Mt19937{ state: _mt_seed_state(seed); index: _MT_N; };
}

/// Re-seed an existing generator in place using the classic seeding algorithm.
pub fn mt19937_reseed(r: &mut Mt19937, seed: UInt32) {
  r.state[0] = seed;
  var i: Int = 1;
  while i < _MT_N {
    let prev: Int = _mt_u32(r.state[i - 1] as Int);
    let v: Int = 1812433253 * (prev ^ (prev >> 30)) + i;
    r.state[i] = _mt_u32(v) as UInt32;
    i = i + 1;
  };
  r.index = _MT_N;
}

/// Generate the next 624-word block (the standard "twist").
/// y = (state[i] & UPPER_MASK) | (state[(i+1) % 624] & LOWER_MASK);
/// state[i] = state[(i+397) % 624] ^ (y >> 1) ^ (y & 1 ? MATRIX_A : 0).
fn _mt_twist(r: &mut Mt19937) {
  var i: Int = 0;
  while i < _MT_N {
    let upper: Int = _mt_u32(r.state[i] as Int) & _MT_UPPER_MASK;
    let lower: Int = _mt_u32(r.state[(i + 1) % _MT_N] as Int) & _MT_LOWER_MASK;
    let y: Int = upper | lower;
    let xor_val: Int = _mt_u32(r.state[(i + _MT_M) % _MT_N] as Int) ^ (y >> 1);
    if (y & 1) == 0 {
      r.state[i] = _mt_u32(xor_val) as UInt32;
    } else {
      r.state[i] = _mt_u32(xor_val ^ _MT_MATRIX_A) as UInt32;
    };
    i = i + 1;
  };
  r.index = 0;
}

/// Return the next 32-bit output word, tempering with:
///   y ^= y >> 11; y ^= (y << 7) & 0x9d2c5680; y ^= (y << 15) & 0xefc60000; y ^= y >> 18.
pub fn mt19937_next_u32(r: &mut Mt19937) -> UInt32 {
  if r.index >= _MT_N {
    _mt_twist(r);
  };
  var y: Int = _mt_u32(r.state[r.index] as Int);
  r.index = r.index + 1;
  y = y ^ (y >> 11);
  y = y ^ ((y << 7) & 0x9d2c5680);
  y = y ^ ((y << 15) & 0xefc60000);
  y = y ^ (y >> 18);
  return _mt_u32(y) as UInt32;
}

/// Return the next value as a signed i64 in [0, 2^32).
pub fn mt19937_next_int(r: &mut Mt19937) -> Int {
  return _mt_u32(mt19937_next_u32(r) as Int);
}

/// Return the next value as a Float64 in [0, 1).
pub fn mt19937_next_float(r: &mut Mt19937) -> Float64 {
  let v: Int = _mt_u32(mt19937_next_u32(r) as Int);
  return (v as Float64) / 4294967296.0;
}

/// Return the next value in [0, hi). Requires hi > 0.
pub fn mt19937_next_bounded(r: &mut Mt19937, hi: Int) -> Int {
  if hi <= 0 {
    return 0;
  };
  let v: Int = _mt_u32(mt19937_next_u32(r) as Int);
  return v % hi;
}

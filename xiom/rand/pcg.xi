// XIOM -- PCG (Permuted Congruential Generator) XSH-RR 64/32 PRNG
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Faithful port of the pcg32 variant (XSH-RR): a 64-bit LCG state with the
// standard output transformation xorshift-high and variable rotate. Uses
// UInt64 for the state/stream and returns 32-bit words.

module xiom.rand.pcg

const _PCG_MULT: Int = 6364136223846793005;

/// PCG64 RNG state.
pub type Pcg = {
  state: UInt64;
  inc: UInt64;
}

/// Logical (zero-fill) right shift of a UInt64.
/// The compiler lowers `>>` on UInt64 to a signed ashr; masking removes the
/// sign fill so the result matches a true unsigned shift.
fn _u64_lshr(x: UInt64, k: Int) -> UInt64 {
  if k <= 0 {
    return x;
  };
  if k >= 64 {
    var z: UInt64 = 0;
    return z;
  };
  var mask: UInt64 = ((1 as UInt64) << (64 - k)) - 1;
  return (x >> k) & mask;
}

/// One LCG step: state = state * 6364136223846793005 + inc (wrapping).
fn _pcg_advance(r: &mut Pcg) {
  r.state = r.state * (_PCG_MULT as UInt64) + r.inc;
}

/// Create a PCG generator with the reference default state/stream constants.
pub fn pcg_new() -> Pcg {
  var st: UInt64 = 0x853c49e6748fea9b;
  var inc: UInt64 = 0xda3e39cb94b95bdb;
  return Pcg{ state: st; inc: inc; };
}

/// Create a PCG generator from a 64-bit seed.
/// Standard init: state = 0, inc = (seed << 1) | 1, then advance once.
pub fn pcg_from_seed(seed: UInt64) -> Pcg {
  var inc: UInt64 = (seed << 1) | (1 as UInt64);
  var st: UInt64 = 0;
  var r = Pcg{ state: st; inc: inc; };
  _pcg_advance(&mut r);
  return r;
}

/// Return the next 32-bit output word.
/// xorshifted = ((oldstate >> 18) ^ oldstate) >> 27;
/// rot = oldstate >> 59;
/// output = (xorshifted >> rot) | (xorshifted << ((-rot) & 31)).
pub fn pcg_next_u32(r: &mut Pcg) -> UInt32 {
  let oldstate: UInt64 = r.state;
  _pcg_advance(r);
  let xs: UInt64 = _u64_lshr(_u64_lshr(oldstate, 18) ^ oldstate, 27);
  let xs32: UInt64 = xs & 0xFFFFFFFF;
  let rot: Int = ((oldstate >> 59) as Int) & 31;
  let right: UInt64 = _u64_lshr(xs32, rot);
  let left: UInt64 = xs32 << ((0 - rot) & 31);
  return ((right | left) & 0xFFFFFFFF) as UInt32;
}

/// Return the next value as a signed i64 in [0, 2^32).
pub fn pcg_next_int(r: &mut Pcg) -> Int {
  return (pcg_next_u32(r) as Int) & 0xFFFFFFFF;
}

/// Return the next value as a Float64 in [0, 1).
pub fn pcg_next_float(r: &mut Pcg) -> Float64 {
  let v: Int = (pcg_next_u32(r) as Int) & 0xFFFFFFFF;
  return (v as Float64) / 4294967296.0;
}

/// Return the next value in [0, hi). Requires hi > 0.
pub fn pcg_next_bounded(r: &mut Pcg, hi: Int) -> Int {
  if hi <= 0 {
    return 0;
  };
  let v: Int = (pcg_next_u32(r) as Int) & 0xFFFFFFFF;
  return v % hi;
}

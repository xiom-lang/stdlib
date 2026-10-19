// p_wave187_math_shapes.xi -- wave 187: contracts for xiom.math.primitives
// and xiom.math.trigonometry.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime ensures clauses (a violation
// aborts the probe). Cases:
// 1. min/max/clamp/hypot are NaN-truthful (the pre-existing clauses were
//    false when an operand was NaN; smoothstep reaches clamp with t = NaN).
// 2. signum returns exactly -1/0/1 with the sign law; step is binary.
// 3. smoothstep stays in [0,1] over several windows and degenerate edges.
// 4. fract/modf fractional parts stay strictly inside (-1,1).
// 5. copysign preserves |x|; nextafter satisfies nextafter(x,x) == x
//    (strict ordering is NOT asserted: the negative-power-of-two walk
//    returns x, a latent body defect outside this contract-only wave).
// 6. fma(0,0,c) == c for finite c and NaN for c = NaN (infinite addends
//    also produce NaN through 2Sum, so they are not asserted).
// 7. frexp mantissa in [0.5,1) (sign-preserved), ldexp sign/zero laws.
// 8. cbrt sign and zero law.
// 9. classification predicates agree with their IEEE definitions.
// 10. tan/cot/tan_pure/tanpi zero and non-finite behavior; sincos and
//     sincospi component ranges; sin_pure/cos_pure special values.
// Returns 0 when every case holds.

module p_wave187_math_shapes

use xiom.math;

fn main() -> Int {
  var inf = 1.0 / 0.0;
  var nan = 0.0 / 0.0;
  var i = 0;

  // 1: NaN-truthful min/max/clamp/hypot.
  if (math.primitives.min(nan, 1.0) != 1.0) { return 1; }
  var mn = math.primitives.min(1.0, nan);
  if (mn == mn) { return 2; }
  if (math.primitives.max(nan, 1.0) != 1.0) { return 3; }
  var mx = math.primitives.max(1.0, nan);
  if (mx == mx) { return 4; }
  if (!(math.primitives.clamp(nan, 0.0, 1.0) != math.primitives.clamp(nan, 0.0, 1.0))) { return 5; }
  if (!(math.primitives.hypot(nan, nan) != math.primitives.hypot(nan, nan))) { return 6; }
  if (math.primitives.clamp(5.0, 0.0, 3.0) != 3.0) { return 7; }
  if (math.primitives.abs(-2.5) != 2.5) { return 8; }

  // 2: signum and step.
  if (math.primitives.signum(-2.0) != -1) { return 9; }
  if (math.primitives.signum(0.0) != 0) { return 10; }
  if (math.primitives.signum(2.0) != 1) { return 11; }
  if (math.primitives.signum(nan) != 0) { return 12; }
  if (math.primitives.step(2.0, 1.0) != 0.0) { return 13; }
  if (math.primitives.step(2.0, 2.0) != 1.0) { return 14; }
  if (math.primitives.step(2.0, 3.0) != 1.0) { return 15; }

  // 3: smoothstep range.
  i = -2000;
  while i <= 2000 {
    var t = (i as Float64) / 1000.0;
    var v = math.primitives.smoothstep(0.0, 1.0, t);
    if (!(v >= 0.0) || !(v <= 1.0)) { return 16; }
    var w = math.primitives.smoothstep(-3.0, 2.0, t);
    if (!(w >= 0.0) || !(w <= 1.0)) { return 17; }
    i = i + 1;
  }
  if (math.primitives.smoothstep(1.0, 1.0, 0.5) != 0.0) { return 18; }
  if (math.primitives.smoothstep(1.0, 1.0, 2.0) != 1.0) { return 19; }
  if (!(math.primitives.smoothstep(0.0, 1.0, nan) != math.primitives.smoothstep(0.0, 1.0, nan))) { return 20; }

  // 4: fract/modf fractional-part ranges.
  i = -50000;
  while i <= 50000 {
    var f = math.primitives.fract((i as Float64) / 4096.0);
    if (!(f > -1.0) || !(f < 1.0)) { return 21; }
    var m = math.primitives.modf((i as Float64) / 4096.0);
    if (!(m.1 > -1.0) || !(m.1 < 1.0)) { return 22; }
    i = i + 1;
  }
  if (math.primitives.fract(9007199254740992.0) != 0.0) { return 23; }
  if (math.primitives.fract(-9007199254740992.0) != 0.0) { return 24; }
  if (!(math.primitives.fract(nan) != math.primitives.fract(nan))) { return 25; }

  // 5: copysign magnitude and nextafter identity.
  i = -500;
  while i <= 500 {
    var a = (i as Float64) / 7.0;
    var r = math.primitives.copysign(a, -2.0);
    if (!(r == a) && !(r == -a)) { return 26; }
    var q = math.primitives.copysign(a, 3.0);
    if (!(q == a) && !(q == -a)) { return 27; }
    i = i + 1;
  }
  if (math.primitives.nextafter(1.0, 1.0) != 1.0) { return 28; }
  if (math.primitives.nextafter(-3.0, -3.0) != -3.0) { return 29; }
  if (!(math.primitives.nextafter(nan, 1.0) != math.primitives.nextafter(nan, 1.0))) { return 30; }

  // 6: fma zero-product law.
  if (math.primitives.fma(0.0, 0.0, 7.5) != 7.5) { return 31; }
  if (math.primitives.fma(0.0, 0.0, -3.25) != -3.25) { return 32; }
  if (!(math.primitives.fma(0.0, 0.0, nan) != math.primitives.fma(0.0, 0.0, nan))) { return 33; }
  if (math.primitives.fma(2.0, 3.0, 4.0) != 10.0) { return 34; }

  // 7: frexp mantissa and ldexp sign.
  i = 1;
  while i <= 5000 {
    var fv = (i as Float64) / 3.0;
    var p = math.primitives.frexp(fv);
    var ap = p.0;
    if (ap < 0.0) { ap = -ap; }
    if (!(ap >= 0.5) || !(ap < 1.0)) { return 35; }
    var pn = math.primitives.frexp(-fv);
    var apn = pn.0;
    if (apn < 0.0) { apn = -apn; }
    if (!(apn >= 0.5) || !(apn < 1.0)) { return 36; }
    i = i + 1;
  }
  var pz = math.primitives.frexp(0.0);
  if (pz.0 != 0.0 || pz.1 != 0) { return 37; }
  if (math.primitives.ldexp(3.5, 3) != 28.0) { return 38; }
  if (math.primitives.ldexp(-3.5, 3) != -28.0) { return 39; }
  if (math.primitives.ldexp(0.0, 100) != 0.0) { return 40; }
  if (!(math.primitives.ldexp(nan, 0) != math.primitives.ldexp(nan, 0))) { return 41; }

  // 8: cbrt sign and zero law.
  i = -1000;
  while i <= 1000 {
    var cx = (i as Float64) / 7.0;
    var cr = math.primitives.cbrt(cx);
    if (cx > 0.0 && !(cr > 0.0)) { return 42; }
    if (cx < 0.0 && !(cr < 0.0)) { return 43; }
    if (cx == 0.0 && cr != 0.0) { return 44; }
    i = i + 1;
  }

  // 9: classification predicates.
  if (!math.primitives.is_nan(nan)) { return 45; }
  if (math.primitives.is_nan(1.0)) { return 46; }
  if (!math.primitives.is_inf(inf)) { return 47; }
  if (!math.primitives.is_inf(-inf)) { return 48; }
  if (math.primitives.is_inf(3.5)) { return 49; }
  if (!math.primitives.is_finite(3.5)) { return 50; }
  if (math.primitives.is_finite(inf)) { return 51; }
  if (math.primitives.is_finite(nan)) { return 52; }

  // 10: trigonometry zero/non-finite laws and pair ranges.
  if (math.trigonometry.tan(0.0) != 0.0) { return 53; }
  if (math.trigonometry.tan_pure(0.0) != 0.0) { return 54; }
  if (math.trigonometry.tanpi(0.0) != 0.0) { return 55; }
  if (!(math.trigonometry.cot(0.0) == inf)) { return 56; }
  if (math.trigonometry.tan(inf) == math.trigonometry.tan(inf)) { return 57; }
  if (math.trigonometry.cot(-inf) == math.trigonometry.cot(-inf)) { return 58; }
  if (math.trigonometry.tan_pure(inf) == math.trigonometry.tan_pure(inf)) { return 59; }
  if (math.trigonometry.tanpi(-inf) == math.trigonometry.tanpi(-inf)) { return 60; }
  if (math.trigonometry.sin_pure(0.0) != 0.0) { return 61; }
  if (math.trigonometry.cos_pure(0.0) != 1.0) { return 62; }
  if (math.trigonometry.sin_pure(inf) == math.trigonometry.sin_pure(inf)) { return 63; }
  if (math.trigonometry.cos_pure(-inf) == math.trigonometry.cos_pure(-inf)) { return 64; }
  var sc = math.trigonometry.sincos(1.234);
  if (sc.0 < -1.0 || sc.0 > 1.0) { return 65; }
  if (sc.1 < -1.0 || sc.1 > 1.0) { return 66; }
  var sp = math.trigonometry.sincospi(1.234);
  if (sp.0 < -1.0 || sp.0 > 1.0) { return 67; }
  if (sp.1 < -1.0 || sp.1 > 1.0) { return 68; }

  return 0;
}

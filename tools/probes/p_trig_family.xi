// p_trig_family.xi -- wave 37 verification: range clauses for the trig /
// hyperbolic family plus the non-finite guards in trigonometry.xi.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime ensures clauses (a violation
// aborts the probe). Cases:
// 1. sin/cos range and NaN propagation (math.sin(inf) == NaN).
// 2. asin/acos/atan/atan2 bounds and out-of-domain NaN.
// 3. hyperbolic ranges: cosh >= 0, tanh saturation, sech >= 0, coth outside
//    (-1, 1), acosh >= 0 with NaN below the domain.
// 4. sec/csc magnitude >= 1, including the 1/0 -> +inf poles.
// 5. trigonometry sin/cos/csc/sec clauses and sinpi/cospi values.
// 6. the recon-found hang fix: _norm and sinpi/cospi/tanpi return NaN for
//    +/-inf instead of spinning in the reduction loops.
// Returns 0 when every case holds.

module p_trig_family

use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000000001;
}

fn is_nan(x: Float64) -> Bool {
  return x != x;
}

fn main() -> Int {
  var inf = 1.0 / 0.0;
  var nan = 0.0 / 0.0;

  // 1: sin/cos range + NaN.
  if math.trig.sin(1.234) < -1.0 || math.trig.sin(1.234) > 1.0 { return 1; }
  if !is_nan(math.trig.sin(inf)) { return 2; }
  if math.trig.cos(1.234) < -1.0 || math.trig.cos(1.234) > 1.0 { return 3; }
  if !near(math.trig.sin(0.0), 0.0) { return 4; }
  if !near(math.trig.cos(0.0), 1.0) { return 5; }
  if !is_nan(math.trig.sin(nan)) { return 6; }

  // 2: inverse bounds and domain errors.
  if math.trig.asin(1.0) > 1.5708 { return 7; }
  if !is_nan(math.trig.asin(2.0)) { return 8; }
  if math.trig.acos(1.0) > 3.1416 { return 9; }
  if !is_nan(math.trig.acos(-2.0)) { return 10; }
  if math.trig.atan(inf) > 1.5708 { return 11; }
  if math.trig.atan2(1.0, -1.0) > 3.1416 { return 12; }
  if !is_nan(math.trig.atan2(0.0, 0.0)) { return 13; }

  // 3: hyperbolic ranges.
  if math.hyperbolic.cosh(0.0) < 0.0 { return 14; }
  if math.hyperbolic.cosh(1.0) < 0.0 { return 15; }
  if math.trig.cosh(0.0) < 0.0 { return 16; }
  if math.hyperbolic.tanh(100.0) > 1.0 { return 17; }
  if math.hyperbolic.tanh(-100.0) < -1.0 { return 18; }
  if math.trig.tanh(0.5) < -1.0 || math.trig.tanh(0.5) > 1.0 { return 19; }
  if math.hyperbolic.sech(0.0) < 0.0 { return 20; }
  if math.hyperbolic.coth(0.0) < 1.0 { return 21; }
  if math.hyperbolic.coth(1.0) < 1.0 { return 22; }
  if math.hyperbolic.coth(-1.0) > -1.0 { return 23; }
  if !is_nan(math.hyperbolic.acosh(0.5)) { return 24; }
  if math.hyperbolic.acosh(1.0) < 0.0 { return 25; }
  if math.trig.acosh(2.0) < 0.0 { return 26; }
  if !is_nan(math.hyperbolic.tanh(nan)) { return 27; }

  // 4: sec/csc magnitudes.
  if math.trig.sec(1.0) < 1.0 { return 28; }
  if math.trig.sec(3.0) > -1.0 { return 29; }
  if math.trig.csc(0.0) < 1.0 { return 30; }
  if math.trig.csc(-1.0) > -1.0 { return 31; }
  if math.trig.sin_deg(90.0) < -1.0 || math.trig.sin_deg(90.0) > 1.0 { return 32; }
  if math.trig.cos_deg(180.0) > 1.0 || math.trig.cos_deg(180.0) < -1.0 { return 33; }
  if math.trig.asinh(0.0) < 0.0 { return 34; }
  if math.trig.asinh(-2.0) > 0.0 { return 35; }

  // 5: trigonometry module clauses + sinpi/cospi values.
  if math.trigonometry.csc(0.0) < 1.0 { return 36; }
  if math.trigonometry.sec(0.0) < 1.0 { return 37; }
  if !near(math.trigonometry.sinpi(0.5), 1.0) { return 38; }
  if !near(math.trigonometry.cospi(0.0), 1.0) { return 39; }
  if math.trigonometry.sin(0.0) < -1.0 || math.trigonometry.sin(0.0) > 1.0 { return 40; }
  if math.trigonometry.cos(0.0) < -1.0 || math.trigonometry.cos(0.0) > 1.0 { return 41; }

  // 6: non-finite guard fix (hang class).
  if !is_nan(math.trigonometry.sinpi(inf)) { return 42; }
  if !is_nan(math.trigonometry.cospi(-inf)) { return 43; }
  if !is_nan(math.trigonometry.tanpi(inf)) { return 44; }
  if !is_nan(math.trigonometry.sin_pure(inf)) { return 45; }
  if !is_nan(math.trigonometry.cos_pure(-inf)) { return 46; }

  return 0;
}

// p_wave38_shapes.xi -- wave 38 verification: rounding + angular clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (a violation aborts).
// Cases: rounding identities (floor/ceil/round ties-away/trunc/fract, pure
// variants, aliases, modf), round_nearest ties-to-even + saturation, angular
// conversions, normalization boundaries (-pi maps to pi, 3pi maps to pi,
// -180 maps to 180), infinities passing through, NaN propagation.
// Returns 0 when every case holds.

module p_wave38_shapes

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

  // rounding, libm-backed.
  if !near(math.rounding.floor(2.7), 2.0) { return 1; }
  if !near(math.rounding.ceil(2.1), 3.0) { return 2; }
  if !near(math.rounding.round(2.5), 3.0) { return 3; }
  if !near(math.rounding.round(-2.5), -3.0) { return 4; }
  if !near(math.rounding.trunc(-2.7), -2.0) { return 5; }
  if !near(math.rounding.fract(-2.5), -0.5) { return 6; }
  if math.rounding.floor(inf) != inf { return 7; }
  if !is_nan(math.rounding.ceil(nan)) { return 8; }

  // rounding, pure variants.
  if !near(math.rounding.floor_pure(2.7), 2.0) { return 9; }
  if !near(math.rounding.ceil_pure(2.1), 3.0) { return 10; }
  if !near(math.rounding.round_pure(2.5), 3.0) { return 11; }
  if !near(math.rounding.trunc_pure(-2.7), -2.0) { return 12; }
  if !near(math.rounding.fract_pure(2.5), 0.5) { return 13; }

  // aliases and modf.
  if !near(math.rounding.integer_part(-2.7), -2.0) { return 14; }
  if !near(math.rounding.frac_part(2.5), 0.5) { return 15; }
  var mf = math.rounding.modf(-2.5);
  if !near(mf.0, -0.5) { return 16; }
  if !near(mf.1, -2.0) { return 17; }

  // round_nearest: ties to even + saturation.
  if math.rounding.round_nearest(2.5) != 2 { return 18; }
  if math.rounding.round_nearest(3.5) != 4 { return 19; }
  if math.rounding.round_nearest(-2.5) != -2 { return 20; }
  if math.rounding.round_nearest(inf) != 9223372036854775807 { return 21; }

  // angular conversions.
  if !near(math.angular.to_radians(180.0), 3.141592653589793) { return 22; }
  if !near(math.angular.to_degrees(3.141592653589793), 180.0) { return 23; }
  if !near(math.angular.to_gradians(90.0), 100.0) { return 24; }
  if !near(math.angular.from_gradians(100.0), 90.0) { return 25; }
  if !near(math.angular.to_mils(360.0), 6400.0) { return 26; }
  if !near(math.angular.from_mils(6400.0), 360.0) { return 27; }
  if !near(math.angular.to_arcmin(1.0), 60.0) { return 28; }
  if !near(math.angular.from_arcmin(60.0), 1.0) { return 29; }
  if !near(math.angular.to_arcsec(1.0), 3600.0) { return 30; }
  if !near(math.angular.from_arcsec(3600.0), 1.0) { return 31; }
  if math.angular.to_radians(inf) != inf { return 32; }
  if !is_nan(math.angular.to_degrees(nan)) { return 33; }

  // normalization, diff, lerp.
  if !near(math.angular.normalize_angle(3.141592653589793 * 3.0), 3.141592653589793) { return 34; }
  if math.angular.normalize_angle(inf) != inf { return 35; }
  if !near(math.angular.normalize_angle_deg(-180.0), 180.0) { return 36; }
  if !near(math.angular.angle_diff(3.141592653589793 / 2.0, 0.0), 3.141592653589793 / 2.0) { return 37; }
  if !near(math.angular.angle_lerp(0.0, 3.141592653589793, 0.5), 3.141592653589793 / 2.0) { return 38; }

  return 0;
}

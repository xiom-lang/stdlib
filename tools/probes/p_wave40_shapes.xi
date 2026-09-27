// p_wave40_shapes.xi -- wave 40 verification: xiom.complex field clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (field equalities are
// NaN-tolerant; complex_div stays clause-free). Cases: construction, polar,
// arithmetic identities, conjugate/scale, abs/arg, epsilon predicates,
// exp/log/pow/sqrt, sin/cos/tan, to_string, NaN input tolerance.
// Returns 0 when every case holds.

module p_wave40_shapes

use xiom.complex;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn is_nan(x: Float64) -> Bool {
  return x != x;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;
  var z = xiom.complex.complex_new(3.0, 4.0);
  if !near(z.re, 3.0, 1e-9) { return 1; }
  if !near(z.im, 4.0, 1e-9) { return 2; }

  var w = xiom.complex.complex_new(1.0, -2.0);
  var s = xiom.complex.complex_add(z, w);
  if !near(s.re, 4.0, 1e-9) { return 3; }
  if !near(s.im, 2.0, 1e-9) { return 4; }
  var d = xiom.complex.complex_sub(z, w);
  if !near(d.re, 2.0, 1e-9) { return 5; }
  if !near(d.im, 6.0, 1e-9) { return 6; }

  // (3+4i)(1-2i) = 11 - 2i
  var m = xiom.complex.complex_mul(z, w);
  if !near(m.re, 11.0, 1e-9) { return 7; }
  if !near(m.im, -2.0, 1e-9) { return 8; }
  var c = xiom.complex.complex_conj(z);
  if !near(c.re, 3.0, 1e-9) { return 9; }
  if !near(c.im, -4.0, 1e-9) { return 10; }
  var sc = xiom.complex.complex_scale(z, 2.0);
  if !near(sc.re, 6.0, 1e-9) { return 11; }
  if !near(sc.im, 8.0, 1e-9) { return 12; }

  if !near(xiom.complex.complex_abs(z), 5.0, 1e-9) { return 13; }
  var unit_i = xiom.complex.complex_new(0.0, 1.0);
  if !near(xiom.complex.complex_arg(unit_i), 1.5707963267948966, 1e-9) { return 14; }

  if !xiom.complex.complex_equals(z, z, 1e-9) { return 15; }
  if xiom.complex.complex_equals(z, w, 1e-9) { return 16; }
  if xiom.complex.complex_equals(z, z, -1.0) { return 17; }
  if !xiom.complex.complex_is_zero(xiom.complex.complex_new(0.0, 0.0), 1e-9) { return 18; }
  if xiom.complex.complex_is_zero(z, 1e-9) { return 19; }
  if xiom.complex.complex_is_zero(z, 0.0) { return 20; }

  var p = xiom.complex.complex_from_polar(2.0, 0.0);
  if !near(p.re, 2.0, 1e-9) { return 21; }
  if !near(p.im, 0.0, 1e-9) { return 22; }

  var e = xiom.complex.complex_exp(xiom.complex.complex_new(0.0, 0.0));
  if !near(e.re, 1.0, 1e-9) { return 23; }
  if !near(e.im, 0.0, 1e-9) { return 24; }
  var l = xiom.complex.complex_log(unit_i);
  if !near(l.re, 0.0, 1e-9) { return 25; }
  if !near(l.im, 1.5707963267948966, 1e-9) { return 26; }
  var one = xiom.complex.complex_new(1.0, 0.0);
  var two = xiom.complex.complex_new(2.0, 0.0);
  var pw = xiom.complex.complex_pow(one, two);
  if !near(pw.re, 1.0, 1e-9) { return 27; }
  if !near(pw.im, 0.0, 1e-9) { return 28; }

  var q = xiom.complex.complex_sqrt(xiom.complex.complex_new(4.0, 0.0));
  if !near(q.re, 2.0, 1e-9) { return 29; }
  if !near(q.im, 0.0, 1e-9) { return 30; }
  var q2 = xiom.complex.complex_sqrt(xiom.complex.complex_new(0.0, 4.0));
  if !near(q2.re, 1.4142135623730951, 1e-9) { return 31; }
  if !near(q2.im, 1.4142135623730951, 1e-9) { return 32; }

  var si = xiom.complex.complex_sin(xiom.complex.complex_new(0.0, 0.0));
  if !near(si.re, 0.0, 1e-9) { return 33; }
  if !near(si.im, 0.0, 1e-9) { return 34; }
  var co = xiom.complex.complex_cos(xiom.complex.complex_new(0.0, 0.0));
  if !near(co.re, 1.0, 1e-9) { return 35; }
  if !near(co.im, 0.0, 1e-9) { return 36; }
  var ta = xiom.complex.complex_tan(xiom.complex.complex_new(0.0, 0.0));
  if !near(ta.re, 0.0, 1e-9) { return 37; }
  if !near(ta.im, 0.0, 1e-9) { return 38; }
  if xiom.complex.complex_to_string(z) == "" { return 39; }

  // NaN tolerance of the field clauses.
  var zn = xiom.complex.complex_new(nan, nan);
  var sn = xiom.complex.complex_add(zn, z);
  if !is_nan(sn.re) { return 40; }
  if !is_nan(sn.im) { return 41; }
  var cn = xiom.complex.complex_conj(zn);
  if !is_nan(cn.re) { return 42; }
  var mn = xiom.complex.complex_mul(zn, z);
  if !is_nan(mn.re) { return 43; }

  return 0;
}

// p_wave165_shapes.xi -- wave 165 lock: the math/fixed-point wishlist rows.
// New surfaces (all verified red-before via the compile probe below: the
// modules did not exist pre-wave):
//   row  9 -- xiom.math.int saturating add/sub/mul (clamp at INT_MIN/INT_MAX)
//   row 10 -- xiom.math.int div_round (half away from zero) + div_ceil
//   row 11 -- xiom.math.fixed mul(a,b,scale) + guarded sum_mul/sum_sq
//   row 12 -- xiom.math.int Newton isqrt (standalone) + fixed sin/cos with
//             2*pi range reduction
//   row 27 -- fixed log2 + integer stats (int_mean, int_slope)
//   row 16 -- fixed exp / ln / pow_int
//   row  8 -- fixed mse matching the float stats mean-of-squares semantics
//   row 14 -- interp_linear over an ordered (tick, value) table
//   row 17 -- exact-sum softmax (floor + residue-to-max; sum == scale)
//   row  4 -- stable argmax (first-wins) + documented NaN policy sibling
// Rows (0 = all hold):
//  1 -- saturating add/sub/mul incl. MIN/MAX edges and MIN * -1
//  2 -- div_round (half away from zero) + div_ceil edges incl. MIN / -1
//  3 -- mul scale-once rounding + guard, sum_mul dot, sum_sq norm
//  4 -- isqrt: 0/1/2/3/4/.../1000^2/3037000499^2 boundaries
//  5 -- sin/cos on the unit circle with range reduction and negatives
//  6 -- log2 anchors + int_mean + int_slope exactness
//  7 -- exp/ln anchors with tolerances + pow_int signs and negative e
//  8 -- mse semantics (scaled mean of squared errors) + guards
//  9 -- interp_linear: interior, exact ticks, clamp, single, guards
// 10 -- softmax exact sum (residue-to-max) incl. a 100-long no-drift row
// 11 -- int_argmax first-wins + f64_argmax NaN policy
// Setup failures use 20+.

module p_wave165_shapes

use xiom.math.int;
use xiom.math.fixed;
use xiom.stats.int_stats;
use xiom.core;

fn abs_i(x: Int) -> Int {
  if x < 0 { return 0 - x; }
  return x;
}

fn main() -> Int {
  // Row 1: saturating add/sub/mul (wishlist row 9).
  if int.saturating_add(core.INT_MAX, 1) != core.INT_MAX { return 1; }
  if int.saturating_add(core.INT_MAX, 0) != core.INT_MAX { return 1; }
  if int.saturating_add(core.INT_MIN, 0 - 1) != core.INT_MIN { return 1; }
  if int.saturating_add(2, 3) != 5 { return 1; }
  if int.saturating_add(0 - 5, 2) != 0 - 3 { return 1; }
  if int.saturating_sub(core.INT_MIN, 1) != core.INT_MIN { return 1; }
  if int.saturating_sub(core.INT_MAX, 0 - 1) != core.INT_MAX { return 1; }
  if int.saturating_sub(10, 4) != 6 { return 1; }
  if int.saturating_mul(core.INT_MAX, 2) != core.INT_MAX { return 1; }
  if int.saturating_mul(core.INT_MIN, 2) != core.INT_MIN { return 1; }
  if int.saturating_mul(core.INT_MIN, 0 - 1) != core.INT_MAX { return 1; }
  if int.saturating_mul(0 - 5, 7) != 0 - 35 { return 1; }
  if int.saturating_mul(46341, 46341) != 2147488281 { return 1; }
  if int.saturating_mul(core.INT_MAX, 1) != core.INT_MAX { return 1; }
  if int.saturating_mul(core.INT_MIN, 1) != core.INT_MIN { return 1; }

  // Row 2: div_round + div_ceil (wishlist row 10).
  if int.div_round(5, 2) != 3 { return 2; }
  if int.div_round(0 - 5, 2) != 0 - 3 { return 2; }
  if int.div_round(5, 0 - 2) != 0 - 3 { return 2; }
  if int.div_round(0 - 5, 0 - 2) != 3 { return 2; }
  if int.div_round(1, 2) != 1 { return 2; }
  if int.div_round(0 - 1, 2) != 0 - 1 { return 2; }
  if int.div_round(7, 2) != 4 { return 2; }
  if int.div_round(0, 5) != 0 { return 2; }
  if int.div_round(5, 0) != 0 { return 2; }
  if int.div_round(7, 1) != 7 { return 2; }
  if int.div_round(core.INT_MIN, 0 - 1) != core.INT_MAX { return 2; }
  if int.div_round(core.INT_MIN, 1) != core.INT_MIN { return 2; }
  if int.div_ceil(7, 2) != 4 { return 2; }
  if int.div_ceil(0 - 7, 2) != 0 - 3 { return 2; }
  if int.div_ceil(7, 0 - 2) != 0 - 3 { return 2; }
  if int.div_ceil(0 - 7, 0 - 2) != 4 { return 2; }
  if int.div_ceil(6, 2) != 3 { return 2; }
  if int.div_ceil(0 - 6, 2) != 0 - 3 { return 2; }
  if int.div_ceil(1, 2) != 1 { return 2; }
  if int.div_ceil(0 - 1, 2) != 0 { return 2; }
  if int.div_ceil(5, 0) != 0 { return 2; }
  if int.div_ceil(core.INT_MIN, 0 - 1) != core.INT_MIN { return 2; }

  // Row 3: mul + sum_mul + sum_sq (wishlist row 11).
  if fixed.mul(1500, 2500, 1000) != 3750 { return 3; }
  if fixed.mul(1500, 0 - 2500, 1000) != 0 - 3750 { return 3; }
  if fixed.mul(4000, 4000, 1000) != 16000 { return 3; }
  if fixed.mul(1, 500, 1000) != 1 { return 3; }
  if fixed.mul(1, 499, 1000) != 0 { return 3; }
  if fixed.mul(0, 2500, 1000) != 0 { return 3; }
  if fixed.mul(70, 70, 1000) != 5 { return 3; }
  if fixed.mul(core.INT_MAX, core.INT_MAX, 1) != core.INT_MAX { return 3; }
  if fixed.mul(1500, 2500, 0) != 0 { return 3; }
  var da = Vec[Int].new();
  da.push(1500);
  da.push(2000);
  var db = Vec[Int].new();
  db.push(2000);
  db.push(3000);
  if fixed.sum_mul(&da, &db, 1000) != 9000 { return 3; }
  if fixed.sum_mul(&da, &db, 0) != 0 { return 3; }
  var dshort = Vec[Int].new();
  dshort.push(1);
  if fixed.sum_mul(&da, &dshort, 1000) != 0 { return 3; }
  if fixed.sum_mul(&dshort, &dshort, 1000) != 0 { return 3; }
  var sq = Vec[Int].new();
  sq.push(3000);
  sq.push(4000);
  if fixed.sum_sq(&sq, 1000) != 25000 { return 3; }
  if fixed.sum_sq(&sq, 0) != 0 { return 3; }
  var empty = Vec[Int].new();
  if fixed.sum_sq(&empty, 1000) != 0 { return 3; }

  // Row 4: standalone isqrt (wishlist row 12a).
  if int.isqrt(0) != 0 { return 4; }
  if int.isqrt(1) != 1 { return 4; }
  if int.isqrt(2) != 1 { return 4; }
  if int.isqrt(3) != 1 { return 4; }
  if int.isqrt(4) != 2 { return 4; }
  if int.isqrt(8) != 2 { return 4; }
  if int.isqrt(9) != 3 { return 4; }
  if int.isqrt(15) != 3 { return 4; }
  if int.isqrt(16) != 4 { return 4; }
  if int.isqrt(0 - 5) != 0 { return 4; }
  if int.isqrt(1000000) != 1000 { return 4; }
  if int.isqrt(999999) != 999 { return 4; }
  if int.isqrt(core.INT_MAX) != 3037000499 { return 4; }
  if int.isqrt(9223372030926249001) != 3037000499 { return 4; }

  // Row 5: fixed sin/cos (wishlist row 12b), scale 1000.
  if fixed.sin(0, 1000) != 0 { return 5; }
  if fixed.cos(0, 1000) != 1000 { return 5; }
  if abs_i(fixed.sin(3142, 1000)) > 1 { return 5; }
  if abs_i(fixed.cos(3142, 1000) + 1000) > 1 { return 5; }
  if abs_i(fixed.sin(1571, 1000) - 1000) > 1 { return 5; }
  if abs_i(fixed.cos(1571, 1000)) > 2 { return 5; }
  if abs_i(fixed.sin(785, 1000) - 707) > 2 { return 5; }
  if abs_i(fixed.cos(785, 1000) - 707) > 2 { return 5; }
  if abs_i(fixed.sin(0 - 1571, 1000) + 1000) > 1 { return 5; }
  // 2*pi + pi/6: range reduction must fold to sin(pi/6) ~ 500.
  if abs_i(fixed.sin(6807, 1000) - 500) > 2 { return 5; }
  if abs_i(fixed.cos(6807, 1000) - 866) > 2 { return 5; }
  if abs_i(fixed.sin(12566, 1000)) > 2 { return 5; }
  if abs_i(fixed.cos(12566, 1000) - 1000) > 2 { return 5; }
  if fixed.sin(1000, 0) != 0 { return 5; }
  if fixed.cos(1000, 0) != 0 { return 5; }

  // Row 6: log2 + integer stats (wishlist row 27).
  if fixed.log2(1000, 1000) != 0 { return 6; }
  if fixed.log2(2000, 1000) != 1000 { return 6; }
  if fixed.log2(4000, 1000) != 2000 { return 6; }
  if fixed.log2(500, 1000) != 0 - 1000 { return 6; }
  if abs_i(fixed.log2(3000, 1000) - 1585) > 1 { return 6; }
  if abs_i(fixed.log2(1024, 1000) - 34) > 1 { return 6; }
  if fixed.log2(0, 1000) != 0 { return 6; }
  if fixed.log2(0 - 3, 1000) != 0 { return 6; }
  if fixed.log2(100, 0) != 0 { return 6; }
  var mv = Vec[Int].new();
  mv.push(1000);
  mv.push(2000);
  mv.push(4000);
  if int_stats.int_mean(&mv) != 2333 { return 6; }
  var mv2 = Vec[Int].new();
  mv2.push(1);
  mv2.push(2);
  if int_stats.int_mean(&mv2) != 2 { return 6; }
  var mv3 = Vec[Int].new();
  mv3.push(0 - 1);
  mv3.push(0 - 2);
  if int_stats.int_mean(&mv3) != 0 - 2 { return 6; }
  if int_stats.int_mean(&empty) != 0 { return 6; }
  var mv4 = Vec[Int].new();
  mv4.push(core.INT_MAX);
  mv4.push(core.INT_MAX);
  if int_stats.int_mean(&mv4) != core.INT_MAX { return 6; }
  var xs = Vec[Int].new();
  xs.push(1000);
  xs.push(2000);
  xs.push(3000);
  var ys = Vec[Int].new();
  ys.push(1000);
  ys.push(2000);
  ys.push(4000);
  if int_stats.int_slope(&xs, &ys, 1000) != 1500 { return 6; }
  var ys2 = Vec[Int].new();
  ys2.push(2000);
  ys2.push(4000);
  ys2.push(6000);
  if int_stats.int_slope(&xs, &ys2, 1000) != 2000 { return 6; }
  var xflat = Vec[Int].new();
  xflat.push(5);
  xflat.push(5);
  var yflat = Vec[Int].new();
  yflat.push(1);
  yflat.push(2);
  if int_stats.int_slope(&xflat, &yflat, 1000) != 0 { return 6; }
  if int_stats.int_slope(&dshort, &dshort, 1000) != 0 { return 6; }
  if int_stats.int_slope(&xs, &ys2, 0) != 0 { return 6; }

  // Row 7: exp / ln / pow_int (wishlist row 16), scale 1000.
  if fixed.ln(1000, 1000) != 0 { return 7; }
  if abs_i(fixed.ln(2000, 1000) - 693) > 1 { return 7; }
  if abs_i(fixed.ln(4000, 1000) - 1386) > 1 { return 7; }
  if abs_i(fixed.ln(1, 1000) + 6908) > 2 { return 7; }
  if fixed.ln(0, 1000) != 0 { return 7; }
  if fixed.ln(0 - 5, 1000) != 0 { return 7; }
  if fixed.exp(0, 1000) != 1000 { return 7; }
  if abs_i(fixed.exp(1000, 1000) - 2718) > 1 { return 7; }
  if abs_i(fixed.exp(0 - 1000, 1000) - 368) > 1 { return 7; }
  if abs_i(fixed.exp(2000, 1000) - 7389) > 2 { return 7; }
  if abs_i(fixed.exp(10000, 1000) - 22026466) > 5 { return 7; }
  if fixed.exp(100000, 1000) != core.INT_MAX { return 7; }
  if fixed.exp(0 - 100000, 1000) != 0 { return 7; }
  if fixed.exp(123, 0) != 0 { return 7; }
  if fixed.pow_int(2000, 3, 1000) != 8000 { return 7; }
  if fixed.pow_int(2000, 0 - 1, 1000) != 500 { return 7; }
  if fixed.pow_int(1500, 2, 1000) != 2250 { return 7; }
  if fixed.pow_int(5, 0, 1000) != 1000 { return 7; }
  if fixed.pow_int(3000, 0 - 2, 1000) != 111 { return 7; }
  if fixed.pow_int(0 - 2000, 2, 1000) != 4000 { return 7; }
  if fixed.pow_int(0 - 2000, 3, 1000) != 0 - 8000 { return 7; }
  if fixed.pow_int(0, 3, 1000) != 0 { return 7; }
  if fixed.pow_int(2000, 2, 0) != 0 { return 7; }

  // Row 8: mse (wishlist row 8), scale 1000.
  var a1 = Vec[Int].new();
  a1.push(1000);
  a1.push(2000);
  var p1 = Vec[Int].new();
  p1.push(1000);
  p1.push(1000);
  if fixed.mse(&a1, &p1, 1000) != 500 { return 8; }
  var a2 = Vec[Int].new();
  a2.push(1500);
  var p2 = Vec[Int].new();
  p2.push(1000);
  if fixed.mse(&a2, &p2, 1000) != 250 { return 8; }
  if fixed.mse(&a1, &a1, 1000) != 0 { return 8; }
  var a3 = Vec[Int].new();
  a3.push(1100);
  a3.push(900);
  if fixed.mse(&a3, &p1, 1000) != 10 { return 8; }
  if fixed.mse(&empty, &empty, 1000) != 0 { return 8; }
  if fixed.mse(&a1, &p2, 1000) != 0 { return 8; }
  if fixed.mse(&a1, &p1, 0) != 0 { return 8; }

  // Row 9: interp_linear (wishlist row 14).
  var tk = Vec[Int].new();
  tk.push(0);
  tk.push(1000);
  tk.push(2000);
  var vl = Vec[Int].new();
  vl.push(0);
  vl.push(10000);
  vl.push(5000);
  if fixed.interp_linear(&tk, &vl, 500) != 5000 { return 9; }
  if fixed.interp_linear(&tk, &vl, 0) != 0 { return 9; }
  if fixed.interp_linear(&tk, &vl, 1000) != 10000 { return 9; }
  if fixed.interp_linear(&tk, &vl, 2000) != 5000 { return 9; }
  if fixed.interp_linear(&tk, &vl, 3000) != 5000 { return 9; }
  if fixed.interp_linear(&tk, &vl, 0 - 100) != 0 { return 9; }
  if fixed.interp_linear(&tk, &vl, 1500) != 7500 { return 9; }
  if fixed.interp_linear(&tk, &vl, 1250) != 8750 { return 9; }
  var tk2 = Vec[Int].new();
  tk2.push(0);
  tk2.push(3);
  var vl2 = Vec[Int].new();
  vl2.push(0);
  vl2.push(1);
  if fixed.interp_linear(&tk2, &vl2, 1) != 0 { return 9; }
  if fixed.interp_linear(&tk2, &vl2, 2) != 1 { return 9; }
  var tk1 = Vec[Int].new();
  tk1.push(5);
  var vl1 = Vec[Int].new();
  vl1.push(42);
  if fixed.interp_linear(&tk1, &vl1, 100) != 42 { return 9; }
  if fixed.interp_linear(&vl1, &vl1, 3) != 42 { return 9; }
  if fixed.interp_linear(&empty, &empty, 3) != 0 { return 9; }
  if fixed.interp_linear(&tk, &vl1, 3) != 0 { return 9; }

  // Row 10: exact-sum softmax (wishlist row 17), scale 1000.
  var lg0 = Vec[Int].new();
  lg0.push(0);
  lg0.push(0);
  var sm0 = fixed.softmax(&lg0, 1000);
  if sm0.len() != 2 { return 10; }
  if sm0[0] != 500 || sm0[1] != 500 { return 10; }
  var lg1 = Vec[Int].new();
  lg1.push(0);
  lg1.push(0);
  lg1.push(0);
  var sm1 = fixed.softmax(&lg1, 1000);
  var s1 = sm1[0] + sm1[1] + sm1[2];
  if s1 != 1000 { return 10; }
  if sm1[0] != 334 || sm1[1] != 333 || sm1[2] != 333 { return 10; }
  var lgu = Vec[Int].new();
  lgu.push(2000);
  lgu.push(1000);
  lgu.push(1000);
  var smu = fixed.softmax(&lgu, 1000);
  var su = smu[0] + smu[1] + smu[2];
  if su != 1000 { return 10; }
  if !(smu[0] > smu[1]) { return 10; }
  var lgt = Vec[Int].new();
  lgt.push(2000);
  lgt.push(2000);
  var smt = fixed.softmax(&lgt, 1000);
  if smt[0] != 500 || smt[1] != 500 { return 10; }
  // 100 equal logits: exact denominator accumulation, sum stays 1000.
  var lgl = Vec[Int].new();
  var i100 = 0;
  while i100 < 100 {
    lgl.push(7);
    i100 = i100 + 1;
  }
  var sml = fixed.softmax(&lgl, 1000);
  var sl = 0;
  i100 = 0;
  while i100 < 100 {
    sl = sl + sml[i100];
    i100 = i100 + 1;
  }
  if sl != 1000 { return 10; }
  if sml[0] != 10 { return 10; }
  var sme = fixed.softmax(&empty, 1000);
  if sme.len() != 0 { return 10; }
  var smz = fixed.softmax(&lg0, 0);
  if smz.len() != 0 { return 10; }

  // Row 11: argmax stability + NaN policy (wishlist row 4).
  if int_stats.int_argmax(&empty) != 0 { return 11; }
  var am1 = Vec[Int].new();
  am1.push(3);
  if int_stats.int_argmax(&am1) != 0 { return 11; }
  var am2 = Vec[Int].new();
  am2.push(1);
  am2.push(5);
  am2.push(2);
  am2.push(5);
  if int_stats.int_argmax(&am2) != 1 { return 11; }
  var am3 = Vec[Int].new();
  am3.push(0 - 3);
  am3.push(0 - 1);
  am3.push(0 - 9);
  if int_stats.int_argmax(&am3) != 1 { return 11; }
  var am4 = Vec[Int].new();
  am4.push(7);
  am4.push(7);
  am4.push(7);
  if int_stats.int_argmax(&am4) != 0 { return 11; }
  var fm1 = Vec[Float64].new();
  fm1.push(1.0);
  fm1.push(3.0);
  fm1.push(2.0);
  if int_stats.f64_argmax(&fm1) != 1 { return 11; }
  var fm2 = Vec[Float64].new();
  fm2.push(1.0);
  fm2.push(3.0);
  fm2.push(3.0);
  if int_stats.f64_argmax(&fm2) != 1 { return 11; }
  var fm3 = Vec[Float64].new();
  fm3.push(1.0);
  fm3.push(0.0 / 0.0);
  fm3.push(0.5);
  if int_stats.f64_argmax(&fm3) != 0 { return 11; }
  var fm4 = Vec[Float64].new();
  fm4.push(0.0 / 0.0);
  fm4.push(0.0 / 0.0);
  if int_stats.f64_argmax(&fm4) != 0 { return 11; }
  var fm5 = Vec[Float64].new();
  fm5.push(0.0 / 0.0);
  fm5.push(2.0);
  fm5.push(0.0 / 0.0);
  if int_stats.f64_argmax(&fm5) != 1 { return 11; }
  var fm6 = Vec[Float64].new();
  fm6.push(0.0 / 0.0);
  fm6.push(2.0);
  fm6.push(3.0);
  if int_stats.f64_argmax(&fm6) != 2 { return 11; }
  var fme = Vec[Float64].new();
  if int_stats.f64_argmax(&fme) != 0 { return 11; }

  return 0;
}

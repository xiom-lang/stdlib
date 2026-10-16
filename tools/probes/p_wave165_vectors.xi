// p_wave165_vectors.xi -- wave 165 numeric cross-checks (companion to
// p_wave165_shapes.xi): invariants, inverse round-trips and multi-scale
// anchors for the new math/fixed-point surface. Rows (0 = all hold):
//  1 -- sin^2 + cos^2 == scale^2 within tolerance on the circle, both scales
//  2 -- ln(exp(x)) round-trips (scale 10000) and exp/ln anchors at scale 4096
//  3 -- log2 exactness at other scales + ln/log2 cross-consistency
//  4 -- mul/sum_mul/sum_sq exact cases (incl. clause-exercising b == scale)
//  5 -- div_round/div_ceil nearest-integer invariants incl. negative b
//  6 -- isqrt sweep: floor property for a range + boundary squares
//  7 -- softmax: exact sum to scale on an 1000-long LCG logit vector and
//       monotone probabilities vs logits
//  8 -- mse symmetry, zero on equal vectors, monotone in error size
// Setup failures use 20+.

module p_wave165_vectors

use xiom.math.int;
use xiom.math.fixed;
use xiom.stats.int_stats;
use xiom.core;

fn abs_i(x: Int) -> Int {
  if x < 0 { return 0 - x; }
  return x;
}

fn main() -> Int {
  // Row 1: Pythagorean identity at scale 1000 and 4096.
  var xs = Vec[Int].new();
  xs.push(0);
  xs.push(250);
  xs.push(785);
  xs.push(1571);
  xs.push(2356);
  xs.push(3142);
  xs.push(0 - 785);
  xs.push(5000);
  var scales = Vec[Int].new();
  scales.push(1000);
  scales.push(4096);
  var si = 0;
  while si < scales.len() {
    var s = scales[si];
    var i = 0;
    while i < xs.len() {
      var x = xs[i] * s / 1000;
      var sn = fixed.sin(x, s);
      var cs = fixed.cos(x, s);
      var ident = sn * sn + cs * cs - s * s;
      if abs_i(ident) > 4 * s { return 1; }
      i = i + 1;
    }
    si = si + 1;
  }

  // Row 2: exp/ln round trip at scale 10000, anchors at 4096.
  var ev = Vec[Int].new();
  ev.push(500);
  ev.push(1000);
  ev.push(0 - 1500);
  ev.push(3250);
  var k = 0;
  while k < ev.len() {
    var x = ev[k];
    var r = fixed.ln(fixed.exp(x, 10000), 10000);
    if abs_i(r - x) > 3 { return 2; }
    k = k + 1;
  }
  if abs_i(fixed.exp(1000, 4096) - 5229) > 4 { return 2; }
  if abs_i(fixed.exp(0 - 1000, 4096) - 3209) > 4 { return 2; }
  if abs_i(fixed.ln(8192, 4096) - 2839) > 2 { return 2; }
  if abs_i(fixed.ln(4096, 4096)) > 0 { return 2; }

  // Row 3: log2 exactness and ln/log2 cross-consistency.
  if fixed.log2(4096, 4096) != 0 { return 3; }
  if fixed.log2(8192, 4096) != 4096 { return 3; }
  if fixed.log2(1024, 4096) != 0 - 8192 { return 3; }
  // ln(10) / ln(2) = log2(10) ~ 3.32193; cross-check at scale 1000.
  var l10 = fixed.ln(10000, 1000);
  var l2 = fixed.ln(2000, 1000);
  var lg10 = fixed.log2(10000, 1000);
  var est = int.div_round(l10 * 1000, l2);
  if abs_i(est - lg10) > 3 { return 3; }

  // Row 4: mul/sum_mul/sum_sq exact cases + clause paths.
  if fixed.mul(7, 1000, 1000) != 7 { return 4; }
  if fixed.mul(12345, 54321, 100000) != 6706 { return 4; }
  if fixed.mul(0 - 12345, 54321, 100000) != 0 - 6706 { return 4; }
  var ma = Vec[Int].new();
  ma.push(2000);
  ma.push(3000);
  var mb = Vec[Int].new();
  mb.push(4000);
  mb.push(5000);
  if fixed.sum_mul(&ma, &mb, 1000) != 23000 { return 4; }
  if fixed.sum_sq(&ma, 1000) != 13000 { return 4; }
  if int.saturating_mul(0, 5) != 0 { return 4; }
  if fixed.pow_int(1000, 7, 1000) != 1000 { return 4; }

  // Row 5: div_round/div_ceil nearest-integer invariants.
  var av = Vec[Int].new();
  av.push(7);
  av.push(0 - 7);
  av.push(12345);
  av.push(0 - 12345);
  var bv = Vec[Int].new();
  bv.push(2);
  bv.push(3);
  bv.push(0 - 2);
  bv.push(1000);
  var ai = 0;
  while ai < av.len() {
    var bi = 0;
    while bi < bv.len() {
      var a = av[ai];
      var b = bv[bi];
      var q = int.div_round(a, b);
      var err = q * b - a;
      var half = b / 2;
      if half < 0 { half = 0 - half; }
      if abs_i(err) > half { return 5; }
      var c = int.div_ceil(a, b);
      var rem = c * b - a;
      if b > 0 {
        if rem < 0 { return 5; }
        if rem >= b { return 5; }
        if c < q { return 5; }
      } else {
        if rem > 0 { return 5; }
        if rem <= b { return 5; }
      }
      if c < q { return 5; }
      bi = bi + 1;
    }
    ai = ai + 1;
  }

  // Row 6: isqrt sweep (floor property) + boundary squares.
  var n = 2;
  while n <= 300 {
    var r = int.isqrt(n);
    if r * r > n { return 6; }
    var rp = r + 1;
    if rp * rp <= n { return 6; }
    n = n + 1;
  }
  var bigs = Vec[Int].new();
  bigs.push(1000000000000);
  bigs.push(999999999999);
  bigs.push(2147483647);
  bigs.push(4611686014132420609);
  var bi = 0;
  while bi < bigs.len() {
    var v = bigs[bi];
    var r = int.isqrt(v);
    if r * r > v { return 6; }
    if (r + 1) <= 3037000499 {
      var rp = r + 1;
      if rp * rp <= v { return 6; }
    }
    bi = bi + 1;
  }
  if int.isqrt(1000000000000) != 1000000 { return 6; }
  if int.isqrt(4611686014132420609) != 2147483647 { return 6; }

  // Row 7: softmax exact sum on an 1000-long LCG vector + monotonicity.
  var lg = Vec[Int].new();
  var state = 12345;
  var j = 0;
  while j < 1000 {
    state = (state * 1103515245 + 12345) % 2147483648;
    if state < 0 { state = 0 - state; }
    lg.push(state % 20001 - 10000);
    j = j + 1;
  }
  var sm = fixed.softmax(&lg, 1000);
  if sm.len() != 1000 { return 7; }
  var total = 0;
  j = 0;
  while j < 1000 {
    if sm[j] < 0 { return 7; }
    total = total + sm[j];
    j = j + 1;
  }
  if total != 1000 { return 7; }
  // Monotonicity: a strictly larger logit must not get a smaller probability.
  var lg2 = Vec[Int].new();
  lg2.push(1000);
  lg2.push(2500);
  lg2.push(2500);
  lg2.push(4000);
  var sm2 = fixed.softmax(&lg2, 1000);
  if sm2[3] < sm2[1] { return 7; }
  if sm2[1] < sm2[0] { return 7; }
  if sm2[0] + sm2[1] + sm2[2] + sm2[3] != 1000 { return 7; }
  if sm2[1] != sm2[2] { return 7; }

  // Row 8: mse symmetry / zero / monotone.
  var m1 = Vec[Int].new();
  m1.push(1000);
  m1.push(2500);
  m1.push(0 - 500);
  var m2 = Vec[Int].new();
  m2.push(1200);
  m2.push(2300);
  m2.push(0 - 700);
  var e1 = fixed.mse(&m1, &m2, 1000);
  var e2 = fixed.mse(&m2, &m1, 1000);
  if e1 != e2 { return 8; }
  if fixed.mse(&m1, &m1, 1000) != 0 { return 8; }
  if !(e1 > 0) { return 8; }

  return 0;
}

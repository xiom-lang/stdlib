// XIOM - Geom: Curves
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the parametric-curve domain.

module xiom.geom.curves

// Depends on: xiom.geom

// ============================================================================
// Parametric curves split from geom.xi: Bezier, Catmull-Rom, B-spline, Hermite,
// and arc-length queries. TODO(compiler): implement.
//
// All functions operate on dynamic Vec[Float64] points and return fresh
// Vec[Float64] results (single-level reads are sound in this compiler).
// ============================================================================

use xiom.math;

// Point on a quadratic Bezier curve at parameter t. O(1).
pub fn bezier_quad(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = p0.len();
  if p1.len() != n || p2.len() != n || n == 0 { return out; }
  var inv = 1.0 - t;
  var i = 0;
  while i < n {
    out.push(inv * inv * p0[i] + 2.0 * inv * t * p1[i] + t * t * p2[i]);
    i = i + 1;
  }
  return out;
}

// Point on a cubic Bezier curve at parameter t. O(1).
pub fn bezier_cubic(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = p0.len();
  if p1.len() != n || p2.len() != n || p3.len() != n || n == 0 { return out; }
  var inv = 1.0 - t;
  var inv2 = inv * inv;
  var t2 = t * t;
  var i = 0;
  while i < n {
    out.push(inv2 * inv * p0[i] + 3.0 * inv2 * t * p1[i] + 3.0 * inv * t2 * p2[i] + t2 * t * p3[i]);
    i = i + 1;
  }
  return out;
}

// Tangent vector of a Bezier curve at t: the derivative of the de Casteljau
// ladder. O(k^2).
pub fn bezier_derivative(points: &Vec[Vec[Float64]], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = points.len();
  if n < 2 { return out; }
  var dim = points[0].len();
  // Deep-copy the control points (two-step: single-level rows, then fresh
  // element rows) so by-ref nested reads (BUG 26 #1) are avoided.
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    sc.push(points[i]);
    i = i + 1;
  }
  var pc = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < dim {
      row.push(sc[i][j]);
      j = j + 1;
    }
    pc.push(row);
    i = i + 1;
  }
  var d = Vec[Vec[Float64]].new();
  i = 0;
  while i < n - 1 {
    var row = Vec[Float64].new();
    var j = 0;
    while j < dim {
      row.push(pc[i + 1][j] - pc[i][j]);
      j = j + 1;
    }
    d.push(row);
    i = i + 1;
  }
  var level = d.len();
  while level > 1 {
    var next = Vec[Vec[Float64]].new();
    var j2 = 0;
    while j2 < level - 1 {
      var a = d[j2];
      var b = d[j2 + 1];
      var row = Vec[Float64].new();
      var k = 0;
      while k < dim {
        row.push(a[k] + (b[k] - a[k]) * t);
        k = k + 1;
      }
      next.push(row);
      j2 = j2 + 1;
    }
    d = next;
    level = level - 1;
  }
  var scale = n - 1;
  var k2 = 0;
  while k2 < dim {
    var s = 0.0;
    var i2 = 0;
    while i2 < n - 1 {
      var w = _bernstein(n - 2, i2, t);
      s = s + (pc[i2 + 1][k2] - pc[i2][k2]) * w;
      i2 = i2 + 1;
    }
    out.push(s * (scale as Float64));
    k2 = k2 + 1;
  }
  return out;
}

// Bernstein basis polynomial B_{i,degree}(t). O(degree).
fn _bernstein(degree: Int, i: Int, t: Float64) -> Float64 {
  var c = 1;
  var k = 1;
  while k <= i {
    c = c * (degree - i + k) / k;
    k = k + 1;
  }
  var inv = 1.0 - t;
  var pow_t = 1.0;
  var p = 0;
  while p < i {
    pow_t = pow_t * t;
    p = p + 1;
  }
  var pow_inv = 1.0;
  p = 0;
  while p < degree - i {
    pow_inv = pow_inv * inv;
    p = p + 1;
  }
  var cf = c as Float64;
  return cf * pow_t * pow_inv;
}

// Catmull-Rom spline point over [p1, p2] at parameter t in [0, 1]. O(1).
pub fn catmull_rom(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = p0.len();
  if p1.len() != n || p2.len() != n || p3.len() != n || n == 0 { return out; }
  var t2 = t * t;
  var t3 = t2 * t;
  var i = 0;
  while i < n {
    var c0 = -0.5 * p0[i] + 1.5 * p1[i] - 1.5 * p2[i] + 0.5 * p3[i];
    var c1 = p0[i] - 2.5 * p1[i] + 2.0 * p2[i] - 0.5 * p3[i];
    var c2 = -0.5 * p0[i] + 0.5 * p2[i];
    out.push(c0 * t3 + c1 * t2 + c2 * t + p1[i]);
    i = i + 1;
  }
  return out;
}

// Uniform cubic B-spline point at parameter t in [0, 1] over the four control
// points. O(1).
pub fn b_spline(points: &Vec[Vec[Float64]], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if points.len() < 4 { return out; }
  var dim = points[0].len();
  var sc = Vec[Vec[Float64]].new();
  var r = 0;
  while r < points.len() {
    sc.push(points[r]);
    r = r + 1;
  }
  var i = 0;
  while i < dim {
    var p0 = sc[0][i];
    var p1 = sc[1][i];
    var p2 = sc[2][i];
    var p3 = sc[3][i];
    var b0 = (1.0 - t) * (1.0 - t) * (1.0 - t) / 6.0;
    var b1 = (3.0 * t * t * t - 6.0 * t * t + 4.0) / 6.0;
    var b2 = (-3.0 * t * t * t + 3.0 * t * t + 3.0 * t + 1.0) / 6.0;
    var b3 = t * t * t / 6.0;
    out.push(b0 * p0 + b1 * p1 + b2 * p2 + b3 * p3);
    i = i + 1;
  }
  return out;
}

// Hermite interpolation with endpoint tangents t0 and t1. O(1).
pub fn hermite_curve(p0: &Vec[Float64], t0: &Vec[Float64], p1: &Vec[Float64], t1: &Vec[Float64], t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = p0.len();
  if t0.len() != n || p1.len() != n || t1.len() != n || n == 0 { return out; }
  var t2 = t * t;
  var t3 = t2 * t;
  var h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
  var h10 = t3 - 2.0 * t2 + t;
  var h01 = -2.0 * t3 + 3.0 * t2;
  var h11 = t3 - t2;
  var i = 0;
  while i < n {
    out.push(h00 * p0[i] + h10 * t0[i] + h01 * p1[i] + h11 * t1[i]);
    i = i + 1;
  }
  return out;
}

// Arc length of a sampled curve over [a, b] by piecewise-linear integration
// with n segments. O(n * cost(f)).
pub fn curve_length(samples: fn(Float64) -> Vec[Float64], a: Float64, b: Float64, n: Int) -> Float64 {
  if n < 1 { return 0.0; }
  var segs = n;
  var total = 0.0;
  var prev = samples(a);
  var i = 1;
  while i <= segs {
    var u = a + (b - a) * (i as Float64) / (segs as Float64);
    var cur = samples(u);
    var s = 0.0;
    var k = 0;
    var m = prev.len();
    if cur.len() < m { m = cur.len(); }
    while k < m {
      var d = cur[k] - prev[k];
      s = s + d * d;
      k = k + 1;
    }
    total = total + math.sqrt(s);
    prev = cur;
    i = i + 1;
  }
  return total;
}

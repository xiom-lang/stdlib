// XIOM - Math: Chaos Theory
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.chaos

// Depends on: xiom.math

// ============================================================================
// Chaotic dynamical systems, fractals, and sensitive-dependence diagnostics
// such as Lyapunov exponents. Iterations carry explicit step caps. Vector
// outputs that are nested (Vec[Vec[Float64]]) are built locally; element
// reads by callers are subject to a compiler limitation (BUG 23 #1 residual;
// see the smoke notes). Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;
use xiom.core.to_float;

// Logistic map x_{k+1} = r x (1 - x) iterated n steps from x0. Returns the
// orbit (x0, x1, ..., x_{n-1}); empty for n <= 0. Complexity: O(n).
pub fn logistic_map(r: Float64, x0: Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var x = x0;
  var i = 0;
  while i < n {
    out.push(x);
    x = r * x * (1.0 - x);
    i = i + 1;
  }
  return out;
}

// Lorenz system dx/dt = sigma(y-x), dy/dt = x(rho-z) - y, dz/dt = xy - beta z
// integrated by explicit Euler. Returns steps + 1 rows of 3 components;
// empty for steps <= 0. Complexity: O(steps).
pub fn lorenz_system(sigma: Float64, rho: Float64, beta: Float64, x0: &Vec[Float64], steps: Int, dt: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if steps <= 0 || x0.len() != 3 { return out; }
  var x = x0[0];
  var y = x0[1];
  var z = x0[2];
  var i = 0;
  while i <= steps {
    var row = Vec[Float64].new();
    row.push(x);
    row.push(y);
    row.push(z);
    out.push(row);
    if i < steps {
      var nx = x + dt * sigma * (y - x);
      var ny = y + dt * (x * (rho - z) - y);
      var nz = z + dt * (x * y - beta * z);
      x = nx;
      y = ny;
      z = nz;
    }
    i = i + 1;
  }
  return out;
}

// Rossler system dx/dt = -y - z, dy/dt = x + a y, dz/dt = b + z(x - c)
// integrated by explicit Euler. Returns steps + 1 rows of 3 components;
// empty for steps <= 0. Complexity: O(steps).
pub fn rossler_system(a: Float64, b: Float64, c: Float64, x0: &Vec[Float64], steps: Int, dt: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if steps <= 0 || x0.len() != 3 { return out; }
  var x = x0[0];
  var y = x0[1];
  var z = x0[2];
  var i = 0;
  while i <= steps {
    var row = Vec[Float64].new();
    row.push(x);
    row.push(y);
    row.push(z);
    out.push(row);
    if i < steps {
      var nx = x + dt * (-y - z);
      var ny = y + dt * (x + a * y);
      var nz = z + dt * (b + z * (x - c));
      x = nx;
      y = ny;
      z = nz;
    }
    i = i + 1;
  }
  return out;
}

// Henon map x' = 1 - a x^2 + y, y' = b x iterated n steps. Returns the orbit
// as (x, y) pairs; empty for n <= 0. Complexity: O(n).
pub fn henon_map(a: Float64, b: Float64, x0: Float64, y0: Float64, n: Int) -> Vec[(Float64, Float64)] {
  var out = Vec[(Float64, Float64)].new();
  if n <= 0 { return out; }
  var x = x0;
  var y = y0;
  var i = 0;
  while i < n {
    out.push((x, y));
    var nx = 1.0 - a * x * x + y;
    var ny = b * x;
    x = nx;
    y = ny;
    i = i + 1;
  }
  return out;
}

// Bifurcation-diagram points of the logistic map: for `steps` parameter
// values uniformly spread over [r_min, r_max], discard `transients`
// iterations then capture 10 orbit points as (r, x) pairs. Empty for
// degenerate input. Complexity: O(steps * (transients + 10)).
pub fn bifurcation_diagram(r_min: Float64, r_max: Float64, steps: Int, transients: Int) -> Vec[(Float64, Float64)] {
  var out = Vec[(Float64, Float64)].new();
  if steps <= 0 || r_max < r_min { return out; }
  var k = 0;
  while k < steps {
    var r = r_min + (r_max - r_min) * ((k as Float64) / (steps as Float64));
    var x = 0.5;
    var t = 0;
    while t < transients {
      x = r * x * (1.0 - x);
      t = t + 1;
    }
    var c = 0;
    while c < 10 {
      x = r * x * (1.0 - x);
      out.push((r, x));
      c = c + 1;
    }
    k = k + 1;
  }
  return out;
}

// Estimated largest Lyapunov exponent of a 1-D time series from the mean
// log expansion ratio |x_{k+1} - x_k| / |x_k - x_{k-1}|. NaN for fewer than
// 3 points or a zero difference (documented). Complexity: O(n).
pub fn lyapunov_exponent(orbit: &Vec[Float64]) -> Float64 {
  var n = orbit.len();
  if n < 3 { return 0.0 / 0.0; }
  var sum = 0.0;
  var count = 0;
  var i = 1;
  while i < n - 1 {
    var d1 = orbit[i] - orbit[i - 1];
    var d2 = orbit[i + 1] - orbit[i];
    if d1 < 0.0 { d1 = -d1; }
    if d2 < 0.0 { d2 = -d2; }
    if d1 > 0.0 && d2 > 0.0 {
      sum = sum + math.ln(d2 / d1);
      count = count + 1;
    }
    i = i + 1;
  }
  if count == 0 { return 0.0 / 0.0; }
  return sum / (count as Float64);
}

// Trajectory of a chaotic attractor under the discrete dynamics map
// x <- dynamics(x), n steps. Returns n + 1 states; empty for n <= 0.
// Complexity: O(n * cost(dynamics)).
pub fn strange_attractor(dynamics: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if n < 0 { return out; }
  var x = Vec[Float64].new();
  var i = 0;
  while i < x0.len() {
    x.push(x0[i]);
    i = i + 1;
  }
  var row = Vec[Float64].new();
  var j = 0;
  while j < x.len() {
    row.push(x[j]);
    j = j + 1;
  }
  out.push(row);
  var s = 0;
  while s < n {
    var nx = dynamics(&x);
    x = nx;
    var row2 = Vec[Float64].new();
    var m = 0;
    while m < x.len() {
      row2.push(x[m]);
      m = m + 1;
    }
    out.push(row2);
    s = s + 1;
  }
  return out;
}

// Box-counting fractal dimension of a 2-D point set: for four box sizes the
// occupied-box counts are fit by least squares on log-log scales. NaN for
// fewer than 2 points. Complexity: O(4 * n).
pub fn fractal_dimension(points: &Vec[(Float64, Float64)]) -> Float64 {
  var n = points.len();
  if n < 2 { return 0.0 / 0.0; }
  var minx = points[0].0;
  var maxx = points[0].0;
  var miny = points[0].1;
  var maxy = points[0].1;
  var i = 1;
  while i < n {
    var px = points[i].0;
    var py = points[i].1;
    if px < minx { minx = px; }
    if px > maxx { maxx = px; }
    if py < miny { miny = py; }
    if py > maxy { maxy = py; }
    i = i + 1;
  }
  var range = maxx - minx;
  if maxy - miny > range { range = maxy - miny; }
  if range <= 0.0 { return 0.0 / 0.0; }
  var sx = 0.0;
  var sy = 0.0;
  var sxx = 0.0;
  var sxy = 0.0;
  var b = 0;
  while b < 4 {
    var size = range / math.pow(2.0, (b + 1) as Float64);
    var cells = Vec[Int].new();
    var c = 0;
    while c < 1000 {
      cells.push(0);
      c = c + 1;
    }
    var count = 0;
    var j = 0;
    while j < n {
      var cx = to_int((points[j].0 - minx) / size);
      var cy = to_int((points[j].1 - miny) / size);
      var idx = cx * 32 + cy;
      if idx >= 0 && idx < 1000 {
        if cells[idx] == 0 {
          cells[idx] = 1;
          count = count + 1;
        }
      }
      j = j + 1;
    }
    var x = math.ln(1.0 / size);
    var y = math.ln((count as Float64) + 1.0);
    sx = sx + x;
    sy = sy + y;
    sxx = sxx + x * x;
    sxy = sxy + x * y;
    b = b + 1;
  }
  var denom = 4.0 * sxx - sx * sx;
  if denom == 0.0 { return 0.0 / 0.0; }
  return (4.0 * sxy - sx * sy) / denom;
}

// Escape iterations of c under z <- z^2 + c from z = 0; max_iter means the
// point is inside the set. Complexity: O(max_iter).
pub fn mandelbrot_set(c_re: Float64, c_im: Float64, max_iter: Int) -> Int {
  var zr = 0.0;
  var zi = 0.0;
  var it = 0;
  while it < max_iter {
    var zr2 = zr * zr;
    var zi2 = zi * zi;
    if zr2 + zi2 > 4.0 { return it; }
    var nr = zr2 - zi2 + c_re;
    var ni = 2.0 * zr * zi + c_im;
    zr = nr;
    zi = ni;
    it = it + 1;
  }
  return max_iter;
}

// Escape iterations of z0 under z <- z^2 + c for fixed parameter c; max_iter
// means the point is inside the Julia set. Complexity: O(max_iter).
pub fn julia_set(c_re: Float64, c_im: Float64, z_re: Float64, z_im: Float64, max_iter: Int) -> Int {
  var zr = z_re;
  var zi = z_im;
  var it = 0;
  while it < max_iter {
    var zr2 = zr * zr;
    var zi2 = zi * zi;
    if zr2 + zi2 > 4.0 { return it; }
    var nr = zr2 - zi2 + c_re;
    var ni = 2.0 * zr * zi + c_im;
    zr = nr;
    zi = ni;
    it = it + 1;
  }
  return max_iter;
}

// Burning-ship fractal escape count: z <- (|re z| + i |im z|)^2 + c.
// Complexity: O(max_iter).
pub fn burning_ship(c_re: Float64, c_im: Float64, max_iter: Int) -> Int {
  var zr = 0.0;
  var zi = 0.0;
  var it = 0;
  while it < max_iter {
    var zr2 = zr * zr;
    var zi2 = zi * zi;
    if zr2 + zi2 > 4.0 { return it; }
    var ar = zr;
    var ai = zi;
    if ar < 0.0 { ar = -ar; }
    if ai < 0.0 { ai = -ai; }
    var nr = ar * ar - ai * ai + c_re;
    var ni = 2.0 * ar * ai + c_im;
    zr = nr;
    zi = ni;
    it = it + 1;
  }
  return max_iter;
}

// Index of the root that a point converges to under Newton iteration on the
// polynomial a x^2 + b x + c (given as coeffs [a, b, c]). Returns 0 or 1 for
// a non-degenerate quadratic (documented restriction to degree <= 2).
// Complexity: O(iters).
pub fn newton_fractal(coeffs: &Vec[Float64], z: Float64, max_iter: Int) -> Int {
  var n = coeffs.len();
  if n < 3 { return 0; }
  var a = coeffs[0];
  var b = coeffs[1];
  var c = coeffs[2];
  if a == 0.0 {
    if b == 0.0 { return 0; }
    return 0;
  }
  var disc = b * b - 4.0 * a * c;
  var r1 = (-b + math.sqrt(math.abs_float(disc))) / (2.0 * a);
  var r2 = (-b - math.sqrt(math.abs_float(disc))) / (2.0 * a);
  var x = z;
  var it = 0;
  while it < max_iter {
    var f = a * x * x + b * x + c;
    var fp = 2.0 * a * x + b;
    if fp == 0.0 { it = max_iter; }
    else {
      x = x - f / fp;
    }
    it = it + 1;
  }
  var d1 = x - r1;
  var d2 = x - r2;
  if d1 < 0.0 { d1 = -d1; }
  if d2 < 0.0 { d2 = -d2; }
  if d1 <= d2 { return 0; }
  return 1;
}

// Tent map x_{k+1} = mu * min(x, 1 - x) iterated n steps from x0. Returns
// the orbit; empty for n <= 0. Complexity: O(n).
pub fn tent_map(mu: Float64, x0: Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var x = x0;
  var i = 0;
  while i < n {
    out.push(x);
    var xm = x;
    if x > 0.5 { xm = 1.0 - x; }
    x = mu * xm;
    i = i + 1;
  }
  return out;
}

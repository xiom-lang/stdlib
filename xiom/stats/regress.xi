// XIOM - Stats: Regress
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.regress

// Depends on: xiom.math

// ============================================================================
// Regression models and correlation measures.
//
// Linear fits use the closed-form least-squares equations (avoiding matrix
// reads, which are unreliable in this compiler build). Polynomial fits are
// exact for degree <= 2 (normal equations solved by Cramer's rule); higher
// degrees return the empty vector (documented). Complexity is documented per
// function.
// ============================================================================

use xiom.math;

// Least-squares linear fit result: slope, intercept, and R^2.
pub type RegressionResult = {
  slope: Float64;
  intercept: Float64;
  r2: Float64;
}

// Least-squares linear fit y = slope*x + intercept with R-squared. Returns a
// zeroed result for fewer than 2 points or a mismatch. Complexity: O(n).
pub fn linear_regression(x: &Vec[Float64], y: &Vec[Float64]) -> RegressionResult {
  var s = slope(x, y);
  var b = intercept(x, y);
  var r = r_squared(x, y);
  return RegressionResult{ slope: s, intercept: b, r2: r };
}

// Regression slope. Returns 0 for degenerate input. Complexity: O(n).
pub fn slope(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if n < 2 || y.len() != n { return 0.0; }
  var mx = 0.0;
  var my = 0.0;
  var i = 0;
  while i < n {
    mx = mx + x[i];
    my = my + y[i];
    i = i + 1;
  }
  mx = mx / (n as Float64);
  my = my / (n as Float64);
  var num = 0.0;
  var den = 0.0;
  var j = 0;
  while j < n {
    var dx = x[j] - mx;
    num = num + dx * (y[j] - my);
    den = den + dx * dx;
    j = j + 1;
  }
  if den == 0.0 { return 0.0; }
  return num / den;
}

// Regression intercept. Returns 0 for degenerate input. Complexity: O(n).
pub fn intercept(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if n == 0 || y.len() != n { return 0.0; }
  var mx = 0.0;
  var my = 0.0;
  var i = 0;
  while i < n {
    mx = mx + x[i];
    my = my + y[i];
    i = i + 1;
  }
  mx = mx / (n as Float64);
  my = my / (n as Float64);
  var m = slope(x, y);
  return my - m * mx;
}

// Coefficient of determination R^2. Returns 0 for degenerate input.
// Complexity: O(n).
pub fn r_squared(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if n < 2 || y.len() != n { return 0.0; }
  var m = slope(x, y);
  var b = intercept(x, y);
  var my = 0.0;
  var i = 0;
  while i < n {
    my = my + y[i];
    i = i + 1;
  }
  my = my / (n as Float64);
  var ss_res = 0.0;
  var ss_tot = 0.0;
  var j = 0;
  while j < n {
    var pred = m * x[j] + b;
    var res = y[j] - pred;
    ss_res = ss_res + res * res;
    var dy = y[j] - my;
    ss_tot = ss_tot + dy * dy;
    j = j + 1;
  }
  if ss_tot == 0.0 { return 0.0; }
  return 1.0 - ss_res / ss_tot;
}

// Pearson correlation coefficient. Complexity: O(n).
pub fn pearson_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if n < 2 || y.len() != n { return 0.0 / 0.0; }
  var mx = 0.0;
  var my = 0.0;
  var i = 0;
  while i < n {
    mx = mx + x[i];
    my = my + y[i];
    i = i + 1;
  }
  mx = mx / (n as Float64);
  my = my / (n as Float64);
  var num = 0.0;
  var dx2 = 0.0;
  var dy2 = 0.0;
  var j = 0;
  while j < n {
    var dx = x[j] - mx;
    var dy = y[j] - my;
    num = num + dx * dy;
    dx2 = dx2 + dx * dx;
    dy2 = dy2 + dy * dy;
    j = j + 1;
  }
  var denom = math.sqrt(dx2) * math.sqrt(dy2);
  if denom == 0.0 { return 0.0; }
  return num / denom;
}

// Rank-based Spearman correlation. Complexity: O(n log n).
pub fn spearman_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if y.len() != n { return 0.0 / 0.0; }
  if n < 2 { return 0.0 / 0.0; }
  var rx = _ranks(x);
  var ry = _ranks(y);
  return pearson_correlation(&rx, &ry);
}

// Least-squares polynomial coefficients (lowest degree first) by solving the
// normal equations: exact for degree 1 and 2 (Cramer's rule); higher degrees
// return the empty vector (documented). Complexity: O(n).
pub fn polynomial_regression(x: &Vec[Float64], y: &Vec[Float64], degree: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n < degree + 1 || y.len() != n { return out; }
  if degree == 1 {
    var m = slope(x, y);
    var b = intercept(x, y);
    out.push(b);
    out.push(m);
    return out;
  }
  if degree == 2 {
    var s0 = n as Float64;
    var s1 = 0.0;
    var s2 = 0.0;
    var s3 = 0.0;
    var s4 = 0.0;
    var t0 = 0.0;
    var t1 = 0.0;
    var t2 = 0.0;
    var i = 0;
    while i < n {
      var xv = x[i];
      var x2 = xv * xv;
      var x3 = x2 * xv;
      var x4 = x3 * xv;
      s1 = s1 + xv;
      s2 = s2 + x2;
      s3 = s3 + x3;
      s4 = s4 + x4;
      t0 = t0 + y[i];
      t1 = t1 + y[i] * xv;
      t2 = t2 + y[i] * x2;
      i = i + 1;
    }
    var d0 = _det3(s0, s1, s2, s1, s2, s3, s2, s3, s4);
    var d1 = _det3(t0, s1, s2, t1, s2, s3, t2, s3, s4);
    var d2 = _det3(s0, t0, s2, s1, t1, s3, s2, t2, s4);
    var d3 = _det3(s0, s1, t0, s1, s2, t1, s2, s3, t2);
    if d0 == 0.0 { return out; }
    out.push(d1 / d0);
    out.push(d2 / d0);
    out.push(d3 / d0);
    return out;
  }
  return out;
}

// 3x3 determinant.
fn _det3(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64, g: Float64, h: Float64, i: Float64) -> Float64 {
  return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
}

// Exponential fit y = a * exp(b*x): linear regression on (x, ln y). Returns
// (a, b); NaN for non-positive y. Complexity: O(n).
pub fn exponential_fit(x: &Vec[Float64], y: &Vec[Float64]) -> (Float64, Float64) {
  var n = x.len();
  if n < 2 || y.len() != n {
    return (0.0 / 0.0, 0.0 / 0.0);
  }
  var ly = Vec[Float64].new();
  var i = 0;
  while i < n {
    if y[i] <= 0.0 {
      return (0.0 / 0.0, 0.0 / 0.0);
    }
    ly.push(math.ln(y[i]));
    i = i + 1;
  }
  var b = slope(x, &ly);
  var la = intercept(x, &ly);
  var a = math.exp(la);
  return (a, b);
}

// Predicted value slope * x + intercept. Complexity: O(1).
pub fn predict_line(slope: Float64, intercept: Float64, x: Float64) -> Float64 {
  return slope * x + intercept;
}

// Observed minus predicted values. Empty for a mismatch. Complexity: O(n).
pub fn residuals(x: &Vec[Float64], y: &Vec[Float64], slope: Float64, intercept: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if y.len() != n { return out; }
  var i = 0;
  while i < n {
    var pred = slope * x[i] + intercept;
    out.push(y[i] - pred);
    i = i + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// Insertion sort of the indices by their values (ascending).
fn _sort_idx(v: &Vec[Float64], order: &mut Vec[Int]) {
  var n = order.len();
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      if v[order[j]] < v[order[j - 1]] {
        var t = order[j];
        order[j] = order[j - 1];
        order[j - 1] = t;
        j = j - 1;
      } else {
        j = 0;
      }
    }
    i = i + 1;
  }
}

// Average ranks (ties share the mean rank).
fn _ranks(data: &Vec[Float64]) -> Vec[Float64] {
  var n = data.len();
  var ranks = Vec[Float64].new();
  var order = Vec[Int].new();
  var i = 0;
  while i < n {
    ranks.push(0.0);
    order.push(i);
    i = i + 1;
  }
  _sort_idx(data, &mut order);
  var pos = 0;
  while pos < n {
    var end = pos;
    while end + 1 < n && data[order[end + 1]] == data[order[pos]] {
      end = end + 1;
    }
    var avg = ((pos + end) as Float64) / 2.0 + 1.0;
    var k = pos;
    while k <= end {
      ranks[order[k]] = avg;
      k = k + 1;
    }
    pos = end + 1;
  }
  return ranks;
}

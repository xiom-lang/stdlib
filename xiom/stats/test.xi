// XIOM - Stats: Test
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.stats.test

// Depends on: xiom.math

// ============================================================================
// Hypothesis testing and interval estimation.
//
// P-values come from the regularized incomplete gamma/beta machinery in
// math.special. NaN is returned for degenerate inputs. Complexity is
// documented per function.
// ============================================================================

use xiom.math;

// One-sample t statistic against population mean mu. NaN for fewer than 2
// samples. Complexity: O(n).
pub fn t_test_one_sample(data: &Vec[Float64], mu: Float64) -> Float64 {
  var n = data.len();
  if n < 2 { return 0.0 / 0.0; }
  var m = 0.0;
  var i = 0;
  while i < n {
    m = m + data[i];
    i = i + 1;
  }
  m = m / (n as Float64);
  var v = 0.0;
  var j = 0;
  while j < n {
    var d = data[j] - m;
    v = v + d * d;
    j = j + 1;
  }
  var s = math.sqrt(v / ((n - 1) as Float64));
  if s == 0.0 { return 0.0 / 0.0; }
  return (m - mu) / (s / math.sqrt(n as Float64));
}

// Independent two-sample t statistic (Welch, unequal variance). NaN for
// fewer than 2 samples in either group. Complexity: O(n).
pub fn t_test_two_sample(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var na = a.len();
  var nb = b.len();
  if na < 2 || nb < 2 { return 0.0 / 0.0; }
  var ma = 0.0;
  var mb = 0.0;
  var i = 0;
  while i < na {
    ma = ma + a[i];
    i = i + 1;
  }
  ma = ma / (na as Float64);
  var j = 0;
  while j < nb {
    mb = mb + b[j];
    j = j + 1;
  }
  mb = mb / (nb as Float64);
  var va = 0.0;
  var k = 0;
  while k < na {
    var da = a[k] - ma;
    va = va + da * da;
    k = k + 1;
  }
  var vb = 0.0;
  var l = 0;
  while l < nb {
    var db = b[l] - mb;
    vb = vb + db * db;
    l = l + 1;
  }
  var se2 = va / ((na - 1) as Float64) / (na as Float64) + vb / ((nb - 1) as Float64) / (nb as Float64);
  if se2 == 0.0 { return 0.0 / 0.0; }
  return (ma - mb) / math.sqrt(se2);
}

// Paired t statistic on the differences a - b. NaN for a mismatch or fewer
// than 2 pairs. Complexity: O(n).
pub fn t_test_paired(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n || n < 2 { return 0.0 / 0.0; }
  var diff = Vec[Float64].new();
  var i = 0;
  while i < n {
    diff.push(a[i] - b[i]);
    i = i + 1;
  }
  return t_test_one_sample(&diff, 0.0);
}

// Chi-squared goodness-of-fit statistic sum (o - e)^2 / e. NaN for a
// mismatch or a zero expected count. Complexity: O(n).
pub fn chi_squared_test(observed: &Vec[Int], expected: &Vec[Float64]) -> Float64 {
  var n = observed.len();
  if expected.len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    var e = expected[i];
    if e <= 0.0 { return 0.0 / 0.0; }
    var d = (observed[i] as Float64) - e;
    s = s + d * d / e;
    i = i + 1;
  }
  return s;
}

// F statistic as the ratio of the sample variances. NaN for fewer than 2
// samples or a zero denominator variance. Complexity: O(n).
pub fn f_test(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var na = a.len();
  var nb = b.len();
  if na < 2 || nb < 2 { return 0.0 / 0.0; }
  var ma = 0.0;
  var mb = 0.0;
  var i = 0;
  while i < na {
    ma = ma + a[i];
    i = i + 1;
  }
  ma = ma / (na as Float64);
  var j = 0;
  while j < nb {
    mb = mb + b[j];
    j = j + 1;
  }
  mb = mb / (nb as Float64);
  var va = 0.0;
  var vb = 0.0;
  var k = 0;
  while k < na {
    var da = a[k] - ma;
    va = va + da * da;
    k = k + 1;
  }
  var l = 0;
  while l < nb {
    var db = b[l] - mb;
    vb = vb + db * db;
    l = l + 1;
  }
  var sa = va / ((na - 1) as Float64);
  var sb = vb / ((nb - 1) as Float64);
  if sb == 0.0 { return 0.0 / 0.0; }
  return sa / sb;
}

// One-way ANOVA F statistic across groups.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the groups are a
// Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1 residual;
// verified by minimal probe). Keep the frozen signature; revisit when nested
// float Vec reads land.
pub fn anova_one_way(groups: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0 / 0.0;
}

// Two-tailed p-value for a t statistic with df degrees of freedom:
// P(|T| > t) = I_{df/(df + t^2)}(df/2, 1/2). Complexity: O(iterations).
pub fn p_value_from_t(t: Float64, df: Float64) -> Float64 {
  if df <= 0.0 { return 0.0 / 0.0; }
  if t != t { return t; }
  var z = df / (df + t * t);
  var ib = math.special.incomplete_beta(df / 2.0, 0.5, z);
  return ib;
}

// Right-tail p-value for a chi-squared statistic: 1 - P(df/2, x/2).
// Complexity: O(iterations).
pub fn p_value_from_chi2(x: Float64, df: Float64) -> Float64 {
  if df <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 { return 1.0; }
  var p = math.special.incomplete_gamma(df / 2.0, x / 2.0);
  return 1.0 - p;
}

// Standardized score (x - mu) / sigma. Complexity: O(1).
pub fn z_score(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma == 0.0 { return 0.0 / 0.0; }
  return (x - mu) / sigma;
}

// t-quantile: the two-sided critical value with df degrees of freedom for
// the confidence level, found by bisection on p_value_from_t. Complexity:
// O(50 * iterations).
fn _t_quantile(df: Float64, level: Float64) -> Float64 {
  if df <= 0.0 || level <= 0.0 || level >= 1.0 { return 0.0 / 0.0; }
  var target = 1.0 - level;
  var lo = 0.0;
  var hi = 20.0;
  var it = 0;
  while it < 50 {
    var mid = 0.5 * (lo + hi);
    var p = p_value_from_t(mid, df);
    if p < target {
      hi = mid;
    } else {
      lo = mid;
    }
    it = it + 1;
  }
  return 0.5 * (lo + hi);
}

// Confidence interval (lower, upper) for the sample mean at the given
// confidence level. NaN for fewer than 2 samples or an invalid level.
// Complexity: O(n).
pub fn confidence_interval(data: &Vec[Float64], level: Float64) -> (Float64, Float64) {
  var n = data.len();
  if n < 2 || level <= 0.0 || level >= 1.0 {
    return (0.0 / 0.0, 0.0 / 0.0);
  }
  var se = standard_error(data);
  var crit = _t_quantile((n - 1) as Float64, level);
  var m = 0.0;
  var i = 0;
  while i < n {
    m = m + data[i];
    i = i + 1;
  }
  m = m / (n as Float64);
  var lo = m - crit * se;
  var hi = m + crit * se;
  return (lo, hi);
}

// Standard error of the mean. NaN for fewer than 2 samples. Complexity: O(n).
pub fn standard_error(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n < 2 { return 0.0 / 0.0; }
  var m = 0.0;
  var i = 0;
  while i < n {
    m = m + data[i];
    i = i + 1;
  }
  m = m / (n as Float64);
  var v = 0.0;
  var j = 0;
  while j < n {
    var d = data[j] - m;
    v = v + d * d;
    j = j + 1;
  }
  var s = math.sqrt(v / ((n - 1) as Float64));
  return s / math.sqrt(n as Float64);
}

module xiom.stats

use xiom.stats.statistics;
use xiom.stats.probability;
use xiom.stats.dist;
use xiom.stats.test;
use xiom.stats.regress;
use xiom.stats.histogram;
use xiom.stats.moments;

use xiom.math;

fn stats_mean(data: &Vec[Int]) -> Int
  requires: data.len() >= 0
  ensures: result >= 0 || data.len() == 0
{
  if data.len() == 0 {
    0
  } else {
    stats_sum(data, 0) / data.len()
  }
}

fn stats_sum(data: &Vec[Int], idx: Int) -> Int
  requires: idx >= 0
  requires: idx <= data.len()
{
  if idx >= data.len() {
    0
  } else {
    data[idx] + stats_sum(data, idx + 1)
  }
}

fn stats_median(data: &Vec[Int]) -> Int
  requires: data.len() >= 0
{
  let len = data.len();
  if len == 0 {
    0
  } elif len % 2 == 1 {
    data[len / 2]
  } else {
    (data[len / 2 - 1] + data[len / 2]) / 2
  }
}

fn stats_stddev(data: &Vec[Int], mean: Int) -> Int
  requires: data.len() >= 0
{
  if data.len() == 0 {
    0
  } else {
    let variance = stats_variance_sum(data, mean, 0) / data.len();
    int_sqrt(variance)
  }
}

fn stats_variance_sum(data: &Vec[Int], mean: Int, idx: Int) -> Int
  requires: idx >= 0
  requires: idx <= data.len()
{
  if idx >= data.len() {
    0
  } else {
    let diff = data[idx] - mean;
    (diff * diff) + stats_variance_sum(data, mean, idx + 1)
  }
}

fn int_sqrt(n: Int) -> Int
  requires: n >= 0
  ensures: result >= 0
  ensures: result * result <= n && (result + 1) * (result + 1) > n
{
  if n <= 1 {
    n
  } else {
    int_sqrt_iter(n, n / 2)
  }
}

fn int_sqrt_iter(n: Int, guess: Int) -> Int
  requires: n >= 0
  requires: guess >= 0
{
  let next = (guess + n / guess) / 2;
  if next >= guess {
    guess
  } else {
    int_sqrt_iter(n, next)
  }
}

fn stats_percentile(data: &Vec[Int], p: Int) -> Int
  requires: data.len() >= 0
  requires: p >= 0 && p <= 100
{
  if data.len() == 0 {
    0
  } elif p <= 0 {
    data[0]
  } elif p >= 100 {
    data[data.len() - 1]
  } else {
    let idx = (p * data.len()) / 100;
    data[idx]
  }
}

// -- Min, Max, Range ---------------------------------------------------------

/// Returns the minimum value in a vector of integers.
/// Returns 0 for empty input.
pub fn stats_min(data: &Vec[Int]) -> Int {
  let len = data.len();
  if len == 0 { return 0; };
  var minval: Int = data[0];
  var i: Int = 1;
  while i < len {
    if data[i] < minval {
      minval = data[i];
    };
    i = i + 1;
  };
  return minval;
}

/// Returns the maximum value in a vector of integers.
/// Returns 0 for empty input.
pub fn stats_max(data: &Vec[Int]) -> Int {
  let len = data.len();
  if len == 0 { return 0; };
  var maxval: Int = data[0];
  var i: Int = 1;
  while i < len {
    if data[i] > maxval {
      maxval = data[i];
    };
    i = i + 1;
  };
  return maxval;
}

/// Returns the range (max - min) of a vector of integers.
pub fn stats_range(data: &Vec[Int]) -> Int {
  return stats_max(data) - stats_min(data);
}

// -- Mode --------------------------------------------------------------------

/// Returns the most frequently occurring value (mode) in a sorted vector.
/// For ties, returns the first mode encountered.
pub fn stats_mode(data: &Vec[Int]) -> Option[Int] {
  let len = data.len();
  if len == 0 {
    return Option[Int]{ is_some: false; value: 0; };
  };
  var best_val: Int = data[0];
  var best_count: Int = 1;
  var cur_val: Int = data[0];
  var cur_count: Int = 1;
  var i: Int = 1;
  while i < len {
    if data[i] == cur_val {
      cur_count = cur_count + 1;
    } else {
      if cur_count > best_count {
        best_count = cur_count;
        best_val = cur_val;
      };
      cur_val = data[i];
      cur_count = 1;
    };
    i = i + 1;
  };
  if cur_count > best_count {
    best_val = cur_val;
  };
  return Option[Int]{ is_some: true; value: best_val; };
}

// -- Variance & Standard Deviation -------------------------------------------

/// Computes the population variance of a vector of integers.
/// Sum of squared deviations from the mean divided by N.
pub fn stats_variance(data: &Vec[Int]) -> Float64 {
  let len = data.len();
  if len == 0 { return 0.0; };
  let mean = stats_mean(data);
  var fsum: Float64 = 0.0;
  var i: Int = 0;
  while i < len {
    let diff = (data[i] as Float64) - (mean as Float64);
    fsum = fsum + (diff * diff);
    i = i + 1;
  };
  return fsum / (len as Float64);
}

/// Computes the sample variance (Bessel's correction: divide by N-1).
pub fn stats_sample_variance(data: &Vec[Int]) -> Float64 {
  let len = data.len();
  if len < 2 { return 0.0; };
  let mean = stats_mean(data);
  var fsum: Float64 = 0.0;
  var i: Int = 0;
  while i < len {
    let diff = (data[i] as Float64) - (mean as Float64);
    fsum = fsum + (diff * diff);
    i = i + 1;
  };
  return fsum / ((len - 1) as Float64);
}

/// Computes the population standard deviation (Float64).
pub fn stats_stddev_f(data: &Vec[Int]) -> Float64 {
  return xiom.math.sqrt(stats_variance(data));
}

/// Computes the sample standard deviation (Float64).
pub fn stats_sample_stddev(data: &Vec[Int]) -> Float64 {
  return xiom.math.sqrt(stats_sample_variance(data));
}

// -- Quartiles ---------------------------------------------------------------

/// Returns the first quartile (Q1) of a sorted vector of integers.
/// Uses the median-of-lower-half method.
pub fn stats_q1(data: &Vec[Int]) -> Int {
  let len = data.len();
  if len == 0 { return 0; };
  let mid = len / 2;
  return data[mid / 2];
}

/// Returns the third quartile (Q3) of a sorted vector of integers.
/// Uses the median-of-upper-half method.
pub fn stats_q3(data: &Vec[Int]) -> Int {
  let len = data.len();
  if len == 0 { return 0; };
  let mid = len / 2;
  if len % 2 == 0 {
    return data[mid + (len - mid) / 2];
  };
  return data[mid + 1 + (len - mid - 1) / 2];
}

/// Returns the interquartile range (Q3 - Q1).
pub fn stats_iqr(data: &Vec[Int]) -> Int {
  return stats_q3(data) - stats_q1(data);
}

// -- Float64-based statistics ------------------------------------------------

/// Sum of a vector of Float64 values.
pub fn stats_sum_f(data: &Vec[Float64]) -> Float64 {
  var sum: Float64 = 0.0;
  var i: Int = 0;
  let len = data.len();
  while i < len {
    sum = sum + data[i];
    i = i + 1;
  };
  return sum;
}

/// Mean of a vector of Float64 values.
pub fn stats_mean_f(data: &Vec[Float64]) -> Float64 {
  let len = data.len();
  if len == 0 { return 0.0; };
  return stats_sum_f(data) / (len as Float64);
}

/// Population standard deviation of a vector of Float64 values.
pub fn stats_stddev_f_f(data: &Vec[Float64]) -> Float64 {
  let len = data.len();
  if len == 0 { return 0.0; };
  let mean = stats_mean_f(data);
  var variance: Float64 = 0.0;
  var i: Int = 0;
  while i < len {
    let diff = data[i] - mean;
    variance = variance + diff * diff;
    i = i + 1;
  };
  variance = variance / (len as Float64);
  return xiom.math.sqrt(variance);
}

// -- Covariance & Correlation ------------------------------------------------

/// Computes the population covariance between two vectors of equal length.
pub fn stats_covariance(a: &Vec[Int], b: &Vec[Int]) -> Float64 {
  let n = a.len();
  if n == 0 || b.len() != n { return 0.0; };
  let mean_a = stats_mean(a);
  let mean_b = stats_mean(b);
  var cov: Float64 = 0.0;
  var i: Int = 0;
  while i < n {
    cov = cov + ((a[i] as Float64) - (mean_a as Float64)) * ((b[i] as Float64) - (mean_b as Float64));
    i = i + 1;
  };
  return cov / (n as Float64);
}

/// Computes the Pearson correlation coefficient between two vectors.
pub fn stats_correlation(a: &Vec[Int], b: &Vec[Int]) -> Float64 {
  let var_a = stats_variance(a);
  let var_b = stats_variance(b);
  if var_a == 0.0 || var_b == 0.0 { return 0.0; };
  let cov = stats_covariance(a, b);
  let denom = xiom.math.sqrt(var_a) * xiom.math.sqrt(var_b);
  if denom == 0.0 { return 0.0; };
  return cov / denom;
}

// -- Histogram ---------------------------------------------------------------

/// Builds a histogram with the specified number of bins over [lo, hi].
/// Each bin counts values in [bin_start, bin_start + bin_width).
pub fn stats_histogram(data: &Vec[Int], bins: Int, lo: Int, hi: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if bins <= 0 || hi <= lo {
    return result;
  };
  var k: Int = 0;
  while k < bins {
    result.push(0);
    k = k + 1;
  };
  let width = hi - lo;
  var i: Int = 0;
  let dlen = data.len();
  while i < dlen {
    let val = data[i];
    if val >= lo && val < hi {
      var idx = ((val - lo) * bins) / width;
      if idx >= bins {
        idx = bins - 1;
      };
      if idx < 0 {
        idx = 0;
      };
      result[idx] = result[idx] + 1;
    };
    i = i + 1;
  };
  return result;
}

// -- Geometric Mean ----------------------------------------------------------

/// Computes the geometric mean using logarithms to avoid overflow.
/// Requires all values to be positive.
pub fn stats_geometric_mean(data: &Vec[Int]) -> Float64 {
  let n = data.len();
  if n == 0 { return 0.0; };
  var log_sum: Float64 = 0.0;
  var i: Int = 0;
  while i < n {
    let val = data[i];
    if val <= 0 { return 0.0; };
    log_sum = log_sum + xiom.math.ln(val as Float64);
    i = i + 1;
  };
  return xiom.math.exp(log_sum / (n as Float64));
}

// -- Harmonic Mean -----------------------------------------------------------

/// Computes the harmonic mean. Returns 0 if any value is <= 0.
pub fn stats_harmonic_mean(data: &Vec[Int]) -> Float64 {
  let n = data.len();
  if n == 0 { return 0.0; };
  var recip_sum: Float64 = 0.0;
  var i: Int = 0;
  while i < n {
    let val = data[i];
    if val <= 0 { return 0.0; };
    recip_sum = recip_sum + (1.0 / (val as Float64));
    i = i + 1;
  };
  return (n as Float64) / recip_sum;
}

// -- Z-score -----------------------------------------------------------------

/// Computes the z-score: (value - mean) / stddev.
pub fn stats_zscore(value: Int, mean: Float64, stddev: Float64) -> Float64 {
  if stddev == 0.0 { return 0.0; };
  return ((value as Float64) - mean) / stddev;
}

// -- Linear Regression -------------------------------------------------------

/// Computes the slope of the simple linear regression line y = mx + b.
pub fn stats_slope(x: &Vec[Int], y: &Vec[Int]) -> Float64 {
  let n = x.len();
  if n < 2 || y.len() != n { return 0.0; };
  let mean_x = stats_mean(x);
  let mean_y = stats_mean(y);
  var num: Float64 = 0.0;
  var den: Float64 = 0.0;
  var i: Int = 0;
  while i < n {
    let dx = (x[i] as Float64) - (mean_x as Float64);
    let dy = (y[i] as Float64) - (mean_y as Float64);
    num = num + dx * dy;
    den = den + dx * dx;
    i = i + 1;
  };
  if den == 0.0 { return 0.0; };
  return num / den;
}

/// Computes the intercept of the simple linear regression line y = mx + b.
pub fn stats_intercept(x: &Vec[Int], y: &Vec[Int]) -> Float64 {
  let mean_y = stats_mean(y);
  let mean_x = stats_mean(x);
  let m = stats_slope(x, y);
  return (mean_y as Float64) - m * (mean_x as Float64);
}

/// Computes the R-squared (coefficient of determination) for linear regression.
pub fn stats_r_squared(x: &Vec[Int], y: &Vec[Int]) -> Float64 {
  let n = x.len();
  if n < 2 || y.len() != n { return 0.0; };
  let mean_y = stats_mean(y);
  let m = stats_slope(x, y);
  let b = stats_intercept(x, y);
  var ss_res: Float64 = 0.0;
  var ss_tot: Float64 = 0.0;
  var i: Int = 0;
  while i < n {
    let predicted = m * (x[i] as Float64) + b;
    let residual = (y[i] as Float64) - predicted;
    ss_res = ss_res + residual * residual;
    let dy = (y[i] as Float64) - (mean_y as Float64);
    ss_tot = ss_tot + dy * dy;
    i = i + 1;
  };
  if ss_tot == 0.0 { return 0.0; };
  return 1.0 - (ss_res / ss_tot);
}


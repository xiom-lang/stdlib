// Smoke: xiom.math.series (sums, series, continued fractions, recurrences).
// Returns 0 on success.
//
// NOTE: the checks use INTERVAL COMPARISONS instead of difference-based
// tolerance, because arithmetic (e.g. `s - 1.644934`) on a value returned by
// a recursive catalog-module function traps with 0xC000001D (BUG 20 AVX-512
// codegen on Zen 2), while relational comparisons are safe.
use xiom.math;
use xiom.io;

// 1/(k+1)^2 for k = 0..: sum_{k=1..n} 1/k^2.
fn inv_sq(k: Int) -> Float64 {
  var kf = (k + 1) as Float64;
  return 1.0 / (kf * kf);
}

// lo <= x <= hi (comparisons only - safe on catalog-returned floats).
fn in_range(x: Float64, lo: Float64, hi: Float64) -> Bool {
  if x < lo { return false; }
  if x > hi { return false; }
  return true;
}

fn main() -> Int {
  // sum of 1/k^2 to 10000 = 1.644884 (within 1e-3 of zeta(2) ~ 1.644934)
  var s = math.series.series_sum(inv_sq, 10000);
  if !in_range(s, 1.6439, 1.6459) { io.println("series-sum"); return 1; }

  // power series: 1 + 2x + 3x^2 at x=2 -> 17
  var coeffs = Vec[Float64].new();
  coeffs.push(1.0);
  coeffs.push(2.0);
  coeffs.push(3.0);
  var ps = math.series.power_series(&coeffs, 2.0);
  if !in_range(ps, 16.999, 17.001) { io.println("power-series"); return 2; }

  // geometric series: 1 + 1/2 + ... 10 terms -> 1.998046875
  var gs = math.series.geometric_series(1.0, 0.5, 10);
  if !in_range(gs, 1.998, 2.0) { io.println("geometric"); return 3; }

  // arithmetic series: 1 + 3 + 5 + 7 + 9 = 25
  var asin_v = math.series.arithmetic_series(1.0, 2.0, 5);
  if !in_range(asin_v, 25.0, 25.0) { io.println("arithmetic"); return 4; }

  // harmonic(10) ~= 2.928968
  var h = math.series.harmonic(10);
  if !in_range(h, 2.9289, 2.9291) { io.println("harmonic"); return 5; }

  // continued fraction [2; 2, 2, 2] = 2 + 1/(2 + 1/(2 + 1/2)) ~= 2.416667
  var cfs = Vec[Float64].new();
  cfs.push(2.0);
  cfs.push(2.0);
  cfs.push(2.0);
  cfs.push(2.0);
  var cf = math.series.continued_fraction(&cfs);
  if !in_range(cf, 2.416, 2.417) { io.println("contfrac"); return 7; }

  // fib / fib_fast
  if math.series.fib(10) != 55 { io.println("fib-10"); return 8; }
  if math.series.fib(-1) != 0 { io.println("fib-neg"); return 9; }
  if math.series.fib_fast(20) != 6765 { io.println("fibfast-20"); return 10; }
  if math.series.fib_fast(0) != 0 { io.println("fibfast-0"); return 11; }

  io.println("smoke_math_series: OK");
  return 0;
}

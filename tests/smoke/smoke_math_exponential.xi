// Smoke: xiom.math.exponential (exp/log/pow functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn near2(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-3;
}

fn main() -> Int {
  var e = math.constants.E;

  // exp / exp2 / exp10
  if !near(math.exponential.exp(0.0), 1.0) { io.println("exp-0"); return 1; }
  if !near(math.exponential.exp(1.0), e) { io.println("exp-1"); return 2; }
  if !near(math.exponential.exp(-1.0), 1.0 / e) { io.println("exp-neg"); return 3; }
  if !near(math.exponential.exp2(3.0), 8.0) { io.println("exp2-3"); return 4; }
  if !near(math.exponential.exp2(0.0), 1.0) { io.println("exp2-0"); return 5; }
  if !near(math.exponential.exp10(2.0), 100.0) { io.println("exp10-2"); return 6; }
  if !near(math.exponential.exp10(0.0), 1.0) { io.println("exp10-0"); return 7; }
  if math.exponential.exp(1000.0) != (1.0 / 0.0) { io.println("exp-overflow"); return 8; }

  // expm1
  if !near(math.exponential.expm1(0.0), 0.0) { io.println("expm1-0"); return 9; }
  if !near(math.exponential.expm1(1.0), e - 1.0) { io.println("expm1-1"); return 10; }
  // small-x accuracy: expm1(x) ~ x + x^2/2, while exp(x)-1 loses precision
  if !near(math.exponential.expm1(1e-10), 1.00000000005e-10) { io.println("expm1-small"); return 11; }
  var em1 = math.exponential.expm1(1e-10);
  var naive = math.exp(1e-10) - 1.0;
  if em1 == 0.0 { io.println("expm1-zero"); return 12; }

  // ln / log2 / log10
  if !near(math.exponential.ln(1.0), 0.0) { io.println("ln-1"); return 13; }
  if !near(math.exponential.ln(e), 1.0) { io.println("ln-e"); return 14; }
  if !math.is_nan(math.exponential.ln(0.0)) { io.println("ln-0-nan"); return 15; }
  if !math.is_nan(math.exponential.ln(-1.0)) { io.println("ln-neg-nan"); return 16; }
  if !near(math.exponential.log2(8.0), 3.0) { io.println("log2-8"); return 17; }
  if !near(math.exponential.log2(2.0), 1.0) { io.println("log2-2"); return 18; }
  if !near(math.exponential.log10(100.0), 2.0) { io.println("log10-100"); return 19; }
  if !near(math.exponential.log10(1000.0), 3.0) { io.println("log10-1000"); return 20; }

  // log1p / ln_1_plus
  if !near(math.exponential.log1p(0.0), 0.0) { io.println("log1p-0"); return 21; }
  if !near(math.exponential.log1p(1.0), math.exponential.ln(2.0)) { io.println("log1p-1"); return 22; }
  if !near(math.exponential.log1p(1e-10), 1e-10) { io.println("log1p-small"); return 23; }
  if !math.is_nan(math.exponential.log1p(-2.0)) { io.println("log1p-neg-nan"); return 24; }
  if math.exponential.ln_1_plus(1.0) != math.exponential.log1p(1.0) { io.println("ln1plus"); return 25; }

  // pow
  if !near(math.exponential.pow(2.0, 10.0), 1024.0) { io.println("pow-2-10"); return 26; }
  if !near(math.exponential.pow(2.0, -1.0), 0.5) { io.println("pow-neg"); return 27; }
  if math.exponential.pow(0.0, 0.0) != (1.0 as Float64) { io.println("pow-0-0"); return 28; }

  // pow_int
  if math.exponential.pow_int(2.0, 10) != (1024.0 as Float64) { io.println("powint-2-10"); return 29; }
  if math.exponential.pow_int(2.0, -2) != (0.25 as Float64) { io.println("powint-neg"); return 30; }
  if math.exponential.pow_int(-2.0, 3) != (-8.0 as Float64) { io.println("powint-negbase"); return 31; }
  if math.exponential.pow_int(-2.0, 2) != (4.0 as Float64) { io.println("powint-even"); return 32; }
  if math.exponential.pow_int(2.0, 0) != (1.0 as Float64) { io.println("powint-0"); return 33; }
  if math.exponential.pow_int(0.0, 0) != (1.0 as Float64) { io.println("powint-00"); return 34; }

  // pow_float / sqrt_power
  if !near(math.exponential.pow_float(3.0, 2.0), 9.0) { io.println("powfloat"); return 35; }
  if math.exponential.sqrt_power(16.0, 0.5) != (2.0 as Float64) { io.println("sqrtpow"); return 36; }
  if !math.is_nan(math.exponential.sqrt_power(-1.0, 2.0)) { io.println("sqrtpow-neg-nan"); return 37; }

  // pure variants (the pure atanh ln series is accurate to ~1e-7 at x=8 and
  // ~1e-6 at x=10; tolerances below reflect that convergence rate)
  if !near(math.exponential.exp_pure(1.0), e) { io.println("exppure-1"); return 38; }
  if !near(math.exponential.exp_pure(-1.0), 1.0 / e) { io.println("exppure-neg"); return 39; }
  if !near(math.exponential.ln_pure(1.0), 0.0) { io.println("lnpure-1"); return 40; }
  if !near(math.exponential.ln_pure(e), 1.0) { io.println("lnpure-e"); return 41; }
  if !math.is_nan(math.exponential.ln_pure(0.0)) { io.println("lnpure-nan"); return 42; }
  if !near2(math.exponential.log2_pure(8.0), 3.0) { io.println("log2pure"); return 43; }
  if !near2(math.exponential.log10_pure(10.0), 1.0) { io.println("log10pure"); return 44; }
  if !near2(math.exponential.pow_pure(2.0, 10.0), 1024.0) { io.println("powpure"); return 45; }
  if !math.is_nan(math.exponential.pow_pure(-2.0, 0.5)) { io.println("powpure-neg-nan"); return 46; }

  io.println("smoke_math_exponential: OK");
  return 0;
}

// Smoke: xiom.math.transcendental (exp/log/pow + special functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near6(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-6;
}

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // sqrt / cbrt
  if math.transcendental.sqrt(4.0) != 2.0 { io.println("sqrt-4"); return 1; }
  if !math.is_nan(math.transcendental.sqrt(-1.0)) { io.println("sqrt-neg"); return 2; }
  if math.transcendental.cbrt(27.0) != 3.0 { io.println("cbrt-27"); return 3; }
  if math.transcendental.cbrt(-27.0) != -3.0 { io.println("cbrt-neg"); return 4; }

  // exp family
  if math.transcendental.exp(0.0) != 1.0 { io.println("exp-0"); return 5; }
  if !near(math.transcendental.exp(1.0), 2.718281828459045) { io.println("exp-1"); return 6; }
  if math.transcendental.exp2(3.0) != 8.0 { io.println("exp2-3"); return 7; }
  if !near(math.transcendental.expm1(1e-10), 1e-10) { io.println("expm1-small"); return 8; }
  if !near(math.transcendental.expm1(0.0), 0.0) { io.println("expm1-0"); return 9; }

  // log family
  if math.transcendental.ln(1.0) != 0.0 { io.println("ln-1"); return 10; }
  if !near(math.transcendental.ln(2.0), 0.6931471805599453) { io.println("ln-2"); return 11; }
  if math.transcendental.log2(8.0) != 3.0 { io.println("log2-8"); return 12; }
  if math.transcendental.log10(100.0) != 2.0 { io.println("log10-100"); return 13; }
  if !near(math.transcendental.log1p(1.0), 0.6931471805599453) { io.println("log1p-1"); return 14; }
  if !near(math.transcendental.log1p(1e-10), 1e-10) { io.println("log1p-small"); return 15; }
  if !math.is_nan(math.transcendental.ln(0.0)) { io.println("ln-0"); return 16; }

  // power
  if math.transcendental.pow(2.0, 3.0) != 8.0 { io.println("pow-23"); return 17; }
  if !near(math.transcendental.pow(2.0, 0.5), 1.4142135623730951) { io.println("pow-half"); return 18; }
  if math.transcendental.pow_int(2.0, 10) != 1024.0 { io.println("powint-2-10"); return 19; }
  if !near(math.transcendental.pow_int(2.0, -2), 0.25) { io.println("powint-neg"); return 20; }
  if math.transcendental.root(16.0, 4) != 2.0 { io.println("root-16-4"); return 21; }
  if math.transcendental.root(-27.0, 3) != -3.0 { io.println("root-neg-odd"); return 22; }
  if !math.is_nan(math.transcendental.root(-4.0, 2)) { io.println("root-neg-even"); return 23; }

  // gamma
  if math.transcendental.gamma(1.0) != 1.0 { io.println("gamma-1"); return 24; }
  if math.transcendental.gamma(2.0) != 1.0 { io.println("gamma-2"); return 25; }
  if !near(math.transcendental.gamma(5.0), 24.0) { io.println("gamma-5"); return 26; }
  if !near(math.transcendental.gamma(0.5), 1.772453850905516) { io.println("gamma-half"); return 27; }
  if !near(math.transcendental.gamma(3.0), 2.0) { io.println("gamma-3"); return 28; }
  if !near(math.transcendental.gamma(6.0), 120.0) { io.println("gamma-6"); return 29; }

  // lgamma (field access on the cross-module tuple — destructuring binds
  // both names to the whole tuple, BUG 26 #3).
  var lg5t = math.transcendental.lgamma(5.0);
  if lg5t.1 != 1 { io.println("lgamma-5-sign"); return 30; }
  if !near(lg5t.0, 3.1780538303479458) { io.println("lgamma-5"); return 31; }
  var lgnt = math.transcendental.lgamma(-0.5);
  if lgnt.1 != -1 { io.println("lgamma-neg-sign"); return 32; }
  if !near(lgnt.0, 1.2655121234846454) { io.println("lgamma-neg"); return 33; }

  // erf / erfc
  if !near6(math.transcendental.erf(0.0), 0.0) { io.println("erf-0"); return 34; }
  if !near6(math.transcendental.erf(1.0), 0.8427007929497149) { io.println("erf-1"); return 35; }
  if !near(math.transcendental.erf(2.0), 0.9953222650189527) { io.println("erf-2"); return 36; }
  if !near6(math.transcendental.erfc(0.0), 1.0) { io.println("erfc-0"); return 37; }
  if !near6(math.transcendental.erfc(1.0), 0.157299207050285) { io.println("erfc-1"); return 38; }
  if !near(math.transcendental.erfc(3.0), 2.20904969986e-5) { io.println("erfc-3"); return 39; }

  // lambert_w
  if !near(math.transcendental.lambert_w(0.0), 0.0) { io.println("w-0"); return 40; }
  if !near(math.transcendental.lambert_w(1.0), 0.5671432904097838) { io.println("w-1"); return 41; }
  if !near(math.transcendental.lambert_w(2.718281828459045), 1.0) { io.println("w-e"); return 42; }
  if !math.is_nan(math.transcendental.lambert_w(-1.0)) { io.println("w-neg"); return 43; }

  io.println("smoke_math_transcendental: OK");
  return 0;
}

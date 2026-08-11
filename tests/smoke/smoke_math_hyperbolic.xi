// Smoke: xiom.math.hyperbolic (hyperbolic + inverse hyperbolic functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // sinh / cosh / tanh known answers
  if math.hyperbolic.sinh(0.0) != (0.0 as Float64) { io.println("sinh-0"); return 1; }
  if math.hyperbolic.cosh(0.0) != (1.0 as Float64) { io.println("cosh-0"); return 2; }
  if math.hyperbolic.tanh(0.0) != (0.0 as Float64) { io.println("tanh-0"); return 3; }
  if !near(math.hyperbolic.sinh(1.0), 1.1752011936438014) { io.println("sinh-1"); return 4; }
  if !near(math.hyperbolic.cosh(1.0), 1.5430806348152437) { io.println("cosh-1"); return 5; }
  if !near(math.hyperbolic.tanh(1.0), 0.7615941559557649) { io.println("tanh-1"); return 6; }

  // identities
  if !near(math.hyperbolic.sinh(-1.0), -1.1752011936438014) { io.println("sinh-neg"); return 7; }
  if !near(math.hyperbolic.cosh(-1.0), 1.5430806348152437) { io.println("cosh-even"); return 8; }
  if !near(math.hyperbolic.tanh(-1.0), -0.7615941559557649) { io.println("tanh-odd"); return 9; }
  var c2 = math.hyperbolic.cosh(2.0) * math.hyperbolic.cosh(2.0) - math.hyperbolic.sinh(2.0) * math.hyperbolic.sinh(2.0);
  if !near(c2, 1.0) { io.println("cosh2-sinh2"); return 10; }
  if math.hyperbolic.tanh(30.0) != (1.0 as Float64) { io.println("tanh-sat"); return 11; }
  if math.hyperbolic.tanh(-30.0) != (-1.0 as Float64) { io.println("tanh-satneg"); return 12; }

  // csch / sech / coth
  if !near(math.hyperbolic.csch(1.0), 1.0 / 1.1752011936438014) { io.println("csch-1"); return 13; }
  if !near(math.hyperbolic.sech(1.0), 1.0 / 1.5430806348152437) { io.println("sech-1"); return 14; }
  if !near(math.hyperbolic.coth(1.0), 1.0 / 0.7615941559557649) { io.println("coth-1"); return 15; }
  if math.hyperbolic.csch(0.0) != (1.0 / 0.0) { io.println("csch-0"); return 16; }
  if math.hyperbolic.coth(0.0) != (1.0 / 0.0) { io.println("coth-0"); return 17; }
  if math.hyperbolic.sech(0.0) != (1.0 as Float64) { io.println("sech-0"); return 18; }

  // inverses
  if !near(math.hyperbolic.asinh(0.0), 0.0) { io.println("asinh-0"); return 19; }
  if !near(math.hyperbolic.asinh(1.0), 0.881373587019543) { io.println("asinh-1"); return 20; }
  if !near(math.hyperbolic.asinh(-1.0), -0.881373587019543) { io.println("asinh-neg"); return 21; }
  if !near(math.hyperbolic.acosh(1.0), 0.0) { io.println("acosh-1"); return 22; }
  if !near(math.hyperbolic.acosh(2.0), 1.3169578969248166) { io.println("acosh-2"); return 23; }
  if !near(math.hyperbolic.acosh(math.hyperbolic.cosh(1.0)), 1.0) { io.println("acosh-roundtrip"); return 24; }
  if !math.is_nan(math.hyperbolic.acosh(0.5)) { io.println("acosh-domain-nan"); return 25; }
  if !near(math.hyperbolic.atanh(0.0), 0.0) { io.println("atanh-0"); return 26; }
  if !near(math.hyperbolic.atanh(0.5), 0.5493061443340549) { io.println("atanh-0.5"); return 27; }
  if !near(math.hyperbolic.atanh(-0.5), -0.5493061443340549) { io.println("atanh-neg"); return 28; }
  if !math.is_nan(math.hyperbolic.atanh(2.0)) { io.println("atanh-domain-nan"); return 29; }
  if !near(math.hyperbolic.atanh(math.hyperbolic.tanh(0.7)), 0.7) { io.println("atanh-roundtrip"); return 30; }

  // pure variants
  if math.hyperbolic.sinh_pure(0.0) != (0.0 as Float64) { io.println("sinhpure-0"); return 31; }
  if math.hyperbolic.cosh_pure(0.0) != (1.0 as Float64) { io.println("coshpure-0"); return 32; }
  if math.hyperbolic.tanh_pure(0.0) != (0.0 as Float64) { io.println("tanhpure-0"); return 33; }
  if !near(math.hyperbolic.sinh_pure(1.0), 1.1752011936438014) { io.println("sinhpure-1"); return 34; }
  if !near(math.hyperbolic.cosh_pure(1.0), 1.5430806348152437) { io.println("coshpure-1"); return 35; }
  if !near(math.hyperbolic.tanh_pure(1.0), 0.7615941559557649) { io.println("tanhpure-1"); return 36; }
  if math.hyperbolic.tanh_pure(30.0) != (1.0 as Float64) { io.println("tanhpure-sat"); return 37; }

  io.println("smoke_math_hyperbolic: OK");
  return 0;
}

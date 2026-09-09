// Smoke: xiom.math.trig (trigonometric + angle conversion).
// Returns 0 on success.
//
// NOTE: the checks use INTERVAL COMPARISONS instead of difference-based
// tolerance, because arithmetic on a value returned by a catalog-module
// function traps with 0xC000001D (BUG 20 AVX-512 codegen on Zen 2), while
// relational comparisons are safe. sinh/cosh/tanh/atanh are documented stubs
// in this build (see the module).
use xiom.math;
use xiom.io;

// lo <= x <= hi (comparisons only - safe on catalog-returned floats).
fn in_range(x: Float64, lo: Float64, hi: Float64) -> Bool {
  if x < lo { return false; }
  if x > hi { return false; }
  return true;
}

fn main() -> Int {
  // known exact values
  if math.trig.sin(0.0) != (0.0 as Float64) { io.println("sin-0"); return 1; }
  if math.trig.cos(0.0) != (1.0 as Float64) { io.println("cos-0"); return 2; }
  if math.trig.tan(0.0) != (0.0 as Float64) { io.println("tan-0"); return 3; }

  // sin(pi/2) ~= 1, cos(pi) ~= -1, tan(pi/4) ~= 1
  var pi = math.constants.PI;
  var sp = math.trig.sin(pi / 2.0);
  if !in_range(sp, 0.999999, 1.000001) { io.println("sin-pi2"); return 4; }
  var cp = math.trig.cos(pi);
  if !in_range(cp, -1.000001, -0.999999) { io.println("cos-pi"); return 5; }
  var tp = math.trig.tan(pi / 4.0);
  if !in_range(tp, 0.999999, 1.000001) { io.println("tan-pi4"); return 6; }

  // inverse (libm-backed)
  var asin_v = math.trig.asin(0.0);
  if !in_range(asin_v, -1e-9, 1e-9) { io.println("asin-0"); return 7; }
  var ac = math.trig.acos(1.0);
  if !in_range(ac, -1e-9, 1e-9) { io.println("acos-1"); return 8; }
  var at = math.trig.atan(1.0);
  if !in_range(at, 0.7853, 0.7855) { io.println("atan-1"); return 9; }
  var a2 = math.trig.atan2(1.0, 1.0);
  if !in_range(a2, 0.7853, 0.7855) { io.println("atan2-11"); return 10; }

  // domain errors -> NaN
  var adom = math.trig.asin(2.0);
  if adom == adom { io.println("asin-domain"); return 11; }
  var acdom = math.trig.acos(-2.0);
  if acdom == acdom { io.println("acos-domain"); return 12; }
  var a2z = math.trig.atan2(0.0, 0.0);
  if a2z == a2z { io.println("atan2-zero"); return 13; }

  // inverse hyperbolic (libm compositions that are codegen-safe)
  var asinh0 = math.trig.asinh(0.0);
  if !in_range(asinh0, -1e-9, 1e-9) { io.println("asinh-0"); return 14; }
  var acosh1 = math.trig.acosh(1.0);
  if !in_range(acosh1, -1e-9, 1e-9) { io.println("acosh-1"); return 15; }

  // reciprocal functions
  var sec0 = math.trig.sec(0.0);
  if !in_range(sec0, 0.999999, 1.000001) { io.println("sec-0"); return 16; }
  var csc90 = math.trig.csc(pi / 2.0);
  if !in_range(csc90, 0.999999, 1.000001) { io.println("csc-pi2"); return 17; }
  var cot45 = math.trig.cot(pi / 4.0);
  if !in_range(cot45, 0.999999, 1.000001) { io.println("cot-pi4"); return 18; }

  // degrees / radians and degree variants
  var d90 = math.trig.degrees(pi / 2.0);
  if !in_range(d90, 89.999, 90.001) { io.println("degrees"); return 19; }
  var r180 = math.trig.radians(180.0);
  if !in_range(r180, 3.1415, 3.1417) { io.println("radians"); return 20; }
  var sd = math.trig.sin_deg(90.0);
  if !in_range(sd, 0.999999, 1.000001) { io.println("sin-deg"); return 21; }
  var cd = math.trig.cos_deg(0.0);
  if !in_range(cd, 0.999999, 1.000001) { io.println("cos-deg"); return 22; }
  var td = math.trig.tan_deg(45.0);
  if !in_range(td, 0.999999, 1.000001) { io.println("tan-deg"); return 23; }

  io.println("smoke_math_trig: OK");
  return 0;
}

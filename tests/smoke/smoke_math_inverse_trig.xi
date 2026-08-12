// Smoke: xiom.math.inverse_trig.
// Returns 0 on success.
//
// NOTE: the checks use INTERVAL COMPARISONS instead of difference-based
// tolerance, because arithmetic on a value returned by a catalog-module
// function traps with 0xC000001D (BUG 20 AVX-512 codegen on Zen 2), while
// relational comparisons are safe.
use xiom.math;
use xiom.io;

// lo <= x <= hi (comparisons only - safe on catalog-returned floats).
fn in_range(x: Float64, lo: Float64, hi: Float64) -> Bool {
  if x < lo { return false; }
  if x > hi { return false; }
  return true;
}

fn main() -> Int {
  var pi = math.constants.PI;

  // libm-backed variants
  var as = math.inverse_trig.asin(0.0);
  if !in_range(as, -1e-9, 1e-9) { io.println("asin-0"); return 1; }
  var ac = math.inverse_trig.acos(1.0);
  if !in_range(ac, -1e-9, 1e-9) { io.println("acos-1"); return 2; }
  var at = math.inverse_trig.atan(1.0);
  if !in_range(at, 0.7853, 0.7855) { io.println("atan-1"); return 3; }
  var a2 = math.inverse_trig.atan2(1.0, 1.0);
  if !in_range(a2, 0.7853, 0.7855) { io.println("atan2-11"); return 4; }
  var as05 = math.inverse_trig.asin(0.5);
  if !in_range(as05, 0.5235, 0.5237) { io.println("asin-0.5"); return 5; }

  // domain errors -> NaN
  var adom = math.inverse_trig.asin(2.0);
  if adom == adom { io.println("asin-domain"); return 6; }
  var acdom = math.inverse_trig.acos(-2.0);
  if acdom == acdom { io.println("acos-domain"); return 7; }
  var a2z = math.inverse_trig.atan2(0.0, 0.0);
  if a2z == a2z { io.println("atan2-zero"); return 8; }

  // radian/degree variants and arg
  var a2r = math.inverse_trig.atan2_radians(1.0, 1.0);
  if !in_range(a2r, 0.7853, 0.7855) { io.println("atan2-rad"); return 14; }
  var a2d = math.inverse_trig.atan2_degrees(1.0, 1.0);
  if !in_range(a2d, 44.999, 45.001) { io.println("atan2-deg"); return 15; }
  var ar = math.inverse_trig.arg(1.0, 1.0);
  if !in_range(ar, 0.7853, 0.7855) { io.println("arg"); return 16; }

  io.println("smoke_math_inverse_trig: OK");
  return 0;
}

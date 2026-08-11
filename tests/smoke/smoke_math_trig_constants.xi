// Smoke: xiom.math.trigonometric_constants (conversion factors + turn consts).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  var pi = math.constants.PI;
  var tau = math.constants.TAU;

  // Conversion factors: deg_to_rad * 180 == pi ; rad_to_deg * pi == 180
  var d1 = math.trigonometric_constants.DEG_TO_RAD * 180.0 - pi;
  if d1 < 0.0 { d1 = -d1; }
  if d1 > 1e-15 { io.println("deg2rad"); return 1; }
  var d2 = math.trigonometric_constants.RAD_TO_DEG * pi - 180.0;
  if d2 < 0.0 { d2 = -d2; }
  if d2 > 1e-12 { io.println("rad2deg"); return 2; }
  var d3 = math.trigonometric_constants.DEG_TO_RAD * math.trigonometric_constants.RAD_TO_DEG - 1.0;
  if d3 < 0.0 { d3 = -d3; }
  if d3 > 1e-15 { io.println("factor-roundtrip"); return 3; }

  // Float32 factors are non-zero and consistent with Float64.
  var f32a = math.trigonometric_constants.DEG_TO_RAD32;
  if f32a == (0 as Float32) { io.println("deg32-zero"); return 4; }
  var f32b = math.trigonometric_constants.RAD_TO_DEG32;
  if f32b == (0 as Float32) { io.println("rad32-zero"); return 5; }
  var f32prod = (f32a as Float64) * (f32b as Float64);
  var f32err = f32prod - 1.0;
  if f32err < 0.0 { f32err = -f32err; }
  if f32err > 1e-6 { io.println("f32-roundtrip"); return 6; }

  // PI fractions.
  var e1 = math.trigonometric_constants.PI_2 * 2.0 - pi;
  if e1 < 0.0 { e1 = -e1; }
  if e1 > 1e-15 { io.println("pi2"); return 7; }
  var e2 = math.trigonometric_constants.PI_4 * 4.0 - pi;
  if e2 < 0.0 { e2 = -e2; }
  if e2 > 1e-15 { io.println("pi4"); return 8; }
  var e3 = math.trigonometric_constants.PI_8 * 8.0 - pi;
  if e3 < 0.0 { e3 = -e3; }
  if e3 > 1e-14 { io.println("pi8"); return 9; }
  var e4 = math.trigonometric_constants.PI_3 * 3.0 - pi;
  if e4 < 0.0 { e4 = -e4; }
  if e4 > 1e-15 { io.println("pi3"); return 10; }
  var e5 = math.trigonometric_constants.PI_6 * 6.0 - pi;
  if e5 < 0.0 { e5 = -e5; }
  if e5 > 1e-15 { io.println("pi6"); return 11; }

  // TAU fractions.
  var t1 = math.trigonometric_constants.TAU_2 * 2.0 - tau;
  if t1 < 0.0 { t1 = -t1; }
  if t1 > 1e-15 { io.println("tau2"); return 12; }
  var t2 = math.trigonometric_constants.TAU_4 * 4.0 - tau;
  if t2 < 0.0 { t2 = -t2; }
  if t2 > 1e-15 { io.println("tau4"); return 13; }
  var t3 = math.trigonometric_constants.TAU_8 * 8.0 - tau;
  if t3 < 0.0 { t3 = -t3; }
  if t3 > 1e-14 { io.println("tau8"); return 14; }
  var t4 = math.trigonometric_constants.TAU_3 * 3.0 - tau;
  if t4 < 0.0 { t4 = -t4; }
  if t4 > 1e-15 { io.println("tau3"); return 15; }
  var t5 = math.trigonometric_constants.TAU_6 * 6.0 - tau;
  if t5 < 0.0 { t5 = -t5; }
  if t5 > 1e-15 { io.println("tau6"); return 16; }
  var t6 = math.trigonometric_constants.TAU_12 * 12.0 - tau;
  if t6 < 0.0 { t6 = -t6; }
  if t6 > 1e-15 { io.println("tau12"); return 17; }

  // Consistency between PI and TAU families.
  var c1 = math.trigonometric_constants.TAU_2 - pi;
  if c1 < 0.0 { c1 = -c1; }
  if c1 > 1e-15 { io.println("tau2-eq-pi"); return 18; }
  var c2 = math.trigonometric_constants.TAU_4 - math.trigonometric_constants.PI_2;
  if c2 < 0.0 { c2 = -c2; }
  if c2 > 1e-15 { io.println("tau4-eq-pi2"); return 19; }
  var c3 = math.trigonometric_constants.TAU_12 - math.trigonometric_constants.PI_6;
  if c3 < 0.0 { c3 = -c3; }
  if c3 > 1e-15 { io.println("tau12-eq-pi6"); return 20; }

  io.println("smoke_math_trig_constants: OK");
  return 0;
}

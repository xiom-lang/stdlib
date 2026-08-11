// Smoke: xiom.math.rounding (rounding and fraction decomposition).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // floor / ceil
  if math.rounding.floor(2.7) != (2.0 as Float64) { io.println("floor-1"); return 1; }
  if math.rounding.floor(-2.7) != (-3.0 as Float64) { io.println("floor-neg"); return 2; }
  if math.rounding.floor(3.0) != (3.0 as Float64) { io.println("floor-int"); return 3; }
  if math.rounding.ceil(2.3) != (3.0 as Float64) { io.println("ceil-1"); return 4; }
  if math.rounding.ceil(-2.3) != (-2.0 as Float64) { io.println("ceil-neg"); return 5; }
  if math.rounding.ceil(3.0) != (3.0 as Float64) { io.println("ceil-int"); return 6; }

  // round (ties away from zero)
  if math.rounding.round(2.5) != (3.0 as Float64) { io.println("round-half"); return 7; }
  if math.rounding.round(-2.5) != (-3.0 as Float64) { io.println("round-halfneg"); return 8; }
  if math.rounding.round(2.4) != (2.0 as Float64) { io.println("round-dn"); return 9; }
  if math.rounding.round(2.6) != (3.0 as Float64) { io.println("round-up"); return 10; }

  // trunc
  if math.rounding.trunc(2.7) != (2.0 as Float64) { io.println("trunc-1"); return 11; }
  if math.rounding.trunc(-2.7) != (-2.0 as Float64) { io.println("trunc-neg"); return 12; }

  // fract
  if math.rounding.fract(2.5) != (0.5 as Float64) { io.println("fract-1"); return 13; }
  if math.rounding.fract(-2.5) != (-0.5 as Float64) { io.println("fract-neg"); return 14; }

  // modf
  var mf = math.rounding.modf(2.5);
  if mf.0 != (0.5 as Float64) { io.println("modf-f"); return 15; }
  if mf.1 != (2.0 as Float64) { io.println("modf-i"); return 16; }
  var mf2 = math.rounding.modf(-2.5);
  if mf2.0 != (-0.5 as Float64) { io.println("modf-f2"); return 17; }
  if mf2.1 != (-2.0 as Float64) { io.println("modf-i2"); return 18; }

  // pure variants agree with libm variants
  var pure_xs = [2.7, -2.7, 3.0, -3.0, 0.5, -0.5, 1234.5678];
  var i = 0;
  while i < 7 {
    var x = pure_xs[i];
    if math.rounding.floor_pure(x) != math.rounding.floor(x) { io.println("fpure"); return 19; }
    if math.rounding.ceil_pure(x) != math.rounding.ceil(x) { io.println("cpure"); return 20; }
    if math.rounding.round_pure(x) != math.rounding.round(x) { io.println("rpure"); return 21; }
    if math.rounding.trunc_pure(x) != math.rounding.trunc(x) { io.println("tpure"); return 22; }
    if math.rounding.fract_pure(x) != math.rounding.fract(x) { io.println("fractpure"); return 23; }
    i = i + 1;
  }

  // integer_part / frac_part aliases
  if math.rounding.integer_part(2.7) != (2.0 as Float64) { io.println("intpart"); return 24; }
  if !near(math.rounding.frac_part(2.7), 0.7) { io.println("fracpart"); return 25; }

  // round_to
  if !near(math.rounding.round_to(3.14159, 2), 3.14) { io.println("rto-2"); return 26; }
  if !near(math.rounding.round_to(2.675, 2), 2.68) { io.println("rto-2b"); return 27; }
  if math.rounding.round_to(1234.5, 0) != (1235.0 as Float64) { io.println("rto-0"); return 28; }
  if math.rounding.round_to(1234.5, -2) != (1200.0 as Float64) { io.println("rto-neg"); return 29; }

  // round_nearest (ties to even)
  if math.rounding.round_nearest(2.5) != 2 { io.println("rn-2.5"); return 30; }
  if math.rounding.round_nearest(3.5) != 4 { io.println("rn-3.5"); return 31; }
  if math.rounding.round_nearest(-2.5) != -2 { io.println("rn--2.5"); return 32; }
  if math.rounding.round_nearest(-3.5) != -4 { io.println("rn--3.5"); return 33; }
  if math.rounding.round_nearest(2.4) != 2 { io.println("rn-2.4"); return 34; }
  if math.rounding.round_nearest(2.6) != 3 { io.println("rn-2.6"); return 35; }
  if math.rounding.round_nearest(3.0) != 3 { io.println("rn-int"); return 36; }

  io.println("smoke_math_rounding: OK");
  return 0;
}

// Smoke: xiom.math.roots (root extraction + distance/norm functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // sqrt
  if math.roots.sqrt(4.0) != (2.0 as Float64) { io.println("sqrt-4"); return 1; }
  if math.roots.sqrt(0.0) != (0.0 as Float64) { io.println("sqrt-0"); return 2; }
  if math.roots.sqrt(2.0) * math.roots.sqrt(2.0) - 2.0 > 1e-9 { io.println("sqrt-2"); return 3; }
  if !math.is_nan(math.roots.sqrt(-1.0)) { io.println("sqrt-neg-nan"); return 4; }

  // cbrt
  if math.roots.cbrt(27.0) != (3.0 as Float64) { io.println("cbrt-27"); return 5; }
  if math.roots.cbrt(-27.0) != (-3.0 as Float64) { io.println("cbrt-neg"); return 6; }
  if math.roots.cbrt(0.0) != (0.0 as Float64) { io.println("cbrt-0"); return 7; }
  if !near(math.roots.cbrt(8.0), 2.0) { io.println("cbrt-8"); return 8; }

  // nth_root
  if math.roots.nth_root(16.0, 4) != (2.0 as Float64) { io.println("nth-16-4"); return 9; }
  if math.roots.nth_root(27.0, 3) != (3.0 as Float64) { io.println("nth-27-3"); return 10; }
  if math.roots.nth_root(-27.0, 3) != (-3.0 as Float64) { io.println("nth-neg-odd"); return 11; }
  if !math.is_nan(math.roots.nth_root(-4.0, 2)) { io.println("nth-neg-even-nan"); return 12; }
  if math.roots.nth_root(0.0, 3) != (0.0 as Float64) { io.println("nth-0"); return 13; }

  // sqrt_pure / cbrt_pure
  if math.roots.sqrt_pure(4.0) != (2.0 as Float64) { io.println("sqrtpure-4"); return 14; }
  if !math.is_nan(math.roots.sqrt_pure(-1.0)) { io.println("sqrtpure-neg-nan"); return 15; }
  if !near(math.roots.cbrt_pure(27.0), 3.0) { io.println("cbrtpure-27"); return 16; }
  if !near(math.roots.cbrt_pure(-27.0), -3.0) { io.println("cbrtpure-neg"); return 17; }
  if !near(math.roots.cbrt_pure(2.0), 1.2599210498948732) { io.println("cbrtpure-2"); return 18; }

  // is_square / is_cube
  if !math.roots.is_square(16) { io.println("issq-16"); return 19; }
  if !math.roots.is_square(0) { io.println("issq-0"); return 20; }
  if !math.roots.is_square(1) { io.println("issq-1"); return 21; }
  if math.roots.is_square(17) { io.println("issq-17"); return 22; }
  if math.roots.is_square(-4) { io.println("issq-neg"); return 23; }
  if !math.roots.is_cube(27) { io.println("iscube-27"); return 24; }
  if !math.roots.is_cube(0) { io.println("iscube-0"); return 25; }
  if !math.roots.is_cube(1) { io.println("iscube-1"); return 26; }
  if math.roots.is_cube(28) { io.println("iscube-28"); return 27; }

  // integer_sqrt / integer_cbrt
  if math.roots.integer_sqrt(16) != 4 { io.println("isqrt-16"); return 28; }
  if math.roots.integer_sqrt(17) != 4 { io.println("isqrt-17"); return 29; }
  if math.roots.integer_sqrt(0) != 0 { io.println("isqrt-0"); return 30; }
  if math.roots.integer_sqrt(9223372036854775807) != 3037000499 { io.println("isqrt-max"); return 31; }
  if math.roots.integer_cbrt(27) != 3 { io.println("icbrt-27"); return 32; }
  if math.roots.integer_cbrt(28) != 3 { io.println("icbrt-28"); return 33; }
  if math.roots.integer_cbrt(0) != 0 { io.println("icbrt-0"); return 34; }
  if math.roots.integer_cbrt(9223372036854775807) != 2097151 { io.println("icbrt-max"); return 35; }
  var big = 1000000000;
  if math.roots.integer_cbrt(big) != 1000 { io.println("icbrt-1e9"); return 36; }

  // hypot
  if math.roots.hypot(3.0, 4.0) != (5.0 as Float64) { io.println("hypot-34"); return 37; }
  if math.roots.hypot(0.0, 0.0) != (0.0 as Float64) { io.println("hypot-0"); return 38; }
  var h1 = math.roots.hypot(1e308, 1e308);
  if h1 == (1.0 / 0.0) { io.println("hypot-overflow"); return 39; }
  if h1 < 1e308 { io.println("hypot-too-small"); return 39; }

  // hypot3
  if math.roots.hypot3(1.0, 2.0, 2.0) != (3.0 as Float64) { io.println("hypot3-122"); return 40; }
  if math.roots.hypot3(0.0, 0.0, 0.0) != (0.0 as Float64) { io.println("hypot3-0"); return 41; }
  var h3 = math.roots.hypot3(1e308, 1e308, 1e308);
  if h3 == (1.0 / 0.0) { io.println("hypot3-overflow"); return 42; }
  if h3 < 1e308 { io.println("hypot3-too-small"); return 42; }

  // norm2 / norm3
  if math.roots.norm2(3.0, 4.0) != (5.0 as Float64) { io.println("norm2"); return 43; }
  if math.roots.norm3(1.0, 2.0, 2.0) != (3.0 as Float64) { io.println("norm3"); return 44; }

  io.println("smoke_math_roots: OK");
  return 0;
}

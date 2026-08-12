// Smoke: xiom.math.integral (numerical quadrature).
// Returns 0 on success.
//
// NOTE: the checks use INTERVAL COMPARISONS instead of difference-based
// tolerance, because arithmetic on a value returned by a recursive
// catalog-module function traps with 0xC000001D (BUG 20 AVX-512 codegen on
// Zen 2), while relational comparisons are safe.
use xiom.math;
use xiom.io;

fn sq(x: Float64) -> Float64 {
  return x * x;
}

fn fourth(x: Float64) -> Float64 {
  return x * x * x * x;
}

// lo <= x <= hi (comparisons only - safe on catalog-returned floats).
fn in_range(x: Float64, lo: Float64, hi: Float64) -> Bool {
  if x < lo { return false; }
  if x > hi { return false; }
  return true;
}

fn main() -> Int {
  // trapezoid: x^2 over [0,1] with 100 intervals ~= 0.33335
  var t = math.integral.integrate_trapezoid(sq, 0.0, 1.0, 100);
  if !in_range(t, 0.3333, 0.3334) { io.println("trapezoid"); return 1; }

  // riemann (left): x^2 over [0,1] with 1000 intervals ~= 0.3328
  var r = math.integral.integrate_riemann(sq, 0.0, 1.0, 1000);
  if !in_range(r, 0.3325, 0.3330) { io.println("riemann"); return 2; }

  // midpoint: x^2 over [0,1] with 100 intervals ~= 0.333333
  var m = math.integral.integrate_midpoint(sq, 0.0, 1.0, 100);
  if !in_range(m, 0.3333, 0.3334) { io.println("midpoint"); return 3; }

  // simpson: x^4 over [0,1] = 0.2
  var s = math.integral.integrate_simpson(fourth, 0.0, 1.0, 8);
  if !in_range(s, 0.1999, 0.2001) { io.println("simpson"); return 4; }

  // Gauss-Legendre: x^2 over [0,1] exact with n >= 2
  var gl = math.integral.integrate_gauss_legendre(sq, 0.0, 1.0, 4);
  if !in_range(gl, 0.3333, 0.3334) { io.println("gauss-legendre"); return 6; }

  // definite integral (default high accuracy)
  var di = math.integral.definite_integral(sq, 0.0, 1.0);
  if !in_range(di, 0.3333, 0.3334) { io.println("definite"); return 7; }

  io.println("smoke_math_integral: OK");
  return 0;
}

// Smoke: xiom.math.numerical (root finding, interpolation, quadrature, opt).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-6;
}

fn sqminus2(x: Float64) -> Float64 {
  return x * x - 2.0;
}

fn sqprime(x: Float64) -> Float64 {
  return 2.0 * x;
}

fn idmap(x: Float64) -> Float64 {
  return x;
}

fn fzero(x: Float64) -> Float64 {
  return x * x * x - x;
}

fn lin(x: Float64) -> Float64 {
  return x;
}

fn quad(x: Float64) -> Float64 {
  return (x - 1.0) * (x - 1.0);
}

fn main() -> Int {
  // Root finding: sqrt(2) ~= 1.41421356.
  var r1 = math.numerical.bisection(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r1, 1.414213562) { io.println("bisection"); return 1; }
  var r2 = math.numerical.bisection_root(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r2, 1.414213562) { io.println("bisection-root"); return 2; }
  var r3 = math.numerical.newton(sqminus2, sqprime, 1.5, 1e-9);
  if !near(r3, 1.414213562) { io.println("newton"); return 3; }
  var r4 = math.numerical.newton_root(sqminus2, sqprime, 1.5, 1e-9);
  if !near(r4, 1.414213562) { io.println("newton-root"); return 4; }
  var r5 = math.numerical.secant(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r5, 1.414213562) { io.println("secant"); return 5; }
  var r6 = math.numerical.falsi(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r6, 1.414213562) { io.println("falsi"); return 6; }
  var r7 = math.numerical.brent(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r7, 1.414213562) { io.println("brent"); return 7; }
  var r8 = math.numerical.solver_single(sqminus2, 1.0, 2.0, 1e-9);
  if !near(r8, 1.414213562) { io.println("solver-single"); return 8; }
  var r9 = math.numerical.fixed_point(ffp, 1.5, 1e-9);
  if !near(r9, 1.414213562) { io.println("fixed-point"); return 9; }
  var r10 = math.numerical.steffensen(sqminus2, 1.5, 1e-9);
  if !near(r10, 1.414213562) { io.println("steffensen"); return 10; }

  // Interpolation.
  var xs = Vec[Float64].new();
  xs.push(0.0);
  xs.push(1.0);
  xs.push(2.0);
  var ys = Vec[Float64].new();
  ys.push(0.0);
  ys.push(2.0);
  ys.push(4.0);
  var il = math.numerical.interp_linear(&xs, &ys, 0.5);
  if !near(il, 1.0) { io.println("interp-linear"); return 11; }
  var il2 = math.numerical.interp_linear(&xs, &ys, 1.5);
  if !near(il2, 3.0) { io.println("interp-linear-2"); return 12; }

  var xq = Vec[Float64].new();
  xq.push(0.0);
  xq.push(1.0);
  xq.push(2.0);
  var yq = Vec[Float64].new();
  yq.push(1.0);
  yq.push(3.0);
  yq.push(9.0);
  var ip = math.numerical.interp_polynomial(&xq, &yq, 2.5);
  if !near(ip, 13.5) { io.println("interp-poly"); return 13; }
  var ip2 = math.numerical.interp_polynomial(&xq, &yq, 1.5);
  if !near(ip2, 5.5) { io.println("interp-poly-2"); return 14; }

  var xc = Vec[Float64].new();
  xc.push(0.0);
  xc.push(1.0);
  xc.push(2.0);
  var yc = Vec[Float64].new();
  yc.push(0.0);
  yc.push(1.0);
  yc.push(0.0);
  var ic = math.numerical.interp_cubic(&xc, &yc, 0.0);
  if !near(ic, 0.0) { io.println("interp-cubic-knot0"); return 15; }
  var ic2 = math.numerical.interp_cubic(&xc, &yc, 1.0);
  if !near(ic2, 1.0) { io.println("interp-cubic-knot1"); return 16; }
  var ic3 = math.numerical.interp_cubic(&xc, &yc, 2.0);
  if !near(ic3, 0.0) { io.println("interp-cubic-knot2"); return 17; }
  var isp = math.numerical.interp_spline(&xc, &yc, 1.0);
  if !near(isp, 1.0) { io.println("interp-spline"); return 18; }

  var xh = Vec[Float64].new();
  xh.push(0.0);
  xh.push(1.0);
  var yh = Vec[Float64].new();
  yh.push(0.0);
  yh.push(1.0);
  var dh = Vec[Float64].new();
  dh.push(0.0);
  dh.push(0.0);
  var ih = math.numerical.interp_hermite(&xh, &yh, &dh, 0.5);
  if !near(ih, 0.5) { io.println("interp-hermite"); return 19; }

  // Quadrature of x over [0, 1] == 0.5.
  var qt = math.numerical.quadrature_trapezoid(lin, 0.0, 1.0, 100);
  if !near(qt, 0.5) { io.println("quad-trapezoid"); return 20; }
  var qs = math.numerical.quadrature_simpson(lin, 0.0, 1.0, 100);
  if !near(qs, 0.5) { io.println("quad-simpson"); return 21; }
  var qg = math.numerical.quadrature_gauss(lin, 0.0, 1.0, 3);
  if !near(qg, 0.5) { io.println("quad-gauss"); return 22; }
  var qa = math.numerical.quadrature_adaptive(lin, 0.0, 1.0, 1e-9);
  if !near(qa, 0.5) { io.println("quad-adaptive"); return 23; }
  var qm = math.numerical.quadrature_monte_carlo(lin, 0.0, 1.0, 2000);
  var qmd = qm - 0.5;
  if qmd < 0.0 { qmd = -qmd; }
  if qmd > 0.1 { io.println("quad-montecarlo"); return 24; }

  // Univariate optimization: (x-1)^2 over [-5, 5] minimized at 1.
  var og = math.numerical.optimize_golden(quad, -5.0, 5.0, 1e-9);
  if !near(og, 1.0) { io.println("opt-golden"); return 25; }
  var ot = math.numerical.optimize_ternary(quad, -5.0, 5.0, 1e-9);
  if !near(ot, 1.0) { io.println("opt-ternary"); return 26; }

  io.println("smoke_math_numerical: OK");
  return 0;
}

// Newton-style fixed-point map for sqrt(2): x = (x + 2/x) / 2.
fn ffp(x: Float64) -> Float64 {
  return (x + 2.0 / x) * 0.5;
}

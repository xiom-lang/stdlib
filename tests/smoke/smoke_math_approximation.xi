// Smoke: xiom.math.approximation (interpolation, extrapolation, fits, splines).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-6;
}

fn sq(x: Float64) -> Float64 {
  return x * x;
}

fn expfn(x: Float64) -> Float64 {
  return math.exp(x);
}

fn main() -> Int {
  // interpolation / extrapolation (scalar results, fully verifiable).
  var xs = Vec[Float64].new();
  xs.push(0.0);
  xs.push(1.0);
  xs.push(2.0);
  var ys = Vec[Float64].new();
  ys.push(0.0);
  ys.push(2.0);
  ys.push(4.0);
  var iv = math.approximation.interpolation(&xs, &ys, 0.5);
  if !near(iv, 1.0) { io.println("interp"); return 1; }
  var ev1 = math.approximation.extrapolation(&xs, &ys, 3.0);
  if !near(ev1, 6.0) { io.println("extrap-high"); return 2; }
  var ev2 = math.approximation.extrapolation(&xs, &ys, -1.0);
  if !near(ev2, -2.0) { io.println("extrap-low"); return 3; }

  // polynomial_approx: quadratic data, degree 2 -> 3 coefficients.
  var xq = Vec[Float64].new();
  xq.push(0.0);
  xq.push(1.0);
  xq.push(2.0);
  xq.push(3.0);
  var yq = Vec[Float64].new();
  yq.push(1.0);
  yq.push(3.0);
  yq.push(9.0);
  yq.push(19.0);
  var pa = math.approximation.polynomial_approx(&xq, &yq, 2);
  if pa.len() != 3 { io.println("poly-approx-len"); return 4; }

  // rational_approx: 1/(1+x) on [0,1], orders (1,1) -> 3 coefficients.
  var xr = Vec[Float64].new();
  xr.push(0.0);
  xr.push(0.5);
  xr.push(1.0);
  var yr = Vec[Float64].new();
  yr.push(1.0);
  yr.push(0.6666666666666666);
  yr.push(0.5);
  var ra = math.approximation.rational_approx(&xr, &yr, 1, 1);
  if ra.len() != 3 { io.println("rational-approx-len"); return 5; }

  // trigonometric_approx: constant data, 1 harmonic -> 3 coefficients.
  var xt = Vec[Float64].new();
  xt.push(0.0);
  xt.push(1.0);
  xt.push(2.0);
  xt.push(3.0);
  var yt = Vec[Float64].new();
  yt.push(1.0);
  yt.push(1.0);
  yt.push(1.0);
  yt.push(1.0);
  var ta = math.approximation.trigonometric_approx(&xt, &yt, 1);
  if ta.len() != 3 { io.println("trig-approx-len"); return 6; }

  // exponential_approx: e^x data -> [a, b] with a ~ 1, b ~ 1.
  var xe = Vec[Float64].new();
  xe.push(0.0);
  xe.push(1.0);
  xe.push(2.0);
  var ye = Vec[Float64].new();
  ye.push(1.0);
  ye.push(2.718281828459045);
  ye.push(7.38905609893065);
  var ea = math.approximation.exponential_approx(&xe, &ye);
  if ea.len() != 2 { io.println("exp-approx-len"); return 7; }

  // chebyshev_approx: x^2 on [-1, 1], degree 2 -> 3 coefficients.
  var ca = math.approximation.chebyshev_approx(sq, -1.0, 1.0, 2);
  if ca.len() != 3 { io.println("cheb-len"); return 8; }

  // least_squares: A x = b with A = [[1,1],[1,2],[1,3]], b = [2,3,4]
  // -> x = [1, 1].
  var ls_a = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(1.0);
  r0.push(1.0);
  var r1 = Vec[Float64].new();
  r1.push(1.0);
  r1.push(2.0);
  var r2 = Vec[Float64].new();
  r2.push(1.0);
  r2.push(3.0);
  ls_a.push(r0);
  ls_a.push(r1);
  ls_a.push(r2);
  var ls_b = Vec[Float64].new();
  ls_b.push(2.0);
  ls_b.push(3.0);
  ls_b.push(4.0);
  // least_squares core blocked: TODO(compiler) BUG 26 #1 — by-ref
  // Vec[Vec[Float64]] element reads return garbage data pointers (len fields
  // are correct), so the normal-equation core cannot run; only the
  // empty-input guard is assertable until the compiler fix lands.
  var empty_a = Vec[Vec[Float64]].new();
  var empty_b = Vec[Float64].new();
  if math.approximation.least_squares(&empty_a, &empty_b).len() != 0 { io.println("least-squares-empty"); return 9; }

  // minimax / remez: x^2 on [-1, 1], degree 2 -> 3 coefficients.
  var mm = math.approximation.minimax(sq, -1.0, 1.0, 2);
  if mm.len() != 3 { io.println("minimax-len"); return 10; }
  var rz = math.approximation.remez(sq, -1.0, 1.0, 2);
  if rz.len() != 3 { io.println("remez-len"); return 11; }

  // pade_approx: exp(x), (1, 1) at 0 -> 3 coefficients.
  var pa2 = math.approximation.pade_approx(expfn, 1, 1, 0.0);
  if pa2.len() != 3 { io.println("pade-len"); return 12; }

  // spline_approx: 3 points -> 2 cubic segments.
  var sa = math.approximation.spline_approx(&xs, &ys);
  if sa.len() != 2 { io.println("spline-approx-len"); return 13; }

  // best_approx: x^2 in basis {1, x, x^2} on [0, 1] -> 3 coefficients.
  var basis = Vec[fn(Float64) -> Float64].new();
  basis.push(const1);
  basis.push(idmap);
  basis.push(sq);
  // best_approx core blocked: TODO(compiler) BUG 26 #2 — Vec[fn] element
  // reads return garbage, so only the empty-basis guard is assertable.
  var empty_basis = Vec[fn(Float64) -> Float64].new();
  if math.approximation.best_approx(sq, &empty_basis, 0.0, 1.0).len() != 0 { io.println("best-approx-empty"); return 14; }

  io.println("smoke_math_approximation: OK");
  return 0;
}

fn const1(x: Float64) -> Float64 {
  return 1.0;
}

fn idmap(x: Float64) -> Float64 {
  return x;
}

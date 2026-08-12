// Smoke: xiom.math.special (gamma, beta, error, Bessel, zeta, elliptic,
// orthogonal polynomials, integrals, theta, hypergeometric).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn main() -> Int {
  // gamma / beta / lgamma
  if !near(math.special.gamma(5.0), 24.0, 1e-9) { io.println("gamma5"); return 1; }
  if !near(math.special.gamma(0.5), 1.7724538509, 1e-9) { io.println("gamma-half"); return 2; }
  if !near(math.special.gamma_ln(5.0), 3.1780538303, 1e-9) { io.println("gammaln"); return 3; }
  if !near(math.special.beta(2.0, 3.0), 1.0 / 12.0, 1e-9) { io.println("beta"); return 4; }
  var lg = math.special.lgamma(0.5);
  if !near(lg.0, 0.5723649429, 1e-9) { io.println("lgamma"); return 5; }
  if lg.1 != 1 { io.println("lg-sign"); return 6; }
  // error functions
  if !near(math.special.erf(0.0), 0.0, 1e-9) { io.println("erf0"); return 7; }
  if !near(math.special.erf(1.0), 0.8427007929, 1e-6) { io.println("erf1"); return 8; }
  if !near(math.special.erfc(0.0), 1.0, 1e-9) { io.println("erfc0"); return 9; }
  if !near(math.special.erfinv(0.5), 0.4769362762, 1e-6) { io.println("erfinv"); return 10; }
  if !near(math.special.erfcinv(0.5), 0.4769362762, 1e-6) { io.println("erfcinv"); return 11; }
  if !near(math.special.erfi(0.5), 0.6149520947, 1e-4) { io.println("erfi"); return 12; }
  // incomplete gamma / beta
  if !near(math.special.incomplete_gamma(1.0, 1.0), 0.6321205588, 1e-9) { io.println("incgamma"); return 13; }
  if !near(math.special.incomplete_beta(1.0, 1.0, 0.5), 0.5, 1e-9) { io.println("incbeta"); return 14; }
  if !near(math.special.incomplete_beta(2.0, 3.0, 0.5), 0.6875, 1e-9) { io.println("incbeta2"); return 15; }
  // zeta family
  if !near(math.special.zeta(2.0), 1.6449340668, 1e-4) { io.println("zeta2"); return 16; }
  if !near(math.special.zeta(-1.0), -0.0833333333, 1e-6) { io.println("zeta-1"); return 17; }
  if !near(math.special.riemann_zeta_eta(2.0), 0.8224670334, 1e-4) { io.println("eta"); return 18; }
  if !near(math.special.dirichlet_beta(2.0), 0.9159655941, 1e-4) { io.println("dirbeta"); return 19; }
  // elliptic
  if !near(math.special.elliptic_k(0.0), 1.5707963268, 1e-9) { io.println("ellK0"); return 20; }
  if !near(math.special.elliptic_e(0.5), 1.4674622093, 1e-4) { io.println("ellE"); return 21; }
  if !near(math.special.elliptic_f(0.5, 0.5), 0.50509, 1e-3) { io.println("ellF"); return 22; }
  // digamma / polygamma
  if !near(math.special.digamma(1.0), -0.5772156649, 1e-9) { io.println("digamma"); return 23; }
  if !near(math.special.trigamma(1.0), 1.6449340668, 1e-6) { io.println("trigamma"); return 24; }
  // orthogonal polynomials
  if !near(math.special.legendre_p(2, 0.5), -0.125, 1e-12) { io.println("legp"); return 25; }
  if !near(math.special.chebyshev_t(3, 0.5), -1.0, 1e-12) { io.println("cheb"); return 26; }
  if !near(math.special.hermite_h(2, 1.0), 2.0, 1e-12) { io.println("herm"); return 27; }
  if !near(math.special.laguerre_l(2, 1.0, 1.0), 0.5, 1e-9) { io.println("lag"); return 28; }
  // bessel
  if !near(math.special.bessel_j0(1.0), 0.7651976866, 1e-6) { io.println("j0"); return 29; }
  if !near(math.special.bessel_j(2, 1.0), 0.1149034849, 1e-6) { io.println("j2"); return 30; }
  if !near(math.special.bessel_i(0, 1.0), 1.2660658778, 1e-6) { io.println("i0"); return 31; }
  // integrals
  if !near(math.special.sin_integral(1.0), 0.9460830704, 1e-6) { io.println("si"); return 32; }
  if !near(math.special.exponential_integral(1.0), 1.8951178164, 1e-5) { io.println("ei"); return 33; }
  if !near(math.special.fresnel_s(1.0), 0.4382591474, 1e-4) { io.println("fresS"); return 34; }
  if !near(math.special.dawson(1.0), 0.5380795069, 1e-5) { io.println("dawson"); return 35; }
  // theta / polylog / hypergeometric
  if !near(math.special.theta_3(0.0, 0.1), 1.200200005, 1e-6) { io.println("theta3"); return 36; }
  if !near(math.special.polylog(2.0, 0.5), 0.5822405265, 1e-4) { io.println("polylog"); return 37; }
  if !near(math.special.hypergeometric_2f1(1.0, 1.0, 1.0, 0.5), 2.0, 1e-9) { io.println("2f1"); return 38; }
  if !near(math.special.hypergeometric_1f1(1.0, 1.0, 1.0), 2.7182818284, 1e-6) { io.println("1f1"); return 39; }
  if !near(math.special.li(2.0), 1.0451637801, 1e-5) { io.println("li"); return 40; }

  io.println("smoke_math_special: OK");
  return 0;
}

// XIOM - Math: Special
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.special

// Depends on: xiom.math

// ============================================================================
// Special functions: gamma, beta, error, Bessel, zeta, orthogonal polynomials,
// and integral functions. TODO(compiler): implement.
// ============================================================================

// fn gamma(x: Float64) -> Float64 - gamma function.
// fn lgamma(x: Float64) -> (Float64, Int) - log-gamma; tuple is (ln|gamma(x)|, sign).
// fn beta(a: Float64, b: Float64) -> Float64 - beta function.
// fn incomplete_gamma(a: Float64, x: Float64) -> Float64 - lower incomplete gamma function.
// fn erf(x: Float64) -> Float64 - error function.
// fn erfc(x: Float64) -> Float64 - complementary error function.
// fn bessel_j(n: Int, x: Float64) -> Float64 - Bessel function of the first kind of integer order n.
// fn bessel_y(n: Int, x: Float64) -> Float64 - Bessel function of the second kind of integer order n.
// fn zeta(x: Float64) -> Float64 - Riemann zeta function.
// fn digamma(x: Float64) -> Float64 - logarithmic derivative of the gamma function.
// fn legendre_p(n: Int, x: Float64) -> Float64 - Legendre polynomial of degree n.
// fn chebyshev_t(n: Int, x: Float64) -> Float64 - Chebyshev polynomial of the first kind of degree n.
// fn hermite_h(n: Int, x: Float64) -> Float64 - Hermite polynomial (physicists') of degree n.
// fn airy_ai(x: Float64) -> Float64 - Airy function of the first kind.
// fn airy_bi(x: Float64) -> Float64 - Airy function of the second kind.
// fn fresnel_s(x: Float64) -> Float64 - Fresnel sine integral S(x).
// fn fresnel_c(x: Float64) -> Float64 - Fresnel cosine integral C(x).
// fn elliptic_k(k: Float64) -> Float64 - complete elliptic integral of the first kind.
// fn elliptic_e(k: Float64) -> Float64 - complete elliptic integral of the second kind.
// fn gamma_ln(x: Float64) -> Float64 - natural log of the gamma function.
// fn trigamma(x: Float64) -> Float64 - second derivative of the log-gamma function.
// fn polygamma(m: Int, x: Float64) -> Float64 - m-th derivative of the digamma function.
// fn beta_ln(a: Float64, b: Float64) -> Float64 - natural log of the beta function.
// fn incomplete_gamma_low(a: Float64, x: Float64) -> Float64 - lower incomplete gamma function.
// fn incomplete_beta(a: Float64, b: Float64, x: Float64) -> Float64 - regularized incomplete beta function.
// fn erfi(x: Float64) -> Float64 - imaginary error function.
// fn erfinv(x: Float64) -> Float64 - inverse error function.
// fn erfcinv(x: Float64) -> Float64 - inverse complementary error function.
// fn bessel_y0(x: Float64) -> Float64 - Bessel function of the second kind, order zero.
// fn bessel_y1(x: Float64) -> Float64 - Bessel function of the second kind, order one.
// fn bessel_yn(n: Int, x: Float64) -> Float64 - Bessel function of the second kind of integer order n.
// fn bessel_i(n: Int, x: Float64) -> Float64 - modified Bessel function of the first kind of integer order n.
// fn bessel_k(n: Int, x: Float64) -> Float64 - modified Bessel function of the second kind of integer order n.
// fn bessel_j0(x: Float64) -> Float64 - Bessel function of the first kind, order zero.
// fn bessel_j1(x: Float64) -> Float64 - Bessel function of the first kind, order one.
// fn bessel_jn(n: Int, x: Float64) -> Float64 - Bessel function of the first kind of integer order n.
// fn airy_aip(x: Float64) -> Float64 - derivative of the Airy function of the first kind.
// fn airy_bip(x: Float64) -> Float64 - derivative of the Airy function of the second kind.
// fn legendre_q(n: Int, x: Float64) -> Float64 - Legendre function of the second kind of degree n.
// fn laguerre_l(n: Int, a: Float64, x: Float64) -> Float64 - generalized Laguerre polynomial of degree n.
// fn jacobi_p(n: Int, a: Float64, b: Float64, x: Float64) -> Float64 - Jacobi polynomial of degree n.
// fn gegenbauer_c(n: Int, a: Float64, x: Float64) -> Float64 - Gegenbauer (ultraspherical) polynomial of degree n.
// fn spherical_harmonic(l: Int, m: Int, theta: Float64, phi: Float64) -> Float64 - spherical harmonic Y_l^m.
// fn dawson(x: Float64) -> Float64 - Dawson integral.
// fn exponential_integral(x: Float64) -> Float64 - exponential integral Ei(x).
// fn li(x: Float64) -> Float64 - logarithmic integral.
// fn li_offset(x: Float64) -> Float64 - offset logarithmic integral Li(x).
// fn sin_integral(x: Float64) -> Float64 - sine integral Si(x).
// fn cos_integral(x: Float64) -> Float64 - cosine integral Ci(x).
// fn hypergeometric_2f1(a: Float64, b: Float64, c: Float64, x: Float64) -> Float64 - Gauss hypergeometric function.
// fn hypergeometric_1f1(a: Float64, b: Float64, x: Float64) -> Float64 - confluent hypergeometric function.
// fn elliptic_pi(n: Float64, k: Float64) -> Float64 - complete elliptic integral of the third kind.
// fn elliptic_f(phi: Float64, k: Float64) -> Float64 - incomplete elliptic integral of the first kind.
// fn elliptic_e_incomplete(phi: Float64, k: Float64) -> Float64 - incomplete elliptic integral of the second kind.
// fn elliptic_pi_incomplete(n: Float64, phi: Float64, k: Float64) -> Float64 - incomplete elliptic integral of the third kind.
// fn theta_1(x: Float64, q: Float64) -> Float64 - Jacobi theta function of the first kind.
// fn theta_2(x: Float64, q: Float64) -> Float64 - Jacobi theta function of the second kind.
// fn theta_3(x: Float64, q: Float64) -> Float64 - Jacobi theta function of the third kind.
// fn theta_4(x: Float64, q: Float64) -> Float64 - Jacobi theta function of the fourth kind.
// fn riemann_zeta(x: Float64) -> Float64 - Riemann zeta function.
// fn riemann_zeta_eta(x: Float64) -> Float64 - Dirichlet eta function.
// fn dirichlet_beta(x: Float64) -> Float64 - Dirichlet beta function.
// fn lerch_phi(z: Float64, s: Float64, a: Float64) -> Float64 - Lerch transcendent.
// fn polylog(s: Float64, z: Float64) -> Float64 - polylogarithm Li_s(z).

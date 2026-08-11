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

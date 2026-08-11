// XIOM - Math: Constants
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.constants

// Depends on: none

// ============================================================================
// Compile-time mathematical constants (extended set, 2026-08-11).
//
// The flat math.xi keeps the frozen PI/E/TAU shims (freeze-gated contract);
// THIS module is the canonical home for the full constant set. Every numeric
// constant is a module-level `pub const` with a SCALAR LITERAL initializer
// only — fn-call initializers on module globals are silently zero (BUG 3) and
// struct FIELD writes on module globals are lost (BUG 2), so the three
// non-literal IEEE special values (INFINITY, NEG_INFINITY, NAN — no literal
// syntax exists) are exposed as pure constructor functions instead:
// `math.constants.infinity()`, `math.constants.neg_infinity()`,
// `math.constants.nan()`. They are contract-free and side-effect-free.
//
// Literal precision: the compiler emits Float64 literals at %.17e (BUG 10
// fixed), so each literal below is the correctly-rounded f64 of the exact
// real constant. Values with a `(...)` in the comment are the exact decimal
// expansion truncated to the printed digits; f64 rounding is exact to the
// last ulp.
// ============================================================================

/// pi — ratio of a circle's circumference to its diameter (3.14159...).
pub const PI: Float64 = 3.14159265358979323846;

/// e — base of the natural logarithm (2.71828...).
pub const E: Float64 = 2.71828182845904523536;

/// tau — full circle in radians, exactly 2*pi (6.28318...).
pub const TAU: Float64 = 6.28318530717958647692;

/// phi — golden ratio, (1 + sqrt(5))/2 (1.61803...).
pub const PHI: Float64 = 1.61803398874989484820;

/// sqrt(2) — 1.41421...
pub const SQRT_2: Float64 = 1.41421356237309504880;

/// sqrt(3) — 1.73205...
pub const SQRT_3: Float64 = 1.73205080756887729352;

/// sqrt(5) — 2.23606...
pub const SQRT_5: Float64 = 2.23606797749978969640;

/// ln(2) — natural logarithm of two (0.69314...).
pub const LN_2: Float64 = 0.69314718055994530942;

/// ln(10) — natural logarithm of ten (2.30258...).
pub const LN_10: Float64 = 2.30258509299404568402;

/// log2(e) — base-2 logarithm of e, 1/ln(2) (1.44269...).
pub const LOG2_E: Float64 = 1.44269504088896340736;

/// log10(e) — base-10 logarithm of e, 1/ln(10) (0.43429...).
pub const LOG10_E: Float64 = 0.43429448190325182765;

/// gamma — Euler-Mascheroni constant (0.57721...).
pub const EULER_GAMMA: Float64 = 0.57721566490153286060;

/// G — Catalan's constant, sum (-1)^k/(2k+1)^2 (0.91596...).
pub const CATALAN: Float64 = 0.91596559417721901505;

/// zeta(3) — Apery's constant (1.20205...).
pub const APERY: Float64 = 1.20205690315959428540;

/// Machine epsilon for Float64: the smallest x such that 1.0 + x != 1.0.
/// Exactly 2^-52.
pub const FLOAT_EPSILON: Float64 = 2.220446049250313e-16;

/// Machine epsilon for Float32 (as Float64). Exactly 2^-23.
pub const FLOAT32_EPSILON: Float64 = 1.1920928955078125e-07;

/// Largest finite representable Float64: (2 - 2^-52) * 2^1023.
pub const FLOAT64_MAX: Float64 = 1.7976931348623157e308;

/// Smallest positive NORMAL Float64: 2^-1022.
pub const FLOAT64_MIN: Float64 = 2.2250738585072014e-308;

/// Largest finite representable Float32 (as Float64): (2 - 2^-23) * 2^127.
pub const FLOAT32_MAX: Float64 = 3.4028234663852886e38;

/// Smallest positive NORMAL Float32 (as Float64): 2^-126.
pub const FLOAT32_MIN: Float64 = 1.1754943508222875e-38;

/// Positive infinity. Constructor fn (no literal syntax; BUG 3 — see header).
pub fn infinity() -> Float64 {
  return 1.0 / 0.0;
}

/// Negative infinity. Constructor fn (no literal syntax; BUG 3 — see header).
pub fn neg_infinity() -> Float64 {
  return -1.0 / 0.0;
}

// NAN (not-a-number) — BLOCKED by BUG 19 (2026-08-11): every NaN-producing
// Float64 operation (`0.0/0.0`, `inf-inf`, `inf*0`) returns a garbage
// sentinel or traps 0xC000001D, and no NaN literal syntax exists. Do NOT
// call a broken constructor — production standard forbids silent failures.
// TODO(compiler): BUG 19 — land IEEE NaN results + a nan literal or a
// bitcast intrinsic; then `pub const NAN: Float64` lands here.

// Smoke: xiom.math.constants (extended constant set).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn main() -> Int {
  // --- Foundational constants: range checks (f64 literal emission exact). ---
  if math.constants.PI < 3.14159265358979 || math.constants.PI > 3.14159265358980 {
    io.println("PI-bad"); return 1;
  }
  if math.constants.E < 2.71828182845904 || math.constants.E > 2.71828182845905 {
    io.println("E-bad"); return 2;
  }
  // TAU is exactly 2*PI
  var tau_diff = math.constants.TAU - 2.0 * math.constants.PI;
  if tau_diff < 0.0 { tau_diff = -tau_diff; }
  if tau_diff > 1e-15 { io.println("TAU-bad"); return 3; }
  // PHI^2 == PHI + 1 (golden ratio identity)
  var phi2 = math.constants.PHI * math.constants.PHI;
  var phi_ident = phi2 - math.constants.PHI - 1.0;
  if phi_ident < 0.0 { phi_ident = -phi_ident; }
  if phi_ident > 1e-12 { io.println("PHI-bad"); return 4; }

  // --- Square roots square back. ---
  var s2 = math.constants.SQRT_2 * math.constants.SQRT_2 - 2.0;
  if s2 < 0.0 { s2 = -s2; }
  if s2 > 1e-12 { io.println("SQRT_2-bad"); return 5; }
  var s3 = math.constants.SQRT_3 * math.constants.SQRT_3 - 3.0;
  if s3 < 0.0 { s3 = -s3; }
  if s3 > 1e-12 { io.println("SQRT_3-bad"); return 6; }
  var s5 = math.constants.SQRT_5 * math.constants.SQRT_5 - 5.0;
  if s5 < 0.0 { s5 = -s5; }
  if s5 > 1e-12 { io.println("SQRT_5-bad"); return 7; }

  // --- Logarithm identities: exp(ln x) == x. ---
  var l2 = math.exp(math.constants.LN_2) - 2.0;
  if l2 < 0.0 { l2 = -l2; }
  if l2 > 1e-12 { io.println("LN_2-bad"); return 8; }
  var l10 = math.exp(math.constants.LN_10) - 10.0;
  if l10 < 0.0 { l10 = -l10; }
  if l10 > 1e-10 { io.println("LN_10-bad"); return 9; }
  // LOG2_E * LN_2 == 1 ; LOG10_E * LN_10 == 1
  var l2e = math.constants.LOG2_E * math.constants.LN_2 - 1.0;
  if l2e < 0.0 { l2e = -l2e; }
  if l2e > 1e-12 { io.println("LOG2_E-bad"); return 10; }
  var l10e = math.constants.LOG10_E * math.constants.LN_10 - 1.0;
  if l10e < 0.0 { l10e = -l10e; }
  if l10e > 1e-12 { io.println("LOG10_E-bad"); return 11; }

  // --- Named constants: sane sign/magnitude. ---
  if math.constants.EULER_GAMMA <= 0.5 || math.constants.EULER_GAMMA >= 0.6 {
    io.println("GAMMA-bad"); return 12;
  }
  if math.constants.CATALAN <= 0.9 || math.constants.CATALAN >= 0.93 {
    io.println("CATALAN-bad"); return 13;
  }
  if math.constants.APERY <= 1.2 || math.constants.APERY >= 1.21 {
    io.println("APERY-bad"); return 14;
  }

  // --- Machine epsilons: the defining property 1 + eps != 1. ---
  if 1.0 + math.constants.FLOAT_EPSILON == 1.0 {
    io.println("FLOAT_EPSILON-small"); return 15;
  }
  if 1.0 + math.constants.FLOAT_EPSILON / 2.0 != 1.0 {
    io.println("FLOAT_EPSILON-big"); return 16;
  }
  if 1.0 + math.constants.FLOAT32_EPSILON == 1.0 {
    io.println("FLOAT32_EPSILON-small"); return 17;
  }

  // --- Limits. ---
  if math.constants.FLOAT64_MAX < 1.7e308 {
    io.println("FLOAT64_MAX-small"); return 18;
  }
  if math.constants.FLOAT64_MAX * 2.0 != math.constants.infinity() {
    io.println("FLOAT64_MAX-overflow"); return 19;
  }
  if math.constants.FLOAT64_MIN <= 0.0 {
    io.println("FLOAT64_MIN-bad"); return 20;
  }
  if math.constants.FLOAT64_MIN / 2.0 == 0.0 {
    io.println("FLOAT64_MIN-subnormal"); return 21;
  }
  if math.constants.FLOAT32_MAX <= math.constants.FLOAT32_MIN {
    io.println("FLOAT32-range"); return 22;
  }
  if math.constants.FLOAT32_MAX < 3.4e38 || math.constants.FLOAT32_MIN > 1.2e-38 {
    io.println("FLOAT32-values"); return 23;
  }
  if math.constants.FLOAT32_MIN <= 0.0 {
    io.println("FLOAT32_MIN-bad"); return 24;
  }

  // --- Specials: infinity / -infinity classification. ---
  // NAN is not yet testable: BUG 19 (NaN-producing float ops trap or return
  // a garbage sentinel) — math.constants.nan() is not shipped until fixed.
  if !math.is_inf(math.constants.infinity()) {
    io.println("INF-bad"); return 25;
  }
  if math.constants.infinity() < 0.0 {
    io.println("INF-neg"); return 26;
  }
  if !math.is_inf(math.constants.neg_infinity()) {
    io.println("NEG_INF-bad"); return 27;
  }
  if math.constants.neg_infinity() >= 0.0 {
    io.println("NEG_INF-pos"); return 28;
  }
  // Infinite is equal to itself.
  if math.constants.infinity() != math.constants.infinity() {
    io.println("INF-ne"); return 31;
  }

  io.println("smoke_math_constants_ext: OK");
  return 0;
}

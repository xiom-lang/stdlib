// p_curve_thunk_zero.xi -- KNOWN FAILURE (compiler v0.61.3, 2026-10-01)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// A fn-typed parameter that returns Vec[Float64] loses its result when the
// catalog function calls it: curves.curve_length(line, 0, 1, 2) returns 0
// instead of the arc length 1.0, while calling the same function value
// directly (line(0.5)) returns the correct (0.5, 0.0). The thunk's Vec
// return appears to arrive empty/zero inside the catalog body, so every
// segment distance collapses to 0. This is the Vec-returning sibling of the
// fixed "fn-typed Float64 thunks returned 0" class.
// Expected: the program returns 0.
// Observed on v0.61.3: curves.curve_length returns 0 (the second check
// returns 2); the direct-call control passes.
// Found while landing the wave-51 geom clauses; the wave-51 probe keeps only
// the n < 1 == 0 branch for curve_length until this is fixed.

module p_curve_thunk_zero

use xiom.geom.curves;

fn line(t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  out.push(t);
  out.push(0.0);
  return out;
}

fn main() -> Int {
  // Control: the same function value called directly is correct.
  var s = line(0.5);
  if s[0] != 0.5 { return 1; }
  // Broken: the catalog's call through the fn-typed parameter sees 0.
  if curves.curve_length(line, 0.0, 1.0, 2) != 1.0 { return 2; }
  return 0;
}

// XIOM - Conversion: Ftos
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.ftos

// Depends on: none

// ============================================================================
// Float-to-string shorthand helpers. All delegate to the canonical
// xiom.convert float formatters (different function names, so delegation is
// safe from the same-name miscompile).
// ============================================================================

use xiom.convert;

/// Float-to-string shorthand: 15 significant digits in the canonical fixed /
/// scientific layout. Handles "nan" and "inf". Complexity: O(|exp10| + 15).
pub fn ftos(f: Float64) -> Str {
  convert.float_to_string(f)
}

/// Float-to-string with exactly `prec` fraction digits (fixed notation,
/// rounded half away from zero). Complexity: O(prec).
pub fn ftos_prec(f: Float64, prec: Int) -> Str {
  convert.float_to_fixed_str(f, prec)
}

/// Float-to-string in scientific notation "d.ddde±XX" with `prec` fraction
/// digits. Complexity: O(|exp10| + prec).
pub fn ftos_sci(f: Float64, prec: Int) -> Str {
  convert.float_to_sci_str(f, prec)
}

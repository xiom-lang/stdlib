// XIOM - String: Printf
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.printf

// Depends on: xiom.fmt

// ============================================================================
// printf-style formatting for the common primitive types: Int, Float64, and Str.
// NOTE: current implementation lives in fmt.sprintf - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.fmt;

/// Format the Int `a` per the printf `spec`. Supports the integer conversions
/// %d/%i/%u/%x/%X/%o/%b with flags, width and precision. Wrong conversion
/// family or missing values yield Err.
/// Params: spec the printf format; a the integer value.
/// Returns: Ok with the formatted string, Err on a malformed or mismatched spec.
/// Error case: malformed spec, non-integer conversion, missing arguments.
/// Complexity: O(|spec| + digits).
pub fn str_printf_i1(spec: Str, a: Int) -> Result[Str, Str] {
  let r = fmt.sprintf_i1(spec, a);
  r
}

/// Format the Float64 `a` per the printf `spec`. Supports %f/%F/%e/%E/%g/%G
/// with flags, width and precision. Wrong conversion family or missing values
/// yield Err.
/// Params: spec the printf format; a the float value.
/// Returns: Ok with the formatted string, Err on a malformed or mismatched spec.
/// Error case: malformed spec, non-float conversion, missing arguments.
/// Complexity: O(|spec| + |fraction digits|).
pub fn str_printf_f1(spec: Str, a: Float64) -> Result[Str, Str] {
  let r = fmt.sprintf_f1(spec, a);
  r
}

/// Format the Str `a` per the printf `spec`. Supports %s with flags, width
/// and precision. Wrong conversion family or missing values yield Err.
/// Params: spec the printf format; a the string value.
/// Returns: Ok with the formatted string, Err on a malformed or mismatched spec.
/// Error case: malformed spec, non-string conversion, missing arguments.
/// Complexity: O(|spec| + |a|).
pub fn str_printf_s1(spec: Str, a: Str) -> Result[Str, Str] {
  let r = fmt.sprintf_s1(spec, a);
  r
}

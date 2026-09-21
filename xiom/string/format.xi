// XIOM - String: Format
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.format

// Depends on: xiom.fmt

// ============================================================================
// Type-generic formatting of one, two, or three arguments against a format
// specifier. NOTE: current implementation lives in fmt.format1..9 + sprintf -
// move the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.fmt;

/// Format a single argument `a` against the `spec` template. The first "{}"
/// in `spec` is replaced by the value's display string; values without a
/// placeholder leave `spec` unchanged.
/// Params: spec the template containing a "{}" placeholder; a the value.
/// Returns: Ok with the formatted string; Err is never produced for this
///          entry point (reserved for API symmetry).
/// Error case: none.
/// Complexity: O(|spec| + |value display|).
pub fn str_format1[T](spec: Str, a: T) -> Result[Str, Str] {
  let r = fmt.format1(spec, a);
  Ok(r)
}

/// Format two arguments `a` and `b` against the `spec` template; the first
/// "{}" takes `a`, the second takes `b`.
/// Params: spec the template; a, b the values.
/// Returns: Ok with the formatted string.
/// Error case: none.
/// Complexity: O(|spec| + |display|).
pub fn str_format2[T, U](spec: Str, a: T, b: U) -> Result[Str, Str] {
  let r = fmt.format2(spec, a, b);
  Ok(r)
}

/// Format three arguments `a`, `b` and `c` against the `spec` template.
/// Params: spec the template; a, b, c the values.
/// Returns: Ok with the formatted string.
/// Error case: none.
/// Complexity: O(|spec| + |display|).
pub fn str_format3[T, U, V](spec: Str, a: T, b: U, c: V) -> Result[Str, Str] {
  let r = fmt.format3(spec, a, b, c);
  Ok(r)
}

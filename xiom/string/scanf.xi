// XIOM - String: Scanf
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.scanf

// Depends on: xiom.fmt

// ============================================================================
// Scan a string against a format specifier to extract typed values. NOTE:
// current implementation lives in fmt.sscanf - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.fmt;

/// Results of `str_scanf_floats`: the parsed Float64 values in v0..v7 (the
/// first `count` slots are valid) and the unconsumed `remainder` of the input.
/// On failure `is_ok` is false, `count` is 0, the value slots are 0.0 and
/// `remainder` carries the error message.
///
/// LAYOUT NOTE (R44, 2026-09-18): this struct was formerly unified with
/// `xiom.fmt.FloatScan` by the codegen same-name dedup, which hid a type
/// mismatch in `str_scanf_floats`. The fmt twin is now `FormatFloatScan`
/// and this wrapper copies every field explicitly, so the two leaves are
/// genuinely independent (same field order/types, different leaf + names).
pub type FloatScan = {
  is_ok: Bool;
  count: Int;
  v0: Float64;
  v1: Float64;
  v2: Float64;
  v3: Float64;
  v4: Float64;
  v5: Float64;
  v6: Float64;
  v7: Float64;
  remainder: Str;
}

/// Scan `s` per `spec`, extracting the raw matched fields. Literal characters
/// match exactly; spec whitespace skips input whitespace. Conversions:
/// %d/%i/%u (decimal), %x/%X (hex, optional 0x), %f/%e/%g (float), %s (token),
/// %c (exact chars), width caps, `*` suppresses. Returns the captured token
/// strings in order, Err on any mismatch.
/// Params: s the input string; spec the scanf-style format.
/// Returns: Ok with the matched token strings, Err on mismatch.
/// Error case: unterminated directive, no match, literal mismatch.
/// Complexity: O(|s| + |spec|).
pub fn str_scanf(s: Str, spec: Str) -> Result[Vec[Str], Str] {
  let r = fmt.sscanf(s, spec);
  r
}

/// Scan `s` per `spec`, extracting Int values. The %d/%i/%u (decimal) and
/// %x/%X (hex) tokens are converted with overflow checking; any other
/// conversion in the spec yields Err.
/// Params: s the input string; spec the scanf-style format.
/// Returns: Ok with the parsed integers in token order, Err on mismatch or
///          a non-integer conversion.
/// Error case: parse failure, integer overflow, non-integer conversion.
/// Complexity: O(|s| + |spec|).
pub fn str_scanf_ints(s: Str, spec: Str) -> Result[Vec[Int], Str] {
  let r = fmt.sscanf_ints(s, spec);
  r
}

/// Scan `s` per `spec`, extracting Float64 values (%f/%e/%g tokens). Values
/// land in v0..v7 in token order with `count` valid slots. Specs with more
/// than eight float conversions, or with a non-float conversion, yield
/// is_ok = false with `error` set.
///
/// NOTE (R44): `xiom.fmt.FloatScan` was renamed `FormatFloatScan`; this
/// wrapper copies the fields explicitly, so `remainder` is the fmt `error`
/// slot on failure and the empty string on success. The unconsumed input
/// tail is not populated; use `str_scanf` with a trailing capture to observe
/// unconsumed input.
/// Params: s the input string; spec the scanf-style format.
/// Returns: a FloatScan struct.
/// Error case: parse failure, too many float conversions, non-float conversion.
/// Complexity: O(|s| + |spec|).
pub fn str_scanf_floats(s: Str, spec: Str) -> FloatScan {
  let r = fmt.sscanf_floats(s, spec);
  return FloatScan{
    is_ok: r.is_ok;
    count: r.count;
    v0: r.v0;
    v1: r.v1;
    v2: r.v2;
    v3: r.v3;
    v4: r.v4;
    v5: r.v5;
    v6: r.v6;
    v7: r.v7;
    remainder: r.error;
  };
}


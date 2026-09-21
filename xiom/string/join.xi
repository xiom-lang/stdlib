// XIOM - String: Join
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.join

// Depends on: xiom.string, xiom.core, xiom.convert

// ============================================================================
// Join collections of strings and primitive values into a single string with a
// separator. All functions are pure; an empty collection joins to an empty
// string.
// ============================================================================

use xiom.string;
use xiom.convert;

/// Joins `parts` with `sep` between consecutive elements.
/// Returns an empty string when `parts` is empty.
/// Complexity: O(total bytes of parts).
pub fn str_join(parts: &Vec[Str], sep: Str) -> Str
  ensures: parts.len() == 0 => result.len() == 0
{
  var result = "";
  let len = parts.len();
  var i: Int = 0;
  while i < len {
    if i > 0 {
      result = string.str_concat(result, sep);
    };
    var p = parts[i];
    result = string.str_concat(result, p);
    i = i + 1;
  };
  result
}

/// Joins `parts`, inserting `sep` after every `after`-th element. When
/// `after <= 0`, no separator is inserted at all.
/// Returns an empty string when `parts` is empty.
/// Complexity: O(total bytes of parts).
pub fn str_join_after(parts: &Vec[Str], sep: Str, after: Int) -> Str
  ensures: after <= 0 => result.len() == 0
{
  var result = "";
  let len = parts.len();
  if after <= 0 {
    return result;
  };
  var i: Int = 0;
  while i < len {
    var p = parts[i];
    result = string.str_concat(result, p);
    if (i + 1) % after == 0 && i + 1 < len {
      result = string.str_concat(result, sep);
    };
    i = i + 1;
  };
  result
}

/// Joins the `Int` values in `values` with `sep` between consecutive elements.
/// Returns an empty string when `values` is empty.
/// Complexity: O(total digits of values).
pub fn vec_int_join(values: &Vec[Int], sep: Str) -> Str
  ensures: values.len() == 0 => result.len() == 0
{
  var result = "";
  let len = values.len();
  var i: Int = 0;
  while i < len {
    if i > 0 {
      result = string.str_concat(result, sep);
    };
    var v = values[i];
    result = string.str_concat(result, xiom.core.to_string(v));
    i = i + 1;
  };
  result
}

/// Joins the `Float64` values in `values` with `sep` between consecutive
/// elements. Returns an empty string when `values` is empty.
/// Complexity: O(total digits of values).
pub fn vec_float_join(values: &Vec[Float64], sep: Str) -> Str
  ensures: values.len() == 0 => result.len() == 0
{
  var result = "";
  let len = values.len();
  var i: Int = 0;
  while i < len {
    if i > 0 {
      result = string.str_concat(result, sep);
    };
    var v = values[i];
    result = string.str_concat(result, convert.float_to_string(v));
    i = i + 1;
  };
  result
}

// XIOM - String: Chunk
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.chunk

// Depends on: none

// ============================================================================
// Split a string into fixed-size chunks and sliding windows. NOTE: current
// implementation lives in string.combinatorics stub - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Splits `s` into consecutive chunks of `n` bytes; the final chunk may be
/// shorter. A chunk size below 1 or an empty input yields an empty vector.
/// Params: s the source string; n the chunk size in bytes.
/// Returns: a Vec[Str] of chunks covering `s` exactly once.
/// Error case: n < 1 or s.len() == 0 => empty vector.
/// Complexity: O(s.len()).
pub fn str_chunk(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 {
    return result;
  };
  if len == 0 {
    return result;
  };
  var i: Int = 0;
  while i < len {
    var end = i + n;
    if end > len {
      end = len;
    };
    let chunk_str = string.str_slice(s, i, end);
    result.push(chunk_str);
    i = end;
  };
  result
}

/// Splits `s` into chunks of `n` bytes starting from the end; the remainder
/// (if any) forms the first chunk. A chunk size below 1 or an empty input
/// yields an empty vector.
/// Params: s the source string; n the chunk size in bytes.
/// Returns: a Vec[Str] of chunks in source order (first may be shorter).
/// Error case: n < 1 or s.len() == 0 => empty vector.
/// Complexity: O(s.len()).
pub fn str_chunks_reverse(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 {
    return result;
  };
  if len == 0 {
    return result;
  };
  var first = len % n;
  if first == 0 {
    first = n;
  };
  var cur = first;
  var i: Int = 0;
  while i < len {
    var end = i + cur;
    if end > len {
      end = len;
    };
    let chunk_str = string.str_slice(s, i, end);
    result.push(chunk_str);
    i = end;
    cur = n;
  };
  result
}

/// Returns all length-`n` overlapping substrings (windows) of `s`.
/// A window size below 1 or larger than the input yields an empty vector.
/// Params: s the source string; n the window size in bytes.
/// Returns: a Vec[Str] with one element per start position 0..len-n.
/// Error case: n < 1 or len < n => empty vector.
/// Complexity: O(s.len()).
pub fn str_windows(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 {
    return result;
  };
  if len < n {
    return result;
  };
  var i: Int = 0;
  while i <= len - n {
    let window_str = string.str_slice(s, i, i + n);
    result.push(window_str);
    i = i + 1;
  };
  result
}

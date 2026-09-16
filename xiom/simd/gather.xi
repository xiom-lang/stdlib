// XIOM - SIMD: Gather/Scatter
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.simd.gather

// Depends on: none

use xiom.simd.mask;

// ============================================================================
// Gather/scatter memory access, masked loads, compression and expansion
// helpers.
//
// Scalar fallback (this build has no runtime SIMD/gather path): the memory
// gather/scatter entry points (`gather_load`, `gather_load4`, `gather_mask`,
// `scatter_store`) cannot read/write arbitrary addresses into a generic `T`
// (the language has no `Int as T` cast), so they are documented stubs:
// gathers return default-valued `T()` elements of the correct shape and
// scatter is a no-op. The pure data-movement helpers `gather_compress` and
// `gather_expand` are fully implemented (they copy existing `T` values).
// ============================================================================

/// Load `T` values from `base + index` for every index. Scalar fallback:
/// generic memory loads are unavailable -- returns default `T()` values with
/// one element per index (documented).
/// Complexity: O(len(indices)).
pub fn gather_load[T](base: Int, indices: &Vec[Int]) -> Vec[T] {
  var out = Vec[T].new();
  var i: Int = 0;
  while i < indices.len() {
    out.push(T());
    i = i + 1;
  };
  out
}

/// Load four `T` values; the tuple is the four gathered values. Scalar
/// fallback: returns default `T()` values (documented).
/// Complexity: O(1).
pub fn gather_load4[T](base: Int, i0: Int, i1: Int, i2: Int, i3: Int) -> (T, T, T, T) {
  (T(), T(), T(), T())
}

/// Store `values` to `base + index`. Scalar fallback: generic memory stores
/// are unavailable -- no-op (documented).
/// Complexity: O(1).
pub fn scatter_store[T](base: Int, indices: &Vec[Int], values: &Vec[T]) {
}

/// Gather only the lanes where the mask is set. Scalar fallback: generic
/// memory loads are unavailable -- returns default `T()` values, one per set
/// lane (documented).
/// Complexity: O(32).
pub fn gather_mask[T](base: Int, indices: &Vec[Int], m: Mask) -> Vec[T] {
  var out = Vec[T].new();
  var i: Int = 0;
  while i < 32 {
    if mask.mask_get(m, i) {
      out.push(T());
    };
    i = i + 1;
  };
  out
}

/// Compact the set-lane values to the front. Fully implemented scalar
/// fallback: the result holds `values[i]` for every set lane `i`, in lane
/// order.
/// Complexity: O(min(values, 32)).
pub fn gather_compress[T](values: &Vec[T], m: Mask) -> Vec[T] {
  var out = Vec[T].new();
  var i: Int = 0;
  while i < values.len() && i < 32 {
    if mask.mask_get(m, i) {
      out.push(values[i]);
    };
    i = i + 1;
  };
  out
}

/// Spread `values` back into set-lane positions. Fully implemented scalar
/// fallback: the result has 32 lanes; lane `i` holds the next value from
/// `values` when the mask bit is set and a default `T()` otherwise.
/// Complexity: O(32).
pub fn gather_expand[T](values: &Vec[T], m: Mask) -> Vec[T] {
  var out = Vec[T].new();
  var v: Int = 0;
  var i: Int = 0;
  while i < 32 {
    if mask.mask_get(m, i) {
      if v < values.len() {
        out.push(values[v]);
      } else {
        out.push(T());
      };
      v = v + 1;
    } else {
      out.push(T());
    };
    i = i + 1;
  };
  out
}

/// Materialize the values `base + 0 .. base + n-1`. Scalar fallback: generic
/// construction from an Int is unavailable -- returns default `T()` values,
/// one per element (documented).
/// Complexity: O(n).
pub fn gather_iota[T](base: Int, n: Int) -> Vec[T] {
  var out = Vec[T].new();
  var i: Int = 0;
  while i < n {
    out.push(T());
    i = i + 1;
  };
  out
}

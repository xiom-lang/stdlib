// p_geom_matrix_result_infer.xi -- KNOWN FAILURE (compiler v0.61.3 + v0.62.1, 2026-09-30)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Call-site type inference for xiom.geom.matrix results of type
// Vec[Vec[Float64]] loses a nesting level when the local is declared
// WITHOUT an explicit type: `var z = matrix.zero(2, 2); z[0].len()` reads
// 0 (matrix.one surfaces the raw double bits as the row length), and the
// same happens for tuple elements (`var l2 = lu.0;`). With an explicit
// `var z: Vec[Vec[Float64]] = ...` the identical read is correct. The same
// un-annotated shape against xiom.geom.mat (mat_identity) is correct, and
// single-level Vec[Float64] returns are unaffected.
// Expected: every read is 2 (the program returns 0).
// Observed on v0.61.3 and v0.62.1: the first check returns 1 (z1 row
// length is 0); the tuple variant (check 4) is also broken.
// Found while landing the wave-50 geom clauses (2026-09-30).
//
// Stdlib impact: xiom.geom.matrix consumers must annotate nested results
// until this is fixed. tests/smoke/smoke_geom_mat.xi already documents the
// cannot-be-read symptom for matrix-module results and verifies through
// det/trace/rank scalars; the wave-50 probe annotates every nested local.

module p_geom_matrix_result_infer

use xiom.geom.matrix;
use xiom.geom.mat;

fn main() -> Int {
  // Broken: inferred nested result loses a level (row len 0 on the pin).
  var z1 = matrix.zero(2, 2);
  if z1[0].len() != 2 { return 1; }
  // Correct: explicit annotation.
  var z2: Vec[Vec[Float64]] = matrix.zero(2, 2);
  if z2[0].len() != 2 { return 2; }
  // Control: the same signature via xiom.geom.mat is correct un-annotated.
  var c = mat.mat_identity(2);
  if c[0].len() != 2 { return 3; }
  // Broken: tuple element without annotation (identity keeps LU non-empty).
  var id: Vec[Vec[Float64]] = matrix.identity(2);
  var lu = matrix.lu_decompose(&id);
  var l2 = lu.0;
  if l2[0].len() != 2 { return 4; }
  // Correct: tuple element with annotation.
  var l: Vec[Vec[Float64]] = lu.0;
  if l[0].len() != 2 { return 5; }
  return 0;
}

// p_geom_vector_result_bits.xi -- KNOWN FAILURE (compiler v0.61.3 + v0.62.1, 2026-10-01)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Caller-side element reads of some xiom.geom.vector / xiom.geom.curves
// results are bit-reinterpreted: the stored double's IEEE bits surface as
// if they were an integer converted to Float64. Observed in the wave-51
// probe: vector.lerp returned (1.5, 2.0) but the caller read
// 4.6094342186137e+18 (0x3FF8000000000000, the bit pattern of 1.5);
// vector.clamp 2.0 -> 4.61168601842739e+18; vector.hadamard 3.0 ->
// 4.61393781824107e+18; curves.b_spline 1.5 -> 4.6094342186137e+18.
// Callee-side reads are correct: passing the same results back into
// vector.norm / vector.distance (and the existing smoke_geom_vec checks)
// sees the true values, so the defect is in the caller-side element read
// path for these functions' results. Unaffected controls (same caller
// read shape): vector.cross, normalize, unit, project, reject, slerp,
// reflect, outer; curves bezier_quad/cubic/derivative.
// Expected: every read is the stored value (the program returns 0).
// Observed on v0.61.3 and v0.62.1: the first broken check returns its code.
// Found while landing the wave-51 geom clauses; the wave-51 probe and
// smoke_geom_vec verify lerp/clamp/hadamard/b_spline through scalar
// mediators (dot/norm/distance).
//
// Stdlib impact: consumers must not read those results element-wise;
// mediate through vector.dot/norm/distance or copy via a local loop.

module p_geom_vector_result_bits

use xiom.geom.vector;

fn main() -> Int {
  // Control: same caller-side read shape on a correct function.
  var a3 = Vec[Float64].new();
  a3.push(1.0);
  a3.push(2.0);
  a3.push(3.0);
  var b3 = Vec[Float64].new();
  b3.push(4.0);
  b3.push(5.0);
  b3.push(6.0);
  var x = vector.cross(&a3, &b3);
  if x[0] != -3.0 { return 1; }

  // Broken: vector.lerp element read (1.5 reads as its bit pattern).
  var a = Vec[Float64].new();
  a.push(0.0);
  a.push(0.0);
  var b = Vec[Float64].new();
  b.push(3.0);
  b.push(4.0);
  var lp = vector.lerp(&a, &b, 0.5);
  if lp[0] != 1.5 { return 2; }

  // Broken: vector.clamp element read (2.0 reads as its bit pattern).
  var cl = vector.clamp(&b, 0.0, 2.0);
  if cl[1] != 2.0 { return 3; }
  return 0;
}

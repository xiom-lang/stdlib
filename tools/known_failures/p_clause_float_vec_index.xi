// p_clause_float_vec_index.xi -- KNOWN FAILURE (compiler v0.61.3, 2026-09-29)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Clause-position indexing of Float64 vector elements reads garbage:
//   - Vec[Float64] result element read (`result[0] == 1.0`) violates.
//   - Vec[Vec[Float64]] result row read (`result[0].len() == 2`) violates.
// The Int controls in the same program PASS on the same binary:
//   - Vec[Vec[Int]] nested row lengths and Vec[Int] element reads are fine,
//     and length-only claims on Vec[Vec[Float64]] results are fine.
// Expected: no violation (the indexed values are the ones just stored).
// Observed on v0.61.3: "contract violated: ensures at <fn line>:12" at the
// first Float64-index call; the Int control calls run before it and pass.
// Found while landing the wave-49 geom clauses (mat_identity row claim,
// 2026-09-29). Stdlib mitigation: wave-49 geom clauses use len-only claims
// on Float64 matrix results; re-add the row-length claims when this is
// fixed.

module p_clause_float_vec_index

fn control_int() -> Vec[Vec[Int]]
  ensures: result.len() == 2 && result[0].len() == 2
{
  var out = Vec[Vec[Int]].new();
  var r0 = Vec[Int].new();
  r0.push(1);
  r0.push(2);
  out.push(r0);
  var r1 = Vec[Int].new();
  r1.push(3);
  r1.push(4);
  out.push(r1);
  return out;
}

fn bug_f64() -> Vec[Float64]
  ensures: result.len() == 2 && result[0] == 1.0
{
  var out = Vec[Float64].new();
  out.push(1.0);
  out.push(2.0);
  return out;
}

fn bug_nested_f64() -> Vec[Vec[Float64]]
  ensures: result.len() == 2 && result[0].len() == 2
{
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(1.0);
  r0.push(2.0);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(3.0);
  r1.push(4.0);
  out.push(r1);
  return out;
}

fn main() -> Int {
  // Int controls: green on the pin.
  var iv = control_int();
  if iv.len() != 2 { return 1; }
  if iv[0].len() != 2 { return 2; }
  // Float64 clause index: violates on the pin (first bug_f64 call).
  var fv = bug_f64();
  if fv.len() != 2 { return 3; }
  var nv = bug_nested_f64();
  if nv.len() != 2 { return 4; }
  return 0;
}

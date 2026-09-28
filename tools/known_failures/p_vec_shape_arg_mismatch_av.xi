// Minimal repro (stdlib lane, 2026-09-28, compiler v0.61.3):
// passing &Vec[Float64] where &Vec[Vec[Float64]] is expected compiles with
// NO diagnostic, and the callee's nested element read then crashes with an
// access violation.
//
// Expected: a type error at the call site.
// Observed: compile rc 0, run rc 0xC0000005 (-1073741819).
//
// Hit while writing tools/probes/p_wave42_shapes.xi: mat_mul(&da, &r0) where
// r0 was one flat row instead of a matrix. The same shape with both
// arguments as Vec[Vec[Float64]] is fine (p_wave42_shapes is green).
module p_vec_shape_arg_mismatch_av

use xiom.math;

fn main() -> Int {
  var matrix = Vec[Vec[Float64]].new();
  var row = Vec[Float64].new();
  row.push(1.0);
  row.push(2.0);
  matrix.push(row);
  var flat = Vec[Float64].new();
  flat.push(1.0);
  flat.push(2.0);
  // Second argument must be &Vec[Vec[Float64]]; this compiles silently.
  var out = math.matrices.mat_mul(&matrix, &flat);
  return out.len();
}

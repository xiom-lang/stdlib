// Smoke: xiom.math.matrices (fixed-size Mat2/3/4 + dynamic mat_* functions).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  // Mat2: construct, det, mul, transpose, inverse.
  var m2 = math.matrices.mat2_new(1.0, 2.0, 3.0, 4.0);
  var det2 = math.matrices.mat2_det(m2);
  if det2 != -2.0 { io.println("m2-det"); return 1; }
  var i2 = math.matrices.mat2_new(1.0, 0.0, 0.0, 1.0);
  var p2 = math.matrices.mat2_mul(m2, i2);
  if p2.m00 != 1.0 || p2.m01 != 2.0 || p2.m10 != 3.0 || p2.m11 != 4.0 { io.println("m2-mul-id"); return 2; }
  var t2 = math.matrices.mat2_transpose(m2);
  if t2.m00 != 1.0 || t2.m01 != 3.0 || t2.m10 != 2.0 || t2.m11 != 4.0 { io.println("m2-transpose"); return 3; }
  var inv2 = math.matrices.mat2_inv(m2);
  if !inv2.is_some() { io.println("m2-inv-none"); return 4; }
  var u2 = inv2.unwrap();
  var back2 = math.matrices.mat2_mul(m2, u2);
  if !near(back2.m00, 1.0) || !near(back2.m01, 0.0) { io.println("m2-inv-back-1"); return 5; }
  if !near(back2.m10, 0.0) || !near(back2.m11, 1.0) { io.println("m2-inv-back-2"); return 6; }
  var sing2 = math.matrices.mat2_new(1.0, 2.0, 2.0, 4.0);
  if math.matrices.mat2_inv(sing2).is_some() { io.println("m2-inv-singular"); return 7; }

  // Mat3: construct, det (singular), inverse, transpose.
  var m3 = math.matrices.mat3_new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);
  var det3 = math.matrices.mat3_det(m3);
  if !near(det3, 0.0) { io.println("m3-det-singular"); return 8; }
  if math.matrices.mat3_inv(m3).is_some() { io.println("m3-inv-singular"); return 9; }
  var m3b = math.matrices.mat3_new(1.0, 2.0, 3.0, 0.0, 1.0, 4.0, 5.0, 6.0, 0.0);
  var det3b = math.matrices.mat3_det(m3b);
  if !near(det3b, 1.0) { io.println("m3-det"); return 10; }
  var inv3 = math.matrices.mat3_inv(m3b);
  if !inv3.is_some() { io.println("m3-inv-none"); return 11; }
  var u3 = inv3.unwrap();
  var back3 = math.matrices.mat3_mul(m3b, u3);
  if !near(back3.m00, 1.0) || !near(back3.m11, 1.0) || !near(back3.m22, 1.0) { io.println("m3-inv-back-diag"); return 12; }
  if !near(back3.m01, 0.0) || !near(back3.m12, 0.0) || !near(back3.m20, 0.0) { io.println("m3-inv-back-off"); return 13; }
  var i3 = math.matrices.mat3_new(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
  var prod3 = math.matrices.mat3_mul(m3b, i3);
  if prod3.m00 != 1.0 || prod3.m02 != 3.0 || prod3.m21 != 6.0 { io.println("m3-mul-id"); return 14; }
  var t3 = math.matrices.mat3_transpose(m3b);
  if t3.m01 != 0.0 || t3.m02 != 5.0 || t3.m10 != 2.0 { io.println("m3-transpose"); return 15; }

  // Mat4: diagonal matrix det/inv/transpose/mul.
  var m4 = math.matrices.mat4_new(2.0, 0.0, 0.0, 0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 4.0, 0.0, 0.0, 0.0, 0.0, 5.0);
  var det4 = math.matrices.mat4_det(m4);
  if !near(det4, 120.0) { io.println("m4-det"); return 16; }
  var t4 = math.matrices.mat4_transpose(m4);
  if t4.m00 != 2.0 || t4.m11 != 3.0 || t4.m22 != 4.0 || t4.m33 != 5.0 { io.println("m4-transpose"); return 17; }
  var inv4 = math.matrices.mat4_inv(m4);
  if !inv4.is_some() { io.println("m4-inv-none"); return 18; }
  var u4 = inv4.unwrap();
  var back4 = math.matrices.mat4_mul(m4, u4);
  if !near(back4.m00, 1.0) || !near(back4.m11, 1.0) || !near(back4.m22, 1.0) || !near(back4.m33, 1.0) { io.println("m4-inv-diag"); return 19; }
  if !near(back4.m01, 0.0) || !near(back4.m13, 0.0) || !near(back4.m23, 0.0) { io.println("m4-inv-off"); return 20; }
  var d4 = math.matrices.mat4_new(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
  var prod4 = math.matrices.mat4_mul(d4, m4);
  if prod4.m00 != 2.0 || prod4.m33 != 5.0 { io.println("m4-mul-id"); return 21; }

  // Dynamic matrices: construction-only checks (len). Element reads of a
  // returned Vec[Vec[Float64]] are broken at runtime (compiler bug), so the
  // dynamic solvers are not exercised element-wise here.
  var idn = math.matrices.mat_identity(3);
  if idn.len() != 3 { io.println("mat-identity-len"); return 22; }
  var id0 = math.matrices.mat_identity(0);
  if id0.len() != 0 { io.println("mat-identity-0"); return 23; }
  var persp = math.matrices.mat_perspective(1.0, 1.5, 0.1, 100.0);
  if persp.len() != 4 { io.println("mat-perspective-len"); return 24; }
  var ortho = math.matrices.mat_ortho(-1.0, 1.0, -1.0, 1.0, 0.1, 100.0);
  if ortho.len() != 4 { io.println("mat-ortho-len"); return 25; }
  var persp_bad = math.matrices.mat_perspective(0.0, 1.0, 0.1, 100.0);
  if persp_bad.len() != 0 { io.println("mat-perspective-fovy"); return 26; }
  var ortho_bad = math.matrices.mat_ortho(1.0, 1.0, -1.0, 1.0, 0.1, 100.0);
  if ortho_bad.len() != 0 { io.println("mat-ortho-degen"); return 27; }

  io.println("smoke_math_matrices: OK");
  return 0;
}

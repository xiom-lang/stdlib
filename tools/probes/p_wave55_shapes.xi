// p_wave55_shapes.xi -- wave 55 shape validation: xiom.geom aggregate batch 2
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-55 clauses on the xiom.geom aggregate: quaternion tail
// (15 pub: from_axis_angle, mul_vec3, inverse, dot, length, is_unit, slerp,
// nlerp, from_mat4, to_mat4, to_mat3, roll, pitch, yaw, angle_between),
// Mat2 (8), Mat3 (12) and the Mat4 core (10: identity, mul, translate,
// scale, rotate_x/y/z, perspective, look_at, transform_vec3).
// Struct-payload Options (mat2/mat3 inverse) are checked through is_some
// only. Struct literals are written in DECLARATION order (the wave-54
// positional-literal finding). Returns 0 when every case holds.

module p_wave55_shapes

use xiom.geom;
use xiom.geom.Vec2;
use xiom.geom.Vec3;
use xiom.geom.Vec4;
use xiom.geom.Quaternion;
use xiom.geom.Mat2;
use xiom.geom.Mat3;
use xiom.geom.Mat4;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- quaternion tail
  var qi = geom.quat_identity();
  var qh = geom.quat_from_axis_angle(geom.vec3_new(0.0, 0.0, 2.0), math.PI / 2.0);
  if !(near(qh.x, 0.0) && near(qh.y, 0.0) && near(qh.z, 0.70710678) && near(qh.w, 0.70710678)) { return 1; }
  var qz0 = geom.quat_from_axis_angle(geom.vec3_new(0.0, 0.0, 0.0), math.PI / 2.0);
  if !(qz0.x == 0.0 && qz0.y == 0.0 && qz0.z == 0.0 && near(qz0.w, 0.70710678)) { return 2; }
  var mv = geom.quat_mul_vec3(qh, geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(mv.x, 0.0) && near(mv.y, 1.0) && near(mv.z, 0.0)) { return 3; }
  var qinv = geom.quat_inverse(qh);
  if !(near(qinv.x, 0.0) && near(qinv.y, 0.0) && near(qinv.z, -0.70710678) && near(qinv.w, 0.70710678)) { return 4; }
  var qback = geom.quat_mul(qinv, qh);
  if !(near(qback.x, 0.0) && near(qback.y, 0.0) && near(qback.z, 0.0) && near(qback.w, 1.0)) { return 5; }
  if !near(geom.quat_dot(qi, qi), 1.0) { return 6; }
  if !near(geom.quat_dot(qi, qh), 0.70710678) { return 7; }
  if !near(geom.quat_length(qh), 1.0) { return 8; }
  if !geom.quat_is_unit(qh, 1e-9) { return 9; }
  if geom.quat_is_unit(Quaternion{ x: 0.0; y: 0.0; z: 0.0; w: 0.0; }, 1e-9) { return 10; }
  var sl0 = geom.quat_slerp(qi, qh, 0.0);
  if !(sl0.x == 0.0 && sl0.y == 0.0 && sl0.z == 0.0 && sl0.w == 1.0) { return 11; }
  var sl1 = geom.quat_slerp(qi, qh, 1.0);
  if !(near(sl1.z, qh.z) && near(sl1.w, qh.w)) { return 12; }
  var slh = geom.quat_slerp(qi, qh, 0.5);
  if !(near(slh.z, 0.38268343) && near(slh.w, 0.92387953)) { return 13; }
  var sopp = geom.quat_slerp(qi, Quaternion{ x: 0.0; y: 0.0; z: -0.70710678; w: -0.70710678; }, 0.5);
  if !(near(sopp.z, 0.38268343) && near(sopp.w, 0.92387953)) { return 14; }
  var nlr = geom.quat_nlerp(qi, qh, 0.5);
  if !(near(nlr.z, 0.38268343) && near(nlr.w, 0.92387953)) { return 15; }
  var mq = geom.mat4_from_quat(qh);
  var qb = geom.quat_from_mat4(&mq);
  if !(near(qb.z, 0.70710678) && near(qb.w, 0.70710678)) { return 16; }
  var mid = geom.mat4_identity();
  var qid = geom.quat_from_mat4(&mid);
  if !(near(qid.x, 0.0) && near(qid.y, 0.0) && near(qid.z, 0.0) && near(qid.w, 1.0)) { return 17; }
  var tm4 = geom.quat_to_mat4(qh);
  if !(near(tm4.m00, 0.0) && near(tm4.m01, -1.0) && near(tm4.m10, 1.0) && near(tm4.m11, 0.0)) { return 18; }
  if !(tm4.m03 == 0.0 && tm4.m13 == 0.0 && tm4.m23 == 0.0 && tm4.m30 == 0.0 && tm4.m31 == 0.0 && tm4.m32 == 0.0 && tm4.m33 == 1.0) { return 19; }
  var tm3 = geom.quat_to_mat3(qh);
  if !(near(tm3.m00, 0.0) && near(tm3.m01, -1.0) && near(tm3.m10, 1.0) && near(tm3.m11, 0.0) && near(tm3.m22, 1.0)) { return 20; }
  var qe = geom.quat_from_euler(0.3, 0.2, 0.1);
  if !near(geom.quat_roll(qe), 0.1) { return 21; }
  if !near(geom.quat_pitch(qe), 0.2) { return 22; }
  if !near(geom.quat_yaw(qe), 0.3) { return 23; }
  if !near(geom.quat_roll(qi), 0.0) { return 24; }
  if !near(geom.quat_pitch(qi), 0.0) { return 25; }
  if !near(geom.quat_yaw(qi), 0.0) { return 26; }
  if !near(geom.quat_angle_between(qi, qh), math.PI / 2.0) { return 27; }
  if !near(geom.quat_angle_between(qi, qi), 0.0) { return 28; }

  // ---- Mat2
  var mi2 = geom.mat2_identity();
  if !(mi2.m00 == 1.0 && mi2.m01 == 0.0 && mi2.m10 == 0.0 && mi2.m11 == 1.0) { return 29; }
  var a2 = Mat2{ m00: 1.0; m01: 2.0; m10: 3.0; m11: 4.0; };
  var a2sq = geom.mat2_mul(a2, a2);
  if !(a2sq.m00 == 7.0 && a2sq.m01 == 10.0 && a2sq.m10 == 15.0 && a2sq.m11 == 22.0) { return 30; }
  var a2t = geom.mat2_transpose(a2);
  if !(a2t.m00 == 1.0 && a2t.m01 == 3.0 && a2t.m10 == 2.0 && a2t.m11 == 4.0) { return 31; }
  if geom.mat2_determinant(a2) != -2.0 { return 32; }
  var inv2 = geom.mat2_inverse(Mat2{ m00: 2.0; m01: 0.0; m10: 0.0; m11: 4.0; });
  if !inv2.is_some { return 33; }
  var inv2z = geom.mat2_inverse(Mat2{ m00: 1.0; m01: 2.0; m10: 3.0; m11: 6.0; });
  if inv2z.is_some { return 34; }
  var sc2 = geom.mat2_scale(3.0);
  if !(sc2.m00 == 3.0 && sc2.m01 == 0.0 && sc2.m10 == 0.0 && sc2.m11 == 3.0) { return 35; }
  var rot2 = geom.mat2_rotation(math.PI / 2.0);
  if !(near(rot2.m00, 0.0) && near(rot2.m01, -1.0) && near(rot2.m10, 1.0) && near(rot2.m11, 0.0)) { return 36; }
  var tv2 = geom.mat2_transform_vec2(rot2, geom.vec2_new(1.0, 0.0));
  if !(near(tv2.x, 0.0) && near(tv2.y, 1.0)) { return 37; }

  // ---- Mat3
  var mi3 = geom.mat3_identity();
  if !(mi3.m00 == 1.0 && mi3.m01 == 0.0 && mi3.m11 == 1.0 && mi3.m22 == 1.0) { return 38; }
  var a3 = Mat3{ m00: 1.0; m01: 2.0; m02: 3.0; m10: 4.0; m11: 5.0; m12: 6.0; m20: 7.0; m21: 8.0; m22: 9.0; };
  var a3sq = geom.mat3_mul(a3, a3);
  if !(a3sq.m00 == 30.0 && a3sq.m01 == 36.0 && a3sq.m02 == 42.0) { return 39; }
  if !(a3sq.m20 == 102.0 && a3sq.m21 == 126.0 && a3sq.m22 == 150.0) { return 40; }
  var a3t = geom.mat3_transpose(a3);
  if !(a3t.m00 == 1.0 && a3t.m01 == 4.0 && a3t.m02 == 7.0 && a3t.m20 == 3.0 && a3t.m21 == 6.0 && a3t.m22 == 9.0) { return 41; }
  var d3 = Mat3{ m00: 2.0; m01: 0.0; m02: 0.0; m10: 0.0; m11: 3.0; m12: 0.0; m20: 0.0; m21: 0.0; m22: 4.0; };
  if geom.mat3_determinant(d3) != 24.0 { return 42; }
  var inv3 = geom.mat3_inverse(d3);
  if !inv3.is_some { return 43; }
  var inv3z = geom.mat3_inverse(Mat3{ m00: 1.0; m01: 2.0; m02: 3.0; m10: 4.0; m11: 5.0; m12: 6.0; m20: 7.0; m21: 8.0; m22: 9.0; });
  if inv3z.is_some { return 44; }
  var rotz3 = geom.mat3_rotation_z(math.PI / 2.0);
  var tv3 = geom.mat3_transform_vec3(rotz3, geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(tv3.x, 0.0) && near(tv3.y, 1.0) && near(tv3.z, 0.0)) { return 45; }
  var sc3 = geom.mat3_scale(2.0);
  if !(sc3.m00 == 2.0 && sc3.m11 == 2.0 && sc3.m22 == 2.0) { return 46; }
  var sc3x = geom.mat3_scale_xyz(2.0, 3.0, 4.0);
  if !(sc3x.m00 == 2.0 && sc3x.m11 == 3.0 && sc3x.m22 == 4.0) { return 47; }
  var rx3 = geom.mat3_rotation_x(math.PI / 2.0);
  if !(near(rx3.m11, 0.0) && near(rx3.m12, -1.0) && near(rx3.m21, 1.0) && near(rx3.m22, 0.0) && rx3.m00 == 1.0) { return 48; }
  var ry3 = geom.mat3_rotation_y(math.PI / 2.0);
  if !(near(ry3.m00, 0.0) && near(ry3.m02, 1.0) && near(ry3.m20, -1.0) && near(ry3.m22, 0.0) && ry3.m11 == 1.0) { return 49; }
  var fq3 = geom.mat3_from_quat(qh);
  if !(near(fq3.m00, 0.0) && near(fq3.m01, -1.0) && near(fq3.m10, 1.0) && near(fq3.m11, 0.0) && near(fq3.m22, 1.0)) { return 50; }
  var fq3z = geom.mat3_from_quat(Quaternion{ x: 0.0; y: 0.0; z: 0.0; w: 0.0; });
  if !(fq3z.m00 == 1.0 && fq3z.m11 == 1.0 && fq3z.m22 == 1.0 && fq3z.m01 == 0.0 && fq3z.m10 == 0.0) { return 51; }

  // ---- Mat4 core
  var mi4 = geom.mat4_identity();
  if !(mi4.m00 == 1.0 && mi4.m11 == 1.0 && mi4.m22 == 1.0 && mi4.m33 == 1.0 && mi4.m03 == 0.0 && mi4.m30 == 0.0) { return 52; }
  var tr4 = geom.mat4_translate(1.0, 2.0, 3.0);
  if !(tr4.m03 == 1.0 && tr4.m13 == 2.0 && tr4.m23 == 3.0 && tr4.m00 == 1.0 && tr4.m33 == 1.0) { return 53; }
  var mul4 = geom.mat4_mul(geom.mat4_identity(), tr4);
  if !(near(mul4.m03, 1.0) && near(mul4.m13, 2.0) && near(mul4.m23, 3.0) && near(mul4.m33, 1.0)) { return 54; }
  var sc4 = geom.mat4_scale(2.0, 3.0, 4.0);
  if !(sc4.m00 == 2.0 && sc4.m11 == 3.0 && sc4.m22 == 4.0 && sc4.m33 == 1.0) { return 55; }
  var rx4 = geom.mat4_rotate_x(math.PI / 2.0);
  if !(near(rx4.m11, 0.0) && near(rx4.m12, -1.0) && near(rx4.m21, 1.0) && near(rx4.m22, 0.0)) { return 56; }
  var ry4 = geom.mat4_rotate_y(math.PI / 2.0);
  if !(near(ry4.m00, 0.0) && near(ry4.m02, 1.0) && near(ry4.m20, -1.0) && near(ry4.m22, 0.0)) { return 57; }
  var rz4 = geom.mat4_rotate_z(math.PI / 2.0);
  if !(near(rz4.m00, 0.0) && near(rz4.m01, -1.0) && near(rz4.m10, 1.0) && near(rz4.m11, 0.0)) { return 58; }
  var persp = geom.mat4_perspective(math.PI / 2.0, 1.0, 1.0, 100.0);
  if !(near(persp.m00, 1.0) && near(persp.m11, 1.0) && near(persp.m22, -1.02020202) && near(persp.m23, -2.02020202) && persp.m32 == -1.0) { return 59; }
  var la = geom.mat4_look_at(geom.vec3_new(0.0, 0.0, 5.0), geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0));
  if !(la.m30 == 0.0 && la.m31 == 0.0 && la.m32 == 0.0 && la.m33 == 1.0) { return 60; }
  var lv = geom.mat4_transform_vec3(la, geom.vec3_new(0.0, 0.0, 5.0));
  if !(near(lv.x, 0.0) && near(lv.y, 0.0) && near(lv.z, 0.0)) { return 61; }
  var tv4 = geom.mat4_transform_vec3(tr4, geom.vec3_new(0.0, 0.0, 0.0));
  if !(near(tv4.x, 1.0) && near(tv4.y, 2.0) && near(tv4.z, 3.0)) { return 62; }
  var zdiv = geom.mat4_transform_vec3(Mat4{ m00: 0.0; m01: 0.0; m02: 0.0; m03: 0.0; m10: 0.0; m11: 0.0; m12: 0.0; m13: 0.0; m20: 0.0; m21: 0.0; m22: 0.0; m23: 0.0; m30: 0.0; m31: 0.0; m32: 0.0; m33: 0.0; }, geom.vec3_new(1.0, 2.0, 3.0));
  if !(zdiv.x == 0.0 && zdiv.y == 0.0 && zdiv.z == 0.0) { return 63; }

  // ---- NaN-tolerance paths (field-only, no strict delegates)
  var big = 1.0e308;
  var inf = big + big;
  var nan = inf - inf;
  if !(nan != nan) { return 64; }
  var nq = Quaternion{ x: nan; y: 0.0; z: 0.0; w: 1.0; };
  if !(geom.quat_dot(nq, qi) != geom.quat_dot(nq, qi)) { return 65; }
  var n2m = Mat2{ m00: nan; m01: 0.0; m10: 0.0; m11: 1.0; };
  var n2t = geom.mat2_transpose(n2m);
  if !(n2t.m00 != n2t.m00 && n2t.m01 == 0.0 && n2t.m11 == 1.0) { return 67; }
  var n2sq = geom.mat2_mul(n2m, n2m);
  if !(n2sq.m00 != n2sq.m00) { return 68; }
  if !(geom.mat2_determinant(n2m) != geom.mat2_determinant(n2m)) { return 69; }
  var n3m = Mat3{ m00: nan; m01: 0.0; m02: 0.0; m10: 0.0; m11: 1.0; m12: 0.0; m20: 0.0; m21: 0.0; m22: 1.0; };
  var n3sq = geom.mat3_mul(n3m, n3m);
  if !(n3sq.m00 != n3sq.m00 && n3sq.m11 == 1.0) { return 70; }

  return 0;
}

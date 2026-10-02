// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_geom
use xiom.geom;
use xiom.geom.Quaternion;
use xiom.geom.Mat2;
use xiom.geom.Mat3;
use xiom.math;
fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}
fn main() -> Int {
  var a = xiom.geom.vec3_new(1.0, 2.0, 3.0);
  var b = xiom.geom.vec3_new(4.0, 5.0, 6.0);
  var c = xiom.geom.vec3_add(a, b);
  if !(c.x == 5.0 && c.y == 7.0 && c.z == 9.0) { return 1; }
  if xiom.geom.vec3_dot(a, b) != 32.0 { return 1; }
  var cr = xiom.geom.vec3_cross(a, b);
  if !(cr.x == -3.0 && cr.y == 6.0 && cr.z == -3.0) { return 1; }
  var m = xiom.geom.mat4_identity();
  if m.m00 != 1.0 || m.m11 != 1.0 { return 1; }
  // wave-54 aggregate KATs: vectors, quaternion core, scalar helpers
  var n2 = xiom.geom.vec2_normalize(xiom.geom.vec2_new(3.0, 4.0));
  if !(near(n2.x, 0.6) && near(n2.y, 0.8)) { return 2; }
  var rf2 = xiom.geom.vec2_reflect(xiom.geom.vec2_new(1.0, -1.0), xiom.geom.vec2_new(0.0, 1.0));
  if !(near(rf2.x, 1.0) && near(rf2.y, 1.0)) { return 3; }
  if !xiom.geom.vec2_refract(xiom.geom.vec2_new(1.0, 0.0), xiom.geom.vec2_new(0.0, 1.0), 0.5).is_some { return 4; }
  if xiom.geom.vec2_refract(xiom.geom.vec2_new(1.0, 0.0), xiom.geom.vec2_new(0.0, 1.0), 3.0).is_some { return 5; }
  var pj2 = xiom.geom.vec2_project(xiom.geom.vec2_new(2.0, 3.0), xiom.geom.vec2_new(1.0, 0.0));
  if !(near(pj2.x, 2.0) && near(pj2.y, 0.0)) { return 6; }
  var rj2 = xiom.geom.vec2_reject(xiom.geom.vec2_new(2.0, 3.0), xiom.geom.vec2_new(1.0, 0.0));
  if !(near(rj2.x, 0.0) && near(rj2.y, 3.0)) { return 7; }
  if !near(xiom.geom.vec2_angle_between(xiom.geom.vec2_new(1.0, 0.0), xiom.geom.vec2_new(0.0, 1.0)), math.PI / 2.0) { return 8; }
  var nl2 = xiom.geom.vec2_nlerp(xiom.geom.vec2_new(1.0, 0.0), xiom.geom.vec2_new(0.0, 1.0), 0.5);
  if !(near(nl2.x, 0.70710678) && near(nl2.y, 0.70710678)) { return 9; }
  var rt2 = xiom.geom.vec2_rotate(xiom.geom.vec2_new(1.0, 0.0), math.PI / 2.0);
  if !(near(rt2.x, 0.0) && near(rt2.y, 1.0)) { return 10; }
  var ra2 = xiom.geom.vec2_rotate_around(xiom.geom.vec2_new(2.0, 0.0), xiom.geom.vec2_new(1.0, 0.0), math.PI / 2.0);
  if !(near(ra2.x, 1.0) && near(ra2.y, 1.0)) { return 11; }
  var pp2 = xiom.geom.vec2_perpendicular(xiom.geom.vec2_new(2.0, 3.0));
  if !(pp2.x == -3.0 && pp2.y == 2.0) { return 12; }
  var fa2 = xiom.geom.vec2_from_angle(0.0);
  if !(near(fa2.x, 1.0) && near(fa2.y, 0.0)) { return 13; }
  if !xiom.geom.vec2_is_unit(xiom.geom.vec2_new(0.6, 0.8), 1e-9) { return 14; }
  if xiom.geom.vec2_is_unit(xiom.geom.vec2_new(1.0, 1.0), 1e-9) { return 15; }
  if !xiom.geom.vec2_is_zero(xiom.geom.vec2_new(0.0, 0.0)) { return 16; }
  if xiom.geom.vec2_is_zero(xiom.geom.vec2_new(1e-300, 0.0)) { return 17; }
  if !xiom.geom.vec2_approx_eq(xiom.geom.vec2_new(1.0, 2.0), xiom.geom.vec2_new(1.0 + 1e-9, 2.0 - 1e-9), 1e-6) { return 18; }
  var cl2 = xiom.geom.vec2_clamp_length(xiom.geom.vec2_new(3.0, 4.0), 1.0);
  if !(near(cl2.x, 0.6) && near(cl2.y, 0.8)) { return 19; }
  var n3 = xiom.geom.vec3_normalize(xiom.geom.vec3_new(0.0, 0.0, 2.0));
  if !(near(n3.x, 0.0) && near(n3.y, 0.0) && near(n3.z, 1.0)) { return 20; }
  var lr3 = xiom.geom.vec3_lerp(xiom.geom.vec3_new(0.0, 0.0, 0.0), xiom.geom.vec3_new(2.0, 4.0, 6.0), 0.5);
  if !(lr3.x == 1.0 && lr3.y == 2.0 && lr3.z == 3.0) { return 21; }
  var rf3 = xiom.geom.vec3_reflect(xiom.geom.vec3_new(1.0, -1.0, 0.0), xiom.geom.vec3_new(0.0, 1.0, 0.0));
  if !(near(rf3.x, 1.0) && near(rf3.y, 1.0) && near(rf3.z, 0.0)) { return 22; }
  if !xiom.geom.vec3_refract(xiom.geom.vec3_new(1.0, 0.0, 0.0), xiom.geom.vec3_new(0.0, 1.0, 0.0), 0.5).is_some { return 23; }
  if xiom.geom.vec3_refract(xiom.geom.vec3_new(1.0, 0.0, 0.0), xiom.geom.vec3_new(0.0, 1.0, 0.0), 3.0).is_some { return 24; }
  var pj3 = xiom.geom.vec3_project(xiom.geom.vec3_new(2.0, 3.0, 4.0), xiom.geom.vec3_new(0.0, 0.0, 1.0));
  if !(near(pj3.x, 0.0) && near(pj3.y, 0.0) && near(pj3.z, 4.0)) { return 25; }
  var rj3 = xiom.geom.vec3_reject(xiom.geom.vec3_new(2.0, 3.0, 4.0), xiom.geom.vec3_new(0.0, 0.0, 1.0));
  if !(near(rj3.x, 2.0) && near(rj3.y, 3.0) && near(rj3.z, 0.0)) { return 26; }
  if !near(xiom.geom.vec3_angle_between(xiom.geom.vec3_new(1.0, 0.0, 0.0), xiom.geom.vec3_new(0.0, 0.0, 1.0)), math.PI / 2.0) { return 27; }
  var nl3 = xiom.geom.vec3_nlerp(xiom.geom.vec3_new(1.0, 0.0, 0.0), xiom.geom.vec3_new(0.0, 1.0, 0.0), 0.5);
  if !(near(nl3.x, 0.70710678) && near(nl3.y, 0.70710678)) { return 28; }
  var og3 = xiom.geom.vec3_orthogonal(xiom.geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(og3.z, 1.0) && near(xiom.geom.vec3_dot(og3, xiom.geom.vec3_new(1.0, 0.0, 0.0)), 0.0)) { return 29; }
  if !xiom.geom.vec3_is_unit(xiom.geom.vec3_new(0.0, 0.0, 1.0), 1e-9) { return 30; }
  if xiom.geom.vec3_is_zero(xiom.geom.vec3_new(0.0, 1e-300, 0.0)) { return 31; }
  if !xiom.geom.vec3_approx_eq(xiom.geom.vec3_new(1.0, 2.0, 3.0), xiom.geom.vec3_new(1.0, 2.0, 3.0 + 1e-9), 1e-6) { return 32; }
  var cl3 = xiom.geom.vec3_clamp_length(xiom.geom.vec3_new(0.0, 3.0, 4.0), 1.0);
  if !(near(cl3.y, 0.6) && near(cl3.z, 0.8)) { return 33; }
  var v34 = xiom.geom.vec3_from_vec4(xiom.geom.vec4_new(1.0, 2.0, 3.0, 4.0));
  if !(v34.x == 1.0 && v34.y == 2.0 && v34.z == 3.0) { return 34; }
  var v43 = xiom.geom.vec4_from_vec3(xiom.geom.vec3_new(5.0, 6.0, 7.0), 8.0);
  if !(v43.w == 8.0 && xiom.geom.vec4_approx_eq(v43, v43, 1e-9)) { return 35; }
  var qi = xiom.geom.quat_identity();
  if !(qi.x == 0.0 && qi.y == 0.0 && qi.z == 0.0 && qi.w == 1.0) { return 36; }
  var qz = xiom.geom.quat_new(xiom.geom.vec3_new(0.0, 0.0, 1.0), math.PI);
  if !(near(qz.z, 1.0) && near(qz.w, 0.0)) { return 37; }
  var qm = xiom.geom.quat_mul(qi, qz);
  if !(near(qm.z, qz.z) && near(qm.w, qz.w)) { return 38; }
  var qn = xiom.geom.quat_normalize(xiom.geom.quat_mul(qi, qz));
  if !near(xiom.geom.quat_length(qn), 1.0) { return 39; }
  var qc = xiom.geom.quat_conjugate(xiom.geom.quat_new(xiom.geom.vec3_new(0.0, 0.0, 1.0), math.PI));
  if !(near(qc.z, -1.0) && near(qc.w, 0.0)) { return 40; }
  var qrv = xiom.geom.quat_rotate_vec3(qi, xiom.geom.vec3_new(1.0, 2.0, 3.0));
  if !(near(qrv.x, 1.0) && near(qrv.y, 2.0) && near(qrv.z, 3.0)) { return 41; }
  var qh = xiom.geom.quat_new(xiom.geom.vec3_new(0.0, 0.0, 1.0), math.PI / 2.0);
  var qrv2 = xiom.geom.quat_rotate_vec3(qh, xiom.geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(qrv2.x, 0.0) && near(qrv2.y, 1.0)) { return 42; }
  var qe0 = xiom.geom.quat_from_euler(0.0, 0.0, 0.0);
  if !(near(qe0.x, 0.0) && near(qe0.y, 0.0) && near(qe0.z, 0.0) && near(qe0.w, 1.0)) { return 43; }
  var qe = xiom.geom.quat_from_euler(math.PI / 2.0, 0.0, 0.0);
  if !(near(qe.z, 0.70710678) && near(qe.w, 0.70710678)) { return 44; }
  if !xiom.geom.f64_approx_eq(1.0, 1.0 + 1e-9, 1e-6) { return 45; }
  if !near(xiom.geom.f64_deg_to_rad(180.0), math.PI) { return 46; }
  if !near(xiom.geom.f64_rad_to_deg(math.PI), 180.0) { return 47; }
  if !near(xiom.geom.f32_deg_to_rad(90.0), math.PI / 2.0) { return 48; }
  if !near(xiom.geom.f32_rad_to_deg(math.PI / 2.0), 90.0) { return 49; }
  // wave-55 aggregate KATs: quaternion tail + matrices
  var qaa = xiom.geom.quat_from_axis_angle(xiom.geom.vec3_new(0.0, 0.0, 2.0), math.PI / 2.0);
  if !(near(qaa.z, 0.70710678) && near(qaa.w, 0.70710678)) { return 50; }
  var qmv3 = xiom.geom.quat_mul_vec3(qaa, xiom.geom.vec3_new(1.0, 0.0, 0.0));
  if !near(qmv3.y, 1.0) { return 51; }
  var qiv = xiom.geom.quat_inverse(qaa);
  if !(near(qiv.z, -0.70710678) && near(qiv.w, 0.70710678)) { return 52; }
  if !near(xiom.geom.quat_dot(qi, qi), 1.0) { return 53; }
  if !near(xiom.geom.quat_length(qaa), 1.0) { return 54; }
  if !xiom.geom.quat_is_unit(qaa, 1e-9) { return 55; }
  var qsl = xiom.geom.quat_slerp(qi, qaa, 0.5);
  if !(near(qsl.z, 0.38268343) && near(qsl.w, 0.92387953)) { return 56; }
  var qnl = xiom.geom.quat_nlerp(qi, qaa, 0.5);
  if !(near(qnl.z, 0.38268343) && near(qnl.w, 0.92387953)) { return 57; }
  var qm4 = xiom.geom.mat4_from_quat(qaa);
  var qfm = xiom.geom.quat_from_mat4(&qm4);
  if !(near(qfm.z, 0.70710678) && near(qfm.w, 0.70710678)) { return 58; }
  var qtm4 = xiom.geom.quat_to_mat4(qaa);
  if !(near(qtm4.m00, 0.0) && near(qtm4.m01, -1.0)) { return 59; }
  var qtm3 = xiom.geom.quat_to_mat3(qaa);
  if !(near(qtm3.m00, 0.0) && near(qtm3.m10, 1.0)) { return 60; }
  var qeu = xiom.geom.quat_from_euler(0.3, 0.2, 0.1);
  if !near(xiom.geom.quat_roll(qeu), 0.1) { return 61; }
  if !near(xiom.geom.quat_pitch(qeu), 0.2) { return 62; }
  if !near(xiom.geom.quat_yaw(qeu), 0.3) { return 63; }
  if !near(xiom.geom.quat_angle_between(qi, qaa), math.PI / 2.0) { return 64; }
  var m2i = xiom.geom.mat2_identity();
  if !(m2i.m00 == 1.0 && m2i.m11 == 1.0) { return 65; }
  var m2 = Mat2{ m00: 1.0; m01: 2.0; m10: 3.0; m11: 4.0; };
  var m2sq = xiom.geom.mat2_mul(m2, m2);
  if !(m2sq.m00 == 7.0 && m2sq.m11 == 22.0) { return 66; }
  var m2t = xiom.geom.mat2_transpose(m2);
  if !(m2t.m01 == 3.0 && m2t.m10 == 2.0) { return 67; }
  if xiom.geom.mat2_determinant(m2) != -2.0 { return 68; }
  if !xiom.geom.mat2_inverse(m2).is_some { return 69; }
  var m2s = xiom.geom.mat2_scale(3.0);
  if !(m2s.m00 == 3.0 && m2s.m11 == 3.0) { return 70; }
  var m2r = xiom.geom.mat2_rotation(math.PI / 2.0);
  var m2v = xiom.geom.mat2_transform_vec2(m2r, xiom.geom.vec2_new(1.0, 0.0));
  if !(near(m2v.x, 0.0) && near(m2v.y, 1.0)) { return 71; }
  var m3i = xiom.geom.mat3_identity();
  if !(m3i.m00 == 1.0 && m3i.m22 == 1.0) { return 72; }
  var m3 = Mat3{ m00: 1.0; m01: 2.0; m02: 3.0; m10: 4.0; m11: 5.0; m12: 6.0; m20: 7.0; m21: 8.0; m22: 9.0; };
  var m3sq = xiom.geom.mat3_mul(m3, m3);
  if !(m3sq.m00 == 30.0 && m3sq.m22 == 150.0) { return 73; }
  var m3t = xiom.geom.mat3_transpose(m3);
  if !(m3t.m01 == 4.0 && m3t.m20 == 3.0) { return 74; }
  var m3d = Mat3{ m00: 2.0; m01: 0.0; m02: 0.0; m10: 0.0; m11: 3.0; m12: 0.0; m20: 0.0; m21: 0.0; m22: 4.0; };
  if xiom.geom.mat3_determinant(m3d) != 24.0 { return 75; }
  if !xiom.geom.mat3_inverse(m3d).is_some { return 76; }
  var m3rz = xiom.geom.mat3_rotation_z(math.PI / 2.0);
  var m3v = xiom.geom.mat3_transform_vec3(m3rz, xiom.geom.vec3_new(1.0, 0.0, 0.0));
  if !near(m3v.y, 1.0) { return 77; }
  var m3s = xiom.geom.mat3_scale(2.0);
  if !(m3s.m00 == 2.0 && m3s.m22 == 2.0) { return 78; }
  var m3sx = xiom.geom.mat3_scale_xyz(2.0, 3.0, 4.0);
  if !(m3sx.m00 == 2.0 && m3sx.m11 == 3.0 && m3sx.m22 == 4.0) { return 79; }
  var m3rx = xiom.geom.mat3_rotation_x(math.PI / 2.0);
  if !(near(m3rx.m12, -1.0) && near(m3rx.m21, 1.0)) { return 80; }
  var m3ry = xiom.geom.mat3_rotation_y(math.PI / 2.0);
  if !(near(m3ry.m02, 1.0) && near(m3ry.m20, -1.0)) { return 81; }
  var m3fq = xiom.geom.mat3_from_quat(qaa);
  if !(near(m3fq.m01, -1.0) && near(m3fq.m10, 1.0)) { return 82; }
  var mm4 = xiom.geom.mat4_mul(xiom.geom.mat4_identity(), xiom.geom.mat4_translate(1.0, 2.0, 3.0));
  if !(near(mm4.m03, 1.0) && near(mm4.m23, 3.0)) { return 83; }
  var ms4 = xiom.geom.mat4_scale(2.0, 3.0, 4.0);
  if !(ms4.m00 == 2.0 && ms4.m22 == 4.0) { return 84; }
  var mr4x = xiom.geom.mat4_rotate_x(math.PI / 2.0);
  if !(near(mr4x.m12, -1.0) && near(mr4x.m21, 1.0)) { return 85; }
  var mr4y = xiom.geom.mat4_rotate_y(math.PI / 2.0);
  if !(near(mr4y.m02, 1.0) && near(mr4y.m20, -1.0)) { return 86; }
  var mr4z = xiom.geom.mat4_rotate_z(math.PI / 2.0);
  if !(near(mr4z.m01, -1.0) && near(mr4z.m10, 1.0)) { return 87; }
  var mp4 = xiom.geom.mat4_perspective(math.PI / 2.0, 1.0, 1.0, 100.0);
  if !(near(mp4.m22, -1.02020202) && mp4.m32 == -1.0) { return 88; }
  var mla = xiom.geom.mat4_look_at(xiom.geom.vec3_new(0.0, 0.0, 5.0), xiom.geom.vec3_new(0.0, 0.0, 0.0), xiom.geom.vec3_new(0.0, 1.0, 0.0));
  if mla.m33 != 1.0 { return 89; }
  var mtv = xiom.geom.mat4_transform_vec3(xiom.geom.mat4_translate(1.0, 2.0, 3.0), xiom.geom.vec3_new(0.0, 0.0, 0.0));
  if !(near(mtv.x, 1.0) && near(mtv.z, 3.0)) { return 90; }
  return 0;
}

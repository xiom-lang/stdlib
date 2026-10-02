// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_geom
use xiom.geom;
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
  return 0;
}

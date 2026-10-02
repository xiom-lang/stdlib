// p_wave54_shapes.xi -- wave 54 shape validation: xiom.geom aggregate batch 1
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-54 clauses on the xiom.geom aggregate:
// vec2 (16 pub), vec3 (15), vec4 (3), quaternion core (7) and the five
// scalar angle/epsilon helpers. KATs cover normal and degenerate paths
// (zero vectors, underflow-to-zero lengths, zero normals, clamped lerp
// parameters, cancel-to-zero nlerp, identity/axis rotations); a NaN
// section exercises the NaN-tolerant clause forms through field-only
// paths (no clause-strict delegate calls). Vec-payload Option results are
// checked through is_some only. Returns 0 when every case holds.

module p_wave54_shapes

use xiom.geom;
use xiom.geom.Vec2;
use xiom.geom.Vec3;
use xiom.geom.Vec4;
use xiom.geom.Quaternion;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- vec2: construction / normalize
  var v2 = geom.vec2_new(3.0, 4.0);
  if !(v2.x == 3.0 && v2.y == 4.0) { return 1; }
  var n2 = geom.vec2_normalize(v2);
  if !(near(n2.x, 0.6) && near(n2.y, 0.8)) { return 2; }
  var nz2 = geom.vec2_normalize(geom.vec2_new(0.0, 0.0));
  if !(nz2.x == 0.0 && nz2.y == 0.0) { return 3; }
  var nt2 = geom.vec2_normalize(geom.vec2_new(1e-300, 0.0));
  if !(nt2.x == 0.0 && nt2.y == 0.0) { return 4; }
  // ---- vec2: reflect / refract
  var rf2 = geom.vec2_reflect(geom.vec2_new(1.0, -1.0), geom.vec2_new(0.0, 1.0));
  if !(near(rf2.x, 1.0) && near(rf2.y, 1.0)) { return 5; }
  var rf2z = geom.vec2_reflect(geom.vec2_new(1.0, -1.0), geom.vec2_new(0.0, 0.0));
  if !(rf2z.x == 1.0 && rf2z.y == -1.0) { return 6; }
  var fr2 = geom.vec2_refract(geom.vec2_new(1.0, 0.0), geom.vec2_new(0.0, 1.0), 0.5);
  if !fr2.is_some { return 7; }
  var fr2n = geom.vec2_refract(geom.vec2_new(1.0, 0.0), geom.vec2_new(0.0, 1.0), 3.0);
  if fr2n.is_some { return 8; }
  // ---- vec2: project / reject / angle
  var pj2 = geom.vec2_project(geom.vec2_new(2.0, 3.0), geom.vec2_new(1.0, 0.0));
  if !(near(pj2.x, 2.0) && near(pj2.y, 0.0)) { return 9; }
  var pj2z = geom.vec2_project(geom.vec2_new(2.0, 3.0), geom.vec2_new(0.0, 0.0));
  if !(pj2z.x == 0.0 && pj2z.y == 0.0) { return 10; }
  var rj2 = geom.vec2_reject(geom.vec2_new(2.0, 3.0), geom.vec2_new(1.0, 0.0));
  if !(near(rj2.x, 0.0) && near(rj2.y, 3.0)) { return 11; }
  var rj2z = geom.vec2_reject(geom.vec2_new(2.0, 3.0), geom.vec2_new(0.0, 0.0));
  if !(rj2z.x == 2.0 && rj2z.y == 3.0) { return 12; }
  var a2 = geom.vec2_angle_between(geom.vec2_new(1.0, 0.0), geom.vec2_new(0.0, 1.0));
  if !near(a2, math.PI / 2.0) { return 13; }
  var a2z = geom.vec2_angle_between(geom.vec2_new(1.0, 0.0), geom.vec2_new(0.0, 0.0));
  if a2z != 0.0 { return 14; }
  // ---- vec2: nlerp / rotate / rotate_around
  var nl2 = geom.vec2_nlerp(geom.vec2_new(1.0, 0.0), geom.vec2_new(0.0, 1.0), 0.5);
  if !(near(nl2.x, 0.70710678) && near(nl2.y, 0.70710678)) { return 15; }
  var nl2c = geom.vec2_nlerp(geom.vec2_new(1.0, 0.0), geom.vec2_new(-1.0, 0.0), 0.5);
  if !(nl2c.x == 0.0 && nl2c.y == 0.0) { return 16; }
  var rt2 = geom.vec2_rotate(geom.vec2_new(1.0, 0.0), math.PI / 2.0);
  if !(near(rt2.x, 0.0) && near(rt2.y, 1.0)) { return 17; }
  var ra2 = geom.vec2_rotate_around(geom.vec2_new(2.0, 0.0), geom.vec2_new(1.0, 0.0), math.PI / 2.0);
  if !(near(ra2.x, 1.0) && near(ra2.y, 1.0)) { return 18; }
  // ---- vec2: perpendicular / from_angle / predicates / clamp
  var pp2 = geom.vec2_perpendicular(geom.vec2_new(2.0, 3.0));
  if !(pp2.x == -3.0 && pp2.y == 2.0) { return 19; }
  var fa2 = geom.vec2_from_angle(0.0);
  if !(near(fa2.x, 1.0) && near(fa2.y, 0.0)) { return 20; }
  var fa2b = geom.vec2_from_angle(math.PI / 2.0);
  if !(near(fa2b.x, 0.0) && near(fa2b.y, 1.0)) { return 21; }
  if !(geom.vec2_is_unit(geom.vec2_new(0.6, 0.8), 1e-9)) { return 22; }
  if geom.vec2_is_unit(geom.vec2_new(1.0, 1.0), 1e-9) { return 23; }
  if !(geom.vec2_is_zero(geom.vec2_new(0.0, 0.0))) { return 24; }
  if geom.vec2_is_zero(geom.vec2_new(1e-300, 0.0)) { return 25; }
  if !(geom.vec2_approx_eq(geom.vec2_new(1.0, 2.0), geom.vec2_new(1.0 + 1e-9, 2.0 - 1e-9), 1e-6)) { return 26; }
  if geom.vec2_approx_eq(geom.vec2_new(1.0, 2.0), geom.vec2_new(1.0, 2.001), 1e-6) { return 27; }
  var cl2 = geom.vec2_clamp_length(geom.vec2_new(3.0, 4.0), 1.0);
  if !(near(cl2.x, 0.6) && near(cl2.y, 0.8)) { return 28; }
  var cl2u = geom.vec2_clamp_length(geom.vec2_new(3.0, 4.0), 10.0);
  if !(cl2u.x == 3.0 && cl2u.y == 4.0) { return 29; }
  var cl2z = geom.vec2_clamp_length(geom.vec2_new(3.0, 4.0), 0.0);
  if !(cl2z.x == 0.0 && cl2z.y == 0.0) { return 30; }

  // ---- vec3: construction / normalize / lerp
  var v3 = geom.vec3_new(1.0, 2.0, 3.0);
  if !(v3.x == 1.0 && v3.y == 2.0 && v3.z == 3.0) { return 31; }
  var n3 = geom.vec3_normalize(geom.vec3_new(0.0, 0.0, 2.0));
  if !(near(n3.x, 0.0) && near(n3.y, 0.0) && near(n3.z, 1.0)) { return 32; }
  var nz3 = geom.vec3_normalize(geom.vec3_new(0.0, 0.0, 0.0));
  if !(nz3.x == 0.0 && nz3.y == 0.0 && nz3.z == 0.0) { return 33; }
  var lr3 = geom.vec3_lerp(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(2.0, 4.0, 6.0), 0.5);
  if !(lr3.x == 1.0 && lr3.y == 2.0 && lr3.z == 3.0) { return 34; }
  var lr3a = geom.vec3_lerp(geom.vec3_new(1.0, 2.0, 3.0), geom.vec3_new(4.0, 5.0, 6.0), -1.0);
  if !(lr3a.x == 1.0 && lr3a.y == 2.0 && lr3a.z == 3.0) { return 35; }
  var lr3b = geom.vec3_lerp(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(2.0, 4.0, 6.0), 2.0);
  if !(lr3b.x == 2.0 && lr3b.y == 4.0 && lr3b.z == 6.0) { return 36; }
  // ---- vec3: reflect / refract
  var rf3 = geom.vec3_reflect(geom.vec3_new(1.0, -1.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0));
  if !(near(rf3.x, 1.0) && near(rf3.y, 1.0) && near(rf3.z, 0.0)) { return 37; }
  var rf3z = geom.vec3_reflect(geom.vec3_new(1.0, -1.0, 2.0), geom.vec3_new(0.0, 0.0, 0.0));
  if !(rf3z.x == 1.0 && rf3z.y == -1.0 && rf3z.z == 2.0) { return 38; }
  var fr3 = geom.vec3_refract(geom.vec3_new(1.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0), 0.5);
  if !fr3.is_some { return 39; }
  var fr3n = geom.vec3_refract(geom.vec3_new(1.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0), 3.0);
  if fr3n.is_some { return 40; }
  // ---- vec3: project / reject / angle
  var pj3 = geom.vec3_project(geom.vec3_new(2.0, 3.0, 4.0), geom.vec3_new(0.0, 0.0, 1.0));
  if !(near(pj3.x, 0.0) && near(pj3.y, 0.0) && near(pj3.z, 4.0)) { return 41; }
  var pj3z = geom.vec3_project(geom.vec3_new(2.0, 3.0, 4.0), geom.vec3_new(0.0, 0.0, 0.0));
  if !(pj3z.x == 0.0 && pj3z.y == 0.0 && pj3z.z == 0.0) { return 42; }
  var rj3 = geom.vec3_reject(geom.vec3_new(2.0, 3.0, 4.0), geom.vec3_new(0.0, 0.0, 1.0));
  if !(near(rj3.x, 2.0) && near(rj3.y, 3.0) && near(rj3.z, 0.0)) { return 43; }
  var rj3z = geom.vec3_reject(geom.vec3_new(2.0, 3.0, 4.0), geom.vec3_new(0.0, 0.0, 0.0));
  if !(rj3z.x == 2.0 && rj3z.y == 3.0 && rj3z.z == 4.0) { return 44; }
  var a3 = geom.vec3_angle_between(geom.vec3_new(1.0, 0.0, 0.0), geom.vec3_new(0.0, 0.0, 1.0));
  if !near(a3, math.PI / 2.0) { return 45; }
  var a3z = geom.vec3_angle_between(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(0.0, 0.0, 1.0));
  if a3z != 0.0 { return 46; }
  // ---- vec3: nlerp / orthogonal / predicates / clamp
  var nl3 = geom.vec3_nlerp(geom.vec3_new(1.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0), 0.5);
  if !(near(nl3.x, 0.70710678) && near(nl3.y, 0.70710678) && near(nl3.z, 0.0)) { return 47; }
  var nl3c = geom.vec3_nlerp(geom.vec3_new(1.0, 0.0, 0.0), geom.vec3_new(-1.0, 0.0, 0.0), 0.5);
  if !(nl3c.x == 0.0 && nl3c.y == 0.0 && nl3c.z == 0.0) { return 48; }
  var og3 = geom.vec3_orthogonal(geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(og3.x, 0.0) && near(og3.y, 0.0) && near(og3.z, 1.0)) { return 49; }
  if !near(geom.vec3_dot(og3, geom.vec3_new(1.0, 0.0, 0.0)), 0.0) { return 50; }
  var og3z = geom.vec3_orthogonal(geom.vec3_new(0.0, 0.0, 0.0));
  if !(og3z.x == 0.0 && og3z.y == 0.0 && og3z.z == 0.0) { return 51; }
  if !(geom.vec3_is_unit(geom.vec3_new(0.0, 0.0, 1.0), 1e-9)) { return 52; }
  if geom.vec3_is_unit(geom.vec3_new(1.0, 1.0, 0.0), 1e-9) { return 53; }
  if !(geom.vec3_is_zero(geom.vec3_new(0.0, 0.0, 0.0))) { return 54; }
  if geom.vec3_is_zero(geom.vec3_new(0.0, 1e-300, 0.0)) { return 55; }
  if !(geom.vec3_approx_eq(geom.vec3_new(1.0, 2.0, 3.0), geom.vec3_new(1.0, 2.0, 3.0 + 1e-9), 1e-6)) { return 56; }
  if geom.vec3_approx_eq(geom.vec3_new(1.0, 2.0, 3.0), geom.vec3_new(1.0, 2.0, 3.5), 1e-6) { return 57; }
  var cl3 = geom.vec3_clamp_length(geom.vec3_new(0.0, 3.0, 4.0), 1.0);
  if !(near(cl3.x, 0.0) && near(cl3.y, 0.6) && near(cl3.z, 0.8)) { return 58; }
  var cl3u = geom.vec3_clamp_length(geom.vec3_new(0.0, 3.0, 4.0), 10.0);
  if !(cl3u.x == 0.0 && cl3u.y == 3.0 && cl3u.z == 4.0) { return 59; }
  var cl3z = geom.vec3_clamp_length(geom.vec3_new(0.0, 3.0, 4.0), 0.0);
  if !(cl3z.x == 0.0 && cl3z.y == 0.0 && cl3z.z == 0.0) { return 60; }

  // ---- vec4 + conversions
  var v4 = geom.vec4_new(1.0, 2.0, 3.0, 4.0);
  if !(v4.x == 1.0 && v4.y == 2.0 && v4.z == 3.0 && v4.w == 4.0) { return 61; }
  if !(geom.vec4_approx_eq(v4, geom.vec4_new(1.0, 2.0, 3.0, 4.0 + 1e-9), 1e-6)) { return 62; }
  if geom.vec4_approx_eq(v4, geom.vec4_new(1.0, 2.0, 3.0, 5.0), 1e-6) { return 63; }
  var v34 = geom.vec3_from_vec4(v4);
  if !(v34.x == 1.0 && v34.y == 2.0 && v34.z == 3.0) { return 64; }
  var v43 = geom.vec4_from_vec3(geom.vec3_new(5.0, 6.0, 7.0), 8.0);
  if !(v43.x == 5.0 && v43.y == 6.0 && v43.z == 7.0 && v43.w == 8.0) { return 65; }

  // ---- quaternion core
  var qi = geom.quat_identity();
  if !(qi.x == 0.0 && qi.y == 0.0 && qi.z == 0.0 && qi.w == 1.0) { return 66; }
  var qz = geom.quat_new(geom.vec3_new(0.0, 0.0, 1.0), math.PI);
  if !(near(qz.x, 0.0) && near(qz.y, 0.0) && near(qz.z, 1.0) && near(qz.w, 0.0)) { return 67; }
  var qm = geom.quat_mul(qi, qz);
  if !(near(qm.x, qz.x) && near(qm.y, qz.y) && near(qm.z, qz.z) && near(qm.w, qz.w)) { return 68; }
  var qzero = Quaternion{ x: 0.0; y: 0.0; z: 0.0; w: 0.0; };
  var qn = geom.quat_normalize(qzero);
  if !(qn.x == 0.0 && qn.y == 0.0 && qn.z == 0.0 && qn.w == 1.0) { return 69; }
  var qn2 = geom.quat_normalize(Quaternion{ x: 2.0; y: 0.0; z: 0.0; w: 0.0; });
  if !(near(qn2.x, 1.0) && near(qn2.y, 0.0) && near(qn2.z, 0.0) && near(qn2.w, 0.0)) { return 70; }
  var qc = geom.quat_conjugate(Quaternion{ x: 1.0; y: 2.0; z: 3.0; w: 4.0; });
  if !(qc.x == -1.0 && qc.y == -2.0 && qc.z == -3.0 && qc.w == 4.0) { return 71; }
  var qri = geom.quat_rotate_vec3(qi, geom.vec3_new(1.0, 2.0, 3.0));
  if !(near(qri.x, 1.0) && near(qri.y, 2.0) && near(qri.z, 3.0)) { return 72; }
  var qh = geom.quat_new(geom.vec3_new(0.0, 0.0, 1.0), math.PI / 2.0);
  var qrv = geom.quat_rotate_vec3(qh, geom.vec3_new(1.0, 0.0, 0.0));
  if !(near(qrv.x, 0.0) && near(qrv.y, 1.0) && near(qrv.z, 0.0)) { return 73; }
  var qe0 = geom.quat_from_euler(0.0, 0.0, 0.0);
  if !(near(qe0.x, 0.0) && near(qe0.y, 0.0) && near(qe0.z, 0.0) && near(qe0.w, 1.0)) { return 74; }
  var qe = geom.quat_from_euler(math.PI / 2.0, 0.0, 0.0);
  if !(near(qe.x, 0.0) && near(qe.y, 0.0) && near(qe.z, 0.70710678) && near(qe.w, 0.70710678)) { return 75; }

  // ---- scalar helpers
  if !(geom.f64_approx_eq(1.0, 1.0 + 1e-9, 1e-6)) { return 76; }
  if geom.f64_approx_eq(1.0, 3.0, 0.5) { return 77; }
  if !near(geom.f64_deg_to_rad(180.0), math.PI) { return 78; }
  if !near(geom.f64_rad_to_deg(math.PI), 180.0) { return 79; }
  if !near(geom.f32_deg_to_rad(90.0), math.PI / 2.0) { return 80; }
  if !near(geom.f32_rad_to_deg(math.PI / 2.0), 90.0) { return 81; }

  // ---- NaN-tolerance section (field-only paths; no strict delegates)
  var big = 1.0e308;
  var inf = big + big;
  var nan = inf - inf;
  if !(nan != nan) { return 82; }
  var nv2 = geom.vec2_new(nan, 0.0);
  if !(nv2.x != nv2.x) { return 83; }
  var np2 = geom.vec2_perpendicular(nv2);
  if !(np2.x == 0.0 && np2.y != np2.y) { return 84; }
  if geom.vec2_is_zero(nv2) { return 85; }
  if geom.vec2_approx_eq(nv2, nv2, 1e-6) { return 86; }
  var nr2 = geom.vec2_rotate(nv2, 0.0);
  if !(nr2.x != nr2.x) { return 87; }
  if !(geom.vec2_new(nan, 1.0).x != geom.vec2_new(nan, 1.0).x) { return 88; }
  var nv3 = geom.vec3_new(nan, 0.0, 0.0);
  if geom.vec3_is_zero(nv3) { return 89; }
  var nf3 = geom.vec3_from_vec4(geom.vec4_new(nan, 0.0, 0.0, 0.0));
  if !(nf3.x != nf3.x) { return 90; }
  var nf4 = geom.vec4_from_vec3(nv3, 0.0);
  if !(nf4.x != nf4.x) { return 91; }
  if geom.vec4_approx_eq(nf4, nf4, 1e-6) { return 92; }
  var nl3n = geom.vec3_lerp(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(1.0, 1.0, 1.0), nan);
  if !(nl3n.x != nl3n.x) { return 93; }
  var nq = Quaternion{ x: nan; y: 0.0; z: 0.0; w: 1.0; };
  var nmq = geom.quat_mul(nq, qi);
  if !(nmq.x != nmq.x) { return 94; }
  var ncq = geom.quat_conjugate(nq);
  if !(ncq.x != ncq.x && ncq.w == 1.0) { return 95; }
  var nnq = geom.quat_new(nv3, 1.0);
  if !(nnq.x != nnq.x) { return 96; }
  if geom.f64_approx_eq(nan, 0.0, 1e-6) { return 97; }
  if !(geom.f64_deg_to_rad(nan) != geom.f64_deg_to_rad(nan)) { return 98; }
  if !(geom.f64_rad_to_deg(nan) != geom.f64_rad_to_deg(nan)) { return 99; }

  return 0;
}

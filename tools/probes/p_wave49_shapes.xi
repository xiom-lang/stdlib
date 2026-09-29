// p_wave49_shapes.xi -- wave 49 shape validation: xiom.geom primitive modules
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-49 clauses on the split geom primitive modules
// (xiom.geom.vec, xiom.geom.quat, xiom.geom.mat): component mirrors,
// NaN-tolerant arithmetic claims, zero-vector canonical forms for the
// norm functions, length invariants, quaternion identity/normalization
// forms, matrix shape claims, and the presence mirror on mat_inv.
// Returns 0 when every case holds.

module p_wave49_shapes

use xiom.geom.vec;
use xiom.geom.quat;
use xiom.geom.mat;

fn main() -> Int {
  // ---- vec: 2D primitives
  var a2 = vec.vec2(1.0, 2.0);
  var b2 = vec.vec2(3.0, 5.0);
  var s2 = vec.vec2_add(a2, b2);
  if s2.x != 4.0 || s2.y != 7.0 { return 1; }
  var d2 = vec.vec2_sub(b2, a2);
  if d2.x != 2.0 || d2.y != 3.0 { return 2; }
  var c2 = vec.vec2_scale(a2, 2.0);
  if c2.x != 2.0 || c2.y != 4.0 { return 3; }
  if vec.vec2_dot(a2, b2) != 13.0 { return 4; }
  if vec.vec2_cross(a2, b2) != -1.0 { return 5; }
  if vec.vec2_len(vec.vec2(3.0, 4.0)) != 5.0 { return 6; }
  var nz2 = vec.vec2_norm(vec.vec2(0.0, 0.0));
  if nz2.x != 0.0 || nz2.y != 0.0 { return 7; }
  var u2 = vec.vec2_norm(vec.vec2(3.0, 4.0));
  if u2.x < 0.59 || u2.y < 0.79 { return 8; }
  if vec.vec2_dist(a2, b2) <= 0.0 { return 9; }
  var l2 = vec.vec2_lerp(a2, b2, 0.5);
  if l2.x != 2.0 || l2.y != 3.5 { return 10; }

  // ---- vec: 3D primitives
  var a3 = vec.vec3_new(1.0, 2.0, 3.0);
  var b3 = vec.vec3_new(4.0, 5.0, 6.0);
  var s3 = vec.vec3_add(a3, b3);
  if s3.x != 5.0 || s3.y != 7.0 || s3.z != 9.0 { return 11; }
  var d3 = vec.vec3_sub(b3, a3);
  if d3.x != 3.0 || d3.y != 3.0 || d3.z != 3.0 { return 12; }
  var c3 = vec.vec3_scale(a3, 3.0);
  if c3.x != 3.0 || c3.y != 6.0 || c3.z != 9.0 { return 13; }
  if vec.vec3_dot(a3, b3) != 32.0 { return 14; }
  var x3 = vec.vec3_cross(a3, b3);
  if x3.x != -3.0 || x3.y != 6.0 || x3.z != -3.0 { return 15; }
  if vec.vec3_len(vec.vec3_new(3.0, 4.0, 0.0)) != 5.0 { return 16; }
  var nz3 = vec.vec3_norm(vec.vec3_new(0.0, 0.0, 0.0));
  if nz3.x != 0.0 || nz3.y != 0.0 || nz3.z != 0.0 { return 17; }
  if vec.vec3_dist(vec.vec3_new(0.0, 0.0, 0.0), vec.vec3_new(1.0, 2.0, 2.0)) != 3.0 { return 18; }

  // ---- vec: 4D primitives
  var a4 = vec.vec4_new(1.0, 2.0, 3.0, 4.0);
  var b4 = vec.vec4_new(5.0, 6.0, 7.0, 8.0);
  var s4 = vec.vec4_add(a4, b4);
  if s4.x != 6.0 || s4.y != 8.0 || s4.z != 10.0 || s4.w != 12.0 { return 19; }
  var d4 = vec.vec4_sub(b4, a4);
  if d4.x != 4.0 || d4.y != 4.0 || d4.z != 4.0 || d4.w != 4.0 { return 20; }
  var c4 = vec.vec4_scale(a4, 2.0);
  if c4.x != 2.0 || c4.y != 4.0 || c4.z != 6.0 || c4.w != 8.0 { return 21; }
  if vec.vec4_dot(a4, b4) != 70.0 { return 22; }
  if vec.vec4_len(vec.vec4_new(1.0, 2.0, 2.0, 4.0)) != 5.0 { return 23; }
  var nz4 = vec.vec4_norm(vec.vec4_new(0.0, 0.0, 0.0, 0.0));
  if nz4.x != 0.0 || nz4.y != 0.0 || nz4.z != 0.0 || nz4.w != 0.0 { return 24; }

  // ---- vec: dynamic helpers
  var dv = Vec[Float64].new();
  dv.push(1.0);
  dv.push(-2.0);
  var dn = Vec[Float64].new();
  dn.push(1.0);
  dn.push(0.0);
  var rf = vec.vec_reflect(&dv, &dn);
  if rf.len() != 2 { return 25; }
  if rf[0] != -1.0 || rf[1] != -2.0 { return 26; }
  var dz = Vec[Float64].new();
  dz.push(0.0);
  dz.push(0.0);
  var rfz = vec.vec_reflect(&dv, &dz);
  if rfz.len() != 2 { return 27; }
  if rfz[0] != 1.0 || rfz[1] != -2.0 { return 28; }
  var one = Vec[Float64].new();
  one.push(1.0);
  if vec.vec_reflect(&dv, &one).len() != 0 { return 29; }
  if vec.vec_project(&dv, &dn) != 1.0 { return 30; }
  var pj = vec.vec_project(&dv, &one);
  if !(pj != pj) { return 31; }
  var ag = vec.vec_angle(&dv, &dn);
  if !(ag > 0.0 && ag < 4.0) { return 32; }
  if vec.vec_angle(&dv, &dz) != 0.0 { return 33; }
  var am = vec.vec_angle(&dv, &one);
  if !(am != am) { return 34; }

  // ---- quat
  var qa = quat.quat_new(1.0, 2.0, 3.0, 4.0);
  var qb = quat.quat_new(5.0, 6.0, 7.0, 8.0);
  var qi = quat.quat_identity();
  if qi.x != 0.0 || qi.y != 0.0 || qi.z != 0.0 || qi.w != 1.0 { return 35; }
  var qm = quat.quat_mul(qa, qb);
  if qm.x != 24.0 || qm.y != 48.0 || qm.z != 48.0 || qm.w != -6.0 { return 36; }
  var qc = quat.quat_conjugate(qa);
  if qc.x != -1.0 || qc.y != -2.0 || qc.z != -3.0 || qc.w != 4.0 { return 37; }
  var qiz = quat.quat_inv(quat.quat_new(0.0, 0.0, 0.0, 0.0));
  if qiz.x != 0.0 || qiz.y != 0.0 || qiz.z != 0.0 || qiz.w != 1.0 { return 38; }
  var qii = quat.quat_inv(qi);
  if qii.x != 0.0 || qii.w != 1.0 { return 39; }
  if quat.quat_norm(qa) <= 0.0 { return 40; }
  var qnz = quat.quat_normalize(quat.quat_new(0.0, 0.0, 0.0, 0.0));
  if qnz.x != 0.0 || qnz.w != 1.0 { return 41; }
  var qn = quat.quat_normalize(qa);
  var qnl = quat.quat_norm(qn);
  if qnl < 0.99 || qnl > 1.01 { return 42; }
  var ax = Vec[Float64].new();
  ax.push(0.0);
  ax.push(0.0);
  ax.push(1.0);
  var q90 = quat.quat_from_axis_angle(&ax, 1.5707963267948966);
  if q90.z < 0.7 || q90.w < 0.7 { return 43; }
  var zax = Vec[Float64].new();
  zax.push(0.0);
  zax.push(0.0);
  zax.push(0.0);
  if quat.quat_from_axis_angle(&zax, 1.0).w != 1.0 { return 44; }
  var eax = Vec[Float64].new();
  if quat.quat_from_axis_angle(&eax, 1.0).w != 1.0 { return 45; }
  var eu = quat.quat_to_euler(qi);
  if eu.0 < -4.0 || eu.0 > 4.0 { return 46; }
  if eu.1 < -2.0 || eu.1 > 2.0 { return 47; }
  if eu.2 < -4.0 || eu.2 > 4.0 { return 48; }
  var sl0 = quat.quat_slerp(qa, qb, 0.0);
  if sl0.x != qa.x || sl0.y != qa.y || sl0.z != qa.z || sl0.w != qa.w { return 49; }
  var sl1 = quat.quat_slerp(qa, qb, 1.0);
  if sl1.x != qb.x || sl1.y != qb.y || sl1.z != qb.z || sl1.w != qb.w { return 50; }
  var slh = quat.quat_slerp(qi, qi, 0.5);
  if slh.x != 0.0 || slh.w != 1.0 { return 51; }
  var px = Vec[Float64].new();
  px.push(1.0);
  px.push(0.0);
  px.push(0.0);
  var r0 = quat.quat_rotate(qi, &px);
  if r0.len() != 3 { return 52; }
  if r0[0] != 1.0 || r0[1] != 0.0 || r0[2] != 0.0 { return 53; }
  var short = Vec[Float64].new();
  short.push(1.0);
  if quat.quat_rotate(qi, &short).len() != 0 { return 54; }
  var r90 = quat.quat_rotate(q90, &px);
  if r90.len() != 3 { return 55; }
  if r90[1] < 0.9 { return 56; }

  // ---- mat: identity / products / det
  var m3 = mat.mat_identity(3);
  if m3.len() != 3 { return 57; }
  if m3[0].len() != 3 { return 58; }
  if m3[0][0] != 1.0 || m3[1][1] != 1.0 || m3[0][1] != 0.0 { return 59; }
  if mat.mat_identity(0).len() != 0 { return 60; }
  if mat.mat_identity(-2).len() != 0 { return 99; }
  var m2 = mat.mat_identity(2);
  var m3p = mat.mat_mul(&m3, &m3);
  if m3p.len() != 3 { return 61; }
  if m3p[2][2] != 1.0 { return 62; }
  if mat.mat_mul(&m3, &m2).len() != 0 { return 63; }
  if mat.mat_det(&m2) != 1.0 { return 64; }
  var ms = Vec[Vec[Float64]].new();
  var msr0 = Vec[Float64].new();
  msr0.push(1.0);
  msr0.push(2.0);
  ms.push(msr0);
  var msr1 = Vec[Float64].new();
  msr1.push(2.0);
  msr1.push(4.0);
  ms.push(msr1);
  if mat.mat_det(&ms) != 0.0 { return 65; }
  var mb = Vec[Vec[Float64]].new();
  var mbr0 = Vec[Float64].new();
  mbr0.push(2.0);
  mbr0.push(0.0);
  mb.push(mbr0);
  var mbr1 = Vec[Float64].new();
  mbr1.push(0.0);
  mbr1.push(3.0);
  mb.push(mbr1);
  if mat.mat_det(&mb) != 6.0 { return 66; }
  var ns = Vec[Vec[Float64]].new();
  var nsr0 = Vec[Float64].new();
  nsr0.push(1.0);
  nsr0.push(2.0);
  nsr0.push(3.0);
  ns.push(nsr0);
  var nsr1 = Vec[Float64].new();
  nsr1.push(4.0);
  nsr1.push(5.0);
  nsr1.push(6.0);
  ns.push(nsr1);
  var dn = mat.mat_det(&ns);
  if !(dn != dn) { return 67; }

  // ---- mat: inv
  var iv2 = mat.mat_inv(&m2);
  if !iv2.is_some { return 68; }
  var ivm = iv2.unwrap();
  if ivm.len() != 2 { return 69; }
  if ivm[0][0] != 1.0 || ivm[1][1] != 1.0 { return 70; }
  if mat.mat_inv(&ms).is_some { return 71; }
  var em = Vec[Vec[Float64]].new();
  if mat.mat_inv(&em).is_some { return 72; }
  if mat.mat_inv(&ns).is_some { return 73; }

  // ---- mat: transpose
  var tp = mat.mat_transpose(&ns);
  if tp.len() != 3 { return 74; }
  if tp[0].len() != 2 { return 75; }
  if tp[0][0] != 1.0 || tp[1][0] != 2.0 || tp[2][1] != 6.0 { return 76; }

  // ---- mat: 4x4 transforms
  var m4 = mat.mat_identity(4);
  var tr = mat.mat_translate(&m4, 1.0, 2.0, 3.0);
  if tr.len() != 4 { return 77; }
  if tr[0][3] != 1.0 || tr[1][3] != 2.0 || tr[2][3] != 3.0 { return 78; }
  if mat.mat_translate(&m2, 1.0, 2.0, 3.0).len() != 0 { return 79; }
  var rz = Vec[Float64].new();
  rz.push(0.0);
  rz.push(0.0);
  rz.push(0.0);
  var rt0 = mat.mat_rotate(&m4, 0.0, &rz);
  if rt0.len() != 4 { return 80; }
  if rt0[0][0] != 1.0 { return 81; }
  var z1 = Vec[Float64].new();
  z1.push(0.0);
  z1.push(0.0);
  z1.push(1.0);
  var rt = mat.mat_rotate(&m4, 1.5707963267948966, &z1);
  if rt.len() != 4 { return 82; }
  if rt[0][1] > -0.9 { return 83; }
  if rt[1][0] < 0.9 { return 84; }
  var sc = mat.mat_scale(&m4, 2.0, 3.0, 4.0);
  if sc.len() != 4 { return 85; }
  if sc[0][0] != 2.0 || sc[1][1] != 3.0 || sc[2][2] != 4.0 || sc[3][3] != 1.0 { return 86; }
  if mat.mat_scale(&m2, 1.0, 1.0, 1.0).len() != 0 { return 87; }
  var eye = Vec[Float64].new();
  eye.push(0.0);
  eye.push(0.0);
  eye.push(0.0);
  var tgt = Vec[Float64].new();
  tgt.push(0.0);
  tgt.push(0.0);
  tgt.push(-1.0);
  var upv = Vec[Float64].new();
  upv.push(0.0);
  upv.push(1.0);
  upv.push(0.0);
  var la = mat.mat_look_at(&eye, &tgt, &upv);
  if la.len() != 4 { return 88; }
  if la[3][3] != 1.0 { return 89; }
  var pe = mat.mat_perspective(1.0, 1.5, 0.1, 100.0);
  if pe.len() != 4 { return 90; }
  if pe[3][2] != -1.0 { return 91; }
  var orr = mat.mat_ortho(-1.0, 1.0, -1.0, 1.0, 0.1, 100.0);
  if orr.len() != 4 { return 92; }
  if orr[3][3] != 1.0 { return 93; }
  var pt = Vec[Float64].new();
  pt.push(1.0);
  pt.push(2.0);
  pt.push(3.0);
  var xp = mat.mat_transform_point(&m4, &pt);
  if xp.len() != 3 { return 94; }
  if xp[0] != 1.0 || xp[1] != 2.0 || xp[2] != 3.0 { return 95; }
  var pt0 = Vec[Float64].new();
  pt0.push(1.0);
  pt0.push(2.0);
  pt0.push(3.0);
  pt0.push(0.0);
  var xz = mat.mat_transform_point(&m4, &pt0);
  if xz.len() != 3 { return 96; }
  if xz[0] != 0.0 || xz[1] != 0.0 || xz[2] != 0.0 { return 97; }
  if mat.mat_transform_point(&m2, &pt).len() != 0 { return 98; }

  return 0;
}

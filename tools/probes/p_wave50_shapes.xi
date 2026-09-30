// p_wave50_shapes.xi -- wave 50 shape validation: geom typed matrix + quaternion
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-50 clauses on xiom.geom.matrix (Mat2/3/4 constructors,
// dynamic shapes and solvers) and xiom.geom.quaternion (typed Quat algebra):
// field mirrors, len-only shape claims, NaN/zero bands, presence mirrors,
// tuple-length claims on the decompositions, identity-or-nonzero quaternion
// canonical forms, and KATs for det/inverse/solve/least-squares/eigenvalues,
// the 90-degree z rotation, slerp/nlerp, look-at and between.
// NOTE (known compiler finding, filed 2026-09-30): nested Vec[Vec[Float64]]
// locals receiving xiom.geom.matrix results must carry the explicit
// Vec[Vec[Float64]] annotation (un-annotated inference loses a nesting level
// and row reads return garbage); every such local below is annotated.
// Returns 0 when every case holds.

module p_wave50_shapes

use xiom.geom.matrix;
use xiom.geom.quaternion;
use xiom.math;

fn mk2(a: Float64, b: Float64, c: Float64, d: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(a);
  r0.push(b);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(c);
  r1.push(d);
  out.push(r1);
  return out;
}

fn mk32(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(a);
  r0.push(b);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(c);
  r1.push(d);
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(e);
  r2.push(f);
  out.push(r2);
  return out;
}

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- fixed-size constructors
  var m2 = matrix.mat2_new(1.0, 2.0, 3.0, 4.0);
  if m2.m00 != 1.0 || m2.m01 != 2.0 || m2.m10 != 3.0 || m2.m11 != 4.0 { return 1; }
  var m3 = matrix.mat3_new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0);
  if m3.m00 != 1.0 || m3.m11 != 5.0 || m3.m22 != 9.0 || m3.m02 != 3.0 || m3.m20 != 7.0 { return 2; }
  var m4 = matrix.mat4_new(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0);
  if m4.m00 != 1.0 || m4.m33 != 16.0 || m4.m03 != 4.0 || m4.m30 != 13.0 { return 3; }

  // ---- shapes
  var id3: Vec[Vec[Float64]] = matrix.identity(3);
  if id3.len() != 3 { return 4; }
  if id3[0][0] != 1.0 || id3[1][1] != 1.0 || id3[2][2] != 1.0 || id3[0][1] != 0.0 { return 5; }
  var id0: Vec[Vec[Float64]] = matrix.identity(0);
  if id0.len() != 0 { return 6; }
  var z23: Vec[Vec[Float64]] = matrix.zero(2, 3);
  if z23.len() != 2 || z23[0].len() != 3 || z23[1][2] != 0.0 { return 7; }
  var o22: Vec[Vec[Float64]] = matrix.one(2, 2);
  if o22.len() != 2 || o22[0][1] != 1.0 || o22[1][0] != 1.0 { return 8; }

  // ---- element-wise and product operations on [[1,2],[3,4]]
  var a = mk2(1.0, 2.0, 3.0, 4.0);
  var b = mk2(5.0, 6.0, 7.0, 8.0);
  var ad: Vec[Vec[Float64]] = matrix.add(&a, &b);
  if ad.len() != 2 || ad[0][0] != 6.0 || ad[1][1] != 12.0 { return 9; }
  var mism: Vec[Vec[Float64]] = matrix.add(&a, &id3);
  if mism.len() != 0 { return 10; }
  var sb: Vec[Vec[Float64]] = matrix.sub(&b, &a);
  if sb[0][0] != 4.0 || sb[1][1] != 4.0 { return 11; }
  var id2: Vec[Vec[Float64]] = matrix.identity(2);
  var mu: Vec[Vec[Float64]] = matrix.mul(&a, &id2);
  if mu[0][0] != 1.0 || mu[0][1] != 2.0 || mu[1][0] != 3.0 || mu[1][1] != 4.0 { return 12; }
  var sm: Vec[Vec[Float64]] = matrix.scalar_mul(&a, 2.0);
  if sm[0][0] != 2.0 || sm[1][1] != 8.0 { return 13; }
  var tp: Vec[Vec[Float64]] = matrix.transpose(&a);
  if tp[0][0] != 1.0 || tp[0][1] != 3.0 || tp[1][0] != 2.0 || tp[1][1] != 4.0 { return 14; }

  // ---- det / inverse / minor / cofactor / adjugate / trace
  if matrix.det(&a) != -2.0 { return 15; }
  var iv = matrix.inverse(&a);
  if !iv.is_some { return 16; }
  var ivm: Vec[Vec[Float64]] = iv.unwrap();
  if !near(ivm[0][0], -2.0) || !near(ivm[0][1], 1.0) { return 17; }
  if !near(ivm[1][0], 1.5) || !near(ivm[1][1], -0.5) { return 18; }
  var sing1 = mk2(1.0, 2.0, 2.0, 4.0);
  if matrix.inverse(&sing1).is_some { return 19; }
  if matrix.minor(&a, 0, 0) != 4.0 || matrix.minor(&a, 0, 1) != 3.0 { return 20; }
  if matrix.minor(&a, 1, 0) != 2.0 || matrix.minor(&a, 1, 1) != 1.0 { return 21; }
  if matrix.cofactor(&a, 0, 0) != 4.0 || matrix.cofactor(&a, 0, 1) != -3.0 { return 22; }
  if matrix.cofactor(&a, 1, 0) != -2.0 || matrix.cofactor(&a, 1, 1) != 1.0 { return 23; }
  var adj: Vec[Vec[Float64]] = matrix.adjugate(&a);
  if adj[0][0] != 4.0 || adj[0][1] != -2.0 || adj[1][0] != -3.0 || adj[1][1] != 1.0 { return 24; }
  if matrix.trace(&a) != 5.0 { return 25; }

  // ---- rank / nullity
  if matrix.rank(&a) != 2 { return 26; }
  if matrix.rank(&id3) != 3 { return 27; }
  if matrix.rank(&z23) != 0 { return 28; }
  if matrix.nullity(&z23) != 3 { return 29; }
  if matrix.nullity(&a) != 0 { return 30; }

  // ---- eigenvalues / eigenvectors / diagonal
  var ev: Vec[Float64] = matrix.eigenvalues(&a);
  if ev.len() != 2 { return 31; }
  if !near(ev[0], 5.372281323269014) || !near(ev[1], -0.372281323269014) { return 32; }
  var evec: Vec[Vec[Float64]] = matrix.eigenvectors(&a);
  if evec.len() != 2 { return 33; }
  if evec[0].len() != 2 || evec[1].len() != 2 { return 34; }
  var dg: Vec[Float64] = matrix.diagonal(&a);
  if dg.len() != 2 || dg[0] != 1.0 || dg[1] != 4.0 { return 35; }

  // ---- diag_mul / hadamard / kronecker
  var dv = Vec[Float64].new();
  dv.push(2.0);
  dv.push(3.0);
  var dm: Vec[Vec[Float64]] = matrix.diag_mul(&a, &dv);
  if dm[0][0] != 2.0 || dm[0][1] != 6.0 || dm[1][0] != 6.0 || dm[1][1] != 12.0 { return 36; }
  var dshort = Vec[Float64].new();
  dshort.push(1.0);
  var ds: Vec[Vec[Float64]] = matrix.diag_mul(&a, &dshort);
  if ds.len() != 0 { return 37; }
  var hd: Vec[Vec[Float64]] = matrix.hadamard(&a, &b);
  if hd[0][0] != 5.0 || hd[0][1] != 12.0 || hd[1][0] != 21.0 || hd[1][1] != 32.0 { return 38; }
  var kr: Vec[Vec[Float64]] = matrix.kronecker(&a, &id2);
  if kr.len() != 4 || kr[0].len() != 4 { return 39; }
  if kr[0][0] != 1.0 || kr[0][2] != 2.0 || kr[2][0] != 3.0 || kr[3][3] != 4.0 { return 40; }

  // ---- decompositions
  var lu = matrix.lu_decompose(&a);
  var l: Vec[Vec[Float64]] = lu.0;
  var u: Vec[Vec[Float64]] = lu.1;
  if l.len() != 2 || u.len() != 2 { return 41; }
  if l[0][0] != 1.0 || !near(l[1][0], 3.0) || !near(u[1][1], -2.0) { return 42; }
  var qr = matrix.qr_decompose(&a);
  var q: Vec[Vec[Float64]] = qr.0;
  var r: Vec[Vec[Float64]] = qr.1;
  if q.len() != 2 || r.len() != 2 { return 43; }
  if !near(r[0][0], 3.162277660168379) { return 44; }
  if !near(q[0][0], 0.316227766016838) { return 45; }
  var sv = matrix.svd_decompose(&a);
  var su: Vec[Vec[Float64]] = sv.0;
  var ss: Vec[Float64] = sv.1;
  var svv: Vec[Vec[Float64]] = sv.2;
  if su.len() != 2 || ss.len() != 2 || svv.len() != 2 { return 46; }
  var spd = mk2(4.0, 2.0, 2.0, 3.0);
  var ch = matrix.cholesky(&spd);
  if !ch.is_some { return 47; }
  var chl: Vec[Vec[Float64]] = ch.unwrap();
  if !near(chl[0][0], 2.0) || !near(chl[1][0], 1.0) { return 48; }
  if !near(chl[1][1], 1.414213562373095) { return 49; }
  var nsym = mk2(1.0, 2.0, 2.0, 1.0);
  if matrix.cholesky(&nsym).is_some { return 50; }

  // ---- solvers
  var bv = Vec[Float64].new();
  bv.push(1.0);
  bv.push(2.0);
  var x: Vec[Float64] = matrix.solve_linear(&a, &bv);
  if x.len() != 2 { return 51; }
  if !near(x[0], 0.0) || !near(x[1], 0.5) { return 52; }
  var sng = mk2(1.0, 2.0, 2.0, 4.0);
  var xs: Vec[Float64] = matrix.solve_linear(&sng, &bv);
  if xs.len() != 0 { return 53; }
  var over = mk32(1.0, 1.0, 1.0, 2.0, 1.0, 3.0);
  var ob = Vec[Float64].new();
  ob.push(1.0);
  ob.push(2.0);
  ob.push(2.0);
  var ls: Vec[Float64] = matrix.least_squares(&over, &ob);
  if !near(ls[0], 0.666666666666667) || !near(ls[1], 0.5) { return 54; }
  var cnd = mk2(1.0, 0.0, 0.0, 2.0);
  var cn = matrix.condition_number(&cnd);
  if !near(cn, 2.0) { return 55; }
  var cnsm = mk2(1.0, 2.0, 2.0, 4.0);
  var cns = matrix.condition_number(&cnsm);
  if !(cns != cns) { return 56; }
  var cnn = matrix.condition_number(&id3);
  if !(cnn != cnn) { return 57; }

  // ---- quaternion constructors and conversions
  var qa = quaternion.quat_new(1.0, 2.0, 3.0, 4.0);
  if qa.x != 1.0 || qa.y != 2.0 || qa.z != 3.0 || qa.w != 4.0 { return 58; }
  var qid = quaternion.quat_identity();
  if qid.x != 0.0 || qid.y != 0.0 || qid.z != 0.0 || qid.w != 1.0 { return 59; }
  var ax = Vec[Float64].new();
  ax.push(0.0);
  ax.push(0.0);
  ax.push(1.0);
  var q90 = quaternion.quat_from_axis_angle(&ax, 1.5707963267948966);
  if q90.z < 0.707 || q90.w < 0.707 { return 60; }
  var zax = Vec[Float64].new();
  zax.push(0.0);
  zax.push(0.0);
  zax.push(0.0);
  var qzid = quaternion.quat_from_axis_angle(&zax, 1.0);
  if qzid.w != 1.0 { return 61; }
  var eax = Vec[Float64].new();
  var qeid = quaternion.quat_from_axis_angle(&eax, 1.0);
  if qeid.w != 1.0 { return 62; }
  var qeu = quaternion.quat_from_euler(0.0, 0.0, 0.0);
  if qeu.x != 0.0 || qeu.y != 0.0 || qeu.z != 0.0 || qeu.w != 1.0 { return 63; }
  var qy = quaternion.quat_from_euler(1.5707963267948966, 0.0, 0.0);
  if qy.z < 0.707 || qy.w < 0.707 { return 64; }
  var qrm = quaternion.quat_from_rotation_matrix(&id3);
  if qrm.x != 0.0 || qrm.y != 0.0 || qrm.z != 0.0 || qrm.w != 1.0 { return 65; }
  var m2b = mk2(1.0, 0.0, 0.0, 1.0);
  var qrm2 = quaternion.quat_from_rotation_matrix(&m2b);
  if qrm2.w != 1.0 { return 66; }
  var qtm: Vec[Vec[Float64]] = quaternion.quat_to_matrix(&q90);
  if qtm.len() != 3 { return 67; }
  if !near(qtm[0][0], 0.0) || !near(qtm[0][1], -1.0) { return 68; }
  if !near(qtm[1][0], 1.0) || !near(qtm[1][1], 0.0) { return 69; }
  var qte = quaternion.quat_to_euler(&q90);
  if qte.0 < 1.4 || qte.0 > 1.7 { return 70; }
  if qte.1 < -0.1 || qte.1 > 0.1 { return 71; }

  // ---- quaternion algebra
  var qm = quaternion.quat_mul(&qa, &qid);
  if qm.x != 1.0 || qm.y != 2.0 || qm.z != 3.0 || qm.w != 4.0 { return 72; }
  var qc = quaternion.quat_conj(&qa);
  if qc.x != -1.0 || qc.y != -2.0 || qc.z != -3.0 || qc.w != 4.0 { return 73; }
  var qii = quaternion.quat_inv(&qid);
  if qii.w != 1.0 { return 74; }
  var qiz = quaternion.quat_inv(&qzid);
  if qiz.w != 1.0 { return 75; }
  if !near(quaternion.quat_norm(&q90), 1.0) { return 76; }
  var qn = quaternion.quat_normalize(&qa);
  if !near(quaternion.quat_norm(&qn), 1.0) { return 77; }
  var qnz = quaternion.quat_normalize(&qzid);
  if qnz.w != 1.0 { return 78; }
  var xv = Vec[Float64].new();
  xv.push(1.0);
  xv.push(0.0);
  xv.push(0.0);
  var qr90: Vec[Float64] = quaternion.quat_rotate(&q90, &xv);
  if qr90.len() != 3 { return 79; }
  if !near(qr90[0], 0.0) || !near(qr90[1], 1.0) { return 80; }
  var xv2 = Vec[Float64].new();
  xv2.push(1.0);
  xv2.push(0.0);
  var qrs: Vec[Float64] = quaternion.quat_rotate(&q90, &xv2);
  if qrs.len() != 0 { return 81; }

  // ---- interpolation / angle / axis
  var sl0 = quaternion.quat_slerp(&qid, &q90, -1.0);
  if sl0.x != 0.0 || sl0.w != 1.0 { return 82; }
  var sl1 = quaternion.quat_slerp(&qid, &q90, 2.0);
  if sl1.z != q90.z || sl1.w != q90.w { return 83; }
  var slh = quaternion.quat_slerp(&qid, &q90, 0.5);
  if !near(quaternion.quat_norm(&slh), 1.0) { return 84; }
  var nlh = quaternion.quat_nlerp(&qid, &q90, 0.5);
  if !near(quaternion.quat_norm(&nlh), 1.0) { return 85; }
  if quaternion.quat_angle(&qid) != 0.0 { return 86; }
  if !near(quaternion.quat_angle(&q90), 1.5707963267948966) { return 87; }
  var qaxis: Vec[Float64] = quaternion.quat_axis(&q90);
  if qaxis.len() != 3 { return 88; }
  if !near(qaxis[0], 0.0) || !near(qaxis[1], 0.0) || !near(qaxis[2], 1.0) { return 89; }
  var qaz: Vec[Float64] = quaternion.quat_axis(&qid);
  if qaz[0] != 0.0 || qaz[1] != 0.0 || qaz[2] != 0.0 { return 90; }

  // ---- look_at / between
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
  var qla = quaternion.quat_look_at(&eye, &tgt, &upv);
  if !near(qla.x, 0.0) || !near(qla.y, 0.0) || !near(qla.z, 0.0) || !near(qla.w, 1.0) { return 91; }
  var qlad = quaternion.quat_look_at(&eye, &eye, &upv);
  if qlad.w != 1.0 { return 92; }
  var xa = Vec[Float64].new();
  xa.push(1.0);
  xa.push(0.0);
  xa.push(0.0);
  var ya = Vec[Float64].new();
  ya.push(0.0);
  ya.push(1.0);
  ya.push(0.0);
  var qbt = quaternion.quat_between(&xa, &ya);
  if qbt.z < 0.707 || qbt.w < 0.707 { return 93; }
  var qbz = quaternion.quat_between(&eax, &xa);
  if qbz.w != 1.0 { return 94; }
  var xneg = Vec[Float64].new();
  xneg.push(-1.0);
  xneg.push(0.0);
  xneg.push(0.0);
  var qbo = quaternion.quat_between(&xa, &xneg);
  if !near(qbo.w, 0.0) { return 95; }
  var qbl = math.sqrt(qbo.x * qbo.x + qbo.y * qbo.y + qbo.z * qbo.z);
  if !near(qbl, 1.0) { return 96; }

  return 0;
}

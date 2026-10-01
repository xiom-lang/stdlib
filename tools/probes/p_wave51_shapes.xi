// p_wave51_shapes.xi -- wave 51 shape validation: geom vector/curves/collision
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-51 clauses on xiom.geom.vector (24 pub), xiom.geom.curves
// (7) and xiom.geom.collision (12): constructor field mirrors, len-only shape
// claims on the dynamic-vector algebra, NaN-on-mismatch claims, the
// degenerate-input implications on the collision queries, presence mirrors,
// plus KATs for dot/cross/outer/normalize/project/reject/reflect/refract/
// clamp, the Bezier/Catmull-Rom/B-spline/Hermite points, arc length, and the
// AABB/sphere/ray/segment queries. segment_intersect is checked through
// is_some only (Vec-payload extraction crashes - collision.xi header).
// Returns 0 when every case holds.

module p_wave51_shapes

use xiom.geom.vector;
use xiom.geom.curves;
use xiom.geom.collision;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn line(t: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  out.push(t);
  out.push(0.0);
  return out;
}

fn main() -> Int {
  // ---- vector: constructors
  var v2 = vector.v2_new(1.0, 2.0);
  if v2.x != 1.0 || v2.y != 2.0 { return 1; }
  var v3 = vector.v3_new(1.0, 2.0, 3.0);
  if v3.x != 1.0 || v3.y != 2.0 || v3.z != 3.0 { return 2; }
  var v4 = vector.v4_new(1.0, 2.0, 3.0, 4.0);
  if v4.x != 1.0 || v4.y != 2.0 || v4.z != 3.0 || v4.w != 4.0 { return 3; }

  // ---- vector: products and norms
  var a3 = Vec[Float64].new();
  a3.push(1.0);
  a3.push(2.0);
  a3.push(3.0);
  var b3 = Vec[Float64].new();
  b3.push(4.0);
  b3.push(5.0);
  b3.push(6.0);
  if vector.dot(&a3, &b3) != 32.0 { return 4; }
  var one = Vec[Float64].new();
  one.push(1.0);
  var dn = vector.dot(&one, &a3);
  if !(dn != dn) { return 5; }
  var e0 = Vec[Float64].new();
  if vector.dot(&e0, &e0) != 0.0 { return 6; }
  var x3 = vector.cross(&a3, &b3);
  if x3.len() != 3 { return 7; }
  if x3[0] != -3.0 || x3[1] != 6.0 || x3[2] != -3.0 { return 8; }
  if vector.cross(&one, &a3).len() != 0 { return 9; }
  if vector.cross2(v2, vector.v2_new(3.0, 4.0)) != -2.0 { return 10; }
  var a2 = Vec[Float64].new();
  a2.push(1.0);
  a2.push(2.0);
  var b2 = Vec[Float64].new();
  b2.push(3.0);
  b2.push(4.0);
  var op: Vec[Vec[Float64]] = vector.outer(&a2, &b2);
  if op.len() != 2 { return 11; }
  if op[0][0] != 3.0 || op[0][1] != 4.0 || op[1][0] != 6.0 || op[1][1] != 8.0 { return 12; }
  var n34 = Vec[Float64].new();
  n34.push(3.0);
  n34.push(4.0);
  if vector.norm(&n34) != 5.0 { return 13; }
  if vector.norm(&e0) != 0.0 { return 14; }
  if vector.norm_sq(&n34) != 25.0 { return 15; }
  if vector.norm_sq(&e0) != 0.0 { return 16; }
  var un = vector.normalize(&n34);
  if un.len() != 2 { return 17; }
  if !near(un[0], 0.6) || !near(un[1], 0.8) { return 18; }
  if vector.normalize(&e0).len() != 0 { return 19; }
  var uu = vector.unit(&n34);
  if !near(uu[0], 0.6) || !near(uu[1], 0.8) { return 20; }
  var o2 = Vec[Float64].new();
  o2.push(0.0);
  o2.push(0.0);
  if vector.distance(&o2, &n34) != 5.0 { return 21; }
  var dm = vector.distance(&one, &n34);
  if !(dm != dm) { return 22; }
  if vector.distance_sq(&o2, &n34) != 25.0 { return 23; }
  var dsm = vector.distance_sq(&one, &n34);
  if !(dsm != dsm) { return 24; }

  // ---- vector: angles / projections / interpolation
  var ex = Vec[Float64].new();
  ex.push(1.0);
  ex.push(0.0);
  var ey = Vec[Float64].new();
  ey.push(0.0);
  ey.push(1.0);
  if !near(vector.angle(&ex, &ey), 1.5707963267948966) { return 25; }
  if vector.angle(&e0, &ex) != 0.0 { return 26; }
  var pr = vector.project(&n34, &ex);
  if !near(pr[0], 3.0) || !near(pr[1], 0.0) { return 27; }
  var rj = vector.reject(&n34, &ex);
  if !near(rj[0], 0.0) || !near(rj[1], 4.0) { return 28; }
  var lp = vector.lerp(&o2, &n34, 0.5);
  var lpexp = Vec[Float64].new();
  lpexp.push(1.5);
  lpexp.push(2.0);
  if vector.distance(&lp, &lpexp) != 0.0 { return 29; }
  var sl = vector.slerp(&ex, &ey, 0.5);
  if !near(sl[0], 0.707106781186548) || !near(sl[1], 0.707106781186548) { return 30; }
  var rv = Vec[Float64].new();
  rv.push(1.0);
  rv.push(-1.0);
  var rf = vector.reflect(&rv, &ey);
  if !near(rf[0], 1.0) || !near(rf[1], 1.0) { return 31; }
  var ri = vector.refract(&ex, &ey, 1.0);
  if !ri.is_some { return 32; }
  var rtr = vector.refract(&ex, &ey, 2.0);
  if rtr.is_some { return 34; }
  var rmm = vector.refract(&one, &ey, 1.0);
  if rmm.is_some { return 35; }
  var cl = vector.clamp(&rv, 0.0, 1.0);
  if cl.len() != 2 { return 36; }
  var clexp = Vec[Float64].new();
  clexp.push(1.0);
  clexp.push(0.0);
  if vector.distance(&cl, &clexp) != 0.0 { return 37; }
  var cmin = Vec[Float64].new();
  cmin.push(3.0);
  cmin.push(1.0);
  cmin.push(2.0);
  if vector.component_min(&cmin) != 1.0 { return 38; }
  var cmn = vector.component_min(&e0);
  if !(cmn != cmn) { return 39; }
  if vector.component_max(&cmin) != 3.0 { return 40; }
  var cmx = vector.component_max(&e0);
  if !(cmx != cmx) { return 41; }
  var hd = vector.hadamard(&a2, &b2);
  var hdexp = Vec[Float64].new();
  hdexp.push(3.0);
  hdexp.push(8.0);
  if vector.distance(&hd, &hdexp) != 0.0 { return 42; }
  if vector.hadamard(&one, &a2).len() != 0 { return 43; }

  // ---- curves
  var c00 = Vec[Float64].new();
  c00.push(0.0);
  c00.push(0.0);
  var c12 = Vec[Float64].new();
  c12.push(1.0);
  c12.push(2.0);
  var c20 = Vec[Float64].new();
  c20.push(2.0);
  c20.push(0.0);
  var bq = curves.bezier_quad(&c00, &c12, &c20, 0.5);
  if bq.len() != 2 { return 44; }
  if !near(bq[0], 1.0) || !near(bq[1], 1.0) { return 45; }
  var c13 = Vec[Float64].new();
  c13.push(1.0);
  c13.push(3.0);
  var c23 = Vec[Float64].new();
  c23.push(2.0);
  c23.push(3.0);
  var c30 = Vec[Float64].new();
  c30.push(3.0);
  c30.push(0.0);
  var bc = curves.bezier_cubic(&c00, &c13, &c23, &c30, 0.5);
  if !near(bc[0], 1.5) || !near(bc[1], 2.25) { return 46; }
  var ctrl: Vec[Vec[Float64]] = Vec[Vec[Float64]].new();
  var ctrl0 = Vec[Float64].new();
  ctrl0.push(0.0);
  ctrl0.push(0.0);
  ctrl.push(ctrl0);
  var ctrl1 = Vec[Float64].new();
  ctrl1.push(1.0);
  ctrl1.push(1.0);
  ctrl.push(ctrl1);
  var ctrl2 = Vec[Float64].new();
  ctrl2.push(2.0);
  ctrl2.push(0.0);
  ctrl.push(ctrl2);
  var bd = curves.bezier_derivative(&ctrl, 0.5);
  if bd.len() != 2 { return 47; }
  if !near(bd[0], 2.0) || !near(bd[1], 0.0) { return 48; }
  var cr = curves.catmull_rom(&c00, &c13, &c23, &c30, 0.5);
  var crexp = Vec[Float64].new();
  crexp.push(1.5);
  crexp.push(3.375);
  if vector.distance(&cr, &crexp) != 0.0 { return 49; }
  var bctrl: Vec[Vec[Float64]] = Vec[Vec[Float64]].new();
  var bq0 = Vec[Float64].new();
  bq0.push(0.0);
  bq0.push(0.0);
  bctrl.push(bq0);
  var bq1 = Vec[Float64].new();
  bq1.push(1.0);
  bq1.push(0.0);
  bctrl.push(bq1);
  var bq2 = Vec[Float64].new();
  bq2.push(2.0);
  bq2.push(0.0);
  bctrl.push(bq2);
  var bq3 = Vec[Float64].new();
  bq3.push(3.0);
  bq3.push(0.0);
  bctrl.push(bq3);
  var bs = curves.b_spline(&bctrl, 0.5);
  var bsexp = Vec[Float64].new();
  bsexp.push(1.5);
  bsexp.push(0.0);
  if vector.distance(&bs, &bsexp) != 0.0 { return 50; }
  var ht = Vec[Float64].new();
  ht.push(1.0);
  ht.push(0.0);
  var hc = curves.hermite_curve(&c00, &ht, &ex, &ht, 0.5);
  var hcexp = Vec[Float64].new();
  hcexp.push(0.5);
  hcexp.push(0.0);
  if vector.distance(&hc, &hcexp) != 0.0 { return 51; }
  if curves.curve_length(line, 0.0, 1.0, 0) != 0.0 { return 53; }

  // ---- collision: AABB
  var mn = Vec[Float64].new();
  mn.push(0.0);
  mn.push(0.0);
  mn.push(0.0);
  var mx = Vec[Float64].new();
  mx.push(1.0);
  mx.push(1.0);
  mx.push(1.0);
  var ab = collision.aabb_new(&mn, &mx);
  if ab.min.len() != 3 || ab.max.len() != 3 { return 54; }
  var mid = Vec[Float64].new();
  mid.push(0.5);
  mid.push(0.5);
  mid.push(0.5);
  if !collision.aabb_contains(ab, &mid) { return 55; }
  var out3 = Vec[Float64].new();
  out3.push(2.0);
  out3.push(0.0);
  out3.push(0.0);
  if collision.aabb_contains(ab, &out3) { return 56; }
  var short2 = Vec[Float64].new();
  short2.push(0.5);
  short2.push(0.5);
  if collision.aabb_contains(ab, &short2) { return 57; }
  var ab2 = collision.aabb_new(&mid, &out3);
  if !collision.aabb_intersects(ab, ab2) { return 58; }
  var far = Vec[Float64].new();
  far.push(5.0);
  far.push(5.0);
  far.push(5.0);
  var ab3 = collision.aabb_new(&out3, &far);
  if collision.aabb_intersects(ab, ab3) { return 59; }

  // ---- collision: sphere
  var sp = collision.sphere_new(&mn, 1.0);
  if sp.center.len() != 3 || sp.radius != 1.0 { return 60; }
  if !collision.sphere_contains(sp, &mid) { return 61; }
  if collision.sphere_contains(sp, &out3) { return 62; }
  var sp2 = collision.sphere_new(&out3, 0.5);
  if collision.sphere_intersects(sp, sp2) { return 63; }
  var c15 = Vec[Float64].new();
  c15.push(1.5);
  c15.push(0.0);
  c15.push(0.0);
  var sp3 = collision.sphere_new(&c15, 1.0);
  if !collision.sphere_intersects(sp, sp3) { return 64; }

  // ---- collision: rays
  var dirn = Vec[Float64].new();
  dirn.push(0.0);
  dirn.push(0.0);
  dirn.push(-1.0);
  var ry = collision.ray_new(&mn, &dirn);
  if ry.origin.len() != 3 || ry.dir.len() != 3 { return 65; }
  var sc = Vec[Float64].new();
  sc.push(0.0);
  sc.push(0.0);
  sc.push(-1.0);
  var spc = collision.sphere_new(&sc, 0.5);
  var ts = collision.ray_sphere_intersect(ry, spc);
  if !ts.is_some { return 66; }
  if !near(ts.unwrap(), 0.5) { return 67; }
  var scb = Vec[Float64].new();
  scb.push(0.0);
  scb.push(0.0);
  scb.push(1.0);
  var spb = collision.sphere_new(&scb, 0.5);
  if collision.ray_sphere_intersect(ry, spb).is_some { return 68; }
  var dirx = Vec[Float64].new();
  dirx.push(1.0);
  dirx.push(0.0);
  dirx.push(0.0);
  var ryx = collision.ray_new(&mn, &dirx);
  var bxmin = Vec[Float64].new();
  bxmin.push(1.0);
  bxmin.push(0.0);
  bxmin.push(0.0);
  var bxmax = Vec[Float64].new();
  bxmax.push(2.0);
  bxmax.push(0.0);
  bxmax.push(0.0);
  var bx = collision.aabb_new(&bxmin, &bxmax);
  var ta = collision.ray_aabb_intersect(ryx, bx);
  if !ta.is_some { return 69; }
  if !near(ta.unwrap(), 1.0) { return 70; }
  var diry = Vec[Float64].new();
  diry.push(0.0);
  diry.push(1.0);
  diry.push(0.0);
  var ryy = collision.ray_new(&mn, &diry);
  if collision.ray_aabb_intersect(ryy, bx).is_some { return 71; }
  var pln = Vec[Float64].new();
  pln.push(0.0);
  pln.push(0.0);
  pln.push(1.0);
  pln.push(-1.0);
  var tp = collision.ray_plane_intersect(ry, &pln);
  if !tp.is_some { return 72; }
  if !near(tp.unwrap(), 1.0) { return 73; }
  var plb = Vec[Float64].new();
  plb.push(0.0);
  plb.push(0.0);
  plb.push(1.0);
  plb.push(1.0);
  if collision.ray_plane_intersect(ry, &plb).is_some { return 74; }
  var plp = Vec[Float64].new();
  plp.push(1.0);
  plp.push(0.0);
  plp.push(0.0);
  plp.push(0.0);
  if collision.ray_plane_intersect(ry, &plp).is_some { return 75; }
  var tri_a = Vec[Float64].new();
  tri_a.push(0.0);
  tri_a.push(0.0);
  tri_a.push(0.0);
  var tri_b = Vec[Float64].new();
  tri_b.push(1.0);
  tri_b.push(0.0);
  tri_b.push(0.0);
  var tri_c = Vec[Float64].new();
  tri_c.push(0.0);
  tri_c.push(1.0);
  tri_c.push(0.0);
  var t_in = Vec[Float64].new();
  t_in.push(0.25);
  t_in.push(0.25);
  t_in.push(0.0);
  if !collision.point_in_triangle(&t_in, &tri_a, &tri_b, &tri_c) { return 76; }
  var t_out = Vec[Float64].new();
  t_out.push(1.0);
  t_out.push(1.0);
  t_out.push(0.0);
  if collision.point_in_triangle(&t_out, &tri_a, &tri_b, &tri_c) { return 77; }
  var s1 = Vec[Float64].new();
  s1.push(0.0);
  s1.push(0.0);
  var s2 = Vec[Float64].new();
  s2.push(2.0);
  s2.push(2.0);
  var s3 = Vec[Float64].new();
  s3.push(0.0);
  s3.push(2.0);
  var s4 = Vec[Float64].new();
  s4.push(2.0);
  s4.push(0.0);
  if !collision.segment_intersect(&s1, &s2, &s3, &s4).is_some { return 78; }
  var s5 = Vec[Float64].new();
  s5.push(0.0);
  s5.push(1.0);
  var s6 = Vec[Float64].new();
  s6.push(2.0);
  s6.push(3.0);
  if collision.segment_intersect(&s1, &s2, &s5, &s6).is_some { return 79; }
  var s7 = Vec[Float64].new();
  s7.push(3.0);
  s7.push(0.0);
  var s8 = Vec[Float64].new();
  s8.push(3.0);
  s8.push(2.0);
  if collision.segment_intersect(&s1, &s2, &s7, &s8).is_some { return 80; }
  var short1 = Vec[Float64].new();
  short1.push(0.0);
  if collision.segment_intersect(&short1, &s2, &s3, &s4).is_some { return 81; }

  return 0;
}

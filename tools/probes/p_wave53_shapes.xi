// p_wave53_shapes.xi -- wave 53 shape validation: geometry_extended + polyhedra + linear
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-53 clauses on xiom.geom.geometry_extended (14 pub),
// xiom.geom.polyhedra (10) and xiom.geom.linear (15): len-only shape claims,
// degenerate-input implications, and scalar/predicate KATs.
// Nested float Vec element reads of module-returned matrices are corrupt
// (BUG 23 #1 / wave-51 finding), so linear results are verified through
// length counts and through the module's own predicates (callee-side reads
// are sound); matrix round-trips use skew_to_vec, which copies first.
// Returns 0 when every case holds.

module p_wave53_shapes

use xiom.geom.geometry_extended;
use xiom.geom.polyhedra;
use xiom.geom.linear;
use xiom.geom.geometry_2d;
use xiom.geom.geometry_2d.Point2;
use xiom.geom.geometry_2d.Rect;
use xiom.geom.geometry_2d.Line2;
use xiom.geom.geometry_3d.Mesh;
use xiom.geom.geometry_3d.Point3;
use xiom.geom.Vec2;
use xiom.geom.Vec3;

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

fn mkvec(a: Float64, b: Float64, c: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  out.push(a);
  out.push(b);
  out.push(c);
  return out;
}

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- polyhedra: vertex/face counts and hulls
  if polyhedra.cube_vertices(2.0).len() != 8 { return 1; }
  if polyhedra.cube_faces().len() != 12 { return 2; }
  if polyhedra.sphere_vertices(1.0, 2, 2).len() != 9 { return 3; }
  if polyhedra.sphere_vertices(1.0, 0, 2).len() != 0 { return 4; }
  if polyhedra.icosahedron_vertices().len() != 12 { return 5; }
  if polyhedra.icosahedron_faces().len() != 20 { return 6; }
  if polyhedra.tetrahedron_vertices().len() != 4 { return 7; }
  if polyhedra.octahedron_vertices().len() != 6 { return 8; }
  if polyhedra.dodecahedron_vertices().len() != 20 { return 9; }
  var hv2 = Vec[Vec[Float64]].new();
  hv2.push(mkvec(0.0, 0.0, 0.0));
  hv2.push(mkvec(2.0, 0.0, 0.0));
  hv2.push(mkvec(2.0, 2.0, 0.0));
  hv2.push(mkvec(0.0, 2.0, 0.0));
  var e2h = Vec[Vec[Float64]].new();
  if polyhedra.convex_hull_2d(&e2h).len() != 0 { return 11; }
  var hv3 = Vec[Vec[Float64]].new();
  hv3.push(mkvec(0.0, 0.0, 0.0));
  hv3.push(mkvec(1.0, 0.0, 0.0));
  hv3.push(mkvec(0.0, 1.0, 0.0));
  hv3.push(mkvec(0.0, 0.0, 1.0));
  var e3h = Vec[Vec[Float64]].new();
  if polyhedra.convex_hull_3d(&e3h).len() != 0 { return 13; }

  // ---- geometry_extended: tessellation and curves
  var sites = Vec[Point2].new();
  sites.push(Point2{ x: 0.5; y: 0.5; });
  sites.push(Point2{ x: 1.5; y: 1.5; });
  var bounds = Rect{ min: Point2{ x: 0.0; y: 0.0; }; max: Point2{ x: 2.0; y: 2.0; }; };
  var vor = geometry_extended.voronoi(&sites, bounds);
  if vor.len() != 2 { return 14; }
  var e_sites = Vec[Point2].new();
  if geometry_extended.voronoi(&e_sites, bounds).len() != 0 { return 15; }
  var dl_pts = Vec[Point2].new();
  dl_pts.push(Point2{ x: 0.0; y: 0.0; });
  dl_pts.push(Point2{ x: 2.0; y: 0.0; });
  dl_pts.push(Point2{ x: 2.0; y: 2.0; });
  dl_pts.push(Point2{ x: 0.0; y: 2.0; });
  var dl = geometry_extended.delaunay(&dl_pts);
  if dl.len() == 0 { return 16; }
  var dshort = Vec[Point2].new();
  dshort.push(Point2{ x: 0.0; y: 0.0; });
  dshort.push(Point2{ x: 1.0; y: 0.0; });
  if geometry_extended.delaunay(&dshort).len() != 0 { return 17; }
  var ctrl = Vec[Vec2].new();
  ctrl.push(Vec2{ x: 0.0; y: 0.0; });
  ctrl.push(Vec2{ x: 1.0; y: 1.0; });
  ctrl.push(Vec2{ x: 2.0; y: 0.0; });
  var bz = geometry_extended.bezier_curve(&ctrl, 0.5);
  if !near(bz.x, 1.0) || !near(bz.y, 0.5) { return 18; }
  var e_ctrl = Vec[Vec2].new();
  var bz0 = geometry_extended.bezier_curve(&e_ctrl, 0.5);
  if bz0.x != 0.0 || bz0.y != 0.0 { return 19; }
  var knots = Vec[Float64].new();
  knots.push(0.0);
  knots.push(0.0);
  knots.push(0.0);
  knots.push(1.0);
  knots.push(1.0);
  knots.push(1.0);
  var bs = geometry_extended.b_spline(&ctrl, &knots, 0.5);
  if !near(bs.x, 1.0) || !near(bs.y, 0.5) { return 20; }
  var bshort = Vec[Vec2].new();
  bshort.push(Vec2{ x: 0.0; y: 0.0; });
  var bz2 = geometry_extended.b_spline(&bshort, &knots, 0.5);
  if bz2.x != 0.0 || bz2.y != 0.0 { return 21; }
  var wts = Vec[Float64].new();
  wts.push(1.0);
  wts.push(1.0);
  wts.push(1.0);
  var nu = geometry_extended.nurbs(&ctrl, &wts, &knots, 0.5);
  if !near(nu.x, 1.0) || !near(nu.y, 0.5) { return 22; }
  var wshort = Vec[Float64].new();
  wshort.push(1.0);
  var nu2 = geometry_extended.nurbs(&ctrl, &wshort, &knots, 0.5);
  if nu2.x != 0.0 || nu2.y != 0.0 { return 23; }

  // ---- geometry_extended: mesh ops and non-Euclidean metrics
  var mv = Vec[Point3].new();
  mv.push(Point3{ x: 0.0; y: 0.0; z: 0.0; });
  mv.push(Point3{ x: 1.0; y: 0.0; z: 0.0; });
  mv.push(Point3{ x: 0.0; y: 1.0; z: 0.0; });
  mv.push(Point3{ x: 0.0; y: 0.0; z: 1.0; });
  var mi = Vec[Int].new();
  mi.push(0);
  mi.push(1);
  mi.push(2);
  mi.push(0);
  mi.push(1);
  mi.push(3);
  mi.push(0);
  mi.push(2);
  mi.push(3);
  mi.push(1);
  mi.push(2);
  mi.push(3);
  var mesh = Mesh{ vertices: mv; indices: mi; };
  var sub = geometry_extended.subdivision(mesh, 1);
  if sub.vertices.len() != 16 { return 24; }
  if sub.indices.len() != 48 { return 25; }
  var sub0 = geometry_extended.subdivision(mesh, 0);
  if sub0.vertices.len() != 4 || sub0.indices.len() != 12 { return 26; }
  var vdup = Vec[Point3].new();
  vdup.push(Point3{ x: 0.0; y: 0.0; z: 0.0; });
  vdup.push(Point3{ x: 0.0; y: 0.0; z: 0.0; });
  vdup.push(Point3{ x: 1.0; y: 0.0; z: 0.0; });
  var idup = Vec[Int].new();
  idup.push(0);
  idup.push(1);
  idup.push(2);
  var dupmesh = Mesh{ vertices: vdup; indices: idup; };
  var clean = geometry_extended.mesh_processing(dupmesh);
  if clean.vertices.len() != 2 { return 27; }
  if clean.indices.len() != 3 { return 28; }
  var pj = Vec[Vec3].new();
  pj.push(Vec3{ x: 1.0; y: 0.0; z: 0.0; });
  pj.push(Vec3{ x: -1.0; y: -1.0; z: 1.0; });
  var proj = geometry_extended.projective_geometry(&pj);
  if proj.len() != 2 { return 29; }
  if !near(proj[0].x, 0.5) { return 30; }
  var ha = mkvec(0.0, 0.0, 0.0);
  var hb = mkvec(0.5, 0.0, 0.0);
  if !near(geometry_extended.hyperbolic_geometry(&ha, &hb), 1.09861228866811) { return 31; }
  if geometry_extended.hyperbolic_geometry(&ha, &ha) != 0.0 { return 32; }
  var h2 = Vec[Float64].new();
  h2.push(1.0);
  h2.push(0.0);
  var hm = geometry_extended.hyperbolic_geometry(&ha, &h2);
  if !(hm != hm) { return 33; }
  var ea = mkvec(1.0, 0.0, 0.0);
  var eb = mkvec(0.0, 1.0, 0.0);
  if !near(geometry_extended.elliptic_geometry(&ea, &eb), 1.5707963267948966) { return 34; }
  if geometry_extended.elliptic_geometry(&ea, &ea) != 0.0 { return 35; }
  if geometry_extended.non_euclidean(&ha, &ha) != 0.0 { return 36; }
  var ip = Vec[Point2].new();
  ip.push(Point2{ x: 0.0; y: 0.0; });
  var il = Vec[Line2].new();
  il.push(Line2{ a: 1.0; b: 0.0; c: 0.0; });
  if !geometry_extended.incidence_geometry(&ip, &il) { return 37; }
  var ip2 = Vec[Point2].new();
  ip2.push(Point2{ x: 1.0; y: 1.0; });
  if geometry_extended.incidence_geometry(&ip2, &il) { return 38; }
  var ip0 = Vec[Point2].new();
  if !geometry_extended.incidence_geometry(&ip0, &il) { return 39; }
  var cg = Vec[Vec2].new();
  cg.push(Vec2{ x: 0.0; y: 0.0; });
  cg.push(Vec2{ x: 2.0; y: 0.0; });
  cg.push(Vec2{ x: 2.0; y: 2.0; });
  cg.push(Vec2{ x: 0.0; y: 2.0; });
  if geometry_extended.convex_geometry(&cg).vertices.len() != 4 { return 40; }
  var comp = geometry_extended.computational_geometry(&cg);
  if comp.len() != 1 { return 41; }
  var cg0 = Vec[Vec2].new();
  if geometry_extended.computational_geometry(&cg0).len() != 0 { return 42; }

  // ---- linear: predicates on probe-built matrices (callee reads are sound)
  var id2 = mk2(1.0, 0.0, 0.0, 1.0);
  if !linear.is_orthogonal(&id2) { return 43; }
  var tri_m = mk2(1.0, 0.0, 1.0, 1.0);
  if linear.is_orthogonal(&tri_m) { return 44; }
  var sym = mk2(1.0, 2.0, 2.0, 3.0);
  if !linear.is_symmetric(&sym) { return 45; }
  var nsym = mk2(1.0, 2.0, 3.0, 4.0);
  if linear.is_symmetric(&nsym) { return 46; }
  var skew = mk2(0.0, -1.0, 1.0, 0.0);
  if !linear.is_skew_symmetric(&skew) { return 47; }
  if linear.is_skew_symmetric(&sym) { return 48; }
  var pd = mk2(2.0, 0.0, 0.0, 3.0);
  if !linear.is_positive_definite(&pd) { return 49; }
  var npd = mk2(1.0, 2.0, 2.0, 1.0);
  if linear.is_positive_definite(&npd) { return 50; }
  var dd = mk2(2.0, 1.0, 1.0, 2.0);
  if !linear.is_diagonal_dominant(&dd) { return 51; }
  var ndd = mk2(1.0, 2.0, 0.0, 1.0);
  if linear.is_diagonal_dominant(&ndd) { return 52; }
  var em = Vec[Vec[Float64]].new();
  if !linear.is_symmetric(&em) { return 53; }
  if linear.is_positive_definite(&em) { return 54; }

  // ---- linear: transforms (length checks + predicate mediation)
  var gsv = Vec[Vec[Float64]].new();
  gsv.push(mkvec(1.0, 0.0, 0.0));
  gsv.push(mkvec(1.0, 1.0, 0.0));
  var gs = linear.gram_schmidt(&gsv);
  if gs.len() != 2 { return 55; }
  var og = linear.orthogonalize(&gsv);
  if og.len() != 2 { return 56; }
  var nr = linear.normalize_rows(&sym);
  if nr.len() != 2 { return 57; }
  var nc = linear.normalize_columns(&sym);
  if nc.len() == 0 { return 58; }
  var zero2 = mk2(0.0, 0.0, 0.0, 0.0);
  var mex = linear.matrix_exponential(&zero2);
  if mex.len() != 2 { return 59; }
  var mlg = linear.matrix_logarithm(&id2);
  if mlg.len() != 2 { return 60; }
  var msq = linear.matrix_sqrt(&pd);
  if msq.len() != 2 { return 61; }
  var mpw = linear.matrix_power(&id2, -1);
  if mpw.len() != 2 { return 62; }
  var nsm = Vec[Vec[Float64]].new();
  var nsr0 = Vec[Float64].new();
  nsr0.push(1.0);
  nsr0.push(0.0);
  nsr0.push(0.0);
  nsm.push(nsr0);
  var nsr1 = Vec[Float64].new();
  nsr1.push(0.0);
  nsr1.push(1.0);
  nsr1.push(0.0);
  nsm.push(nsr1);
  var mns = linear.matrix_exponential(&nsm);
  if mns.len() != 0 { return 63; }
  var nsp2 = Vec[Vec[Float64]].new();
  if linear.matrix_power(&nsp2, 2).len() != 0 { return 64; }

  // ---- linear: skew round-trip (skew_to_vec copies rows first)
  var v3 = mkvec(1.0, 2.0, 3.0);
  var sk = linear.vec_to_skew(&v3);
  if sk.len() != 3 { return 65; }
  var back = linear.skew_to_vec(&sk);
  if back.len() != 3 { return 66; }
  if back[0] != 1.0 || back[1] != 2.0 || back[2] != 3.0 { return 67; }
  var v2s = Vec[Float64].new();
  v2s.push(1.0);
  v2s.push(2.0);
  if linear.vec_to_skew(&v2s).len() != 0 { return 68; }
  var bad3 = mk2(1.0, 0.0, 0.0, 1.0);
  if linear.skew_to_vec(&bad3).len() != 0 { return 69; }

  return 0;
}

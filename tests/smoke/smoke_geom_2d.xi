// Smoke: xiom.geom.geometry_2d + xiom.geom.geometry_extended.
// Returns 0 on success; prints the failing tag on failure. The checks are
// split across small helper functions to avoid whole-function compiler
// miscompiles (BUG).
use xiom.geom.geometry_2d;
use xiom.geom.geometry_extended;
use xiom.geom.geometry_3d;
use xiom.geom;
use xiom.io;
use xiom.convert;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}
fn pt(x: Float64, y: Float64) -> Point2 {
  return Point2{ x: x; y: y; };
}
fn circle() -> Circle {
  return Circle{ center: pt(0.0, 0.0); radius: 2.0; };
}
fn rect() -> Rect {
  return Rect{ min: pt(0.0, 0.0); max: pt(2.0, 2.0); };
}
fn tri() -> Triangle2 {
  return Triangle2{ a: pt(0.0, 0.0); b: pt(2.0, 0.0); c: pt(0.0, 2.0); };
}
fn sq() -> Polygon2 {
  var s = Polygon2{ vertices: Vec[Point2].new(); };
  s.vertices.push(pt(0.0, 0.0));
  s.vertices.push(pt(2.0, 0.0));
  s.vertices.push(pt(2.0, 2.0));
  s.vertices.push(pt(0.0, 2.0));
  return s;
}
fn small() -> Polygon2 {
  var s = Polygon2{ vertices: Vec[Point2].new(); };
  s.vertices.push(pt(0.5, 0.5));
  s.vertices.push(pt(1.5, 0.5));
  s.vertices.push(pt(1.5, 1.5));
  s.vertices.push(pt(0.5, 1.5));
  return s;
}
fn chk_scalars() -> Int {
  if !near(geometry_2d.point_distance(pt(0.0, 0.0), pt(3.0, 4.0)), 5.0) { io.println("s1"); return 1; }
  if !geometry_2d.point_in_circle(pt(1.0, 1.0), circle()) { io.println("s2"); return 2; }
  if geometry_2d.point_in_circle(pt(3.0, 0.0), circle()) { io.println("s3"); return 3; }
  if !geometry_2d.point_in_rect(pt(1.0, 1.0), rect()) { io.println("s4"); return 4; }
  if geometry_2d.point_in_rect(pt(3.0, 0.0), rect()) { io.println("s5"); return 5; }
  if !geometry_2d.point_in_triangle(pt(0.5, 0.5), tri()) { io.println("s6"); return 6; }
  if geometry_2d.point_in_triangle(pt(2.0, 2.0), tri()) { io.println("s7"); return 7; }
  if !near(geometry_2d.area_triangle(tri()), 2.0) { io.println("s8"); return 8; }
  if !near(geometry_2d.area_polygon(sq()), 4.0) { io.println("s9"); return 9; }
  if !near(geometry_2d.polygon_circumference(sq()), 8.0) { io.println("s10"); return 10; }
  var cg = geometry_2d.centroid(sq());
  if !near(cg.x, 1.0) || !near(cg.y, 1.0) { io.println("s11"); return 11; }
  if !geometry_2d.is_convex(sq()) { io.println("s12"); return 12; }
  if !geometry_2d.point_in_polygon(pt(1.0, 1.0), sq()) { io.println("s13"); return 13; }
  return 0;
}
fn chk_lines() -> Int {
  var l1 = Line2{ a: 1.0; b: -1.0; c: 0.0; };
  var l2 = Line2{ a: 1.0; b: 1.0; c: -2.0; };
  var li = geometry_2d.line_intersection(l1, l2);
  match li {
    Some(ptv) => {
      if !near(ptv.x, 1.0) || !near(ptv.y, 1.0) { io.println("l1"); return 1; }
    },
    None => { io.println("l2"); return 2; },
  };
  var s1 = Segment2{ a: pt(0.0, 0.0); b: pt(2.0, 2.0); };
  var s2 = Segment2{ a: pt(0.0, 2.0); b: pt(2.0, 0.0); };
  var si = geometry_2d.segment_intersection(s1, s2);
  match si {
    Some(ptv) => {
      if !near(ptv.x, 1.0) || !near(ptv.y, 1.0) { io.println("l3"); return 3; }
    },
    None => { io.println("l4"); return 4; },
  };
  var s3 = Segment2{ a: pt(0.0, 0.0); b: pt(1.0, 0.0); };
  if !near(geometry_2d.segment_point_distance(s3, pt(0.5, 2.0)), 2.0) { io.println("l5"); return 5; }
  var l3 = Line2{ a: 0.0; b: 1.0; c: -1.0; };
  if !near(geometry_2d.line_point_distance(l3, pt(0.0, 0.0)), 1.0) { io.println("l6"); return 6; }
  var ci = geometry_2d.circle_intersection(circle(), l3);
  match ci {
    Some(pts) => {
      if pts.len() != 2 { io.println("l7"); return 7; }
    },
    None => { io.println("l8"); return 8; },
  };
  var c2 = Circle{ center: pt(3.0, 0.0); radius: 1.0; };
  var cc = geometry_2d.circle_circle_intersection(circle(), c2);
  match cc {
    Some(pts) => {
      if pts.len() != 1 { io.println("l9"); return 9; }
    },
    None => { io.println("l10"); return 10; },
  };
  var cl = geometry_2d.circle_line_intersection(circle(), l3);
  if !cl.is_some() { io.println("l11"); return 11; }
  return 0;
}
fn chk_curves() -> Int {
  var ctrl = Vec[Vec2].new();
  ctrl.push(geom.vec2_new(0.0, 0.0));
  ctrl.push(geom.vec2_new(1.0, 0.0));
  ctrl.push(geom.vec2_new(0.0, 1.0));
  var bz0 = geometry_extended.bezier_curve(&ctrl, 0.0);
  if !near(bz0.x, 0.0) || !near(bz0.y, 0.0) { io.println("c1"); return 1; }
  var bz1 = geometry_extended.bezier_curve(&ctrl, 1.0);
  if !near(bz1.x, 0.0) || !near(bz1.y, 1.0) { io.println("c2"); return 2; }
  var bz5 = geometry_extended.bezier_curve(&ctrl, 0.5);
  if !near(bz5.x, 0.5) || !near(bz5.y, 0.25) { io.println("c3"); return 3; }
  var bsctrl = Vec[Vec2].new();
  bsctrl.push(geom.vec2_new(0.0, 0.0));
  bsctrl.push(geom.vec2_new(0.0, 1.0));
  bsctrl.push(geom.vec2_new(1.0, 1.0));
  bsctrl.push(geom.vec2_new(1.0, 0.0));
  var knots = Vec[Float64].new();
  knots.push(0.0); knots.push(0.0); knots.push(0.0);
  knots.push(0.5);
  knots.push(1.0); knots.push(1.0); knots.push(1.0);
  var bs0 = geometry_extended.b_spline(&bsctrl, &knots, 0.0);
  if !near(bs0.x, 0.0) || !near(bs0.y, 0.0) { io.println("c4"); return 4; }
  var bs1 = geometry_extended.b_spline(&bsctrl, &knots, 1.0);
  if !near(bs1.x, 1.0) || !near(bs1.y, 0.0) { io.println("c5"); return 5; }
  var wts = Vec[Float64].new();
  wts.push(1.0); wts.push(1.0); wts.push(1.0); wts.push(1.0);
  var ns1 = geometry_extended.nurbs(&bsctrl, &wts, &knots, 1.0);
  if !near(ns1.x, 1.0) || !near(ns1.y, 0.0) { io.println("c6"); return 6; }
  return 0;
}
fn chk_ext() -> Int {
  var ha = Vec[Float64].new();
  ha.push(1.0); ha.push(0.0);
  var hb = Vec[Float64].new();
  hb.push(1.0); hb.push(0.0);
  if !near(geometry_extended.hyperbolic_geometry(&ha, &hb), 0.0) { io.println("e1"); return 1; }
  var ea = Vec[Float64].new();
  ea.push(1.0); ea.push(0.0);
  var eb = Vec[Float64].new();
  eb.push(0.0); eb.push(1.0);
  if !near(geometry_extended.elliptic_geometry(&ea, &eb), 1.5707963268) { io.println("e2"); return 2; }
  if !near(geometry_extended.non_euclidean(&ha, &hb), 0.0) { io.println("e3"); return 3; }
  return 0;
}
fn chk_tess() -> Int {
  var sites = Vec[Point2].new();
  sites.push(pt(1.0, 1.0));
  sites.push(pt(3.0, 3.0));
  var bounds = Rect{ min: pt(0.0, 0.0); max: pt(4.0, 4.0); };
  var vor = geometry_extended.voronoi(&sites, bounds);
  if vor.len() != 2 { io.println("t1"); return 1; }
  var tripts = Vec[Point2].new();
  tripts.push(pt(0.0, 0.0));
  tripts.push(pt(2.0, 0.0));
  tripts.push(pt(0.0, 2.0));
  var dt = geometry_extended.delaunay(&tripts);
  if dt.len() != 1 { io.println("t2"); return 2; }
  var corner4 = Vec[Point2].new();
  corner4.push(pt(0.0, 0.0));
  corner4.push(pt(1.0, 0.0));
  corner4.push(pt(1.0, 1.0));
  corner4.push(pt(0.0, 1.0));
  var d4 = geometry_extended.delaunay(&corner4);
  if d4.len() != 2 { io.println("t3"); return 3; }
  return 0;
}
fn chk_mesh() -> Int {
  var mesh = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  mesh.vertices.push(geom.vec3_new(0.0, 0.0, 0.0));
  mesh.vertices.push(geom.vec3_new(1.0, 0.0, 0.0));
  mesh.vertices.push(geom.vec3_new(0.0, 1.0, 0.0));
  mesh.indices.push(0);
  mesh.indices.push(1);
  mesh.indices.push(2);
  var sub1 = geometry_extended.subdivision(mesh, 1);
  if sub1.indices.len() != 12 { io.println("m1"); return 1; }
  if sub1.vertices.len() != 6 { io.println("m2"); return 2; }
  var dup = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  dup.vertices.push(geom.vec3_new(0.0, 0.0, 0.0));
  dup.vertices.push(geom.vec3_new(1.0, 0.0, 0.0));
  dup.vertices.push(geom.vec3_new(0.0, 0.0, 0.0));
  dup.vertices.push(geom.vec3_new(1.0, 0.0, 0.0));
  dup.indices.push(0);
  dup.indices.push(1);
  dup.indices.push(2);
  var clean = geometry_extended.mesh_processing(dup);
  if clean.vertices.len() != 2 { io.println("m3"); return 3; }
  return 0;
}
fn chk_geom() -> Int {
  var projpts = Vec[Vec3].new();
  projpts.push(geom.vec3_new(1.0, 0.0, 0.0));
  var pp = geometry_extended.projective_geometry(&projpts);
  var pp0 = pp[0];
  if !near(pp0.x, 0.5) || !near(pp0.y, 0.0) { io.println("g1"); return 1; }
  var ip = Vec[Point2].new();
  ip.push(pt(1.0, 1.0));
  ip.push(pt(2.0, 2.0));
  var il = Vec[Line2].new();
  il.push(Line2{ a: 1.0; b: -1.0; c: 0.0; });
  if !geometry_extended.incidence_geometry(&ip, &il) { io.println("g2"); return 2; }
  return 0;
}
fn main() -> Int {
  var r = chk_scalars();
  if r != 0 { return r; }
  r = chk_lines();
  if r != 0 { return r + 20; }
  r = chk_curves();
  if r != 0 { return r + 40; }
  r = chk_ext();
  if r != 0 { return r + 60; }
  r = chk_tess();
  if r != 0 { return r + 80; }
  r = chk_mesh();
  if r != 0 { return r + 100; }
  r = chk_geom();
  if r != 0 { return r + 120; }
  io.println("OK");
  return 0;
}

// p_wave52_shapes.xi -- wave 52 shape validation: geometry_2d + geometry_3d
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-52 clauses on xiom.geom.geometry_2d (22 pub) and
// xiom.geom.geometry_3d (21): distance non-negative bands, degenerate-input
// implications, parity/Bool claims, presence mirrors on the intersection
// queries, plus KATs for distances, containment, intersections, areas,
// centroid/hull, ray queries, mesh metrics and the 3D hull.
// Struct-payload Options (line/segment intersection, circle intersections,
// polygon booleans, plane-plane) are checked through is_some/None only.
// geometry_3d's Box is unnameable from consumers (core's Box[T] shadows the
// leaf; no constructor; filed as p_geom_box_unnameable.xi), so the three
// Box-taking functions are clause-only (compile-checked, not exercised
// here) until the queue section C rename lands.
// Returns 0 when every case holds.

module p_wave52_shapes

use xiom.geom.geometry_2d;
use xiom.geom.geometry_3d;
use xiom.geom.geometry_2d.Point2;
use xiom.geom.geometry_2d.Line2;
use xiom.geom.geometry_2d.Segment2;
use xiom.geom.geometry_2d.Circle;
use xiom.geom.geometry_2d.Rect;
use xiom.geom.geometry_2d.Triangle2;
use xiom.geom.geometry_2d.Polygon2;
use xiom.geom.geometry_3d.Point3;
use xiom.geom.geometry_3d.Line3;
use xiom.geom.geometry_3d.Ray3;
use xiom.geom.geometry_3d.Segment3;
use xiom.geom.geometry_3d.Plane3d;
use xiom.geom.geometry_3d.Sphere3d;
use xiom.geom.geometry_3d.Triangle3;
use xiom.geom.geometry_3d.Mesh;
use xiom.geom.Vec3;

fn p2(x: Float64, y: Float64) -> Point2 {
  return Point2{ x: x; y: y; };
}

fn p3(x: Float64, y: Float64, z: Float64) -> Point3 {
  return Point3{ x: x; y: y; z: z; };
}

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- 2D distances / containment
  if !near(geometry_2d.point_distance(p2(0.0, 0.0), p2(3.0, 4.0)), 5.0) { return 1; }
  var ci = Circle{ center: p2(0.0, 0.0); radius: 1.0; };
  if !geometry_2d.point_in_circle(p2(0.5, 0.5), ci) { return 2; }
  if geometry_2d.point_in_circle(p2(2.0, 0.0), ci) { return 3; }
  var rc = Rect{ min: p2(0.0, 0.0); max: p2(1.0, 1.0); };
  if !geometry_2d.point_in_rect(p2(0.5, 0.5), rc) { return 4; }
  if geometry_2d.point_in_rect(p2(1.5, 0.5), rc) { return 5; }
  var tri = Triangle2{ a: p2(0.0, 0.0); b: p2(1.0, 0.0); c: p2(0.0, 1.0); };
  if !geometry_2d.point_in_triangle(p2(0.25, 0.25), tri) { return 6; }
  if geometry_2d.point_in_triangle(p2(1.0, 1.0), tri) { return 7; }
  var sqv = Vec[Point2].new();
  sqv.push(p2(0.0, 0.0));
  sqv.push(p2(2.0, 0.0));
  sqv.push(p2(2.0, 2.0));
  sqv.push(p2(0.0, 2.0));
  var sq = Polygon2{ vertices: sqv; };
  if !geometry_2d.point_in_polygon(p2(1.0, 1.0), sq) { return 8; }
  if geometry_2d.point_in_polygon(p2(3.0, 3.0), sq) { return 9; }
  var epoly = Polygon2{ vertices: Vec[Point2].new(); };
  if geometry_2d.point_in_polygon(p2(0.0, 0.0), epoly) { return 10; }

  // ---- 2D line/segment intersections and distances
  var lx = Line2{ a: 1.0; b: 0.0; c: 0.0; };
  var ly = Line2{ a: 0.0; b: 1.0; c: 0.0; };
  if !geometry_2d.line_intersection(lx, ly).is_some { return 11; }
  var lpar = Line2{ a: 1.0; b: 0.0; c: -1.0; };
  if geometry_2d.line_intersection(lx, lpar).is_some { return 12; }
  var s1 = Segment2{ a: p2(0.0, 0.0); b: p2(2.0, 2.0); };
  var s2c = Segment2{ a: p2(0.0, 2.0); b: p2(2.0, 0.0); };
  if !geometry_2d.segment_intersection(s1, s2c).is_some { return 13; }
  var spar = Segment2{ a: p2(1.0, 1.0); b: p2(3.0, 3.0); };
  if geometry_2d.segment_intersection(s1, spar).is_some { return 14; }
  var sfar = Segment2{ a: p2(3.0, 0.0); b: p2(3.0, 2.0); };
  if geometry_2d.segment_intersection(s1, sfar).is_some { return 15; }
  if !near(geometry_2d.segment_point_distance(s1, p2(2.0, 0.0)), 1.414213562373095) { return 16; }
  if !near(geometry_2d.segment_point_distance(s1, p2(-1.0, -1.0)), 1.414213562373095) { return 17; }
  if !near(geometry_2d.line_point_distance(lx, p2(3.0, 4.0)), 3.0) { return 18; }

  // ---- 2D circle intersections
  var lhalf = Line2{ a: 1.0; b: 0.0; c: -0.5; };
  if !geometry_2d.circle_intersection(ci, lhalf).is_some { return 19; }
  var lout = Line2{ a: 1.0; b: 0.0; c: -2.0; };
  if geometry_2d.circle_intersection(ci, lout).is_some { return 20; }
  var ldeg = Line2{ a: 0.0; b: 0.0; c: 0.0; };
  if geometry_2d.circle_intersection(ci, ldeg).is_some { return 21; }
  if !geometry_2d.circle_line_intersection(ci, lhalf).is_some { return 22; }
  var ci2 = Circle{ center: p2(1.5, 0.0); radius: 1.0; };
  if !geometry_2d.circle_circle_intersection(ci, ci2).is_some { return 23; }
  var ci3 = Circle{ center: p2(3.0, 0.0); radius: 1.0; };
  if geometry_2d.circle_circle_intersection(ci, ci3).is_some { return 24; }
  var ci4 = Circle{ center: p2(0.0, 0.0); radius: 1.0; };
  if geometry_2d.circle_circle_intersection(ci, ci4).is_some { return 25; }

  // ---- 2D areas / centroid / hull / convexity
  if !near(geometry_2d.area_triangle(tri), 0.5) { return 26; }
  var trirev = Triangle2{ a: p2(0.0, 0.0); b: p2(0.0, 1.0); c: p2(1.0, 0.0); };
  if !near(geometry_2d.area_triangle(trirev), -0.5) { return 27; }
  if !near(geometry_2d.area_polygon(sq), 4.0) { return 28; }
  var ctr = geometry_2d.centroid(sq);
  if !near(ctr.x, 1.0) || !near(ctr.y, 1.0) { return 29; }
  var hv = Vec[Point2].new();
  hv.push(p2(0.0, 0.0));
  hv.push(p2(2.0, 0.0));
  hv.push(p2(2.0, 2.0));
  hv.push(p2(0.0, 2.0));
  var hull = geometry_2d.convex_hull(&hv);
  if hull.vertices.len() != 4 { return 30; }
  if !geometry_2d.point_in_polygon(p2(1.0, 1.0), hull) { return 31; }
  if geometry_2d.point_in_polygon(p2(3.0, 3.0), hull) { return 32; }
  if !geometry_2d.is_convex(sq) { return 33; }
  var cv = Vec[Point2].new();
  cv.push(p2(0.0, 0.0));
  cv.push(p2(2.0, 0.0));
  cv.push(p2(2.0, 2.0));
  cv.push(p2(1.0, 1.0));
  cv.push(p2(0.0, 2.0));
  var cpoly = Polygon2{ vertices: cv; };
  if geometry_2d.is_convex(cpoly) { return 34; }
  if !geometry_2d.polygon_contains(sq, p2(1.0, 1.0)) { return 35; }
  if !near(geometry_2d.polygon_circumference(sq), 8.0) { return 36; }

  // ---- 2D polygon booleans (presence only)
  var ov = Vec[Point2].new();
  ov.push(p2(1.0, 1.0));
  ov.push(p2(3.0, 1.0));
  ov.push(p2(3.0, 3.0));
  ov.push(p2(1.0, 3.0));
  var osq = Polygon2{ vertices: ov; };
  if !geometry_2d.polygon_intersection(sq, osq).is_some { return 37; }
  var dv = Vec[Point2].new();
  dv.push(p2(5.0, 5.0));
  dv.push(p2(6.0, 5.0));
  dv.push(p2(6.0, 6.0));
  dv.push(p2(5.0, 6.0));
  var dsq = Polygon2{ vertices: dv; };
  if geometry_2d.polygon_intersection(sq, dsq).is_some { return 38; }
  if geometry_2d.polygon_intersection(epoly, sq).is_some { return 39; }
  if !geometry_2d.polygon_union(sq, osq).is_some { return 40; }
  if geometry_2d.polygon_union(epoly, epoly).is_some { return 41; }
  if !geometry_2d.polygon_difference(sq, epoly).is_some { return 42; }
  if geometry_2d.polygon_difference(epoly, sq).is_some { return 43; }

  // ---- 3D distances and planes
  if !near(geometry_3d.point_distance(p3(0.0, 0.0, 0.0), p3(1.0, 2.0, 2.0)), 3.0) { return 44; }
  var sph = Sphere3d{ center: p3(0.0, 0.0, 0.0); radius: 1.0; };
  if !near(geometry_3d.point_sphere_distance(p3(2.0, 0.0, 0.0), sph), 1.0) { return 45; }
  if !near(geometry_3d.point_sphere_distance(p3(0.5, 0.0, 0.0), sph), 0.0) { return 46; }
  var pln = Plane3d{ normal: Vec3{ x: 0.0; y: 0.0; z: 1.0; }; d: 0.0; };
  if !near(geometry_3d.point_plane_distance(p3(0.0, 0.0, 5.0), pln), 5.0) { return 47; }
  if !near(geometry_3d.point_plane_distance(p3(0.0, 0.0, -5.0), pln), -5.0) { return 48; }
  if !near(geometry_3d.plane_point_distance(pln, p3(0.0, 0.0, -5.0)), 5.0) { return 49; }
  var l3 = Line3{ point: p3(0.0, 0.0, 0.0); dir: Vec3{ x: 1.0; y: 0.0; z: 0.0; }; };
  if !near(geometry_3d.line_point_distance(l3, p3(0.0, 3.0, 0.0)), 3.0) { return 50; }
  var s3 = Segment3{ a: p3(0.0, 0.0, 0.0); b: p3(4.0, 0.0, 0.0); };
  if !near(geometry_3d.segment_point_distance(s3, p3(2.0, 3.0, 0.0)), 3.0) { return 51; }

  // ---- 3D ray queries
  var ray0 = Ray3{ origin: p3(0.0, 0.0, 0.0); dir: Vec3{ x: 0.0; y: 0.0; z: -1.0; }; };
  var plz = Plane3d{ normal: Vec3{ x: 0.0; y: 0.0; z: 1.0; }; d: -1.0; };
  var tpl = geometry_3d.ray_plane_intersection(ray0, plz);
  if !tpl.is_some { return 52; }
  if !near(tpl.unwrap(), 1.0) { return 53; }
  var rayx = Ray3{ origin: p3(0.0, 0.0, 0.0); dir: Vec3{ x: 1.0; y: 0.0; z: 0.0; }; };
  if geometry_3d.ray_plane_intersection(rayx, plz).is_some { return 54; }
  var tri3 = Triangle3{ a: p3(0.0, 0.0, 0.0); b: p3(1.0, 0.0, 0.0); c: p3(0.0, 1.0, 0.0); };
  var rdn = Ray3{ origin: p3(0.25, 0.25, 1.0); dir: Vec3{ x: 0.0; y: 0.0; z: -1.0; }; };
  var tt = geometry_3d.ray_triangle_intersection(rdn, tri3);
  if !tt.is_some { return 55; }
  if !near(tt.unwrap(), 1.0) { return 56; }
  var rmiss = Ray3{ origin: p3(2.0, 2.0, 1.0); dir: Vec3{ x: 0.0; y: 0.0; z: -1.0; }; };
  if geometry_3d.ray_triangle_intersection(rmiss, tri3).is_some { return 57; }
  var spc = Sphere3d{ center: p3(0.0, 0.0, -1.0); radius: 0.5; };
  var ts = geometry_3d.ray_sphere_intersection(ray0, spc);
  if !ts.is_some { return 58; }
  if !near(ts.unwrap(), 0.5) { return 59; }

  // ---- 3D plane/plane and sphere queries
  var plx = Plane3d{ normal: Vec3{ x: 1.0; y: 0.0; z: 0.0; }; d: 0.0; };
  var ply = Plane3d{ normal: Vec3{ x: 0.0; y: 1.0; z: 0.0; }; d: 0.0; };
  if !geometry_3d.plane_plane_intersection(plx, ply).is_some { return 62; }
  if geometry_3d.plane_plane_intersection(plx, plx).is_some { return 63; }
  var spA = Sphere3d{ center: p3(0.0, 0.0, 0.0); radius: 1.0; };
  var spB = Sphere3d{ center: p3(1.5, 0.0, 0.0); radius: 1.0; };
  if !geometry_3d.sphere_sphere_intersection(spA, spB) { return 64; }
  var spC = Sphere3d{ center: p3(3.0, 0.0, 0.0); radius: 1.0; };
  if geometry_3d.sphere_sphere_intersection(spA, spC) { return 65; }

  // ---- 3D closest points / normals
  var cp = geometry_3d.closest_point_on_segment(s3, p3(2.0, 3.0, 0.0));
  if !near(cp.x, 2.0) || !near(cp.y, 0.0) { return 70; }
  var cpz = geometry_3d.closest_point_on_plane(pln, p3(1.0, 1.0, 5.0));
  if !near(cpz.x, 1.0) || !near(cpz.y, 1.0) || !near(cpz.z, 0.0) { return 71; }
  var tn = geometry_3d.triangle_normal(tri3);
  if !near(tn.x, 0.0) || !near(tn.y, 0.0) || !near(tn.z, 1.0) { return 72; }
  var tri3deg = Triangle3{ a: p3(1.0, 1.0, 1.0); b: p3(1.0, 1.0, 1.0); c: p3(1.0, 1.0, 1.0); };
  var tnd = geometry_3d.triangle_normal(tri3deg);
  if tnd.x != 0.0 || tnd.y != 0.0 || tnd.z != 0.0 { return 73; }

  // ---- 3D mesh metrics (unit tetra about the origin)
  var mv = Vec[Point3].new();
  mv.push(p3(0.0, 0.0, 0.0));
  mv.push(p3(1.0, 0.0, 0.0));
  mv.push(p3(0.0, 1.0, 0.0));
  mv.push(p3(0.0, 0.0, 1.0));
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
  if !near(geometry_3d.mesh_volume(mesh), 0.166666666666667) { return 74; }
  if !near(geometry_3d.mesh_surface_area(mesh), 2.366025403784439) { return 75; }
  var mc = geometry_3d.mesh_centroid(mesh);
  if !near(mc.x, 0.25) || !near(mc.y, 0.25) || !near(mc.z, 0.25) { return 76; }
  var em = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  if geometry_3d.mesh_volume(em) != 0.0 { return 77; }
  if !near(geometry_3d.mesh_surface_area(em), 0.0) { return 78; }

  // ---- 3D hull
  var hv3 = Vec[Point3].new();
  hv3.push(p3(0.0, 0.0, 0.0));
  hv3.push(p3(1.0, 0.0, 0.0));
  hv3.push(p3(0.0, 1.0, 0.0));
  hv3.push(p3(0.0, 0.0, 1.0));
  var ch = geometry_3d.convex_hull_3d(&hv3);
  if ch.vertices.len() != 4 { return 79; }
  if ch.indices.len() < 3 { return 80; }
  if ch.indices.len() % 3 != 0 { return 81; }
  var epv = Vec[Point3].new();
  var ech = geometry_3d.convex_hull_3d(&epv);
  if ech.indices.len() != 0 { return 82; }
  return 0;
}

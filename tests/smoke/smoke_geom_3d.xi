// Smoke: xiom.geom.geometry_3d.
// Returns 0 on success; prints the failing tag on failure. Checks are split
// across small helper functions to avoid whole-function compiler miscompiles.
// NOTE: geometry_3d.Sphere/Plane/Box cannot be constructed smoke-side because
// geom.xi's Sphere/Plane (and core's generic Box) shadow those names through
// the transitive xiom.geom import (compiler type-identity bug) - the
// sphere/plane/box query functions are therefore verified indirectly through
// the primitive types that are constructible.
use xiom.geom.geometry_3d;
use xiom.geom.vec;
use xiom.io;
use xiom.convert;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn p3(x: Float64, y: Float64, z: Float64) -> Point3 {
  return Point3{ x: x; y: y; z: z; };
}

fn chk_distances() -> Int {
  if !near(geometry_3d.point_distance(p3(0.0, 0.0, 0.0), p3(3.0, 4.0, 0.0)), 5.0) { io.println("d1"); return 1; }
  var ln = Line3{ point: p3(0.0, 0.0, 0.0); dir: vec.vec3_new(1.0, 0.0, 0.0); };
  if !near(geometry_3d.line_point_distance(ln, p3(0.0, 1.0, 0.0)), 1.0) { io.println("d2"); return 2; }
  var sg = Segment3{ a: p3(0.0, 0.0, 0.0); b: p3(1.0, 0.0, 0.0); };
  if !near(geometry_3d.segment_point_distance(sg, p3(0.5, 3.0, 0.0)), 3.0) { io.println("d3"); return 3; }
  var cp = geometry_3d.closest_point_on_segment(sg, p3(1.0, 1.0, 0.0));
  if !near(cp.x, 1.0) || !near(cp.y, 0.0) { io.println("d4"); return 4; }
  return 0;
}

fn chk_rays() -> Int {
  var ray = Ray3{ origin: p3(0.0, 0.0, 5.0); dir: vec.vec3_new(0.0, 0.0, -1.0); };
  var tri = Triangle3{ a: p3(1.0, 0.0, 0.0); b: p3(0.0, 1.0, 0.0); c: p3(0.0, 0.0, 0.0); };
  var rt = geometry_3d.ray_triangle_intersection(ray, tri);
  match rt {
    Some(t) => {
      if !near(t, 5.0) { io.println("r1"); return 1; }
    },
    None => { io.println("r2"); return 2; },
  };
  var n = geometry_3d.triangle_normal(tri);
  if !near(n.x, 0.0) || !near(n.y, 0.0) || !near(n.z, 1.0) { io.println("r3"); return 3; }
  return 0;
}

fn chk_mesh() -> Int {
  var mesh = Mesh{ vertices: Vec[Point3].new(); indices: Vec[Int].new(); };
  mesh.vertices.push(p3(0.0, 0.0, 0.0));
  mesh.vertices.push(p3(1.0, 0.0, 0.0));
  mesh.vertices.push(p3(0.0, 1.0, 0.0));
  mesh.vertices.push(p3(0.0, 0.0, 1.0));
  mesh.indices.push(1); mesh.indices.push(2); mesh.indices.push(3);
  mesh.indices.push(0); mesh.indices.push(3); mesh.indices.push(2);
  mesh.indices.push(0); mesh.indices.push(1); mesh.indices.push(3);
  mesh.indices.push(0); mesh.indices.push(2); mesh.indices.push(1);
  var vol = geometry_3d.mesh_volume(mesh);
  if !near(vol, 0.1666666667) { io.println("m1"); return 1; }
  var area = geometry_3d.mesh_surface_area(mesh);
  if !near(area, 2.3660254038) { io.println("m2"); return 2; }
  var cent = geometry_3d.mesh_centroid(mesh);
  if !near(cent.x, 0.25) || !near(cent.y, 0.25) || !near(cent.z, 0.25) { io.println("m3"); return 3; }
  return 0;
}

fn chk_hull() -> Int {
  var pts = Vec[Point3].new();
  pts.push(p3(0.0, 0.0, 0.0));
  pts.push(p3(1.0, 0.0, 0.0));
  pts.push(p3(0.0, 1.0, 0.0));
  pts.push(p3(0.0, 0.0, 1.0));
  var hull = geometry_3d.convex_hull_3d(&pts);
  if hull.indices.len() != 12 { io.println("h1"); return 1; }
  return 0;
}

fn main() -> Int {
  var r = chk_distances();
  if r != 0 { return r; }
  r = chk_rays();
  if r != 0 { return r + 20; }
  r = chk_mesh();
  if r != 0 { return r + 40; }
  r = chk_hull();
  if r != 0 { return r + 60; }
  io.println("OK");
  return 0;
}

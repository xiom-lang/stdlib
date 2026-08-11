// XIOM - Geom: Geometry 3D
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.geometry_3d

// Depends on: xiom.geom

// ============================================================================
// 3D primitives, ray queries, containment tests, and mesh metrics. NOTE:
// current implementation lives in geom/collision.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Point3 - 3D point; struct { x: Float64; y: Float64; z: Float64 }.
// type Line3 - infinite line; struct { point: Point3; dir: Vec3 }.
// type Ray3 - ray; struct { origin: Point3; dir: Vec3 }.
// type Segment3 - segment; struct { a: Point3; b: Point3 }.
// type Plane - plane; struct { normal: Vec3; d: Float64 } (normal . p = d).
// type Sphere - sphere; struct { center: Point3; radius: Float64 }.
// type Capsule - capsule; struct { a: Point3; b: Point3; radius: Float64 }.
// type Cylinder - cylinder; struct { axis: Segment3; radius: Float64 }.
// type Cone - cone; struct { apex: Point3; axis: Vec3; half_angle: Float64 }.
// type Box - axis-aligned box; struct { min: Point3; max: Point3 }.
// type OBB - oriented box; struct { center: Point3; axes: Vec[Vec3]; half_extents: Vec[Float64] }.
// type Triangle3 - triangle; struct { a: Point3; b: Point3; c: Point3 }.
// type Polygon3 - polygon; struct { vertices: Vec[Point3] }.
// type Mesh - triangle mesh; struct { vertices: Vec[Point3]; indices: Vec[Int] }.
// fn point_distance(a: Point3, b: Point3) -> Float64 - Euclidean distance between two points. TODO(compiler): implement.
// fn point_sphere_distance(p: Point3, s: Sphere) -> Float64 - distance from p to the sphere surface. TODO(compiler): implement.
// fn point_plane_distance(p: Point3, pl: Plane) -> Float64 - signed distance from p to plane. TODO(compiler): implement.
// fn plane_point_distance(pl: Plane, p: Point3) -> Float64 - alias of point_plane_distance. TODO(compiler): implement.
// fn line_point_distance(l: Line3, p: Point3) -> Float64 - shortest distance from p to line. TODO(compiler): implement.
// fn segment_point_distance(s: Segment3, p: Point3) -> Float64 - shortest distance from p to segment. TODO(compiler): implement.
// fn ray_plane_intersection(r: Ray3, pl: Plane) -> Option[Float64] - t along the ray; None if parallel. TODO(compiler): implement.
// fn ray_triangle_intersection(r: Ray3, t: Triangle3) -> Option[Float64] - t along the ray; None on miss. TODO(compiler): implement.
// fn ray_sphere_intersection(r: Ray3, s: Sphere) -> Option[Float64] - nearest positive t; None on miss. TODO(compiler): implement.
// fn ray_box_intersection(r: Ray3, b: Box) -> Option[Float64] - nearest positive t; None on miss. TODO(compiler): implement.
// fn plane_plane_intersection(p1: Plane, p2: Plane) -> Option[Line3] - line of intersection; None if parallel. TODO(compiler): implement.
// fn sphere_sphere_intersection(a: Sphere, b: Sphere) -> Bool - true if the spheres overlap. TODO(compiler): implement.
// fn aabb_intersection(a: Box, b: Box) -> Bool - true if the boxes overlap. TODO(compiler): implement.
// fn aabb_contains(b: Box, p: Point3) -> Bool - true if p is inside or on the box. TODO(compiler): implement.
// fn closest_point_on_segment(s: Segment3, p: Point3) -> Point3 - closest point on s to p. TODO(compiler): implement.
// fn closest_point_on_plane(pl: Plane, p: Point3) -> Point3 - orthogonal projection of p onto pl. TODO(compiler): implement.
// fn triangle_normal(t: Triangle3) -> Vec3 - unit normal of the triangle. TODO(compiler): implement.
// fn mesh_volume(m: Mesh) -> Float64 - signed volume of a closed mesh. TODO(compiler): implement.
// fn mesh_surface_area(m: Mesh) -> Float64 - total surface area of a mesh. TODO(compiler): implement.
// fn mesh_centroid(m: Mesh) -> Point3 - volume-weighted centroid of a mesh. TODO(compiler): implement.
// fn convex_hull_3d(points: &Vec[Point3]) -> Mesh - convex hull of a point cloud. TODO(compiler): implement.

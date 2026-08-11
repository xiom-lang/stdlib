// XIOM - Geom: Collision
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the intersection/containment domain; the
// canonical Aabb, Sphere, Ray types live in geom.xi.

module xiom.geom.collision

// Depends on: xiom.geom

// ============================================================================
// Collision primitives and queries split from geom.xi: bounding volumes, rays,
// point-in-shape tests, and segment intersection. TODO(compiler): implement.
// ============================================================================

// type Aabb - axis-aligned bounding box; struct { min: Vec[Float64]; max: Vec[Float64] }.
// fn aabb_new(min: &Vec[Float64], max: &Vec[Float64]) -> Aabb - construct from corners.
// fn aabb_contains(a: Aabb, p: &Vec[Float64]) -> Bool - true iff p lies inside a (inclusive).
// fn aabb_intersects(a: Aabb, b: Aabb) -> Bool - true iff the boxes overlap.
// type Sphere - sphere primitive; struct { center: Vec[Float64]; radius: Float64 }.
// fn sphere_new(center: &Vec[Float64], radius: Float64) -> Sphere - construct from center and radius.
// fn sphere_contains(s: Sphere, p: &Vec[Float64]) -> Bool - true iff p lies inside s (inclusive).
// fn sphere_intersects(a: Sphere, b: Sphere) -> Bool - true iff the spheres overlap or touch.
// type Ray - ray primitive; struct { origin: Vec[Float64]; dir: Vec[Float64] } with dir normalized.
// fn ray_new(origin: &Vec[Float64], dir: &Vec[Float64]) -> Ray - construct a ray.
// fn ray_sphere_intersect(r: Ray, s: Sphere) -> Option[Float64] - nearest positive hit distance t; None on miss.
// fn ray_aabb_intersect(r: Ray, a: Aabb) -> Option[Float64] - slab-method hit distance t; None on miss.
// fn ray_plane_intersect(r: Ray, plane: &Vec[Float64]) -> Option[Float64] - hit distance t against plane (n, d); None when parallel.
// fn point_in_triangle(p: &Vec[Float64], a: &Vec[Float64], b: &Vec[Float64], c: &Vec[Float64]) -> Bool - true iff p is inside triangle (a, b, c).
// fn segment_intersect(p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], p4: &Vec[Float64]) -> Option[Vec[Float64]] - intersection point of segments p1p2 and p3p4; None if disjoint.

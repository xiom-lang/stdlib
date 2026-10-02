// p_geom_box_unnameable.xi -- KNOWN FAILURE (compiler v0.61.3, 2026-10-01)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// xiom.geom.geometry_3d declares `pub type Box = { min: Point3; max: Point3; }`
// but the leaf name is shadowed by xiom.core's private `Box[T]`, so consumer
// code cannot name the geometry_3d type at all: `Box{...}` resolves to the
// core type (T001 "type 'Box' has no field 'min'"), and neither qualified
// `geometry_3d.Box{...}` (T001 "unknown type") nor `use ...Box as GBox;`
// (T001 "unknown type 'GBox'") works. There is no box_new constructor, so
// aabb_intersection / aabb_contains / ray_box_intersection are uncallable
// from any other module. Expected: the program compiles and returns 0.
// Observed on v0.61.3: compile fails with the errors above.
// Found while landing the wave-52 geom clauses (2026-10-01); the wave-52
// probe therefore keeps the three Box functions clause-only (compile-checked,
// not runtime-exercised) until the geom dedup/rename (queue section C) lands.
//
// Stdlib impact: consumers needing AABB/ray-box queries must use
// xiom.geom.collision (CollisionAabb) or add a constructor to geometry_3d.

module p_geom_box_unnameable

use xiom.geom.geometry_3d;
use xiom.geom.geometry_3d.Point3;

fn p3(x: Float64, y: Float64, z: Float64) -> Point3 {
  return Point3{ x: x; y: y; z: z; };
}

fn main() -> Int {
  var b = geometry_3d.Box{ min: p3(0.0, 0.0, 0.0); max: p3(1.0, 1.0, 1.0); };
  if !geometry_3d.aabb_contains(b, p3(0.5, 0.5, 0.5)) { return 1; }
  var b2 = geometry_3d.Box{ min: p3(0.5, 0.5, 0.5); max: p3(2.0, 2.0, 2.0); };
  if !geometry_3d.aabb_intersection(b, b2) { return 2; }
  return 0;
}

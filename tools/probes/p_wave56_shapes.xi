// p_wave56_shapes.xi -- wave 56 shape validation: xiom.geom aggregate batch 3
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-56 clauses on the xiom.geom aggregate: Mat4 tail (17),
// Aabb (14), Sphere (8), Ray (8) and Plane (4). Option results are checked
// through is_some only (struct/scalar payloads); struct literals stay in
// declaration order. Returns 0 when every case holds.

module p_wave56_shapes

use xiom.geom;
use xiom.geom.Vec3;
use xiom.geom.Quaternion;
use xiom.geom.Mat4;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000001;
}

fn main() -> Int {
  // ---- Mat4 tail
  var mi = geom.mat4_identity();
  var tr = geom.mat4_translate(1.0, 2.0, 3.0);
  var trt = geom.mat4_transpose(tr);
  if !(trt.m03 == 0.0 && trt.m30 == 1.0 && trt.m31 == 2.0 && trt.m32 == 3.0 && trt.m33 == 1.0) { return 1; }
  if geom.mat4_determinant(mi) != 1.0 { return 2; }
  if geom.mat4_determinant(geom.mat4_scale(2.0, 3.0, 4.0)) != 24.0 { return 3; }
  if !geom.mat4_inverse(mi).is_some { return 4; }
  if geom.mat4_inverse(Mat4{ m00: 0.0; m01: 0.0; m02: 0.0; m03: 0.0; m10: 0.0; m11: 0.0; m12: 0.0; m13: 0.0; m20: 0.0; m21: 0.0; m22: 0.0; m23: 0.0; m30: 0.0; m31: 0.0; m32: 0.0; m33: 0.0; }).is_some { return 5; }
  var tv4 = geom.mat4_transform_vec4(mi, geom.vec4_new(1.0, 2.0, 3.0, 4.0));
  if !(near(tv4.x, 1.0) && near(tv4.w, 4.0)) { return 6; }
  var tp = geom.mat4_transform_point(tr, geom.vec3_new(10.0, 20.0, 30.0));
  if !(near(tp.x, 11.0) && near(tp.y, 22.0) && near(tp.z, 33.0)) { return 7; }
  var td = geom.mat4_transform_direction(tr, geom.vec3_new(10.0, 20.0, 30.0));
  if !(near(td.x, 10.0) && near(td.y, 20.0) && near(td.z, 30.0)) { return 8; }
  var fs = geom.mat4_from_scale(2.0, 3.0, 4.0);
  if !(fs.m00 == 2.0 && fs.m11 == 3.0 && fs.m22 == 4.0) { return 9; }
  var ft = geom.mat4_from_translation(geom.vec3_new(1.0, 2.0, 3.0));
  if !(ft.m13 == 2.0 && ft.m23 == 3.0) { return 10; }
  var tx = geom.mat4_translation_xyz(4.0, 5.0, 6.0);
  if !(tx.m03 == 4.0 && tx.m13 == 5.0 && tx.m23 == 6.0) { return 11; }
  var frx = geom.mat4_from_rotation_x(math.PI / 2.0);
  if !(near(frx.m12, -1.0) && near(frx.m21, 1.0) && frx.m33 == 1.0) { return 12; }
  var fry = geom.mat4_from_rotation_y(math.PI / 2.0);
  if !(near(fry.m02, 1.0) && near(fry.m20, -1.0)) { return 13; }
  var frz = geom.mat4_from_rotation_z(math.PI / 2.0);
  if !(near(frz.m01, -1.0) && near(frz.m10, 1.0)) { return 14; }
  var qh = geom.quat_from_axis_angle(geom.vec3_new(0.0, 0.0, 1.0), math.PI / 2.0);
  var fq = geom.mat4_from_quat(qh);
  if !(near(fq.m01, -1.0) && near(fq.m10, 1.0) && fq.m33 == 1.0 && fq.m03 == 0.0) { return 15; }
  var raa = geom.mat4_rotation_axis_angle(geom.vec3_new(0.0, 0.0, 3.0), math.PI / 2.0);
  if !(near(raa.m01, -1.0) && near(raa.m10, 1.0) && raa.m30 == 0.0) { return 16; }
  var orth = geom.mat4_orthographic(-1.0, 1.0, -1.0, 1.0, 1.0, 100.0);
  if !(near(orth.m00, 1.0) && near(orth.m11, 1.0) && near(orth.m22, -0.02020202) && orth.m03 == 0.0 && orth.m33 == 1.0) { return 17; }
  if !geom.mat4_is_identity(mi, 0.0) { return 18; }
  if geom.mat4_is_identity(tr, 1e-9) { return 19; }
  if !geom.mat4_approx_eq(mi, mi, 1e-9) { return 20; }
  if geom.mat4_approx_eq(mi, geom.mat4_scale(2.0, 2.0, 2.0), 1e-9) { return 21; }

  // ---- Aabb
  var box = geom.aabb_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(2.0, 2.0, 2.0));
  if !(box.min.x == 0.0 && box.max.z == 2.0) { return 22; }
  if !geom.aabb_contains_point(box, geom.vec3_new(0.5, 1.0, 1.5)) { return 23; }
  if geom.aabb_contains_point(box, geom.vec3_new(3.0, 1.0, 1.0)) { return 24; }
  if !geom.aabb_intersects_aabb(box, geom.aabb_new(geom.vec3_new(1.0, 1.0, 1.0), geom.vec3_new(3.0, 3.0, 3.0))) { return 25; }
  if geom.aabb_intersects_aabb(box, geom.aabb_new(geom.vec3_new(5.0, 5.0, 5.0), geom.vec3_new(6.0, 6.0, 6.0))) { return 26; }
  var b2 = geom.aabb_from_min_max(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(1.0, 2.0, 3.0));
  if !(b2.max.y == 2.0 && b2.max.z == 3.0) { return 27; }
  var bc = geom.aabb_center(b2);
  if !(near(bc.x, 0.5) && near(bc.y, 1.0) && near(bc.z, 1.5)) { return 28; }
  var bs = geom.aabb_size(b2);
  if !(near(bs.x, 1.0) && near(bs.y, 2.0) && near(bs.z, 3.0)) { return 29; }
  var bh = geom.aabb_half_extents(b2);
  if !(near(bh.x, 0.5) && near(bh.y, 1.0) && near(bh.z, 1.5)) { return 30; }
  if !geom.aabb_intersects_sphere(box, geom.sphere_new(geom.vec3_new(3.0, 1.0, 1.0), 1.1)) { return 31; }
  if geom.aabb_intersects_sphere(box, geom.sphere_new(geom.vec3_new(3.0, 1.0, 1.0), 0.5)) { return 32; }
  var bcp = geom.aabb_closest_point(box, geom.vec3_new(3.0, 1.0, 1.0));
  if !(near(bcp.x, 2.0) && near(bcp.y, 1.0) && near(bcp.z, 1.0)) { return 33; }
  if !near(geom.aabb_surface_area(b2), 22.0) { return 34; }
  if !near(geom.aabb_volume(b2), 6.0) { return 35; }
  var bex = geom.aabb_expand(box, geom.vec3_new(3.0, 1.0, 1.0));
  if !(near(bex.max.x, 3.0) && near(bex.min.x, 0.0)) { return 36; }
  var bu = geom.aabb_union(box, geom.aabb_new(geom.vec3_new(4.0, 0.0, 0.0), geom.vec3_new(5.0, 1.0, 1.0)));
  if !(near(bu.min.x, 0.0) && near(bu.max.x, 5.0) && near(bu.max.y, 2.0)) { return 37; }
  if !geom.aabb_intersection(box, geom.aabb_new(geom.vec3_new(1.0, 1.0, 1.0), geom.vec3_new(3.0, 3.0, 3.0))).is_some { return 38; }
  if geom.aabb_intersection(box, geom.aabb_new(geom.vec3_new(5.0, 5.0, 5.0), geom.vec3_new(6.0, 6.0, 6.0))).is_some { return 39; }

  // ---- Sphere
  var sph = geom.sphere_new(geom.vec3_new(0.0, 0.0, 0.0), 2.0);
  if !(sph.center.z == 0.0 && sph.radius == 2.0) { return 40; }
  if !geom.sphere_contains_point(sph, geom.vec3_new(1.0, 1.0, 1.0)) { return 41; }
  if geom.sphere_contains_point(sph, geom.vec3_new(3.0, 0.0, 0.0)) { return 42; }
  if !geom.sphere_intersects_sphere(sph, geom.sphere_new(geom.vec3_new(4.0, 0.0, 0.0), 2.0)) { return 43; }
  if geom.sphere_intersects_sphere(sph, geom.sphere_new(geom.vec3_new(4.0, 0.0, 0.0), 1.0)) { return 44; }
  if !geom.sphere_intersects_aabb(geom.sphere_new(geom.vec3_new(3.0, 1.0, 1.0), 1.1), box) { return 45; }
  var scp = geom.sphere_closest_point(sph, geom.vec3_new(3.0, 0.0, 0.0));
  if !(near(scp.x, 2.0) && near(scp.y, 0.0) && near(scp.z, 0.0)) { return 46; }
  var scc = geom.sphere_closest_point(sph, geom.vec3_new(0.0, 0.0, 0.0));
  if !(scc.x == 0.0 && scc.y == 0.0 && scc.z == 0.0) { return 47; }
  if !near(geom.sphere_surface_area(geom.sphere_new(geom.vec3_new(0.0, 0.0, 0.0), 1.0)), 4.0 * math.PI) { return 48; }
  if !near(geom.sphere_volume(geom.sphere_new(geom.vec3_new(0.0, 0.0, 0.0), 1.0)), 4.0 / 3.0 * math.PI) { return 49; }
  var sex = geom.sphere_expand(sph, geom.vec3_new(3.0, 0.0, 0.0));
  if !(near(sex.radius, 3.0) && sex.center.x == 0.0) { return 50; }
  var sex2 = geom.sphere_expand(sph, geom.vec3_new(1.0, 0.0, 0.0));
  if !near(sex2.radius, 2.0) { return 51; }

  // ---- Ray
  var ray = geom.ray_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(1.0, 0.0, 0.0));
  if !(ray.origin.x == 0.0 && ray.dir.x == 1.0) { return 52; }
  if !geom.ray_intersect_sphere(ray, geom.sphere_new(geom.vec3_new(5.0, 0.0, 0.0), 1.0)).is_some { return 53; }
  if geom.ray_intersect_sphere(ray, geom.sphere_new(geom.vec3_new(0.0, 5.0, 0.0), 1.0)).is_some { return 54; }
  if !geom.ray_intersect_aabb(ray, geom.aabb_new(geom.vec3_new(2.0, -1.0, -1.0), geom.vec3_new(4.0, 1.0, 1.0))).is_some { return 55; }
  if geom.ray_intersect_aabb(ray, geom.aabb_new(geom.vec3_new(-4.0, -1.0, -1.0), geom.vec3_new(-2.0, 1.0, 1.0))).is_some { return 56; }
  var rat = geom.ray_at(geom.ray_new(geom.vec3_new(1.0, 2.0, 3.0), geom.vec3_new(1.0, 0.0, 0.0)), 2.0);
  if !(near(rat.x, 3.0) && near(rat.y, 2.0) && near(rat.z, 3.0)) { return 57; }
  var ror = geom.ray_origin(ray);
  if !(ror.x == 0.0 && ror.y == 0.0 && ror.z == 0.0) { return 58; }
  var rdr = geom.ray_dir(ray);
  if !(rdr.x == 1.0 && rdr.y == 0.0 && rdr.z == 0.0) { return 59; }
  if !geom.ray_intersect_plane(ray, geom.vec3_new(5.0, 0.0, 0.0), geom.vec3_new(1.0, 0.0, 0.0)).is_some { return 60; }
  if geom.ray_intersect_plane(geom.ray_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0)), geom.vec3_new(5.0, 0.0, 0.0), geom.vec3_new(1.0, 0.0, 0.0)).is_some { return 61; }
  if geom.ray_intersect_plane(ray, geom.vec3_new(-5.0, 0.0, 0.0), geom.vec3_new(1.0, 0.0, 0.0)).is_some { return 62; }
  if !near(geom.ray_distance_to_point(ray, geom.vec3_new(1.0, 2.0, 0.0)), 2.0) { return 63; }
  var rz = geom.ray_distance_to_point(geom.ray_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(0.0, 0.0, 0.0)), geom.vec3_new(3.0, 4.0, 0.0));
  if !near(rz, 5.0) { return 64; }

  // ---- Plane
  var pl = geom.plane_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0));
  if !(pl.point.y == 0.0 && pl.normal.y == 1.0) { return 65; }
  if !near(geom.plane_signed_distance(&pl, geom.vec3_new(0.0, 3.0, 0.0)), 3.0) { return 66; }
  if !near(geom.plane_signed_distance(&pl, geom.vec3_new(0.0, -2.0, 0.0)), -2.0) { return 67; }
  if !near(geom.plane_distance_to_point(&pl, geom.vec3_new(0.0, -2.0, 0.0)), 2.0) { return 68; }
  if !geom.plane_intersect_ray(&pl, geom.ray_new(geom.vec3_new(0.0, 3.0, 0.0), geom.vec3_new(0.0, -1.0, 0.0))).is_some { return 69; }
  if geom.plane_intersect_ray(&pl, geom.ray_new(geom.vec3_new(0.0, 3.0, 0.0), geom.vec3_new(1.0, 0.0, 0.0))).is_some { return 70; }

  // ---- NaN-tolerance paths (mirror-only bodies)
  var big = 1.0e308;
  var inf = big + big;
  var nan = inf - inf;
  if !(nan != nan) { return 71; }
  var nb = geom.aabb_new(geom.vec3_new(nan, 0.0, 0.0), geom.vec3_new(1.0, 1.0, 1.0));
  var nbc = geom.aabb_center(nb);
  if !(nbc.x != nbc.x) { return 72; }
  var nsp = geom.sphere_new(geom.vec3_new(0.0, 0.0, 0.0), nan);
  if !(nsp.radius != nsp.radius) { return 73; }
  var nr = geom.ray_new(geom.vec3_new(0.0, 0.0, 0.0), geom.vec3_new(nan, 0.0, 0.0));
  if !(nr.dir.x != nr.dir.x) { return 74; }
  var nt = geom.mat4_translate(nan, 2.0, 3.0);
  var ntt = geom.mat4_transpose(nt);
  if !(ntt.m30 != ntt.m30 && ntt.m31 == 2.0) { return 75; }
  var ncp = geom.aabb_closest_point(b2, geom.vec3_new(nan, 0.0, 0.0));
  if !(ncp.x != ncp.x) { return 76; }
  var np = geom.plane_new(geom.vec3_new(nan, 0.0, 0.0), geom.vec3_new(0.0, 1.0, 0.0));
  if !(np.point.x != np.point.x) { return 77; }

  return 0;
}

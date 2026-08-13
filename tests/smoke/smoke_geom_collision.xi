// Smoke: xiom.geom.collision + xiom.geom.curves + xiom.geom.polyhedra.
// Returns 0 on success; prints the failing tag on failure. Checks are split
// across small helper functions to avoid whole-function compiler miscompiles.
use xiom.geom.collision;
use xiom.geom.curves;
use xiom.geom.polyhedra;
use xiom.io;
use xiom.convert;
use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn v3(x: Float64, y: Float64, z: Float64) -> Vec[Float64] {
  var v = Vec[Float64].new();
  v.push(x); v.push(y); v.push(z);
  return v;
}

fn chk_tri_seg() -> Int {
  var p = v3(0.2, 0.2, 0.0);
  var ta = v3(1.0, 0.0, 0.0);
  var tb = v3(0.0, 1.0, 0.0);
  var tc = v3(0.0, 0.0, 0.0);
  if !collision.point_in_triangle(&p, &ta, &tb, &tc) { io.println("t1"); return 1; }
  var pout = v3(2.0, 2.0, 0.0);
  if collision.point_in_triangle(&pout, &ta, &tb, &tc) { io.println("t2"); return 2; }
  var p1 = v3(0.0, 0.0, 0.0);
  var p2 = v3(2.0, 2.0, 0.0);
  var p3 = v3(0.0, 2.0, 0.0);
  var p4 = v3(2.0, 0.0, 0.0);
  var si = collision.segment_intersect(&p1, &p2, &p3, &p4);
  if !si.is_some() { io.println("t3"); return 3; }
  var p5 = v3(5.0, 5.0, 0.0);
  var p6 = v3(6.0, 6.0, 0.0);
  var si2 = collision.segment_intersect(&p1, &p2, &p5, &p6);
  if si2.is_some() { io.println("t4"); return 4; }
  return 0;
}

fn chk_curves() -> Int {
  var p0 = v3(0.0, 0.0, 0.0);
  var p1 = v3(1.0, 0.0, 0.0);
  var p2 = v3(0.0, 1.0, 0.0);
  var p3 = v3(0.0, 0.0, 1.0);
  var q0 = curves.bezier_quad(&p0, &p1, &p2, 0.0);
  var q0x: Float64 = q0[0];
  var q0y: Float64 = q0[1];
  if !near(q0x, 0.0) || !near(q0y, 0.0) { io.println("c1"); return 1; }
  var q1 = curves.bezier_quad(&p0, &p1, &p2, 1.0);
  var q1x: Float64 = q1[0];
  var q1y: Float64 = q1[1];
  if !near(q1x, 0.0) || !near(q1y, 1.0) { io.println("c2"); return 2; }
  var cu0 = curves.bezier_cubic(&p0, &p1, &p2, &p3, 0.0);
  var cu0x: Float64 = cu0[0];
  if !near(cu0x, 0.0) { io.println("c3"); return 3; }
  var cu1 = curves.bezier_cubic(&p0, &p1, &p2, &p3, 1.0);
  var cu1z: Float64 = cu1[2];
  if !near(cu1z, 1.0) { io.println("c4"); return 4; }
  var ctrl = Vec[Vec[Float64]].new();
  ctrl.push(p0);
  ctrl.push(p1);
  ctrl.push(p2);
  var bd0 = curves.bezier_derivative(&ctrl, 0.0);
  var bd0x: Float64 = bd0[0];
  var bd0y: Float64 = bd0[1];
  if !near(bd0x, 2.0) || !near(bd0y, 0.0) { io.println("c5"); return 5; }
  var cm0 = curves.catmull_rom(&p0, &p1, &p2, &p3, 0.0);
  var cm0x: Float64 = cm0[0];
  var cm0y: Float64 = cm0[1];
  if !near(cm0x, 1.0) || !near(cm0y, 0.0) { io.println("c6"); return 6; }
  var cm1 = curves.catmull_rom(&p0, &p1, &p2, &p3, 1.0);
  var cm1x: Float64 = cm1[0];
  var cm1y: Float64 = cm1[1];
  if !near(cm1x, 0.0) || !near(cm1y, 1.0) { io.println("c7"); return 7; }
  var t0 = v3(1.0, 0.0, 0.0);
  var t1 = v3(0.0, 1.0, 0.0);
  var h0 = curves.hermite_curve(&p0, &t0, &p1, &t1, 0.0);
  var h0x: Float64 = h0[0];
  if !near(h0x, 0.0) { io.println("c9"); return 9; }
  var h1 = curves.hermite_curve(&p0, &t0, &p1, &t1, 1.0);
  var h1x: Float64 = h1[0];
  if !near(h1x, 1.0) { io.println("c10"); return 10; }
  return 0;
}

fn chk_poly() -> Int {
  var cv = polyhedra.cube_vertices(2.0);
  if cv.len() != 8 { io.println("p1"); return 1; }
  var cf = polyhedra.cube_faces();
  if cf.len() != 12 { io.println("p2"); return 2; }
  var sv = polyhedra.sphere_vertices(1.0, 8, 4);
  if sv.len() != 45 { io.println("p3"); return 3; }
  var iv = polyhedra.icosahedron_vertices();
  if iv.len() != 12 { io.println("p4"); return 4; }
  var icf = polyhedra.icosahedron_faces();
  if icf.len() != 20 { io.println("p5"); return 5; }
  if polyhedra.tetrahedron_vertices().len() != 4 { io.println("p6"); return 6; }
  if polyhedra.octahedron_vertices().len() != 6 { io.println("p7"); return 7; }
  if polyhedra.dodecahedron_vertices().len() != 20 { io.println("p8"); return 8; }
  return 0;
}


fn main() -> Int {
  var r = chk_tri_seg();
  if r != 0 { return r; }
  r = chk_curves();
  if r != 0 { return r + 40; }
  r = chk_poly();
  if r != 0 { return r + 80; }

  io.println("OK");
  return 0;
}

module smoke_geom
use xiom.geom;
fn main() -> Int {
  var a = xiom.geom.vec3_new(1.0, 2.0, 3.0);
  var b = xiom.geom.vec3_new(4.0, 5.0, 6.0);
  var c = xiom.geom.vec3_add(a, b);
  if !(c.x == 5.0 && c.y == 7.0 && c.z == 9.0) { return 1; }
  if xiom.geom.vec3_dot(a, b) != 32.0 { return 1; }
  var cr = xiom.geom.vec3_cross(a, b);
  if !(cr.x == -3.0 && cr.y == 6.0 && cr.z == -3.0) { return 1; }
  var m = xiom.geom.mat4_identity();
  if m.m00 != 1.0 || m.m11 != 1.0 { return 1; }
  return 0;
}

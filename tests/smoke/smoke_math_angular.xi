// Smoke: xiom.math.angular (angle unit conversion + angle arithmetic).
// Returns 0 on success.
use xiom.math;
use xiom.io;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 1e-9;
}

fn main() -> Int {
  var pi = math.constants.PI;

  // deg <-> rad
  if !near(math.angular.to_radians(180.0), pi) { io.println("deg2rad"); return 1; }
  if !near(math.angular.to_degrees(pi), 180.0) { io.println("rad2deg"); return 2; }
  if !near(math.angular.to_radians(90.0), pi / 2.0) { io.println("deg2rad-90"); return 3; }
  var roundtrip = math.angular.to_radians(math.angular.to_degrees(1.0));
  if !near(roundtrip, 1.0) { io.println("rad-roundtrip"); return 4; }

  // gradians
  if !near(math.angular.to_gradians(90.0), 100.0) { io.println("deg2grad"); return 5; }
  if !near(math.angular.from_gradians(100.0), 90.0) { io.println("grad2deg"); return 6; }
  if !near(math.angular.to_gradians(360.0), 400.0) { io.println("full-grad"); return 7; }

  // mils (6400 per circle)
  if !near(math.angular.to_mils(360.0), 6400.0) { io.println("deg2mil"); return 8; }
  if !near(math.angular.from_mils(6400.0), 360.0) { io.println("mil2deg"); return 9; }
  if !near(math.angular.to_mils(1.0), 17.77777777777778) { io.println("mil-1deg"); return 10; }

  // arcmin / arcsec
  if !near(math.angular.to_arcmin(1.0), 60.0) { io.println("deg2arcmin"); return 11; }
  if !near(math.angular.from_arcmin(60.0), 1.0) { io.println("arcmin2deg"); return 12; }
  if !near(math.angular.to_arcsec(1.0), 3600.0) { io.println("deg2arcsec"); return 13; }
  if !near(math.angular.from_arcsec(3600.0), 1.0) { io.println("arcsec2deg"); return 14; }

  // normalize_angle into (-pi, pi]
  if !near(math.angular.normalize_angle(0.0), 0.0) { io.println("norm-0"); return 15; }
  if !near(math.angular.normalize_angle(3.0 * pi), pi) { io.println("norm-3pi"); return 16; }
  if !near(math.angular.normalize_angle(-pi), pi) { io.println("norm--pi"); return 17; }
  if !near(math.angular.normalize_angle(2.0 * pi), 0.0) { io.println("norm-2pi"); return 18; }
  if !near(math.angular.normalize_angle(-2.5 * pi), -0.5 * pi) { io.println("norm--2.5pi"); return 19; }
  if !near(math.angular.normalize_angle(10.0), math.angular.normalize_angle(10.0 + 2.0 * pi)) { io.println("norm-period"); return 20; }

  // normalize_angle_deg into (-180, 180]
  if !near(math.angular.normalize_angle_deg(0.0), 0.0) { io.println("normd-0"); return 21; }
  if !near(math.angular.normalize_angle_deg(540.0), 180.0) { io.println("normd-540"); return 22; }
  if !near(math.angular.normalize_angle_deg(-180.0), 180.0) { io.println("normd--180"); return 23; }
  if !near(math.angular.normalize_angle_deg(360.0), 0.0) { io.println("normd-360"); return 24; }

  // angle_diff
  if !near(math.angular.angle_diff(pi / 2.0, 0.0), pi / 2.0) { io.println("diff-1"); return 25; }
  if !near(math.angular.angle_diff(0.0, pi / 2.0), -pi / 2.0) { io.println("diff-2"); return 26; }
  if !near(math.angular.angle_diff(3.0 * pi, 0.0), pi) { io.println("diff-wrap"); return 27; }

  // angle_lerp
  if !near(math.angular.angle_lerp(0.0, pi, 0.5), pi / 2.0) { io.println("lerp-1"); return 28; }
  if !near(math.angular.angle_lerp(0.0, pi, 0.0), 0.0) { io.println("lerp-0"); return 29; }
  if !near(math.angular.angle_lerp(0.0, pi, 1.0), pi) { io.println("lerp-1"); return 30; }
  // shortest path through the wrap: from near -pi to near +pi, the short way
  // crosses the wrap and the midpoint is -pi (== +pi).
  var lp = math.angular.angle_lerp(-pi + 0.1, pi - 0.1, 0.5);
  if !(near(lp, -pi) || near(lp, pi)) { io.println("lerp-wrap"); return 31; }
  var lp2 = math.angular.angle_lerp(pi - 0.1, -pi + 0.1, 0.5);
  if !(near(lp2, -pi) || near(lp2, pi)) { io.println("lerp-wrap2"); return 32; }

  io.println("smoke_math_angular: OK");
  return 0;
}

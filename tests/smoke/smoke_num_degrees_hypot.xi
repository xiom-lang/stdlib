module smoke_num_degrees_hypot
use xiom.num;

fn main() -> Int {
  var deg = num.to_degrees(3.141592653589793);
  if deg < 179.99 || deg > 180.01 { return 1; }

  var rad = num.to_radians(180.0);
  if rad < 3.14 || rad > 3.15 { return 2; }

  var rad2 = num.to_radians(0.0);
  if rad2 != 0.0 { return 3; }

  var h = num.hypot(3.0, 4.0);
  if h < 4.99 || h > 5.01 { return 4; }

  var h2 = num.hypot(0.0, 5.0);
  if h2 < 4.99 || h2 > 5.01 { return 5; }

  var h3 = num.hypot(0.0, 0.0);
  if h3 != 0.0 { return 6; }

  return 0;
}

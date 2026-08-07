module smoke_ecc
use xiom.ecc;
fn main() -> Int {
  var curve = xiom.ecc.curve_small_test();
  var gpt = EcPoint{ x: curve.gx; y: curve.gy; };
  var g = EcPointOpt{ is_some: true; pt: gpt; };
  var g2 = xiom.ecc.ec_add(g, g, &curve);
  var gd = xiom.ecc.ec_double(&gpt, &curve);
  if !(g2.is_some && gd.is_some && g2.pt.x == gd.pt.x && g2.pt.y == gd.pt.y) { return 1; }
  if !xiom.ecc.ec_is_on_curve(&gpt, &curve) { return 1; }
  return 0;
}

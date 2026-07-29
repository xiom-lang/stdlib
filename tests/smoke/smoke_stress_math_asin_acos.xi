module smoke_stress_math_asin_acos
use xiom.math;

fn main() -> Int {
    var asin0 = math.asin(0.0);
    if asin0 != 0.0 { return 1; }
    var asin1 = math.asin(1.0);
    if asin1 < 1.55 || asin1 > 1.59 { return 2; }
    var asin_neg1 = math.asin(-1.0);
    if asin_neg1 > -1.55 || asin_neg1 < -1.59 { return 3; }
    var acos1 = math.acos(1.0);
    if acos1 != 0.0 { return 4; }
    var acos0 = math.acos(0.0);
    if acos0 < 1.55 || acos0 > 1.59 { return 5; }
    var acos_neg1 = math.acos(-1.0);
    if acos_neg1 < 3.12 || acos_neg1 > 3.16 { return 6; }
    return 0;
}

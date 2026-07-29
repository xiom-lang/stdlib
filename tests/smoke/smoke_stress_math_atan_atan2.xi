module smoke_stress_math_atan_atan2
use xiom.math;

fn main() -> Int {
    var atan0 = math.atan(0.0);
    if atan0 != 0.0 { return 1; }
    var atan1 = math.atan(1.0);
    if atan1 < 0.78 || atan1 > 0.79 { return 2; }
    var atan_inf = math.atan(1000000.0);
    if atan_inf < 1.55 || atan_inf > 1.58 { return 3; }
    var atan2_x = math.atan2(1.0, 0.0);
    if atan2_x < 1.55 || atan2_x > 1.58 { return 4; }
    var atan2_y = math.atan2(0.0, 1.0);
    if atan2_y != 0.0 { return 5; }
    var atan2_neg = math.atan2(-1.0, -1.0);
    if atan2_neg > -2.34 || atan2_neg < -2.38 { return 6; }
    var atan2_pos = math.atan2(1.0, 1.0);
    if atan2_pos < 0.78 || atan2_pos > 0.79 { return 7; }
    return 0;
}

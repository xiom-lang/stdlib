module smoke_stress_math_pure_fallbacks
use xiom.math;

fn main() -> Int {
    var x = math.sqrt_pure(4.0);
    if x != 2.0 { return 1; }
    var y = math.sqrt_pure(0.0);
    if y != 0.0 { return 2; }
    var s0 = math.sin_pure(0.0);
    if s0 != 0.0 { return 3; }
    var c0 = math.cos_pure(0.0);
    if c0 != 1.0 { return 4; }
    var s_pi2 = math.sin_pure(1.5707963267948966);
    if s_pi2 < 0.99 || s_pi2 > 1.01 { return 5; }
    var c_pi2 = math.cos_pure(1.5707963267948966);
    if c_pi2 < -0.01 || c_pi2 > 0.01 { return 6; }
    var sqrt9 = math.sqrt_pure(9.0);
    if sqrt9 != 3.0 { return 7; }
    return 0;
}

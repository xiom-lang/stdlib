module smoke_stress_math_floor_ceil_neg
use xiom.math;

fn main() -> Int {
    if math.floor(-1.1) != -2.0 { return 1; }
    if math.floor(-1.9) != -2.0 { return 2; }
    if math.floor(-0.1) != -1.0 { return 3; }
    if math.floor(-5.0) != -5.0 { return 4; }
    if math.floor(-100.001) != -101.0 { return 5; }
    if math.ceil(-1.1) != -1.0 { return 6; }
    if math.ceil(-1.9) != -1.0 { return 7; }
    if math.ceil(-0.1) != 0.0 { return 8; }
    if math.ceil(-5.0) != -5.0 { return 9; }
    if math.ceil(-100.001) != -100.0 { return 10; }
    return 0;
}

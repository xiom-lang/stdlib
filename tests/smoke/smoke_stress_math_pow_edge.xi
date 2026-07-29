module smoke_stress_math_pow_edge
use xiom.math;

fn main() -> Int {
    if math.pow(0.0, 0.0) != 1.0 { return 1; }
    if math.pow(0.0, 1.0) != 0.0 { return 2; }
    if math.pow(1.0, 0.0) != 1.0 { return 3; }
    if math.pow(1.0, 100.0) != 1.0 { return 4; }
    if math.pow(2.0, 0.0) != 1.0 { return 5; }
    if math.pow(2.0, 1.0) != 2.0 { return 6; }
    if math.pow(-1.0, 2.0) != 1.0 { return 7; }
    if math.pow(-1.0, 3.0) != -1.0 { return 8; }
    if math.pow(2.0, -1.0) != 0.5 { return 9; }
    return 0;
}

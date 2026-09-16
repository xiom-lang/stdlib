module q1v_math
use xiom.math;
fn main() -> Int { var x = math.sin(1.0); if x < 0.5 { return 1; } return 0; }

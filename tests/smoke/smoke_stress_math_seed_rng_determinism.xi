module smoke_stress_math_seed_rng_determinism
use xiom.math;

fn main() -> Int {
    math.seed_rng(42);
    var r1 = math.random();
    math.seed_rng(42);
    var r2 = math.random();
    if r1 != r2 { return 1; }
    math.seed_rng(777);
    var s1 = math.random();
    var s2 = math.random();
    math.seed_rng(777);
    var s3 = math.random();
    if s1 != s3 { return 2; }
    if s1 != s2 { return 0; }
    return 3;
}

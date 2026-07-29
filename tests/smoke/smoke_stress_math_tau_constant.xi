module smoke_stress_math_tau_constant
use xiom.math;

fn main() -> Int {
    var tau = math.TAU;
    if tau < 6.2831 || tau > 6.2833 { return 1; }
    var pi = math.PI;
    var tau_div_2 = tau / 2.0;
    var diff = math.abs_pure(tau_div_2 - pi);
    if diff > 0.0001 { return 2; }
    var e = math.E;
    if e < 2.7182 || e > 2.7183 { return 3; }
    return 0;
}

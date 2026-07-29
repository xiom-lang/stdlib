module smoke_stress_convert_float_to_string_prec
use xiom.convert;

fn main() -> Int {
    var s1 = convert.float_to_string(3.14159, 2);
    if s1 != "3.14" { return 1; }
    var s2 = convert.float_to_string(3.14159, 5);
    if s2 != "3.14159" { return 2; }
    var s3 = convert.float_to_string(0.0, 0);
    if s3 != "0" { return 3; }
    var s4 = convert.float_to_string(1.0, 0);
    if s4 != "1" { return 4; }
    var s5 = convert.float_to_string(-2.5, 1);
    if s5 != "-2.5" { return 5; }
    var s6 = convert.float_to_string(0.0001, 4);
    if s6 != "0.0001" { return 6; }
    return 0;
}

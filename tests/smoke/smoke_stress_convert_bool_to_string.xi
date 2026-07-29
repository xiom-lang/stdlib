module smoke_stress_convert_bool_to_string
use xiom.convert;

fn main() -> Int {
    var t = convert.bool_to_string(true);
    if t != "true" { return 1; }
    var f = convert.bool_to_string(false);
    if f != "false" { return 2; }
    if t != "true" { return 3; }
    if f != "false" { return 4; }
    return 0;
}

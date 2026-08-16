module smoke_stress_convert_int_to_string_max
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_string(2147483647);
        if result == "2147483647" {
            return 0;
        } else {
            return 1;
        }
}

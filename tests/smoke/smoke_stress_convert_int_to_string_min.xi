module smoke_stress_convert_int_to_string_min
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_string(-2147483648);
        if result == "-2147483648" {
            return 0;
        } else {
            return 1;
        }
}

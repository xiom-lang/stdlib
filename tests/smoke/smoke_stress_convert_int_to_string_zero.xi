module smoke_stress_convert_int_to_string_zero
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_string(0);
        if result == "0" {
            return 0;
        } else {
            return 1;
        }
}

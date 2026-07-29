module smoke_stress_convert_int_to_string_large
use xiom.convert;

fn main() -> Int {
    var result = convert.int_to_string(1234567890);
    if result == "1234567890" {
        return 0;
    } else {
        return 1;
    }
}

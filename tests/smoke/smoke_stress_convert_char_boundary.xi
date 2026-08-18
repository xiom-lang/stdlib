module smoke_stress_convert_char_boundary
use xiom.convert;

fn main() -> Int {
    var a = convert.char_to_int('A');
    if a != 65 { return 1; }
    var z = convert.char_to_int('z');
    if z != 122 { return 2; }
    var zero = convert.char_to_int('0');
    if zero != 48 { return 3; }
    var space = convert.char_to_int(' ');
    if space != 32 { return 4; }
    // int_to_char returns Option[Char] (None for out-of-range codes)
    match convert.int_to_char(65) {
        Some(c) => { if c != 'A' { return 5; } }
        None => { return 10; }
    }
    match convert.int_to_char(57) {
        Some(c) => { if c != '9' { return 6; } }
        None => { return 11; }
    }
    match convert.int_to_char(10) {
        Some(c) => { if c != '\n' { return 7; } }
        None => { return 12; }
    }
    // out-of-range must be None
    match convert.int_to_char(-1) {
        Some(_) => { return 8; }
        None => {}
    }
    match convert.int_to_char(1114112) {
        Some(_) => { return 9; }
        None => {}
    }
    return 0;
}

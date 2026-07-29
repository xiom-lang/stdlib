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
    var char_a = convert.int_to_char(65);
    if char_a != 'A' { return 5; }
    var char_9 = convert.int_to_char(57);
    if char_9 != '9' { return 6; }
    var char_newline = convert.int_to_char(10);
    if char_newline != '\n' { return 7; }
    return 0;
}

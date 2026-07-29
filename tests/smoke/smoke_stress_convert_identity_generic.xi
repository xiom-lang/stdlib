module smoke_stress_convert_identity_generic
use xiom.convert;

fn main() -> Int {
    var i = convert.identity(42);
    if i != 42 { return 1; }
    var f = convert.identity(3.14);
    if f != 3.14 { return 2; }
    var s = convert.identity("hello");
    if s != "hello" { return 3; }
    var b = convert.identity(true);
    if b != true { return 4; }
    var n = convert.identity(-7);
    if n != -7 { return 5; }
    return 0;
}

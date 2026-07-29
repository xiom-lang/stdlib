module smoke_cross_string_fmt_convert
use xiom.string;
use xiom.fmt;
use xiom.convert;

fn main() -> Int {
  var s = string.str_to_int("42");
  match s {
    Ok(n) => {
      var formatted = fmt.format1("result: {}", n);
      if formatted != "result: 42" { return 1; }
    },
    Err(_) => { return 2; },
  };

  var f = string.str_to_float("3.14");
  match f {
    Ok(val) => {
      var s2 = convert.float_to_string(val);
      if s2 == "" { return 3; }
    },
    Err(_) => { return 4; },
  };

  return 0;
}

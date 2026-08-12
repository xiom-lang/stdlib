// XIOM stdlib smoke test - itos/ftos/tostring/toint/tofloat/parse/atoi
// Checks: string formatting and parsing helpers.

module smoke_convert_strings
use xiom.convert.itos;
use xiom.convert.ftos;
use xiom.convert.tostring;
use xiom.convert.toint;
use xiom.convert.tofloat;
use xiom.convert.parse;
use xiom.convert.atoi;
use xiom.io;
use xiom.string;

fn main() -> Int {
  if itos.itos(42) != "42" { io.println("itos"); return 1; }
  if itos.itos(-10) != "-10" { io.println("itos neg"); return 2; }
  if itos.itos_padded(42, 5) != "00042" { io.println(string.str_concat("itos_padded ", itos.itos_padded(42, 5))); return 3; }
  if itos.itos_padded(-42, 5) != "-0042" { io.println(string.str_concat("itos_padded neg ", itos.itos_padded(-42, 5))); return 4; }
  if itos.itos_signed(5) != "+5" { io.println(string.str_concat("itos_signed ", itos.itos_signed(5))); return 5; }
  if itos.itos_signed(-5) != "-5" { io.println("itos_signed neg"); return 6; }

  if ftos.ftos(1.5) != "1.5" { io.println(string.str_concat("ftos ", ftos.ftos(1.5))); return 7; }
  if ftos.ftos_prec(1.5, 3) != "1.500" { io.println(string.str_concat("ftos_prec ", ftos.ftos_prec(1.5, 3))); return 8; }
  if ftos.ftos_sci(1.5, 2) != "1.50e+00" { io.println(string.str_concat("ftos_sci ", ftos.ftos_sci(1.5, 2))); return 9; }
  if ftos.ftos(0.5) != "0.5" { io.println(string.str_concat("ftos half ", ftos.ftos(0.5))); return 10; }

  if tostring.to_string(42) != "42" { io.println("to_string"); return 11; }
  if tostring.to_string(-9223372036854775808) != "-9223372036854775808" { io.println(string.str_concat("to_string min ", tostring.to_string(-9223372036854775808))); return 12; }
  if tostring.to_string_float(1.5) != "1.5" { io.println("to_string_float"); return 13; }
  if tostring.to_string_bool(true) != "true" { io.println("to_string_bool"); return 14; }
  if tostring.to_string_bool(false) != "false" { io.println("to_string_bool f"); return 15; }
  if tostring.to_string_char('x') != "x" { io.println(string.str_concat("to_string_char ", tostring.to_string_char('x'))); return 16; }
  if tostring.to_string_radix(255, 16) != "ff" { io.println(string.str_concat("to_string_radix ", tostring.to_string_radix(255, 16))); return 17; }
  if tostring.to_string_radix(255, 1) != "" { io.println("to_string_radix bad base"); return 18; }

  if toint.to_int(3.9) != 3 { io.println("to_int"); return 19; }
  if toint.to_int(-3.9) != -3 { io.println("to_int neg"); return 20; }
  if toint.to_int_saturating(1.0e20) != 9223372036854775807 { io.println("to_int_sat"); return 21; }
  if toint.to_int_saturating(-1.0e20) != -9223372036854775808 { io.println("to_int_sat neg"); return 22; }
  var ic = toint.to_int_checked(3.9);
  match ic {
    Some(v) => { if v != 3 { io.println("to_int_checked"); return 23; } },
    None => { io.println("to_int_checked none"); return 24; },
  }
  var ic2 = toint.to_int_checked(1.0e20);
  match ic2 {
    Some(_) => { io.println("to_int_checked big"); return 25; },
    None => {},
  }
  if toint.to_int_from_char('A') != 65 { io.println("to_int_from_char"); return 26; }

  if tofloat.to_float(5) != 5.0 { io.println("to_float"); return 27; }
  if tofloat.to_float_saturating("1.5") != 1.5 { io.println("to_float_sat"); return 28; }
  if tofloat.to_float_saturating("x") != 0.0 { io.println("to_float_sat bad"); return 29; }
  var fc = tofloat.to_float_checked("1.5");
  match fc {
    Some(v) => { if v != 1.5 { io.println("to_float_checked"); return 30; } },
    None => { io.println("to_float_checked none"); return 31; },
  }
  var fc2 = tofloat.to_float_checked("x");
  match fc2 {
    Some(_) => { io.println("to_float_checked bad"); return 32; },
    None => {},
  }

  var pi = parse.parse_int("42");
  match pi {
    Ok(v) => { if v != 42 { io.println("parse_int"); return 33; } },
    Err(e) => { io.println(string.str_concat("parse_int err ", e)); return 34; },
  }
  var pir = parse.parse_int_radix("ff", 16);
  match pir {
    Ok(v) => { if v != 255 { io.println("parse_int_radix"); return 35; } },
    Err(e) => { io.println(string.str_concat("parse_int_radix err ", e)); return 36; },
  }
  var pf = parse.parse_float("1.5");
  match pf {
    Ok(v) => { if v != 1.5 { io.println("parse_float"); return 37; } },
    Err(e) => { io.println(string.str_concat("parse_float err ", e)); return 38; },
  }
  var pb = parse.parse_bool("true");
  match pb {
    Some(v) => { if !v { io.println("parse_bool"); return 39; } },
    None => { io.println("parse_bool none"); return 40; },
  }
  var pc = parse.parse_char("x");
  match pc {
    Some(v) => { if v != 'x' { io.println("parse_char"); return 41; } },
    None => { io.println("parse_char none"); return 42; },
  }

  if atoi.atoi("42") != 42 { io.println("atoi"); return 43; }
  if atoi.atoi("  -17") != -17 { io.println(string.str_concat("atoi ws ", to_string(atoi.atoi("  -17")))); return 44; }
  if atoi.atoi("abc") != 0 { io.println("atoi bad"); return 45; }
  if atoi.atoi_radix("ff", 16) != 255 { io.println(string.str_concat("atoi_radix ", to_string(atoi.atoi_radix("ff", 16)))); return 46; }
  if atoi.atoi_or("x", 7) != 7 { io.println("atoi_or default"); return 47; }
  if atoi.atoi_or("12", 7) != 12 { io.println("atoi_or parsed"); return 48; }

  io.println("OK");
  return 0;
}

module smoke_string_scanf
use xiom.string.scanf;
use xiom.io;

fn main() -> Int {
  // ---- scanf ----
  // NOTE (compiler bug): elements of a Result[Vec[Str], _] cannot be read on
  // this compiler build (mono-layout collision makes them type as Int and the
  // reads crash), so str_scanf is verified via the captured count and the
  // error paths; token content is exercised through str_scanf_ints and
  // str_scanf_floats, which share the same engine.
  var s1 = xiom.string.scanf.str_scanf("42", "%d");
  match s1 {
    Ok(v) => { if v.len() != 1 { io.println("sc-1"); return 1; } };
    Err(e) => { io.println(e); return 2; };
  }
  var s2 = xiom.string.scanf.str_scanf("hello world", "%s");
  match s2 {
    Ok(v) => { if v.len() != 1 { io.println("sc-2"); return 3; } };
    Err(e) => { io.println(e); return 4; };
  }
  var s3 = xiom.string.scanf.str_scanf("abc", "%d");
  match s3 {
    Ok(v) => { return 5; };
    Err(e) => {};
  }
  var s10 = xiom.string.scanf.str_scanf("42", "42");
  match s10 {
    Ok(v) => { if v.len() != 0 { io.println("sc-10"); return 6; } };
    Err(e) => { io.println(e); return 7; };
  }

  var s4 = xiom.string.scanf.str_scanf_ints("3 4", "%d %d");
  match s4 {
    Ok(v) => { if v.len() != 2 || v[0] != 3 || v[1] != 4 { io.println("sc-5"); return 8; } };
    Err(e) => { io.println(e); return 9; };
  }
  var s5 = xiom.string.scanf.str_scanf_ints("ff", "%x");
  match s5 {
    Ok(v) => { if v.len() != 1 || v[0] != 255 { io.println("sc-6"); return 10; } };
    Err(e) => { io.println(e); return 11; };
  }
  var s6 = xiom.string.scanf.str_scanf_ints("-17", "%d");
  match s6 {
    Ok(v) => { if v.len() != 1 || v[0] != -17 { io.println("sc-7"); return 12; } };
    Err(e) => { io.println(e); return 13; };
  }
  var s11 = xiom.string.scanf.str_scanf_ints("0x1f", "%x");
  match s11 {
    Ok(v) => { if v.len() != 1 || v[0] != 31 { io.println("sc-11"); return 14; } };
    Err(e) => { io.println(e); return 15; };
  }

  var s7 = xiom.string.scanf.str_scanf_floats("3.14 2.5", "%f %f");
  if !s7.is_ok { io.println(s7.remainder); return 16; }
  if s7.count != 2 { io.println("sc-8"); return 17; }
  if s7.v0 * 100.0 < 313.9 || s7.v0 * 100.0 > 314.1 { io.println("sc-9"); return 18; }
  if s7.v1 * 100.0 < 249.9 || s7.v1 * 100.0 > 250.1 { io.println("sc-12"); return 19; }
  var s8 = xiom.string.scanf.str_scanf_floats("1.5e-3", "%f");
  if !s8.is_ok { io.println(s8.remainder); return 20; }
  if s8.count != 1 { io.println("sc-13"); return 21; }
  if s8.v0 * 1000000.0 < 1499.9 || s8.v0 * 1000000.0 > 1500.1 { io.println("sc-14"); return 22; }
  var s9 = xiom.string.scanf.str_scanf_floats("x", "%f");
  if s9.is_ok { io.println("sc-15"); return 23; }

  io.println("smoke_string_scanf: OK");
  return 0;
}

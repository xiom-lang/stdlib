module smoke_fmt_sprintf
use xiom.fmt;
use xiom.convert;
use xiom.string;
use xiom.io;

// printf/scanf-style formatting (G13) + the float_to_string fix.
// All expected strings are C-printf semantics (glibc).

fn expect_s(spec: Str, got: Str, want: Str, label: Str) -> Int {
  if got != want {
    io.println(str_concat(str_concat(str_concat(label, ": got '"), got), "'"));
    return 1;
  }
  return 0;
}

fn main() -> Int {
  // -- sprintf int family --
  var r = xiom.fmt.sprintf_i1("%d", 42);
  match r {
    Ok(v) => { if expect_s("d", v, "42", "d") != 0 { return 1; } };
    Err(e) => { io.println(e); return 2; };
  }
  var r2 = xiom.fmt.sprintf_i1("%5d", 42);
  match r2 {
    Ok(v) => { if expect_s("5d", v, "   42", "5d") != 0 { return 3; } };
    Err(e) => { io.println(e); return 4; };
  }
  var r3 = xiom.fmt.sprintf_i1("%-5d", 42);
  match r3 {
    Ok(v) => { if expect_s("-5d", v, "42   ", "-5d") != 0 { return 5; } };
    Err(e) => { io.println(e); return 6; };
  }
  var r4 = xiom.fmt.sprintf_i1("%05d", 42);
  match r4 {
    Ok(v) => { if expect_s("05d", v, "00042", "05d") != 0 { return 7; } };
    Err(e) => { io.println(e); return 8; };
  }
  var r5 = xiom.fmt.sprintf_i1("%+d", 42);
  match r5 {
    Ok(v) => { if expect_s("+d", v, "+42", "+d") != 0 { return 9; } };
    Err(e) => { io.println(e); return 10; };
  }
  var r6 = xiom.fmt.sprintf_i1("% d", 42);
  match r6 {
    Ok(v) => { if expect_s(" d", v, " 42", " d") != 0 { return 11; } };
    Err(e) => { io.println(e); return 12; };
  }
  var r7 = xiom.fmt.sprintf_i1("%d", -42);
  match r7 {
    Ok(v) => { if expect_s("neg", v, "-42", "neg") != 0 { return 13; } };
    Err(e) => { io.println(e); return 14; };
  }
  var r8 = xiom.fmt.sprintf_i1("%x", 255);
  match r8 {
    Ok(v) => { if expect_s("x", v, "ff", "x") != 0 { return 15; } };
    Err(e) => { io.println(e); return 16; };
  }
  var r9 = xiom.fmt.sprintf_i1("%X", 255);
  match r9 {
    Ok(v) => { if expect_s("X", v, "FF", "X") != 0 { return 17; } };
    Err(e) => { io.println(e); return 18; };
  }
  var r10 = xiom.fmt.sprintf_i1("%x", -1);
  match r10 {
    Ok(v) => { if expect_s("xneg", v, "ffffffffffffffff", "xneg") != 0 { return 19; } };
    Err(e) => { io.println(e); return 20; };
  }
  var r11 = xiom.fmt.sprintf_i1("%o", 8);
  match r11 {
    Ok(v) => { if expect_s("o", v, "10", "o") != 0 { return 21; } };
    Err(e) => { io.println(e); return 22; };
  }
  var r12 = xiom.fmt.sprintf_i1("%b", 5);
  match r12 {
    Ok(v) => { if expect_s("b", v, "101", "b") != 0 { return 23; } };
    Err(e) => { io.println(e); return 24; };
  }
  var r13 = xiom.fmt.sprintf_i1("%.5d", 42);
  match r13 {
    Ok(v) => { if expect_s("prec", v, "00042", "prec") != 0 { return 25; } };
    Err(e) => { io.println(e); return 26; };
  }
  var r14 = xiom.fmt.sprintf_i1("%d", -2147483648);
  match r14 {
    Ok(v) => { if expect_s("intmin", v, "-2147483648", "intmin") != 0 { return 27; } };
    Err(e) => { io.println(e); return 28; };
  }
  var r15 = xiom.fmt.sprintf_i1("100%%");
  match r15 {
    Ok(v) => { if expect_s("pct", v, "100%", "pct") != 0 { return 29; } };
    Err(e) => { io.println(e); return 30; };
  }
  var r16 = xiom.fmt.sprintf_i2("%d-%d", 3, 4);
  match r16 {
    Ok(v) => { if expect_s("i2", v, "3-4", "i2") != 0 { return 31; } };
    Err(e) => { io.println(e); return 32; };
  }
  // wrong family / missing args -> Err (no silent failures)
  var r17 = xiom.fmt.sprintf_f1("%d", 1.5);
  match r17 {
    Ok(v) => { return 33; };
    Err(e) => {};
  }
  var r18 = xiom.fmt.sprintf_i1("%f", 5);
  match r18 {
    Ok(v) => { return 34; };
    Err(e) => {};
  }
  var r19 = xiom.fmt.sprintf_i1("%d %d", 5);
  match r19 {
    Ok(v) => { return 35; };
    Err(e) => {};
  }

  // -- sprintf float family --
  var f1 = xiom.fmt.sprintf_f1("%.2f", 3.14159);
  match f1 {
    Ok(v) => { if expect_s("2f", v, "3.14", "2f") != 0 { return 36; } };
    Err(e) => { io.println(e); return 37; };
  }
  var f2 = xiom.fmt.sprintf_f1("%f", 0.3);
  match f2 {
    Ok(v) => { if expect_s("f03", v, "0.300000", "f03") != 0 { return 38; } };
    Err(e) => { io.println(e); return 39; };
  }
  var f3 = xiom.fmt.sprintf_f1("%e", 12345.678);
  match f3 {
    Ok(v) => { if expect_s("e", v, "1.234568e+04", "e") != 0 { return 40; } };
    Err(e) => { io.println(e); return 41; };
  }
  var f4 = xiom.fmt.sprintf_f1("%.2e", 0.0012345);
  match f4 {
    Ok(v) => { if expect_s("2e", v, "1.23e-03", "2e") != 0 { return 42; } };
    Err(e) => { io.println(e); return 43; };
  }
  var f5 = xiom.fmt.sprintf_f1("%E", 12345.678);
  match f5 {
    Ok(v) => { if expect_s("E", v, "1.234568E+04", "E") != 0 { return 44; } };
    Err(e) => { io.println(e); return 45; };
  }
  var f6 = xiom.fmt.sprintf_f1("%g", 0.00001);
  match f6 {
    Ok(v) => { if expect_s("g1", v, "1e-05", "g1") != 0 { return 46; } };
    Err(e) => { io.println(e); return 47; };
  }
  var f7 = xiom.fmt.sprintf_f1("%g", 1234567.0);
  match f7 {
    Ok(v) => { if expect_s("g2", v, "1.23457e+06", "g2") != 0 { return 48; } };
    Err(e) => { io.println(e); return 49; };
  }
  var f8 = xiom.fmt.sprintf_f1("%g", 0.0001);
  match f8 {
    Ok(v) => { if expect_s("g3", v, "0.0001", "g3") != 0 { return 50; } };
    Err(e) => { io.println(e); return 51; };
  }
  var f9 = xiom.fmt.sprintf_f1("%.10g", 123.456);
  match f9 {
    Ok(v) => { if expect_s("g4", v, "123.456", "g4") != 0 { return 52; } };
    Err(e) => { io.println(e); return 53; };
  }
  var f10 = xiom.fmt.sprintf_f1("%8.2f", 3.14159);
  match f10 {
    Ok(v) => { if expect_s("8.2f", v, "    3.14", "8.2f") != 0 { return 54; } };
    Err(e) => { io.println(e); return 55; };
  }
  var f11 = xiom.fmt.sprintf_f1("%-8.2f", 3.14159);
  match f11 {
    Ok(v) => { if expect_s("-8.2f", v, "3.14    ", "-8.2f") != 0 { return 56; } };
    Err(e) => { io.println(e); return 57; };
  }
  var f12 = xiom.fmt.sprintf_f1("%08.2f", 3.14159);
  match f12 {
    Ok(v) => { if expect_s("08.2f", v, "00003.14", "08.2f") != 0 { return 58; } };
    Err(e) => { io.println(e); return 59; };
  }
  var f13 = xiom.fmt.sprintf_f1("%+f", 1.5);
  match f13 {
    Ok(v) => { if expect_s("+f", v, "+1.500000", "+f") != 0 { return 60; } };
    Err(e) => { io.println(e); return 61; };
  }
  var f14 = xiom.fmt.sprintf_f1("%e", 0.0);
  match f14 {
    Ok(v) => { if expect_s("e0", v, "0.000000e+00", "e0") != 0 { return 62; } };
    Err(e) => { io.println(e); return 63; };
  }
  var f15 = xiom.fmt.sprintf_f2("%.1f|%.3f", 2.25, 1.0);
  match f15 {
    Ok(v) => { if expect_s("f2x", v, "2.3|1.000", "f2x") != 0 { return 64; } };
    Err(e) => { io.println(e); return 65; };
  }

  // -- sprintf str family --
  var s1 = xiom.fmt.sprintf_s1("%s", "hi");
  match s1 {
    Ok(v) => { if expect_s("s", v, "hi", "s") != 0 { return 66; } };
    Err(e) => { io.println(e); return 67; };
  }
  var s2 = xiom.fmt.sprintf_s1("%10s", "hi");
  match s2 {
    Ok(v) => { if expect_s("10s", v, "        hi", "10s") != 0 { return 68; } };
    Err(e) => { io.println(e); return 69; };
  }
  var s3 = xiom.fmt.sprintf_s1("%-10s", "hi");
  match s3 {
    Ok(v) => { if expect_s("-10s", v, "hi        ", "-10s") != 0 { return 70; } };
    Err(e) => { io.println(e); return 71; };
  }
  var s4 = xiom.fmt.sprintf_s1("%.2s", "hello");
  match s4 {
    Ok(v) => { if expect_s(".2s", v, "he", ".2s") != 0 { return 72; } };
    Err(e) => { io.println(e); return 73; };
  }
  var s5 = xiom.fmt.sprintf_s2("%s-%s", "a", "b");
  match s5 {
    Ok(v) => { if expect_s("s2x", v, "a-b", "s2x") != 0 { return 74; } };
    Err(e) => { io.println(e); return 75; };
  }

  // -- convert.float_to_string (was fptosi bit-pattern garbage) --
  if xiom.convert.float_to_string(1.5) != "1.5" { return 76; }
  if xiom.convert.float_to_string(0.1) != "0.1" { return 77; }
  if xiom.convert.float_to_string(3.14159265358979) != "3.14159265358979" { return 78; }
  if xiom.convert.float_to_string(123.456) != "123.456" { return 79; }
  if xiom.convert.float_to_string(-2.5) != "-2.5" { return 80; }
  if xiom.convert.float_to_string(0.0) != "0" { return 81; }
  if xiom.convert.float_to_string(100000000000000000000.0) != "1e+20" { return 82; }
  if xiom.convert.float_to_string(0.00001) != "1e-05" { return 83; }
  if xiom.convert.float_to_fixed_str(3.125, 2) != "3.13" { return 84; }
  if xiom.convert.float_to_sci_str(12345.678, 2) != "1.23e+04" { return 85; }
  if xiom.convert.float_to_fixed_str(-1.5, 2) != "-1.50" { return 86; }

  // -- sscanf --
  var sc1 = xiom.fmt.sscanf_ints("42", "%d");
  match sc1 {
    Ok(v) => { if v.len() != 1 || v[0] != 42 { return 87; } };
    Err(e) => { io.println(e); return 88; };
  }
  var sc2 = xiom.fmt.sscanf_ints("3 4", "%d %d");
  match sc2 {
    Ok(v) => { if v.len() != 2 || v[0] != 3 || v[1] != 4 { return 89; } };
    Err(e) => { io.println(e); return 90; };
  }
  var sc3 = xiom.fmt.sscanf_ints("ff", "%x");
  match sc3 {
    Ok(v) => { if v.len() != 1 || v[0] != 255 { return 91; } };
    Err(e) => { io.println(e); return 92; };
  }
  var sc4 = xiom.fmt.sscanf_ints("0x1f", "%x");
  match sc4 {
    Ok(v) => { if v.len() != 1 || v[0] != 31 { return 93; } };
    Err(e) => { io.println(e); return 94; };
  }
  var sc5 = xiom.fmt.sscanf_ints("-17", "%d");
  match sc5 {
    Ok(v) => { if v.len() != 1 || v[0] != -17 { return 95; } };
    Err(e) => { io.println(e); return 96; };
  }
  var sc6 = xiom.fmt.sscanf_ints(" 42 ", "%d");
  match sc6 {
    Ok(v) => { if v.len() != 1 || v[0] != 42 { return 97; } };
    Err(e) => { io.println(e); return 98; };
  }
  var sc7 = xiom.fmt.sscanf_ints("1,2", "%d,%d");
  match sc7 {
    Ok(v) => { if v.len() != 2 || v[0] != 1 || v[1] != 2 { return 99; } };
    Err(e) => { io.println(e); return 100; };
  }
  var sc8 = xiom.fmt.sscanf_ints("123", "%2d");
  match sc8 {
    Ok(v) => { if v.len() != 1 || v[0] != 12 { return 101; } };
    Err(e) => { io.println(e); return 102; };
  }
  var sc9 = xiom.fmt.sscanf("hello world", "%s");
  match sc9 {
    Ok(v) => { if v.len() != 1 || v[0] != "hello" { return 103; } };
    Err(e) => { io.println(e); return 104; };
  }
  var sc10 = xiom.fmt.sscanf("abc", "%c");
  match sc10 {
    Ok(v) => { if v.len() != 1 || v[0] != "a" { return 105; } };
    Err(e) => { io.println(e); return 106; };
  }
  var sc11 = xiom.fmt.sscanf("abc", "%3c");
  match sc11 {
    Ok(v) => { if v.len() != 1 || v[0] != "abc" { return 107; } };
    Err(e) => { io.println(e); return 108; };
  }
  var sc12 = xiom.fmt.sscanf("hello", "%*s");
  match sc12 {
    Ok(v) => { if v.len() != 0 { return 109; } };
    Err(e) => { io.println(e); return 110; };
  }
  var sc13 = xiom.fmt.sscanf("x42", "%d");
  match sc13 {
    Ok(v) => { return 111; };
    Err(e) => {};
  }
  var sc14 = xiom.fmt.sscanf("42", "42");
  match sc14 {
    Ok(v) => { if v.len() != 0 { return 112; } };
    Err(e) => { io.println(e); return 113; };
  }
  var sc15 = xiom.fmt.sscanf_floats("3.14 2.5e-1", "%f %f");
  if !sc15.is_ok { io.println(sc15.error); return 114; }
  if sc15.count != 2 { return 115; }
  if sc15.v0 * 100.0 < 313.9 || sc15.v0 * 100.0 > 314.1 { return 116; }
  if sc15.v1 * 100.0 < 24.9 || sc15.v1 * 100.0 > 25.1 { return 117; }
  var sc16 = xiom.fmt.sscanf_floats("1.5e-3", "%f");
  if !sc16.is_ok { io.println(sc16.error); return 118; }
  if sc16.count != 1 { return 119; }
  if sc16.v0 * 1000000.0 < 1499.9 || sc16.v0 * 1000000.0 > 1500.1 { return 120; }
  var sc17 = xiom.fmt.sscanf_floats(".5", "%f");
  if !sc17.is_ok { io.println(sc17.error); return 121; }
  if sc17.count != 1 || sc17.v0 * 10.0 < 4.9 || sc17.v0 * 10.0 > 5.1 { return 122; }
  var sc18 = xiom.fmt.sscanf_floats("x", "%d");
  if sc18.is_ok { return 123; }

  io.println("smoke_fmt_sprintf: all 123 checks passed");
  return 0;
}

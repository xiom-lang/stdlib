module smoke_num_base
use xiom.num.base;
use xiom.io;

fn main() -> Int {
  // to_base
  if base.to_base(255, 16) != "ff" { io.println("base: to_base 255,16"); return 1; }
  if base.to_base(255, 2) != "11111111" { io.println("base: to_base 255,2"); return 2; }
  if base.to_base(0, 10) != "0" { io.println("base: to_base 0"); return 3; }
  if base.to_base(-255, 16) != "-ff" { io.println("base: to_base -255"); return 4; }
  if base.to_base(65535, 16) != "ffff" { io.println("base: to_base 65535,16"); return 4; }
  if base.to_base(255, 1) != "" { io.println("base: to_base invalid base 1"); return 5; }
  if base.to_base(255, 37) != "" { io.println("base: to_base invalid base 37"); return 5; }
  // from_base: ok cases
  var r1 = base.from_base("ff", 16);
  match r1 {
    Ok(v) => { if v != 255 { io.println("base: from_base ff"); return 6; } }
    Err(_) => { io.println("base: from_base ff Err"); return 6; }
  }
  var r2 = base.from_base("FF", 16);
  match r2 {
    Ok(v) => { if v != 255 { io.println("base: from_base FF"); return 6; } }
    Err(_) => { io.println("base: from_base FF Err"); return 6; }
  }
  var r3 = base.from_base("101", 2);
  match r3 {
    Ok(v) => { if v != 5 { io.println("base: from_base 101"); return 6; } }
    Err(_) => { io.println("base: from_base 101 Err"); return 6; }
  }
  var r8 = base.from_base("-ff", 16);
  match r8 {
    Ok(v) => { if v != -255 { io.println("base: from_base -ff"); return 6; } }
    Err(_) => { io.println("base: from_base -ff Err"); return 6; }
  }
  var r9 = base.from_base("zz", 36);
  match r9 {
    Ok(v) => { if v != 1295 { io.println("base: from_base zz,36"); return 6; } }
    Err(_) => { io.println("base: from_base zz,36 Err"); return 6; }
  }
  // from_base: error cases
  var e1 = base.from_base("zz", 10);
  match e1 {
    Ok(_) => { io.println("base: from_base zz,10 ok unexpected"); return 7; }
    Err(_) => {}
  }
  var e2 = base.from_base("", 16);
  match e2 {
    Ok(_) => { io.println("base: from_base empty ok"); return 7; }
    Err(_) => {}
  }
  var e3 = base.from_base("1g", 16);
  match e3 {
    Ok(_) => { io.println("base: from_base 1g ok"); return 7; }
    Err(_) => {}
  }
  var e4 = base.from_base("123", 99);
  match e4 {
    Ok(_) => { io.println("base: from_base bad base ok"); return 7; }
    Err(_) => {}
  }
  var e5 = base.from_base("102", 2);
  match e5 {
    Ok(_) => { io.println("base: from_base 102,2 ok"); return 7; }
    Err(_) => {}
  }
  // to_base_float
  if base.to_base_float(255.5, 16, 1) != "ff.8" { io.println("base: to_base_float ff.8"); return 8; }
  if base.to_base_float(255.5, 16, 3) != "ff.800" { io.println("base: to_base_float ff.800"); return 8; }
  if base.to_base_float(0.5, 2, 4) != "0.1000" { io.println("base: to_base_float 0.1000"); return 8; }
  if base.to_base_float(-3.5, 10, 2) != "-3.50" { io.println("base: to_base_float -3.50"); return 8; }
  if base.to_base_float(1.0 / 0.0, 10, 2) != "inf" { io.println("base: to_base_float inf"); return 8; }
  if base.to_base_float(-1.0 / 0.0, 10, 2) != "-inf" { io.println("base: to_base_float -inf"); return 8; }
  if base.to_base_float(0.0, 10, 2) != "0.00" { io.println("base: to_base_float 0.00"); return 8; }
  // from_base_float: ok cases
  var f1 = base.from_base_float("ff.8", 16);
  match f1 {
    Ok(v) => {
      var d: Float64 = v - 255.5;
      if d < 0.0 { d = -d; }
      if d >= 1.0e-9 { io.println("base: from_base_float ff.8 value"); return 9; }
    }
    Err(_) => { io.println("base: from_base_float ff.8 Err"); return 9; }
  }
  var f2 = base.from_base_float("0.1000", 2);
  match f2 {
    Ok(v) => {
      var d: Float64 = v - 0.5;
      if d < 0.0 { d = -d; }
      if d >= 1.0e-9 { io.println("base: from_base_float 0.1000 value"); return 9; }
    }
    Err(_) => { io.println("base: from_base_float 0.1000 Err"); return 9; }
  }
  var f5 = base.from_base_float("-3.5", 10);
  match f5 {
    Ok(v) => {
      var d: Float64 = v + 3.5;
      if d < 0.0 { d = -d; }
      if d >= 1.0e-9 { io.println("base: from_base_float -3.5 value"); return 9; }
    }
    Err(_) => { io.println("base: from_base_float -3.5 Err"); return 9; }
  }
  var f6 = base.from_base_float("1a.2", 16);
  match f6 {
    Ok(v) => {
      var d: Float64 = v - 26.125;
      if d < 0.0 { d = -d; }
      if d >= 1.0e-9 { io.println("base: from_base_float 1a.2 value"); return 9; }
    }
    Err(_) => { io.println("base: from_base_float 1a.2 Err"); return 9; }
  }
  // from_base_float: error cases
  var fe1 = base.from_base_float("zz", 10);
  match fe1 {
    Ok(_) => { io.println("base: from_base_float zz,10 ok"); return 10; }
    Err(_) => {}
  }
  var fe2 = base.from_base_float("", 10);
  match fe2 {
    Ok(_) => { io.println("base: from_base_float empty ok"); return 10; }
    Err(_) => {}
  }
  var fe3 = base.from_base_float("1.2.3", 10);
  match fe3 {
    Ok(_) => { io.println("base: from_base_float double dot ok"); return 10; }
    Err(_) => {}
  }
  // digits_of: LSB first
  var d1 = base.digits_of(255, 2);
  if d1.len() != 8 { io.println("base: digits_of 255,2 len"); return 11; }
  var i = 0;
  while i < d1.len() {
    if d1[i] != 1 { io.println("base: digits_of 255,2 bit"); return 11; }
    i = i + 1;
  }
  var d2 = base.digits_of(255, 16);
  if d2.len() != 2 || d2[0] != 15 || d2[1] != 15 { io.println("base: digits_of 255,16"); return 11; }
  var d3 = base.digits_of(0, 10);
  if d3.len() != 1 || d3[0] != 0 { io.println("base: digits_of 0"); return 11; }
  var d4 = base.digits_of(-255, 10);
  if d4.len() != 3 || d4[0] != 5 || d4[1] != 5 || d4[2] != 2 { io.println("base: digits_of -255"); return 11; }
  var d5 = base.digits_of(42, 1);
  if d5.len() != 0 { io.println("base: digits_of invalid base"); return 11; }
  // from_digits
  if base.from_digits(&d1, 2) != 255 { io.println("base: from_digits bin"); return 12; }
  if base.from_digits(&d2, 16) != 255 { io.println("base: from_digits hex"); return 12; }
  var empty = Vec[Int].new();
  if base.from_digits(&empty, 10) != 0 { io.println("base: from_digits empty"); return 12; }
  var bad = Vec[Int].new();
  bad.push(5);
  if base.from_digits(&bad, 2) != 0 { io.println("base: from_digits bad digit"); return 12; }
  var single = Vec[Int].new();
  single.push(5);
  if base.from_digits(&single, 10) != 5 { io.println("base: from_digits single"); return 12; }
  io.println("smoke_num_base: OK");
  return 0;
}

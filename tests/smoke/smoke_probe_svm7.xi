module smoke_probe_svm7
use xiom.string;
use xiom.io;

fn str_eq(a: Str, b: Str) -> Bool {
  var al = xiom.string.str_len(a);
  var bl = xiom.string.str_len(b);
  if al != bl { return false; }
  var i = 0;
  while i < al {
    if xiom.string.byte_at(a, i) != xiom.string.byte_at(b, i) { return false; }
    i = i + 1;
  }
  true
}

fn bare(v_major: Int, v_minor: Int, v_patch: Int, target: Str) -> Bool {
  var parts = xiom.string.str_split(target, ".");
  if parts.len() == 0 { return false; }
  var p0 = parts[0];
  if str_eq(p0, "x") || str_eq(p0, "X") || str_eq(p0, "*") { return true; }
  var maj = 0;
  var r = xiom.string.str_to_int(p0);
  match r {
    Ok(val) => { maj = val; },
    Err(_) => { return false; },
  }
  if v_major != maj { return false; }
  if parts.len() == 1 { return true; }
  var p1 = parts[1];
  if str_eq(p1, "x") || str_eq(p1, "X") || str_eq(p1, "*") { return true; }
  var min = 0;
  var r2 = xiom.string.str_to_int(p1);
  match r2 {
    Ok(val) => { min = val; },
    Err(_) => { return false; },
  }
  if v_minor != min { return false; }
  if parts.len() == 2 { return true; }
  var p2 = parts[2];
  if str_eq(p2, "x") || str_eq(p2, "X") || str_eq(p2, "*") { return true; }
  var pat = 0;
  var r3 = xiom.string.str_to_int(p2);
  match r3 {
    Ok(val) => { pat = val; },
    Err(_) => { return false; },
  }
  v_patch == pat
}

fn main() -> Int {
  if !bare(1, 2, 3, "1") { io.println("m1"); return 1; }
  if !bare(1, 2, 3, "1.2") { io.println("m2"); return 2; }
  if !bare(1, 2, 3, "1.2.3") { io.println("m3"); return 3; }
  if bare(1, 2, 4, "1.2.3") { io.println("m4"); return 4; }
  io.println("OK");
  return 0;
}

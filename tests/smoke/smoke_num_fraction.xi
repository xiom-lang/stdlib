module smoke_num_fraction
use xiom.num.fraction;
use xiom.io;

fn main() -> Int {
  // fraction_new: reduction, sign normalization, zero
  var f = fraction.fraction_new(2, 4);
  if f.num != 1 || f.den != 2 { io.println("frac: new reduce 2/4"); return 1; }
  var g = fraction.fraction_new(-3, -6);
  if g.num != 1 || g.den != 2 { io.println("frac: new sign flip"); return 2; }
  var z = fraction.fraction_new(0, 5);
  if z.num != 0 || z.den != 1 { io.println("frac: new zero"); return 3; }
  var n2 = fraction.fraction_new(1, -2);
  if n2.num != -1 || n2.den != 2 { io.println("frac: new negative den"); return 3; }
  // arithmetic
  var a = fraction.fraction_add(fraction.fraction_new(1, 2), fraction.fraction_new(1, 3));
  if a.num != 5 || a.den != 6 { io.println("frac: add 1/2+1/3"); return 4; }
  var a2 = fraction.fraction_add(fraction.fraction_new(1, 2), fraction.fraction_new(1, 4));
  if a2.num != 3 || a2.den != 4 { io.println("frac: add 1/2+1/4"); return 4; }
  var s = fraction.fraction_sub(fraction.fraction_new(3, 4), fraction.fraction_new(1, 2));
  if s.num != 1 || s.den != 4 { io.println("frac: sub 3/4-1/2"); return 5; }
  var m = fraction.fraction_mul(fraction.fraction_new(1, 2), fraction.fraction_new(2, 3));
  if m.num != 1 || m.den != 3 { io.println("frac: mul 1/2*2/3"); return 6; }
  var m2 = fraction.fraction_mul(fraction.fraction_new(1, 2), fraction.fraction_new(1, 4));
  if m2.num != 1 || m2.den != 8 { io.println("frac: mul 1/2*1/4"); return 6; }
  // division
  var d = fraction.fraction_div(fraction.fraction_new(1, 2), fraction.fraction_new(1, 3));
  match d {
    Some(v) => {
      if v.num != 3 || v.den != 2 { io.println("frac: div 1/2 / 1/3"); return 7; }
    }
    None => { io.println("frac: div None unexpected"); return 7; }
  }
  var dz = fraction.fraction_div(fraction.fraction_new(1, 2), fraction.fraction_new(0, 1));
  match dz {
    Some(_) => { io.println("frac: div by zero Some unexpected"); return 8; }
    None => {}
  }
  // reduce
  var r = fraction.fraction_reduce(fraction.fraction_new(4, 6));
  if r.num != 2 || r.den != 3 { io.println("frac: reduce 4/6"); return 9; }
  // to_float
  var tf = fraction.fraction_to_float(fraction.fraction_new(1, 2));
  var diff = tf - 0.5;
  if diff < 0.0 { diff = -diff; }
  if diff >= 1.0e-9 { io.println("frac: to_float 1/2"); return 10; }
  var tf3 = fraction.fraction_to_float(fraction.fraction_new(2, 3));
  var diff3 = tf3 - 0.6666666666666666;
  if diff3 < 0.0 { diff3 = -diff3; }
  if diff3 >= 1.0e-9 { io.println("frac: to_float 2/3"); return 10; }
  // to_str
  var ts = fraction.fraction_to_str(fraction.fraction_new(3, 4));
  if ts != "3/4" { io.println("frac: to_str 3/4"); return 11; }
  var ts2 = fraction.fraction_to_str(fraction.fraction_new(-7, 2));
  if ts2 != "-7/2" { io.println("frac: to_str -7/2"); return 11; }
  // is_zero
  if !fraction.fraction_is_zero(fraction.fraction_new(0, 1)) { io.println("frac: is_zero 0/1"); return 12; }
  if fraction.fraction_is_zero(fraction.fraction_new(1, 2)) { io.println("frac: is_zero 1/2"); return 12; }
  // compare
  if fraction.fraction_compare(fraction.fraction_new(1, 2), fraction.fraction_new(1, 3)) != 1 { io.println("frac: cmp 1/2 vs 1/3"); return 13; }
  if fraction.fraction_compare(fraction.fraction_new(1, 3), fraction.fraction_new(1, 2)) != -1 { io.println("frac: cmp 1/3 vs 1/2"); return 13; }
  if fraction.fraction_compare(fraction.fraction_new(1, 2), fraction.fraction_new(2, 4)) != 0 { io.println("frac: cmp 1/2 vs 2/4"); return 13; }
  if fraction.fraction_compare(fraction.fraction_new(-1, 2), fraction.fraction_new(1, 2)) != -1 { io.println("frac: cmp -1/2 vs 1/2"); return 13; }
  // from_float: exact binary values and the 1/3 convergent
  var q1 = fraction.fraction_from_float(0.25);
  if q1.num != 1 || q1.den != 4 { io.println("frac: from_float 0.25"); return 14; }
  var q2 = fraction.fraction_from_float(1.5);
  if q2.num != 3 || q2.den != 2 { io.println("frac: from_float 1.5"); return 14; }
  var q3 = fraction.fraction_from_float(2.0);
  if q3.num != 2 || q3.den != 1 { io.println("frac: from_float 2.0"); return 14; }
  var q4 = fraction.fraction_from_float(0.0);
  if q4.num != 0 || q4.den != 1 { io.println("frac: from_float 0.0"); return 14; }
  var q5 = fraction.fraction_from_float(-1.5);
  if q5.num != -3 || q5.den != 2 { io.println("frac: from_float -1.5"); return 14; }
  var q6 = fraction.fraction_from_float(0.1);
  var back = fraction.fraction_to_float(q6);
  var d6 = back - 0.1;
  if d6 < 0.0 { d6 = -d6; }
  if d6 >= 1.0e-9 { io.println("frac: from_float 0.1 roundtrip"); return 14; }
  io.println("smoke_num_fraction: OK");
  return 0;
}

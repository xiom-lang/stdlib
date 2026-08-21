// XIOM stdlib smoke test - checked/saturating/wrapping/overflow/exact/lossy/
// unchecked/roundtrip conversion helpers.

module smoke_convert_checked
use xiom.convert.checked;
use xiom.convert.saturating;
use xiom.convert.wrapping;
use xiom.convert.exact;
use xiom.convert.lossy;
use xiom.convert.unchecked;
use xiom.convert.roundtrip;
use xiom.io;
use xiom.convert;
use xiom.string;

fn main() -> Int {
  var a = checked.checked_add(1, 2);
  if !a.is_some || a.value != 3 { io.println("checked_add"); return 1; }
  var ao = checked.checked_add(9223372036854775807, 1);
  if ao.is_some { io.println("checked_add overflow"); return 2; }

  var s = checked.checked_sub(5, 3);
  if !s.is_some || s.value != 2 { io.println("checked_sub"); return 3; }
  var so = checked.checked_sub(-9223372036854775808, 1);
  if so.is_some { io.println("checked_sub overflow"); return 4; }

  var m = checked.checked_mul(6, 7);
  if !m.is_some || m.value != 42 { io.println("checked_mul"); return 5; }
  var mo = checked.checked_mul(9223372036854775807, 2);
  if mo.is_some { io.println("checked_mul overflow"); return 6; }

  var d = checked.checked_div(10, 2);
  if !d.is_some || d.value != 5 { io.println("checked_div"); return 7; }
  var dz = checked.checked_div(10, 0);
  if dz.is_some { io.println("checked_div by zero"); return 8; }

  var n = checked.checked_neg(5);
  if !n.is_some || n.value != -5 { io.println("checked_neg"); return 9; }
  var no = checked.checked_neg(-9223372036854775808);
  if no.is_some { io.println("checked_neg INT_MIN"); return 10; }

  var ab = checked.checked_abs(-5);
  if !ab.is_some || ab.value != 5 { io.println("checked_abs"); return 11; }
  var abo = checked.checked_abs(-9223372036854775808);
  if abo.is_some { io.println("checked_abs INT_MIN"); return 12; }

  var p = checked.checked_pow(2, 10);
  if !p.is_some || p.value != 1024 { io.println("checked_pow"); return 13; }
  var po = checked.checked_pow(2, 63);
  if po.is_some { io.println("checked_pow overflow"); return 14; }

  var sl = checked.checked_shl(1, 4);
  if !sl.is_some || sl.value != 16 { io.println("checked_shl"); return 15; }
  var slo = checked.checked_shl(1, 64);
  if slo.is_some { io.println("checked_shl overflow"); return 16; }

  var sr = checked.checked_shr(16, 2);
  if !sr.is_some || sr.value != 4 { io.println("checked_shr"); return 17; }
  var sro = checked.checked_shr(16, -1);
  if sro.is_some { io.println("checked_shr invalid"); return 18; }

  if saturating.saturating_add(9223372036854775807, 1) != 9223372036854775807 { io.println("sat add"); return 19; }
  if saturating.saturating_sub(-9223372036854775808, 1) != -9223372036854775808 { io.println("sat sub"); return 20; }
  if saturating.saturating_mul(9223372036854775807, 2) != 9223372036854775807 { io.println("sat mul"); return 21; }
  if saturating.saturating_abs(-9223372036854775808) != 9223372036854775807 { io.println("sat abs"); return 22; }
  if saturating.saturating_pow(2, 10) != 1024 { io.println("sat pow"); return 23; }

  if wrapping.wrapping_add(9223372036854775807, 1) != -9223372036854775808 { io.println("wrap add"); return 24; }
  if wrapping.wrapping_mul(9223372036854775807, 2) != -2 { io.println("wrap mul"); return 25; }
  if wrapping.wrapping_neg(-9223372036854775808) != -9223372036854775808 { io.println("wrap neg"); return 26; }
  if wrapping.wrapping_abs(-9223372036854775808) != -9223372036854775808 { io.println("wrap abs"); return 27; }
  if wrapping.wrapping_shl(1, 65) != 2 { io.println("wrap shl"); return 28; }
  if wrapping.wrapping_shr(16, 68) != 1 { io.println("wrap shr"); return 29; }

  // NOTE: xiom.convert.overflow's (Int, Bool) returns cannot be compiled in
  // this compiler build (Bool-in-tuple emits invalid IR; see overflow.xi
  // TODO(compiler)) -- the four overflowing_* functions are not exercised.

  var ed = exact.exact_div(6, 3);
  match ed {
    Ok(v) => { if v != 2 { io.println("exact_div"); return 34; } },
    Err(e) => { io.println(string.str_concat("exact_div err ", e)); return 35; },
  }
  var edb = exact.exact_div(7, 3);
  match edb {
    Ok(_) => { io.println("exact_div not exact"); return 36; },
    Err(_) => {},
  }

  var ef = exact.exact_float(1.5, 0.5);
  match ef {
    Some(v) => { if v != 3.0 { io.println("exact_float"); return 37; } },
    None => { io.println("exact_float none"); return 38; },
  }
  var efz = exact.exact_float(1.0, 0.0);
  match efz {
    Some(_) => { io.println("exact_float div0"); return 39; },
    None => {},
  }

  var er = exact.exact_ratio(4, 6);
  match er {
    Some(t) => {
      if t.0 != 2 || t.1 != 3 { io.println(string.str_concat("exact_ratio ", string.str_concat(convert.int_to_string(t.0), string.str_concat("/", convert.int_to_string(t.1))))); return 40; }
    },
    None => { io.println("exact_ratio none"); return 41; },
  }

  if lossy.lossy_from_str("42") != 42 { io.println("lossy from_str"); return 42; }
  if lossy.lossy_from_str("abc") != 0 { io.println("lossy from_str bad"); return 43; }
  if lossy.lossy_from_float(3.9) != 3 { io.println("lossy from_float"); return 44; }
  if lossy.lossy_from_float(-3.9) != -3 { io.println("lossy from_float neg"); return 45; }
  if lossy.lossy_to_float("1.5") != 1.5 { io.println("lossy to_float"); return 46; }
  if lossy.lossy_to_float("xyz") != 0.0 { io.println("lossy to_float bad"); return 47; }
  var c = lossy.lossy_char("abc");
  if c != 'a' { io.println("lossy char"); return 48; }
  var c2 = lossy.lossy_char("");
  if c2 != '\0' { io.println("lossy char empty"); return 49; }

  if unchecked.unchecked_add(1, 2) != 3 { io.println("unchecked add"); return 50; }
  if unchecked.unchecked_sub(5, 3) != 2 { io.println("unchecked sub"); return 51; }
  if unchecked.unchecked_mul(6, 7) != 42 { io.println("unchecked mul"); return 52; }
  if unchecked.unchecked_shl(1, 5) != 32 { io.println("unchecked shl"); return 53; }
  if unchecked.unchecked_shr(32, 3) != 4 { io.println("unchecked shr"); return 54; }

  if !roundtrip.roundtrip_int("42") { io.println("rt int"); return 55; }
  if roundtrip.roundtrip_int("abc") { io.println("rt int bad"); return 56; }
  if !roundtrip.roundtrip_float("1.5") { io.println("rt float"); return 57; }
  if roundtrip.roundtrip_float("abc") { io.println("rt float bad"); return 58; }
  if !roundtrip.roundtrip_fixed(1.5, 2) { io.println("rt fixed"); return 59; }
  if !roundtrip.roundtrip_base(255, 16) { io.println("rt base"); return 60; }
  if roundtrip.roundtrip_base(255, 1) { io.println("rt base bad"); return 61; }

  io.println("OK");
  return 0;
}

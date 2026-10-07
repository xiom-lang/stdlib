// p_wave79_shapes.xi -- wave 79 shape validation: convert numeric shims
// (parse, int, toint, itos, atoi, fromstr, ftos, tofloat, unchecked,
// saturating)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-79 clause guards: empty/malformed parse paths
// (Result/Option presence only, never payloads), zero/negative formatting
// branches, invalid radix, padding widths, NaN/inf float faces, checked/
// saturating conversion clamps, and the unchecked/saturating arithmetic
// mirrors. Returns 0 when every case holds. `Vec.new()` temporaries passed
// as `&Vec` are bound first; no char casts, no odd-length hex.

module p_wave79_shapes

use xiom.convert.parse as cparse;
use xiom.convert.int as cint;
use xiom.convert.toint as ctoint;
use xiom.convert.itos as citos;
use xiom.convert.atoi as catoi;
use xiom.convert.fromstr as cfromstr;
use xiom.convert.ftos as cftos;
use xiom.convert.tofloat as ctofloat;
use xiom.convert.unchecked as cunchecked;
use xiom.convert.saturating as csat;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

fn main() -> Int {
  var nan = 0.0 / 0.0;
  var inf = 1.0 / 0.0;
  var neginf = 0.0 - inf;

  // ---- parse
  if !cparse.parse_int("").is_err { return 1; }
  if !cparse.parse_int("12").is_ok { return 2; }
  if !cparse.parse_int("+7").is_ok { return 3; }
  if !cparse.parse_int("x").is_err { return 4; }
  if !cparse.parse_int_radix("ff", 16).is_ok { return 5; }
  if !cparse.parse_int_radix("1", 1).is_err { return 6; }
  if !cparse.parse_int_radix("", 16).is_err { return 7; }
  if !cparse.parse_float("1.5").is_ok { return 8; }
  if !cparse.parse_float("").is_err { return 9; }
  if !cparse.parse_float("1e3").is_ok { return 10; }
  if !cparse.parse_float("1.2.3").is_err { return 11; }
  if !cparse.parse_bool("true").is_some { return 12; }
  if !cparse.parse_bool("false").is_some { return 13; }
  if !cparse.parse_bool("yes").is_none { return 14; }
  if !cparse.parse_char("a").is_some { return 15; }
  if !cparse.parse_char("").is_none { return 16; }
  if !cparse.parse_char("ab").is_none { return 17; }

  // ---- int
  if cint.int_to_string(0) != "0" { return 18; }
  if cint.int_to_string(-5) != "-5" { return 19; }
  if cint.int_to_string(12) != "12" { return 20; }
  if !cint.string_to_int("").is_err { return 21; }
  if !cint.string_to_int("42").is_ok { return 22; }
  if cint.int_to_base(0, 10) != "0" { return 23; }
  if cint.int_to_base(5, 1) != "" { return 24; }
  if cint.int_to_base(5, 37) != "" { return 25; }
  if cint.int_to_base(255, 16) != "ff" { return 26; }
  if !cint.base_to_int("", 10).is_err { return 27; }
  if !cint.base_to_int("ff", 16).is_ok { return 28; }
  if cint.int_to_hex(0) != "0" { return 29; }
  if cint.int_to_hex(255) != "ff" { return 30; }
  if !cint.int_from_hex("").is_err { return 31; }
  if !cint.int_from_hex("ff").is_ok { return 32; }
  if cint.int_to_octal(0) != "0" { return 33; }
  if cint.int_to_binary(0) != "0" { return 34; }

  // ---- toint
  if ctoint.to_int_saturating(nan) != 0 { return 35; }
  if ctoint.to_int_saturating(1.0e300) != INT_MAX { return 36; }
  if ctoint.to_int_saturating(-1.0e300) != INT_MIN { return 37; }
  if ctoint.to_int_saturating(2.5) != 2 { return 38; }
  if !ctoint.to_int_checked(nan).is_none { return 39; }
  if !ctoint.to_int_checked(1.0e300).is_none { return 40; }
  if !ctoint.to_int_checked(-1.0e300).is_none { return 41; }
  match ctoint.to_int_checked(2.5) {
    Some(v) => { if v != 2 { return 42; } }
    None => { return 43; }
  }

  // ---- itos
  if citos.itos(0) != "0" { return 44; }
  if citos.itos(7) != "7" { return 45; }
  if citos.itos_padded(0, 5) != "00000" { return 46; }
  if citos.itos_padded(7, 0) != "7" { return 47; }
  if citos.itos_signed(0) != "0" { return 48; }
  if citos.itos_signed(9) != "+9" { return 49; }

  // ---- atoi
  if catoi.atoi("") != 0 { return 50; }
  if catoi.atoi("42") != 42 { return 51; }
  if catoi.atoi("  7") != 7 { return 52; }
  if catoi.atoi("x") != 0 { return 53; }
  if catoi.atoi_or("x", 9) != 9 { return 54; }
  if catoi.atoi_or("0", 9) != 0 { return 55; }
  if catoi.atoi_radix("zz", 1) != 0 { return 56; }
  if catoi.atoi_radix("19", 8) != 1 { return 57; }

  // ---- fromstr
  if !cfromstr.from_str_int("").is_err { return 58; }
  if !cfromstr.from_str_int("42").is_ok { return 59; }
  if !cfromstr.from_str_float("").is_err { return 60; }
  if !cfromstr.from_str_float("2.5").is_ok { return 61; }
  if !cfromstr.from_str_bool("true").is_some { return 62; }
  if !cfromstr.from_str_bool("maybe").is_none { return 63; }

  // ---- ftos
  if cftos.ftos(nan) != "nan" { return 64; }
  if cftos.ftos(inf) != "inf" { return 65; }
  if cftos.ftos(1.5).len() < 1 { return 66; }
  if cftos.ftos_prec(nan, 2) != "nan" { return 67; }
  if cftos.ftos_prec(inf, 2) != "inf" { return 68; }
  if cftos.ftos_sci(nan, 2) != "nan" { return 69; }
  if cftos.ftos_sci(neginf, 2) != "-inf" { return 70; }

  // ---- tofloat
  if ctofloat.to_float(0) != 0.0 { return 71; }
  if ctofloat.to_float_saturating("") != 0.0 { return 72; }
  if ctofloat.to_float_saturating("2.5") != 2.5 { return 73; }
  if !ctofloat.to_float_checked("").is_none { return 74; }
  if !ctofloat.to_float_checked("2.5").is_some { return 75; }

  // ---- unchecked
  if cunchecked.unchecked_add(1, 0) != 1 { return 76; }
  if cunchecked.unchecked_add(2, 3) != 5 { return 77; }
  if cunchecked.unchecked_sub(5, 0) != 5 { return 78; }
  if cunchecked.unchecked_mul(5, 1) != 5 { return 79; }
  if cunchecked.unchecked_shl(5, 0) != 5 { return 80; }
  if cunchecked.unchecked_shr(5, 0) != 5 { return 81; }
  if cunchecked.unchecked_add(INT_MAX, 1) != INT_MIN { return 82; }

  // ---- saturating
  if csat.saturating_add(1, 0) != 1 { return 83; }
  if csat.saturating_add(INT_MAX, 1) != INT_MAX { return 84; }
  if csat.saturating_sub(5, 0) != 5 { return 85; }
  if csat.saturating_sub(INT_MIN, 1) != INT_MIN { return 86; }
  if csat.saturating_mul(5, 1) != 5 { return 87; }
  if csat.saturating_mul(INT_MAX, 2) != INT_MAX { return 88; }
  if csat.saturating_abs(0) != 0 { return 89; }
  if csat.saturating_abs(-5) != 5 { return 90; }
  if csat.saturating_abs(INT_MIN) != INT_MAX { return 91; }
  if csat.saturating_pow(2, 0) != 1 { return 92; }
  if csat.saturating_pow(1, 100) != 1 { return 93; }
  if csat.saturating_pow(2, 3) != 8 { return 94; }
  if csat.saturating_pow(2, -1) != 1 { return 95; }

  return 0;
}

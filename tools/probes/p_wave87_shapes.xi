// p_wave87_shapes.xi -- wave 87 shape validation: convert tails
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-87 clause guards: the root convert pins (int/float
// zero identities, fixed/sci string pins, bool mirrors, int_to_char
// range), the cstring null-pointer identities, the float module nan/zero
// pins, the json empty identities plus the escape length band, the
// punycode/idna empty-Ok identities, the strftime empty/percent/ISO pins,
// the strptime empty/layout/short guards and the tryfrom NaN/2^63/empty
// guards. Values returned from the module surface are bound before
// comparing/reading. Returns 0 when every case holds.

module p_wave87_shapes

use xiom.convert;
use xiom.convert.cstring as ccs;
use xiom.convert.float as cfloat;
use xiom.convert.json as cjson;
use xiom.convert.punycode as cpuny;
use xiom.convert.strftime as csf;
use xiom.convert.strptime as csp;
use xiom.convert.tryfrom as ctry;

fn main() -> Int {
  // ---- root convert
  if convert.int_to_float(0) != 0.0 { return 1; }
  if convert.float_to_int(0.0) != 0 { return 2; }
  if convert.int_to_string(0) != "0" { return 3; }
  let nan = 0.0 / 0.0;
  let ff_nan = convert.float_to_fixed_str(nan, 2);
  if ff_nan != "nan" { return 4; }
  let ff_pin = convert.float_to_fixed_str(1.5, 1);
  if ff_pin != "1.5" { return 5; }
  let ff_zero = convert.float_to_fixed_str(0.0, 0);
  if ff_zero != "0" { return 6; }
  let fs_nan = convert.float_to_sci_str(nan, 2);
  if fs_nan != "nan" { return 7; }
  let fs_pin = convert.float_to_sci_str(1.5, 1);
  if fs_pin != "1.5e+00" { return 8; }
  if convert.bool_to_string(true) != "true" { return 9; }
  if convert.bool_to_string(false) != "false" { return 10; }
  if convert.int_to_char(0 - 1).is_some { return 11; }
  if convert.int_to_char(1114112).is_some { return 12; }
  if convert.int_to_char(65).is_none { return 13; }

  // ---- cstring
  if ccs.from_cstring(0) != "" { return 14; }
  if ccs.cstring_len(0) != 0 { return 15; }

  // ---- float module
  let fstr_nan = cfloat.float_to_string(nan);
  if fstr_nan != "nan" { return 16; }
  let fstr_zero = cfloat.float_to_string(0.0);
  if fstr_zero != "0" { return 17; }
  if cfloat.string_to_float("").is_err == false { return 18; }
  if cfloat.string_to_float("1.5").is_ok == false { return 19; }
  let cff_nan = cfloat.float_to_fixed_str(nan, 2);
  if cff_nan != "nan" { return 20; }
  let cff_zero = cfloat.float_to_fixed_str(0.0, 0);
  if cff_zero != "0" { return 21; }
  let cfs_nan = cfloat.float_to_sci_str(nan, 2);
  if cfs_nan != "nan" { return 22; }
  let cfs_pin = cfloat.float_to_sci_str(1.5, 1);
  if cfs_pin != "1.5e+00" { return 23; }
  if cfloat.float_to_int(0.0) != 0 { return 24; }
  if cfloat.int_to_float(0) != 0.0 { return 25; }

  // ---- json
  let je0 = cjson.json_escape("");
  if je0 != "" { return 26; }
  let je1 = cjson.json_escape("\"");
  if je1.len() < 1 { return 27; }
  if cjson.json_unescape("").is_ok == false { return 28; }
  let jq0 = cjson.json_quote("");
  if jq0 != "\"\"" { return 29; }
  if cjson.json_is_valid("") { return 30; }
  if cjson.json_is_valid("{}") == false { return 31; }
  if cjson.json_pretty("").is_ok == false { return 32; }

  // ---- punycode / idna
  if cpuny.punycode_encode("").is_ok == false { return 33; }
  if cpuny.punycode_decode("").is_ok == false { return 34; }
  if cpuny.punycode_encode_domain("").is_ok == false { return 35; }
  if cpuny.punycode_decode_domain("").is_ok == false { return 36; }
  if cpuny.idna_to_ascii("").is_ok == false { return 37; }
  if cpuny.idna_to_unicode("").is_ok == false { return 38; }
  if cpuny.idna_is_valid("") { return 39; }
  if cpuny.idna_uts46_normalize("").is_ok == false { return 40; }
  if cpuny.punycode_encode("abc").is_ok == false { return 41; }

  // ---- strftime / strptime
  let d = Date{ year: 2026; month: 8; day: 12; };
  let sf0 = csf.strftime("", &d);
  if sf0 != "" { return 42; }
  let sfp = csf.strftime("%%", &d);
  if sfp != "%" { return 43; }
  let sfi = csf.strftime("%Y-%m-%d", &d);
  if sfi != "2026-08-12" { return 44; }
  let sfn = csf.strftime_now("");
  if sfn != "" { return 45; }

  let sp0 = csp.strptime("x", "");
  if sp0.is_ok { return 46; }
  let spi = csp.strptime("2026-08-12", "%Y-%m-%d");
  if spi.is_ok == false { return 47; }
  if spi.date.year != 2026 || spi.date.month != 8 || spi.date.day != 12 { return 48; }
  let sps = csp.strptime_iso8601("x");
  if sps.is_ok { return 49; }
  let spi2 = csp.strptime_iso8601("2026-08-12");
  if spi2.is_ok == false { return 50; }

  // ---- tryfrom
  if ctry.try_from_int(0).is_ok == false { return 51; }
  if ctry.try_from_float(nan).is_err == false { return 52; }
  if ctry.try_from_float(1.0e300).is_err == false { return 53; }
  if ctry.try_from_float(0.0 - 1.0e300).is_err == false { return 54; }
  if ctry.try_from_float(0.0).is_ok == false { return 55; }
  if ctry.try_from_str("").is_err == false { return 56; }
  if ctry.try_from_str("42").is_ok == false { return 57; }

  return 0;
}

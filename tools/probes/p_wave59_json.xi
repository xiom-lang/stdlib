// p_wave59_json.xi -- wave 59 JSON hardening probe
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Fix-first witnesses for the recorded JSON legacy bugs:
// - exponent grammar: "1e"/"1e+"/"1e-" must Err (were Ok 1);
// - integer grammar: "00"/"01" must Err (were Ok 0), "1."/".5" must Err;
// - exponent clamp: "1e4000000000" must Err fast (was Ok inf after ~3s;
//   longer digit runs effectively hung);
// - stringify finite guard: non-finite Numbers stringify as "null"
//   (were invalid JSON "inf").
// Also keeps valid-number regressions green (0.05, -0, 1e2, 42.5) and
// checks the new clauses' call shape. Returns 0 when every case holds.

module p_wave59_json

use xiom.serialize.json;

fn main() -> Int {
  if json.json_parse("1e").is_ok { return 1; }
  if json.json_parse("1e+").is_ok { return 2; }
  if json.json_parse("1e-").is_ok { return 3; }
  if json.json_parse("00").is_ok { return 4; }
  if json.json_parse("01").is_ok { return 5; }
  if json.json_parse("1.").is_ok { return 6; }
  if json.json_parse(".5").is_ok { return 7; }
  if !json.json_parse("0").is_ok { return 8; }
  if !json.json_parse("-0").is_ok { return 9; }
  match json.json_parse("0.05") {
    Ok(v) => {
      if !(json.json_stringify(v) == "0.05") { return 10; }
    },
    Err(_) => { return 11; },
  }
  if !json.json_parse("1e2").is_ok { return 12; }
  if !json.json_parse("1e4000000000").is_err { return 13; }
  var inf = 1.0e308 * 10.0;
  if !(json.json_stringify(json.json_number(inf)) == "null") { return 14; }
  if !(json.json_pretty(json.json_number(inf)) == "null") { return 15; }
  if !(json.json_stringify(json.json_number(42.5)) == "42.5") { return 16; }
  if !(json.json_stringify(json.json_null()) == "null") { return 17; }
  return 0;
}

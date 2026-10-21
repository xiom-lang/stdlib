// p_json_number_format.xi -- JSON number rendering must stay byte-identical
// to convert.float_to_string (the wave-208 allocation-free digit path).
// Covers fixed/scientific thresholds, rounding, subnormals and signs.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_number_format

use xiom.serialize.json;
use xiom.convert;
use xiom.io;

fn main() -> Int {
  var vals: Vec[Float64] = Vec[Float64].new();
  vals.push(0.0);
  vals.push(-0.0);
  vals.push(1.0);
  vals.push(-1.0);
  vals.push(1.5);
  vals.push(-1.5);
  vals.push(1821.0);
  vals.push(0.1);
  vals.push(-0.1);
  vals.push(3.141592653589793);
  vals.push(1234.5678);
  vals.push(-1234.5678);
  vals.push(0.0001);
  vals.push(0.00001);
  vals.push(-0.00001);
  vals.push(999999999999999.9);
  vals.push(1234567890123456.0);
  vals.push(1000000000000000.0);
  vals.push(10000000000000000.0);
  vals.push(1.0e14);
  vals.push(1.0e15);
  vals.push(1.0e-4);
  vals.push(1.0e-5);
  vals.push(9.007199254740992e15);
  vals.push(0.30000000000000004);
  vals.push(2.5);
  vals.push(2.5000000000000004);
  vals.push(1.0e300);
  vals.push(1.0e-300);
  vals.push(5.0e-324);
  vals.push(2.2250738585072014e-308);
  vals.push(1.7976931348623157e308);
  vals.push(-1.7976931348623157e308);

  var i = 0;
  while i < vals.len() {
    let v = vals[i];
    let got = json.json_stringify(json.json_number(v));
    let want = convert.float_to_string(v);
    if got != want {
      io.println("v idx " + i.to_str() + " got=[" + got + "] want=[" + want + "]");
      return 1;
    }
    i = i + 1;
  }
  return 0;
}

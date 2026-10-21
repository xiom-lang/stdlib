// p_json_number_random.xi -- deterministic random-magnitude parity between
// the allocation-free JSON number renderer and convert.float_to_string.
// Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_json_number_random

use xiom.io;
use xiom.serialize.json;
use xiom.convert;

fn main() -> Int {
  var seed: Int = 123456789;
  var i = 0;
  while i < 5000 {
    seed = (seed * 48271) % 2147483647;
    let exp = (seed % 600) - 300;
    seed = (seed * 48271) % 2147483647;
    let mant = seed % 1000000;
    var v = mant as Float64;
    var k = 0;
    if exp >= 0 {
      while k < exp {
        v = v * 10.0;
        k = k + 1;
      }
    } else {
      while k > exp {
        v = v / 10.0;
        k = k - 1;
      }
    }
    if (i % 2) == 1 { v = -v; }
    if v == v && v <= 1.7976931348623157e308 && v >= -1.7976931348623157e308 {
      let got = json.json_stringify(json.json_number(v));
      let want = convert.float_to_string(v);
      if got != want {
        io.println("mismatch i=" + i.to_str() + " got=[" + got + "] want=[" + want + "]");
        return 1;
      }
    }
    i = i + 1;
  }
  io.println("random number parity ok");
  return 0;
}

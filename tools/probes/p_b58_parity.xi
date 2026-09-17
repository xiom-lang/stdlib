// p_b58_parity.xi -- dedup parity probe: xiom.convert.base58 int legs vs
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// the xiom.num.convert radix helpers (Result-vs-Option and INT_MIN edges).
module p_b58_parity
use xiom.convert.base58 as cvt;
use xiom.num.convert as num;
use xiom.convert;
use xiom.io;

fn show_res(r: Result[Int, Str]) -> Str {
  match r {
    Ok(v) => { return "Ok:" + convert.int_to_string(v); },
    Err(e) => { return "Err:" + e; },
  }
}

fn show_opt(o: Option[Int]) -> Str {
  if o.is_some {
    return "Some:" + convert.int_to_string(o.value);
  };
  "None"
}

fn cmpv(n: Int) -> Int {
  let a = cvt.to_base58(n);
  let b = num.to_base58(n);
  if a == b {
    io.println("to(" + convert.int_to_string(n) + ") == " + a);
    return 0;
  };
  io.println("to(" + convert.int_to_string(n) + ") DIFF cvt=[" + a + "] num=[" + b + "]");
  1;
}

fn cmps(s: Str) -> Int {
  let a = show_res(cvt.from_base58(s));
  let b = show_opt(num.from_base58(s));
  io.println("from(" + s + ") cvt=" + a + " num=" + b);
  0;
}

fn main() -> Int {
  var bad = 0;
  bad = bad + cmpv(0);
  bad = bad + cmpv(1);
  bad = bad + cmpv(57);
  bad = bad + cmpv(58);
  bad = bad + cmpv(255);
  bad = bad + cmpv(-1);
  bad = bad + cmpv(-10);
  bad = bad + cmpv(-58);
  bad = bad + cmpv(9223372036854775807);
  bad = bad + cmpv(-9223372036854775807);
  bad = bad + cmpv(-9223372036854775808);

  cmps("1");
  cmps("B");
  cmps("21");
  cmps("-B");
  cmps("+B");
  cmps("");
  cmps("0");
  cmps("zzzzzzzzzzzzzzzzzzzzzzzz");
  cmps("-zzzzzzzzzzzzzzzzzzzzzzzz");

  io.println("P_B58_PARITY to-mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  0
}

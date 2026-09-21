// p_result_tuple_vec_loop.xi -- Result with a tuple payload containing a Vec
// mis-layouts the payload when a loop-local value feeds the Vec.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Surfaced by the -IncludeRefs generated tranche on xiom.net.tls_helper
// (2026-09-21). xiom.net.tls_helper.cert_public_key_info and
// cert_is_self_signed fail clang through asn1_read_oid:
//   xiominput.ll:8845:24: error: '%tmp334' defined with type '%struct.Vec
//   = type { ptr, i64, i64, i64 }' but expected '%struct.Result
//   = type { i64, i64, i64 }'
// The Result payload slot for the (Vec[Int], Int) payload is laid out as two
// scalars, so the Vec built in the match arm is stored into a scalar-sized
// slot. Shrunk empirically: the match over a tuple-Result plus a while loop
// whose body declares a local, accumulates, and pushes it into the Vec is
// sufficient; neither the callee nor an early return is required (nested
// simple loops and loop-free arms compile fine).
module p_result_tuple_vec_loop

pub fn f(data: &Vec[UInt8]) -> Result[(Vec[Int], Int), Str] {
  let tlv: Result[(Int, Int, Int), Str] = Ok((0x06, 0, 2));
  match tlv {
    Err(e) => Err(e);
    Ok(t) => {
      let end = t.2;
      var oid = Vec[Int].new();
      var i = 0;
      while i < end {
        var value: Int = 0;
        let b = data[i] as Int;
        value = value * 128 + (b & 0x7F);
        i = i + 1;
        oid.push(value);
      }
      Ok((oid, end));
    }
  }
}

fn main() -> Int {
  var v: Vec[UInt8] = Vec[UInt8].new();
  v.push(1 as UInt8);
  v.push(2 as UInt8);
  let r = f(&v);
  return 0;
}

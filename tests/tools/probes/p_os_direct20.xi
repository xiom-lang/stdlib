// p_os_direct20.xi -- OS-entropy multi-draw shape (recreation of the r17
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// p_os_direct17 probe family). Cross-module calls into
// crypto.os_secure_random_bytes and crypto_random_bytes, multi-draw with
// value compares. STATUS_BREAKPOINT / garbage == still compiler-broken;
// exit 0 with differing buffers == flip-ready.
module p_os_direct20
use xiom.crypto;
use xiom.crypto.rng_crypto;
use xiom.io;
use xiom.convert;

fn buf_sum(b: &Vec[UInt8]) -> Int {
  var s = 0;
  var i = 0;
  while i < b.len() {
    s = s + (b[i] as Int);
    i = i + 1;
  }
  return s;
}

fn main() -> Int {
  // multi-draw, cross-module, direct OS path
  var a = crypto.os_secure_random_bytes(32);
  var b = crypto.os_secure_random_bytes(32);
  var c = crypto.os_secure_random_bytes(32);
  var sa = buf_sum(&a);
  var sb = buf_sum(&b);
  var sc = buf_sum(&c);
  // draws must differ (non-determinism) and be non-empty
  if a.len() != 32 { io.println("len-a"); return 1; }
  if b.len() != 32 { io.println("len-b"); return 2; }
  if c.len() != 32 { io.println("len-c"); return 3; }
  if sa == sb && sb == sc { io.println("all-equal"); return 4; }
  // rng_crypto consumers (also cross-module)
  var r1 = crypto_random_bytes(16);
  var r2 = crypto_random_bytes(16);
  if r1.len() != 16 || r2.len() != 16 { io.println("rng-len"); return 5; }
  if buf_sum(&r1) == buf_sum(&r2) { io.println("rng-equal"); return 6; }
  // per-call single-draw path
  var one = crypto.os_secure_random_bytes(8);
  if one.len() != 8 { io.println("single-len"); return 7; }
  io.println("OK sums " + convert.int_to_string(sa) + "/" + convert.int_to_string(sb) + "/" + convert.int_to_string(sc));
  return 0;
}

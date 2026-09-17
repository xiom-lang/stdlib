// p_str_memcpy.xi -- re-test of the reverted string fast-path shape:
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// str_concat via Str-as-pointer casts + xiom_memcpy_dispatch in CHAINED
// self-concat (the night-session finding 13 failure mode).
module p_str_memcpy
use xiom.io;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn xiom_memcpy_dispatch(dest: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
}

fn concat_mm(a: Str, b: Str) -> Str {
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    xiom_memcpy_dispatch(buf + len_a, b as *UInt8, len_b as UInt);
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

fn main() -> Int {
  // Direct concat
  let d = concat_mm("foo", "bar");
  io.println("direct=" + d);
  if d != "foobar" { return 1; }

  // Chained self-concat: s = s + "ab" five times (finding 13: broke from 3rd link)
  var s = "";
  var i = 0;
  while i < 5 {
    s = concat_mm(s, "ab");
    io.println("link" + i + " len=" + s.len() + " val=" + s);
    i = i + 1;
  }
  if s != "ababababab" { io.println("chained mismatch"); return 2; }
  if s.len() != 10 { io.println("chained len"); return 3; }

  // Longer alternating chain
  var t = "x";
  var j = 0;
  while j < 6 {
    t = concat_mm(t, t);
    j = j + 1;
  }
  io.println("double len=" + t.len());
  if t.len() != 64 { io.println("double mismatch"); return 4; }

  io.println("STR MEMCPY OK");
  return 0;
}

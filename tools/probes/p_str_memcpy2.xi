// p_str_memcpy2.xi -- characterize the Str-cast memcpy failure:
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// (A) single source copy; (B) second source at buf+len_a; (C) byte-loop tail.
module p_str_memcpy2
use xiom.io;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn xiom_memcpy_dispatch(dest: *UInt8, src: *UInt8, n: UInt) -> *UInt8;
  fn xiom_byte_at(s: Str, pos: Int) -> UInt8;
}

// A: copy only the first source through the runtime.
fn copy_a(a: Str) -> Str {
  let len_a = a.len();
  unsafe {
    var buf = malloc(len_a + 1);
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    buf[len_a] = 0;
    return Str.from_cstring(buf);
  }
}

// B: first source via memcpy, second source byte-by-byte.
fn concat_b(a: Str, b: Str) -> Str {
  let len_a = a.len();
  let len_b = b.len();
  let total = len_a + len_b;
  unsafe {
    var buf = malloc(total + 1);
    xiom_memcpy_dispatch(buf, a as *UInt8, len_a as UInt);
    var j = 0;
    while j < len_b {
      buf[len_a + j] = xiom_byte_at(b, j);
      j = j + 1;
    }
    buf[total] = 0;
    return Str.from_cstring(buf);
  }
}

// C: second source via memcpy at buf + len_a.
fn concat_c(a: Str, b: Str) -> Str {
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
  io.println("A=[" + copy_a("hello") + "]");
  io.println("B=[" + concat_b("foo", "bar") + "]");
  io.println("C=[" + concat_c("foo", "bar") + "]");
  return 0;
}

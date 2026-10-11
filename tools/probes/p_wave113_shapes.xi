// p_wave113_shapes.xi -- wave 113 fix lock: str_chars / str_code_points go
// linear (cached base+length byte reads instead of the strnlen-ing
// char_at/byte_at accessors). Same family as REL-20261011-1453-xvector and
// REL-20261011-1543-xvector.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// (1) Value correctness, including the exact malformed-byte behavior:
//     str_chars returns the leading byte for a malformed sequence;
//     str_code_points keeps its masking decode (lone 0xC3 -> 192).
// (2) Bounded linearity: 400 KB strings convert well under the 500 ms
//     gate with a sub-quadratic 2x-size ratio.
// Returns 0 when every case holds.

module p_wave113_shapes

use xiom.string.slice;
use xiom.time;
use xiom.io;

fn main() -> Int {
  // ---- value correctness
  var chars = slice.str_chars("abc");
  if chars.len() != 3 { return 1; }
  if (chars[0] as Int) != 97 { return 1; }
  if (chars[1] as Int) != 98 { return 1; }
  if (chars[2] as Int) != 99 { return 1; }
  var uchars = slice.str_chars("e\u{03A9}");
  if uchars.len() != 2 { return 2; }
  if (uchars[0] as Int) != 101 { return 2; }
  if (uchars[1] as Int) != 937 { return 2; }
  var cps = slice.str_code_points("a\u{03A9}");
  if cps.len() != 2 { return 3; }
  if cps[0] != 97 { return 3; }
  if cps[1] != 937 { return 3; }
  var acps = slice.str_code_points("abc");
  if acps.len() != 3 { return 4; }
  if acps[0] != 97 || acps[1] != 98 || acps[2] != 99 { return 4; }

  // ---- malformed-byte locks (leading-byte / masking behavior)
  var mbuf = Vec[UInt8].new();
  mbuf.push(0xC3 as UInt8);
  let lone = Str::from_utf8(mbuf);
  var lchars = slice.str_chars(lone);
  if lchars.len() != 1 { return 5; }
  if (lchars[0] as Int) != 195 { return 5; }
  var lcps = slice.str_code_points(lone);
  if lcps.len() != 1 { return 6; }
  if lcps[0] != 192 { return 6; }

  // ---- bounded linearity: 200 KB vs 400 KB ASCII
  var big = Vec[UInt8].new();
  var k = 0;
  while k < 400000 {
    big.push(65 as UInt8);
    k = k + 1;
  }
  let s400 = Str::from_utf8(big);
  var small = Vec[UInt8].new();
  k = 0;
  while k < 200000 {
    small.push(65 as UInt8);
    k = k + 1;
  }
  let s200 = Str::from_utf8(small);

  let t0 = time.monotonic_ms();
  let c200 = slice.str_chars(s200);
  let dt_c200 = time.monotonic_ms() - t0;
  let t1 = time.monotonic_ms();
  let c400 = slice.str_chars(s400);
  let dt_c400 = time.monotonic_ms() - t1;
  let t2 = time.monotonic_ms();
  let p400 = slice.str_code_points(s400);
  let dt_p400 = time.monotonic_ms() - t2;
  io.println("chars200=" + dt_c200 + " chars400=" + dt_c400 + " cps400=" + dt_p400);
  if c400.len() != 400000 { return 7; }
  if p400.len() != 400000 { return 7; }
  if c200.len() != 200000 { return 7; }
  if dt_c400 > 500 { return 8; }
  if dt_p400 > 500 { return 8; }
  if dt_c200 >= 10 {
    if dt_c400 > dt_c200 * 3 { return 8; }
  }
  return 0;
}

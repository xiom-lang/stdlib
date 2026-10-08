// p_str_split_scale.xi -- probe lock: linear split/repeat/pad paths
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// ORBITDB relay 2026-10-08: str_split scanned with a slice per position and
// str_repeat/str_pad_* accumulated one piece at a time (quadratic; 5 MB WAL
// replays took ~44 s, and pad leaked one malloc per pad byte). The splitter
// now byte-compares in place, repeat builds by doubling and pads allocate
// once. This locks correctness at scale (~110 KB, built with nested repeats)
// so a regression to the quadratic paths shows up as a slow/failing probe.
// Returns 0 when every case holds.

module p_str_split_scale

use xiom.string;

fn main() -> Int {
  // Build ~110 KB in O(n) via nested repeats (also locks str_repeat).
  let c1 = string.str_repeat("abcde\n", 10);
  let big = string.str_repeat(c1, 2000);
  if big.len() != 120000 { return 1; }

  let parts = string.str_split(big, "\n");
  if parts.len() != 20001 { return 2; }
  let p0 = parts[0];
  if p0 != "abcde" { return 3; }
  let p100 = parts[100];
  if p100 != "abcde" { return 4; }
  let last = parts[20000];
  if last != "" { return 5; }

  // Multi-char delimiter correctness on the same payload.
  let halves = string.str_split(big, "abcde\n");
  if halves.len() != 20001 { return 6; }
  let h1 = halves[1];
  if h1 != "" { return 7; }

  // Empty-delimiter path stays per-byte.
  let chars = string.str_split("ab", "");
  if chars.len() != 2 { return 8; }
  let ch0 = chars[0];
  if ch0 != "a" { return 9; }

  // Pad paths: one allocation, exact widths.
  let pl = string.str_pad_left("7", 5, '0');
  if pl != "00007" { return 10; }
  if pl.len() != 5 { return 11; }
  let pr = string.str_pad_right("7", 5, '.');
  if pr != "7...." { return 12; }
  if pr.len() != 5 { return 13; }
  let wide = string.str_pad_left("x", 1000, ' ');
  if wide.len() != 1000 { return 14; }

  // Repeat edge cases.
  let r0 = string.str_repeat("ab", 0);
  if r0 != "" { return 15; }
  let r5 = string.str_repeat("ab", 5);
  if r5 != "ababababab" { return 16; }
  let r1 = string.str_repeat("ab", 1);
  if r1 != "ab" { return 17; }

  return 0;
}

// p_wave285_hpack_huffman.xi -- RFC 7541 Huffman codec.
// Locks the four Appendix C example strings, round-trips, the H=1 string
// wrapper, empty input, bad padding and EOS rejection. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave285_hpack_huffman

use xiom.net.h2;

fn mk(vals: &Vec[Int]) -> Vec[UInt8] {
  var out = Vec[UInt8].new();
  var i = 0;
  while i < vals.len() {
    out.push(vals[i] as UInt8);
    i = i + 1;
  }
  return out;
}

fn same(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  return true;
}

fn main() -> Int {
  // 1) www.example.com: f1e3c2e5f23a6ba0ab90f4ff
  var v1 = Vec[Int].new();
  v1.push(0xf1); v1.push(0xe3); v1.push(0xc2); v1.push(0xe5);
  v1.push(0xf2); v1.push(0x3a); v1.push(0x6b); v1.push(0xa0);
  v1.push(0xab); v1.push(0x90); v1.push(0xf4); v1.push(0xff);
  let b1 = mk(&v1);
  let d1 = h2.h2_hpack_huffman_decode(&b1);
  if d1.is_err { return 1; }
  if d1.value != "www.example.com" { return 2; }
  let e1 = h2.h2_hpack_huffman_encode("www.example.com");
  if !same(&e1, &b1) { return 3; }

  // 2) no-cache: a8eb10649cbf
  var v2 = Vec[Int].new();
  v2.push(0xa8); v2.push(0xeb); v2.push(0x10);
  v2.push(0x64); v2.push(0x9c); v2.push(0xbf);
  let b2 = mk(&v2);
  let d2 = h2.h2_hpack_huffman_decode(&b2);
  if d2.is_err { return 4; }
  if d2.value != "no-cache" { return 5; }
  if !same(&h2.h2_hpack_huffman_encode("no-cache"), &b2) { return 6; }

  // 3) custom-key: 25a849e95ba97d7f
  var v3 = Vec[Int].new();
  v3.push(0x25); v3.push(0xa8); v3.push(0x49); v3.push(0xe9);
  v3.push(0x5b); v3.push(0xa9); v3.push(0x7d); v3.push(0x7f);
  let b3 = mk(&v3);
  let d3 = h2.h2_hpack_huffman_decode(&b3);
  if d3.is_err { return 7; }
  if d3.value != "custom-key" { return 8; }
  if !same(&h2.h2_hpack_huffman_encode("custom-key"), &b3) { return 9; }

  // 4) custom-value: 25a849e95bb8e8b4bf
  var v4 = Vec[Int].new();
  v4.push(0x25); v4.push(0xa8); v4.push(0x49); v4.push(0xe9);
  v4.push(0x5b); v4.push(0xb8); v4.push(0xe8); v4.push(0xb4);
  v4.push(0xbf);
  let b4 = mk(&v4);
  let d4 = h2.h2_hpack_huffman_decode(&b4);
  if d4.is_err { return 10; }
  if d4.value != "custom-value" { return 11; }
  if !same(&h2.h2_hpack_huffman_encode("custom-value"), &b4) { return 12; }

  // 5) Single 'a' (code 00011, 3 one-bit pad) = 0x1f.
  var v5 = Vec[Int].new();
  v5.push(0x1f);
  let b5 = mk(&v5);
  let d5 = h2.h2_hpack_huffman_decode(&b5);
  if d5.is_err { return 13; }
  if d5.value != "a" { return 14; }
  if !same(&h2.h2_hpack_huffman_encode("a"), &b5) { return 15; }

  // 6) Empty input: empty output; encode empty.
  let empty = Vec[UInt8].new();
  let de = h2.h2_hpack_huffman_decode(&empty);
  if de.is_err { return 16; }
  if de.value != "" { return 17; }
  if h2.h2_hpack_huffman_encode("").len() != 0 { return 18; }

  // 7) Round-trip.
  let rt = h2.h2_hpack_huffman_encode("hello, h2");
  let rd = h2.h2_hpack_huffman_decode(&rt);
  if rd.is_err { return 19; }
  if rd.value != "hello, h2" { return 20; }

  // 8) Complete H=1 HPACK string: 0x8c + 12 Huffman bytes.
  let hs = h2.h2_hpack_string_encode_huffman("www.example.com");
  if hs.len() != 13 { return 21; }
  if hs[0] != 0x8c { return 22; }
  let hd = h2.h2_hpack_string_decode(&hs, 0);
  if hd.is_err { return 23; }
  if hd.value.0 != "www.example.com" { return 24; }
  if hd.value.1 != 13 { return 25; }

  // 9) Bad padding (3 zero bits after '0') is rejected.
  var bad = Vec[Int].new();
  bad.push(0x00);
  let bb = mk(&bad);
  if h2.h2_hpack_huffman_decode(&bb).is_ok { return 26; }

  // 10) 8 one-bits of padding is too long and rejected.
  var pad = Vec[Int].new();
  pad.push(0xff);
  let pb = mk(&pad);
  if h2.h2_hpack_huffman_decode(&pb).is_ok { return 27; }

  // 11) EOS (30 ones) is rejected.
  var eos = Vec[Int].new();
  eos.push(0xff); eos.push(0xff); eos.push(0xff); eos.push(0xff);
  let eb = mk(&eos);
  if h2.h2_hpack_huffman_decode(&eb).is_ok { return 28; }

  return 0;
}

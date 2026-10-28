// huffman_compress on a 5000-byte Vec crashes with SIGILL (rc 132) on
// Linux v0.65.2 and STATUS_ILLEGAL_INSTRUCTION (0xC000001D) on Windows
// v0.65.2 (1/3, allocator-state dependent) and the 2026-10-28 candidate
// (3/3); v0.64.8 is rc 0 on both platforms. Discovered by the pre-release
// matrix: the Ubuntu heavy leg's only smoke failure was
// smoke_compress_roundtrip_family (run_exit 132); this is the minimal step
// inside it. Windows smokes did not catch it (input/inlining/allocator
// state), so keep this repro.
//
// Expected: run rc 0 (decompressed length 5000).
// Observed: v0.65.2 linux-x64 SIGILL 132 3/3; v0.64.8 linux-x64 rc 0;
//           v0.65.2 windows-x64 0xC000001D 1/3 then 0; candidate
//           windows-x64 0xC000001D 3/3; v0.64.8 windows-x64 rc 0.
//
// Tracked on the relay as REL-20261028-1801-stdlib (+ the Windows
// correction item), 2026-10-28.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_huffman_compress_5000_linux

use xiom.compress.huffman;

fn mk(n: Int, seed: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push((65 + ((i * 7 + seed) % 26)) as UInt8);
    i += 1;
  }
  return v;
}

fn main() -> Int {
  var b = mk(5000, 3);
  var h = huffman.huffman_compress(&b);
  match huffman.huffman_decompress(&h) {
    Ok(out) => {
      if out.len() != 5000 { return 1; }
    },
    Err(_) => { return 2; },
  }
  return 0;
}

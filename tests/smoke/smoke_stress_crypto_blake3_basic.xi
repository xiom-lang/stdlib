// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_blake3_basic
use xiom.crypto;
use xiom.encoding.hex;

// Wave 163 hardening: the smoke previously checked only the output LENGTH.
// After the wave-161 BLAKE2b tail-load discovery, the BLAKE3 surface gets
// real known-answer rows: the canonical empty and "abc" digests (BLAKE3
// team vectors) plus the multi-chunk pattern bytes (i % 251) at 1024 and
// 1025 bytes, cross-checked against the reference blake3 implementation.
// Rows: 1 empty KAT, 2 "abc" KAT, 3 1024-byte chunk KAT, 4 1025-byte
// tree KAT, 5 the original "xiom" length check.

fn main() -> Int {
    // 1: empty input.
    var empty = Vec[UInt8].new();
    if hex.hex_encode(&crypto.blake3(&empty)) != "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262" {
      return 1;
    }

    // 2: "abc".
    var abc = Vec[UInt8].new();
    abc.push(97u8);
    abc.push(98u8);
    abc.push(99u8);
    if hex.hex_encode(&crypto.blake3(&abc)) != "6437b3ac38465133ffb63b75273a8db548c558465d79db03fd359c6cd5bd9d85" {
      return 2;
    }

    // 3: 1024-byte pattern (one full chunk).
    var d1024 = Vec[UInt8].new();
    var i = 0;
    while i < 1024 {
      d1024.push((i % 251) as UInt8);
      i = i + 1;
    };
    if hex.hex_encode(&crypto.blake3(&d1024)) != "42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7" {
      return 3;
    }

    // 4: 1025-byte pattern (tree: one full chunk + a 1-byte final chunk).
    var d1025 = Vec[UInt8].new();
    var j = 0;
    while j < 1025 {
      d1025.push((j % 251) as UInt8);
      j = j + 1;
    };
    if hex.hex_encode(&crypto.blake3(&d1025)) != "d00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444" {
      return 4;
    }

    // 5: original length check on "xiom".
    var data = Vec[UInt8].new();
    data.push(120u8);
    data.push(105u8);
    data.push(111u8);
    data.push(109u8);

    var hash = crypto.blake3(&data);

    if hash.len() == 32 {
      return 0;
    }
    return 5;
}

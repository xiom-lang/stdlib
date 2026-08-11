// XIOM - Hashing: Adler-32
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.adler

// Depends on: none

// ============================================================================
// Adler-32 is a fast rolling checksum, weaker than CRC-32 but useful for
// streaming and delta checks where cheap recomputation matters. NOTE: current
// implementation lives in hash.crc.adler32 - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn adler32(data: &Vec[UInt8]) -> UInt32 - compute the Adler-32 checksum over data. TODO(compiler): implement.
// fn adler32_str(s: Str) -> UInt32 - compute the Adler-32 checksum of a string. TODO(compiler): implement.
// fn adler32_combine(a: UInt32, b: UInt32, len_b: Int) -> UInt32 - combine two Adler-32 checksums as if both blocks were concatenated. TODO(compiler): implement.

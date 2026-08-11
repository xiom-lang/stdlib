// XIOM - Hashing: T1HA (Fast Positive Hash)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.hash.t1ha

// ============================================================================
// T1HA is a family of fast non-cryptographic hashes from Positive Technologies
// that is among the fastest on modern x86-64 while keeping good distribution.
// t1ha0 is the latency-optimised portable variant; t1ha1 and t1ha2 trade a
// little speed for stronger avalanche across different message lengths.
// ============================================================================

// fn t1ha0(data: &Vec[UInt8], seed: UInt64) -> UInt64 - t1ha0 latency-optimised portable 64-bit hash. TODO(compiler): implement.
// fn t1ha1(data: &Vec[UInt8], seed: UInt64) -> UInt64 - t1ha1 64-bit hash, well-tuned for medium inputs. TODO(compiler): implement.
// fn t1ha2(data: &Vec[UInt8], seed: UInt64) -> UInt64 - t1ha2 64-bit hash, strongest avalanche of the family. TODO(compiler): implement.
// fn t1ha2_atonce(data: &Vec[UInt8]) -> UInt64 - t1ha2 one-shot 64-bit hash with implicit zero seed. TODO(compiler): implement.
// fn t1ha2_atonce128(data: &Vec[UInt8]) -> (UInt64, UInt64) - t1ha2 one-shot 128-bit digest as two 64-bit words. TODO(compiler): implement.
// fn t1ha_ia32(data: &Vec[UInt8], seed: UInt64) -> UInt64 - t1ha variant tuned for IA-32 targets (smaller state). TODO(compiler): implement.

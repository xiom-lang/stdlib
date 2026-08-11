// XIOM - Serialize: Endian
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.endian

// Depends on: xiom.serialize

// ============================================================================
// Explicit little- and big-endian reads and writes of integers and floats.
// NOTE: current implementation lives in serialize.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn write_u16_le(out: &mut Vec[UInt8], v: UInt16) - append v as two little-endian bytes. TODO(compiler): implement.
// fn write_u32_le(out, v) - append v as four little-endian bytes. TODO(compiler): implement.
// fn write_u64_le(out, v) - append v as eight little-endian bytes. TODO(compiler): implement.
// fn write_u16_be(out, v) - append v as two big-endian bytes. TODO(compiler): implement.
// fn write_u32_be(out, v) - append v as four big-endian bytes. TODO(compiler): implement.
// fn write_u64_be(out, v) - append v as eight big-endian bytes. TODO(compiler): implement.
// fn read_u16_le(data: &Vec[UInt8], pos: Int) -> UInt16 - read a little-endian UInt16 at pos. TODO(compiler): implement.
// fn read_u32_le(data, pos) -> UInt32 - read a little-endian UInt32 at pos. TODO(compiler): implement.
// fn read_u64_le(data, pos) -> UInt64 - read a little-endian UInt64 at pos. TODO(compiler): implement.
// fn read_u16_be(data, pos) -> UInt16 - read a big-endian UInt16 at pos. TODO(compiler): implement.
// fn read_u32_be(data, pos) -> UInt32 - read a big-endian UInt32 at pos. TODO(compiler): implement.
// fn read_u64_be(data, pos) -> UInt64 - read a big-endian UInt64 at pos. TODO(compiler): implement.
// fn write_i64_le(out, v: Int) - append v as eight little-endian bytes. TODO(compiler): implement.
// fn read_i64_le(data, pos) -> Int - read a little-endian signed 64-bit value at pos. TODO(compiler): implement.
// fn write_f64_le(out, v: Float64) - append the IEEE-754 bit pattern of v little-endian. TODO(compiler): implement.
// fn read_f64_le(data, pos) -> Float64 - read a little-endian IEEE-754 double at pos. TODO(compiler): implement.

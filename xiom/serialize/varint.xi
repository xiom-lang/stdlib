// XIOM - Serialize: VarInt
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.serialize.varint

// Depends on: xiom.serialize

// ============================================================================
// LEB128 variable-length integer encoding with zigzag and unsigned forms.
// NOTE: current implementation lives in serialize.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn varint_encode(value: Int) -> Vec[UInt8] - encode value as LEB128 bytes. TODO(compiler): implement.
// fn varint_decode(bytes: &Vec[UInt8]) -> Result[(Int, Int), Str] - decode a varint; returns (value, consumed). TODO(compiler): implement.
// fn varint_size(value: Int) -> Int - the number of bytes needed to encode value. TODO(compiler): implement.
// fn zigzag_encode(n: Int) -> Int - map signed n to an unsigned zigzag value. TODO(compiler): implement.
// fn zigzag_decode(n: Int) -> Int - invert zigzag_encode. TODO(compiler): implement.
// fn uvarint_encode(value: UInt64) -> Vec[UInt8] - encode value as unsigned LEB128 bytes. TODO(compiler): implement.
// fn uvarint_decode(bytes) -> Result[(UInt64, Int), Str] - decode an unsigned varint; the tuple is (value, consumed). TODO(compiler): implement.
// fn varint_encode_slice(values: &Vec[Int]) -> Vec[UInt8] - encode each value back-to-back. TODO(compiler): implement.
// fn varint_decode_slice(bytes) -> Result[Vec[Int], Str] - decode a stream of varints. TODO(compiler): implement.

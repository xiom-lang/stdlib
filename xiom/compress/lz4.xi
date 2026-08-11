// XIOM - Compression: LZ4
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.lz4

// Depends on: xiom.string

// ============================================================================
// LZ4 fast compression in block, frame, and high-compression forms. NOTE:
// current implementation lives in compress.xi - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn lz4_compress(data: &Vec[UInt8]) -> Vec[UInt8] - compress bytes into an LZ4 frame. TODO(compiler): implement.
// fn lz4_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] - decompress an LZ4 frame. TODO(compiler): implement.
// fn lz4_compress_block(data) -> Vec[UInt8] - compress a raw block without frame header. TODO(compiler): implement.
// fn lz4_decompress_block(data) -> Result[Vec[UInt8], Str] - decompress a raw block. TODO(compiler): implement.
// fn lz4_compress_hc(data) -> Vec[UInt8] - high-compression mode. TODO(compiler): implement.
// fn lz4_bound(len: Int) -> Int - worst-case compressed size for len input bytes. TODO(compiler): implement.
// fn lz4_compress_frame(data) -> Vec[UInt8] - full frame format with magic and block sizes. TODO(compiler): implement.
// fn lz4_decompress_frame(data) -> Result[Vec[UInt8], Str] - parse and decompress an LZ4 frame. TODO(compiler): implement.

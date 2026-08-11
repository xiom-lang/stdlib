// XIOM - Compression: Snappy
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.snappy

// Depends on: xiom.string

// ============================================================================
// Snappy fast compression with frame and raw forms. NOTE: current
// implementation lives in compress.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn snappy_compress(data: &Vec[UInt8]) -> Vec[UInt8] - compress bytes into a raw snappy stream. TODO(compiler): implement.
// fn snappy_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] - decompress a raw snappy stream. TODO(compiler): implement.
// fn snappy_compress_frame(data) -> Vec[UInt8] - compress into a framed stream with a varint length. TODO(compiler): implement.
// fn snappy_decompress_frame(data) -> Result[Vec[UInt8], Str] - decompress a framed stream. TODO(compiler): implement.
// fn snappy_max_compressed_len(len: Int) -> Int - upper bound on compressed size for len input bytes. TODO(compiler): implement.
// fn snappy_uncompressed_len(data) -> Result[Int, Str] - read the varint uncompressed length. TODO(compiler): implement.
// fn snappy_validate(data) -> Bool - sanity-check the varint header. TODO(compiler): implement.

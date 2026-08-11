// XIOM - Compression: LZ77
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.compress.lz77

// Depends on: xiom.string

// ============================================================================
// LZ77 sliding-window compression. NOTE: current implementation lives in
// compress.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn lz77_compress(data: &Vec[UInt8]) -> Vec[UInt8] - compress using a sliding-window search. TODO(compiler): implement.
// fn lz77_decompress(data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] - undo an LZ77 token stream. TODO(compiler): implement.
// fn lz77_find_longest_match(data, pos, window) -> (Int, Int) - locate the best match; tuple is (length, distance). TODO(compiler): implement.
// fn lz77_token_encode(length, distance) -> Int - pack a length/distance pair into a token. TODO(compiler): implement.
// fn lz77_token_decode(token: Int) -> (Int, Int) - unpack a token; tuple is (length, distance). TODO(compiler): implement.
